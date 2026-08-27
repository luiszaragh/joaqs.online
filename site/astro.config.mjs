// @ts-check
import { defineConfig } from 'astro/config';

/**
 * DECISIONS.md #25 — the domain lives in exactly TWO places in this repo:
 *
 *   1. `site` below
 *   2. Terraform's `var.domain_name`
 *
 * Canonical URLs, OG URLs, the sitemap and RSS all derive from `Astro.site`.
 * Never write the literal domain anywhere else. Migration day is then:
 * buy domain -> change these two values -> apply -> add a redirect.
 */
export default defineConfig({
  site: 'https://joaqs.online',

  // Directory format emits /about/index.html. Behind CloudFront + S3 OAC the
  // origin is the S3 REST endpoint, which does NOT resolve /about/ to
  // index.html on its own — a CloudFront Function rewrites the request URI.
  // See infra/README.md (M1). Changing this to 'file' without also changing
  // that function will 404 every page but the root.
  build: { format: 'directory' },

  // Hashed asset filenames are what make "invalidate HTML only" safe in
  // site.yml (DECISIONS.md #21 / PLAN.md pipeline table).
  vite: {
    build: {
      assetsInlineLimit: 0,
    },
  },
});
