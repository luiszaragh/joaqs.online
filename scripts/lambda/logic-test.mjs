/**
 * Offline tests for the chatbot's pure logic. DECISIONS.md #63.
 *
 *     node scripts/lambda/logic-test.mjs
 *
 * Runs with no AWS credentials and no node_modules: it reads the FUNCTIONS OUT
 * OF lambda/index.mjs and evaluates them, so it tests the source that actually
 * deploys rather than a copy that can drift away from it.
 *
 * It exists because this is where the subtle bugs have been. Address parsing
 * looked right and silently put every IPv6 visitor in one rate-limit bucket;
 * the prune bound looked bounded and could build an expression past a hard
 * DynamoDB limit. Neither is visible by reading, both are one assertion away.
 *
 * Not wired into ci.yml yet — worth doing, since a test nobody runs is the
 * failure mode this repo has already hit twice (#53, #57).
 */

import { readFileSync } from 'node:fs';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

// Pull the REAL functions out of the shipped source so this tests what deploys.
const src = readFileSync('lambda/index.mjs', 'utf8');
function grab(name) {
  const i = src.indexOf(`function ${name}(`);
  if (i < 0) throw new Error(`not found: ${name}`);
  let d = 0, started = false;
  for (let j = i; j < src.length; j++) {
    if (src[j] === '{') { d++; started = true; }
    else if (src[j] === '}') { d--; if (started && d === 0) return src.slice(i, j + 1); }
  }
}
const IP_SALT = 'test-salt';
const REPLY_KEY = createHmac('sha256', IP_SALT).update('reply-signing').digest();
const mod = new Function('createHash','createHmac','timingSafeEqual','IP_SALT','REPLY_KEY','Buffer',
  `${grab('ipv6Prefix')}\n${grab('viewerAddress')}\n${grab('signReply')}\n${grab('verifyReply')}
   return { ipv6Prefix, viewerAddress, signReply, verifyReply };`
)(createHash, createHmac, timingSafeEqual, IP_SALT, REPLY_KEY, Buffer);

let fail = 0;
const eq = (got, want, label) => {
  const ok = got === want;
  if (!ok) fail++;
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${label}${ok ? '' : `\n         got ${JSON.stringify(got)} want ${JSON.stringify(want)}`}`);
};
const ev = (h) => ({ headers: { 'cloudfront-viewer-address': h }, requestContext: { http: {} } });

console.log('viewerAddress — IPv4');
eq(mod.viewerAddress(ev('203.0.113.9:54321')), '203.0.113.9', 'ipv4 keeps full address');

console.log('viewerAddress — IPv6 (the bug)');
eq(mod.viewerAddress(ev('2001:db8::1:54321')), '2001:db8:0:0', 'no longer collapses to "2001"');
eq(mod.viewerAddress(ev('2001:4860:4860::8888:443')), '2001:4860:4860:0', 'distinct /64 stays distinct');
const a = mod.viewerAddress(ev('2001:db8:1:2:aaaa:bbbb:cccc:dddd:443'));
const b = mod.viewerAddress(ev('2001:db8:1:2:9999:8888:7777:6666:443'));
eq(a, b, 'same /64, different host -> same bucket (limit not evadable)');
const c = mod.viewerAddress(ev('2001:db8:1:3:aaaa:bbbb:cccc:dddd:443'));
eq(a !== c, true, 'different /64 -> different bucket');

console.log('viewerAddress — fallbacks');
eq(mod.viewerAddress({ headers: {}, requestContext: { http: { sourceIp: '198.51.100.7' } } }), '198.51.100.7', 'falls back to sourceIp');
eq(mod.viewerAddress({ headers: {}, requestContext: { http: {} } }), 'unknown', 'no address at all');

console.log('reply signing');
const sig = mod.signReply('Luis holds three AWS certifications.');
eq(mod.verifyReply('Luis holds three AWS certifications.', sig), true, 'genuine reply verifies');
eq(mod.verifyReply('Luis holds ten AWS certifications.', sig), false, 'tampered text rejected');
eq(mod.verifyReply('anything', undefined), false, 'missing signature rejected');
eq(mod.verifyReply('anything', 'x'.repeat(32)), false, 'forged signature rejected');

console.log('prune expression bound');
const MAX = 60;
const evict = Array.from({ length: MAX }, (_, i) => `k${i}`);
const expr = `REMOVE ${evict.map((_, i) => `#viewers.#s${i}`).join(', ')}`;
eq(expr.length < 4096, true, `expression is ${expr.length} bytes, under DynamoDB's 4 KB limit`);

console.log(fail === 0 ? '\nALL PASS' : `\n${fail} FAILED`);
process.exit(fail ? 1 : 0);
