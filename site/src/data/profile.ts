/**
 * The settled facts, in one place.
 *
 * This file is the single source for the header, the About section, the
 * résumé-adjacent copy, and — from M5 — the chatbot corpus that the build
 * writes to S3 (DECISIONS.md #20, #29). One source means the bot cannot drift
 * from the page by construction.
 *
 * The domain is deliberately NOT here. It lives in astro.config.mjs `site`
 * and in Terraform's var.domain_name, and nowhere else (DECISIONS.md #25).
 */

export const profile = {
  name: 'Luis Zara',

  /** DECISIONS.md #26 — one label, no slashes. "Junior" does not appear here. */
  role: 'Cloud & DevOps Engineer',

  /** DECISIONS.md #26 — certs first, then the thing recruiters filter on. */
  availability: 'Open to Cloud/DevOps roles — Metro Manila, hybrid, or remote',

  location: {
    city: 'Quezon City',
    region: 'Metro Manila',
    arrangements: ['on-site around Metro Manila', 'hybrid', 'remote'],
  },

  /** DECISIONS.md #19 — goes in About, not the H1. */
  level: 'BSIT, University of Santo Tomas, 2026 — open to entry-level and associate roles',

  /**
   * DECISIONS.md #19 — Luis's own words. Use close to verbatim; do not
   * "improve" this into marketing copy.
   */
  intro:
    'My interest in infrastructure started with networking. I liked understanding how ' +
    'devices communicate, what happens behind the scenes when you access a service, and ' +
    'eventually how those same concepts translate into cloud environments.',

  /** DECISIONS.md #19 — the in-progress cert ships, visually separated. */
  certifications: {
    earned: [
      { code: 'DOP-C02', name: 'AWS Certified DevOps Engineer – Professional' },
      { code: 'SAA-C03', name: 'AWS Certified Solutions Architect – Associate' },
      { code: 'SOA-C03', name: 'AWS Certified SysOps Administrator – Associate' },
    ],
    inProgress: [{ code: 'AIF-C01', name: 'AWS Certified AI Practitioner' }],
  },

  /**
   * DECISIONS.md #15 / #28 — the email is published unguarded, click-to-copy,
   * no form and no mailto:. Changing it is a one-line change here.
   */
  email: 'luisjoaquinzara@gmail.com',

  links: {
    github: 'https://github.com/luiszaragh',
    /** TODO: add the real profile URL — nothing is rendered while this is null. */
    linkedin: 'https://www.linkedin.com/in/luis-joaquin-zara/',
  },
} as const;

export type Profile = typeof profile;
