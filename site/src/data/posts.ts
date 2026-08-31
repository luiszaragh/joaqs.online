/**
 * The blog's table of contents, in one place.
 *
 * The home page shows titles and an "all posts" link; /blog shows this full
 * list. Both read from here, so the two can never disagree — the same
 * single-source rule as profile.ts (DECISIONS.md #20).
 *
 * A published post has a `published` date and a real page at /blog/<slug>;
 * everything else is honest about its state (DECISIONS.md #27/#33): nothing
 * here pretends to be published before the page exists.
 */

export interface Post {
  /** The page lives at /blog/<slug> once the post is published. */
  slug: string;
  title: string;
  summary: string;
  status: 'published' | 'in-progress' | 'planned';
  /** YYYY-MM-DD, set when (and only when) the page ships. */
  published?: string;
}

export const posts: readonly Post[] = [
  {
    slug: 'how-this-site-is-deployed',
    title: 'How this site is deployed',
    summary:
      'Terraform across two providers, GitHub Actions with OIDC and no stored cloud keys, ' +
      'and the parts that broke on the way — the architecture story behind the page you are reading.',
    status: 'published',
    published: '2026-09-01',
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

export const statusLabels: Record<Post['status'], string> = {
  published: 'Published',
  'in-progress': 'In progress',
  planned: 'Planned',
};

/** True when the post has a page worth linking to. */
export const isPublished = (post: Post): boolean => post.status === 'published';
