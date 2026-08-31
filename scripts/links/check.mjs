/**
 * Internal link checker for the built site. Runs in ci.yml as a blocking gate.
 *
 * This exists because lychee structurally cannot do it. Given `--root-dir`, it
 * resolves a root-relative link like `/#about` to the *directory*
 * `site/dist` — and a directory has no fragments, so every one of the
 * sidebar's links is reported as a missing fragment. There is no index-file
 * option to fix that: `--fallback-extensions` only applies to paths that do
 * not exist, and the directory does.
 *
 * So the division of labour is:
 *   lychee      external URLs, and links inside the markdown docs
 *   this file   every SAME-SITE link in the built HTML, plus its fragment —
 *               root-relative (`/#about`) and absolute (`https://…/blog/`)
 *
 * Absolute same-site links are checked here, and NOT by lychee, because
 * lychee would resolve them over the network against the *currently deployed*
 * site. Every page carries a canonical URL pointing at itself, so a page that
 * is new in this build has a canonical that 404s until the build ships —
 * which made the gate fail on every new page ever added, while saying nothing
 * about whether any link was correct. Resolved against site/dist instead, the
 * same URL answers the question actually worth asking.
 *
 * The alternative was to turn fragment checking off and trust that section ids
 * and the links pointing at them stay in step. They are generated from one
 * file (`site/src/data/sections.ts`), so mostly they must — but `#top` is
 * hand-written in the masthead, and "mostly enforced by construction" is the
 * reasoning that has already let two unrun gates through in this repo.
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, relative } from 'node:path';
import { pathToFileURL } from 'node:url';

const root = resolve(process.argv[2] ?? 'site/dist');

// DECISIONS.md #25 — the domain lives in astro.config.mjs and Terraform, and
// nowhere else. Read it from the config rather than adding a third copy here;
// a link checker with its own idea of the domain would keep passing through
// the migration this rule exists to make cheap.
const siteUrl = (await import(pathToFileURL(resolve('site/astro.config.mjs')).href)).default.site;
const siteOrigin = siteUrl ? new URL(siteUrl).origin : null;

if (!existsSync(root)) {
  console.error(`No build at ${root} — run \`npm run build\` in site/ first.`);
  process.exit(1);
}

const pages = [];
(function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) walk(path);
    else if (path.endsWith('.html')) pages.push(path);
  }
})(root);

/** Resolve a root-relative path the way a static host does. */
function resolveTarget(pathname, fromPage) {
  if (pathname === '') return fromPage; // "#about" on the current page
  let target = join(root, pathname);
  if (existsSync(target) && statSync(target).isDirectory()) target = join(target, 'index.html');
  else if (!existsSync(target) && existsSync(`${target}/index.html`)) target = `${target}/index.html`;
  return target;
}

const failures = [];
let checked = 0;

for (const page of pages) {
  const html = readFileSync(page, 'utf8');

  // Root-relative links, plus absolute ones pointing back at this same site —
  // canonical, og:url, and anything hand-written with the full domain. The
  // absolute ones are normalised to a path so both kinds resolve against the
  // build by exactly the same rules below.
  const links = [...html.matchAll(/(?:href|src)="([^"]+)"/g)]
    .map((m) => m[1])
    .map((href) => {
      if (href.startsWith('/')) return href;
      if (siteOrigin && href.startsWith(siteOrigin)) {
        const rest = href.slice(siteOrigin.length);
        return rest === '' ? '/' : rest;
      }
      return null; // external, mailto:, a fragment on this page, a data: URI
    })
    .filter((href) => href !== null);

  for (const link of new Set(links)) {
    checked++;
    const [pathname, fragment] = link.split('#');
    const target = resolveTarget(pathname, page);
    const where = relative(root, page).replaceAll('\\', '/');

    if (!existsSync(target)) {
      failures.push(`${where}  ->  ${link}  (no such file: ${relative(root, target)})`);
      continue;
    }
    if (!fragment) continue;
    // Only HTML carries fragments; a link into a PDF or an image with one is
    // a mistake worth reporting rather than skipping.
    if (!target.endsWith('.html')) {
      failures.push(`${where}  ->  ${link}  (fragment on a non-HTML target)`);
      continue;
    }
    const targetHtml = readFileSync(target, 'utf8');
    if (!new RegExp(`id="${fragment}"|name="${fragment}"`).test(targetHtml)) {
      failures.push(`${where}  ->  ${link}  (no id="${fragment}" in ${relative(root, target)})`);
    }
  }
}

if (failures.length > 0) {
  console.error(`${failures.length} broken internal link(s):\n`);
  for (const failure of failures) console.error(`  ${failure}`);
  process.exit(1);
}

console.log(`${checked} internal links across ${pages.length} pages — all resolve, fragments included.`);
