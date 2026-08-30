/**
 * The information architecture, in one place.
 *
 * DECISIONS.md #23 fixed this order: about first, certifications at 02, every
 * project gets its own page. The numbers are not decoration — they are the
 * jump-to-section targets in the View menu, the anchor ids, and the label the
 * status bar shows for whatever is currently on screen. Defining them once
 * means those three can never disagree.
 */

export interface Section {
  /** Zero-padded, matches the numbering shown beside each heading. */
  id: string;
  /** URL fragment and DOM id. */
  slug: string;
  /** Heading text, and the label used in the View menu and status bar. */
  label: string;
}

export const sections: readonly Section[] = [
  { id: '00', slug: 'top', label: 'Header' },
  { id: '01', slug: 'about', label: 'About' },
  { id: '02', slug: 'certifications', label: 'Certifications' },
  { id: '03', slug: 'projects', label: 'Projects' },
  { id: '04', slug: 'blog', label: 'Blog' },
  { id: '05', slug: 'experience', label: 'Experience' },
  { id: '06', slug: 'skills', label: 'Skills' },
  { id: '07', slug: 'contact', label: 'Contact' },
] as const;

/** Sections that get a numbered heading on the page. 00 is the masthead. */
export const bodySections = sections.filter((s) => s.id !== '00');
