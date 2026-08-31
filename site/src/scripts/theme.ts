/**
 * The one place theme state changes. DECISIONS.md #51.
 *
 * Two components render theme controls — the wheel in the sidebar and the
 * compact cycle button in the status bar — and both call in here, so the
 * stored value, the fade, and the <html> attribute can never be juggled by
 * two copies of the same logic. Both listen for `theme:mode` to keep their
 * own UI in step, whichever control was touched.
 *
 * The three states mirror what the pre-paint script in BaseLayout already
 * honours: stored 'light' or 'dark' wins; nothing stored means the OS
 * preference governs. 'system' here simply erases the stored choice.
 */

export type ThemeMode = 'light' | 'system' | 'dark';

export function currentMode(): ThemeMode {
  try {
    const stored = localStorage.getItem('theme');
    if (stored === 'light' || stored === 'dark') return stored;
  } catch {
    /* blocked storage — behave as system */
  }
  return 'system';
}

function apply(mode: ThemeMode) {
  if (mode === 'system') {
    delete document.documentElement.dataset.theme;
    try {
      localStorage.removeItem('theme');
    } catch {
      /* nothing stored to remove */
    }
  } else {
    document.documentElement.dataset.theme = mode;
    try {
      localStorage.setItem('theme', mode);
    } catch {
      /* private mode: works for this page view, just not remembered */
    }
  }
  document.dispatchEvent(new CustomEvent<ThemeMode>('theme:mode', { detail: mode }));
}

/**
 * Change the theme with a cross-fade (DECISIONS.md #51 — "an animation that
 * fades between the two modes").
 *
 * `startViewTransition` snapshots the page and cross-fades the whole thing —
 * the best possible version of this effect. Where it is missing, a temporary
 * class turns on colour transitions for one beat instead; global.css removes
 * it from the cascade under reduced motion, and the class is taken off again
 * so colour changes are never animated during normal use.
 */
export function setMode(mode: ThemeMode) {
  const doc = document as Document & { startViewTransition?: (cb: () => void) => void };
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (!reduced && typeof doc.startViewTransition === 'function') {
    doc.startViewTransition(() => apply(mode));
    return;
  }

  document.documentElement.classList.add('theme-fade');
  apply(mode);
  window.setTimeout(() => document.documentElement.classList.remove('theme-fade'), 400);
}

export const MODES: readonly ThemeMode[] = ['light', 'system', 'dark'];
