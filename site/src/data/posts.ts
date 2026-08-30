/**
 * The blog's table of contents, in one place.
 *
 * The home page shows only titles and an "all posts" link; /blog shows this
 * full list. Both read from here, so the two can never disagree — the same
 * single-source rule as profile.ts (DECISIONS.md #20).
 *
 * Posts land in M6, written from the decision records rather than from
 * memory (DECISIONS.md #27/#33). Until then every entry is honest about its
 * state: nothing here pretends to be published.
 */

export interface PlannedPost {
  /** Becomes /blog/<slug> when the post ships. */
  slug: string;
  title: string;
  summary: string;
  status: 'in-progress' | 'planned';
}

export const posts: readonly PlannedPost[] = [
  {
    slug: 'how-this-site-is-deployed',
    title: 'How this site is deployed',
    summary:
      'Terraform across two providers, GitHub Actions with OIDC and no stored cloud keys, ' +
      'and the parts that broke on the way — the architecture story behind the page you are reading.',
    status: 'in-progress',
  },
  {
    slug: 'the-gate-that-never-ran',
    title: 'The gate that never ran',
    summary:
      'A secret scanner existed in this repository for three days before anything executed it, ' +
      'and a phone number reached public GitHub in the gap. What changed so it cannot happen again.',
    status: 'planned',
  },
] as const;

export const statusLabels: Record<PlannedPost['status'], string> = {
  'in-progress': 'In progress',
  planned: 'Planned',
};
