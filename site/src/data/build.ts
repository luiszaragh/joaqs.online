/**
 * Build provenance for the status bar.
 *
 * DECISIONS.md #23 — the status bar shows the deployed commit SHA, linked to
 * that commit on GitHub, plus the build timestamp. That single detail tells any
 * engineer looking at the page that the site is CI-deployed and that Luis knows
 * it matters. It is also a live self-check: if the SHA in the status bar is not
 * the tip of main, a deploy failed quietly.
 *
 * Resolved once, at build time. Nothing here runs in the browser.
 */

import { execSync } from 'node:child_process';
import { profile } from './profile';

function resolveCommit(): string {
  // GitHub Actions sets GITHUB_SHA to the commit that triggered the workflow.
  // In CI this is authoritative and no git call is needed.
  const fromCI = process.env.GITHUB_SHA;
  if (fromCI) return fromCI;

  // Local `npm run dev` / `npm run build`. A shallow clone still answers this.
  try {
    return execSync('git rev-parse HEAD', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch {
    // Building from a tarball with no git available is not an error worth
    // failing a build over — the status bar just says so.
    return '';
  }
}

const commit = resolveCommit();
const builtAt = new Date();

export const build = {
  commit,
  shortCommit: commit ? commit.slice(0, 7) : 'unknown',
  commitUrl: commit ? `${profile.links.github}/joaqs.online/commit/${commit}` : null,

  /** Machine-readable, for <time datetime>. */
  timestamp: builtAt.toISOString(),

  /** Human-readable, UTC so it does not shift with the reader's clock. */
  builtAtLabel: builtAt.toISOString().replace('T', ' ').slice(0, 16) + ' UTC',
} as const;
