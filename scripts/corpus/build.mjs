/**
 * Builds the chatbot's knowledge corpus from the site's own content.
 * DECISIONS.md #20, #29, #33.
 *
 * Runs as the site's `prebuild` script, so it cannot be forgotten: every
 * `npm run build` regenerates it, `astro build` copies it into dist/, and
 * site.yml's existing S3 sync publishes it. The Lambda fetches it from that
 * bucket on cold start.
 *
 * The whole point is that there is ONE source of truth. The bot answers from
 * the same profile.ts, posts.ts and project data the page renders, so it
 * cannot claim a certification the page does not show, or miss a project that
 * shipped yesterday. Drift is impossible by construction rather than by
 * discipline.
 *
 * Output: site/public/corpus.json (gitignored — it is a build artifact).
 *
 * Node imports the .ts data files directly via type stripping (Node >= 22.18;
 * .nvmrc pins 24). No build step, no duplicated copy of the data.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const siteRoot = resolve(here, '../../site');
const outFile = resolve(siteRoot, 'public/corpus.json');

const { profile, experience, projects, skills } = await import(
  new URL('../../site/src/data/profile.ts', import.meta.url).href
);
const { posts } = await import(new URL('../../site/src/data/posts.ts', import.meta.url).href);

// Only what the bot should be able to say. Deliberately NOT a dump of the
// whole module: anything added to profile.ts later has to be listed here to
// reach the bot, which is the safe default for a file that also holds contact
// details and future private notes.
const corpus = {
  // Bumped by hand when the shape changes. The Lambda refuses a corpus whose
  // schema it does not recognise rather than answering from a half-read file.
  schema: 1,
  generatedAt: new Date().toISOString(),

  identity: {
    name: profile.name,
    fullName: profile.fullName,
    role: profile.role,
    availability: profile.availability,
    location: `${profile.location.city}, ${profile.location.region}`,
    arrangements: profile.location.arrangements,
    education: profile.level,
    intro: profile.intro,
    email: profile.email,
    links: profile.links,
  },

  certifications: {
    earned: profile.certifications.earned.map((c) => `${c.code} — ${c.name}`),
    inProgress: profile.certifications.inProgress.map((c) => `${c.code} — ${c.name}`),
  },

  experience: experience.map((role) => ({
    role: role.role,
    org: role.org,
    kind: role.kind,
    period: `${role.start} – ${role.end} (${role.duration})`,
    location: role.location,
    highlights: role.bullets,
  })),

  projects: projects.map((project) => ({
    title: project.title,
    status: project.status,
    // The status note is what keeps the bot honest about unfinished work —
    // without it, a "rework" project reads to the model as a shipped one.
    statusNote: project.statusNote ?? null,
    summary: project.summary,
    stack: project.stack,
    repo: project.repo,
    url: project.status === 'live' ? `/projects/${project.slug}` : null,
  })),

  skills: skills.map((group) => ({ group: group.group, items: group.items })),

  blog: posts.map((post) => ({
    title: post.title,
    status: post.status,
    summary: post.summary,
    url: `/blog/${post.slug}`,
  })),

  // Facts about the site itself. It is the portfolio piece, so "how was this
  // built" is the question most worth answering well — and the answer lives
  // here rather than in the system prompt so it ships with the corpus.
  thisSite: {
    summary:
      'joaqs.online is a static Astro site on S3 behind CloudFront with Origin Access Control, ' +
      'so the bucket is private and reachable only through the CDN. ACM issues the certificate; ' +
      'DNS is Cloudflare, unproxied. Everything is Terraform across two providers.',
    pipeline:
      'GitHub Actions deploys on every push to main. It authenticates to AWS over OIDC — there ' +
      'are no long-lived AWS keys anywhere — and assumes a role scoped to one bucket and one ' +
      'distribution. Terraform plan runs on pull requests with a read-only role; apply runs on ' +
      'main behind a GitHub Environment approval with a separate write role.',
    gates:
      'Blocking CI gates: Gitleaks over full history, a PDF text-extraction scan on the résumé, ' +
      'terraform fmt, validate, tflint and Checkov, an Astro build and a link check. ' +
      'Lighthouse is advisory.',
    chatbot:
      'This assistant is Claude Haiku on AWS Lambda behind a Function URL that only CloudFront ' +
      'can call. Its knowledge is this corpus, generated from the site content at build time — ' +
      'no vector database, because a handful of documents fits in the prompt.',
  },
};

mkdirSync(dirname(outFile), { recursive: true });
writeFileSync(outFile, JSON.stringify(corpus, null, 2) + '\n');

const bytes = JSON.stringify(corpus).length;
console.log(`corpus: ${outFile} (${(bytes / 1024).toFixed(1)} kB, schema ${corpus.schema})`);

// The corpus is stuffed whole into every system prompt (DECISIONS.md #11 —
// context stuffing, not RAG). That is only defensible while it stays small.
// If it ever grows past this, the decision needs revisiting rather than the
// bill quietly growing.
if (bytes > 120_000) {
  console.error(
    `corpus is ${(bytes / 1024).toFixed(0)} kB — too large to stuff into every prompt. ` +
      'Revisit DECISIONS.md #11 before raising this limit.',
  );
  process.exit(1);
}
