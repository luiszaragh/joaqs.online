# scripts

Local-only tooling. Nothing here runs in CI except the corpus builder.

## `portrait/` — the graduation photograph and its ASCII variant

`prepare-web.mjs` produces the committed web copy (`site/src/assets/graduation.jpg`):
EXIF-stripped — verified, not assumed — and resized to display resolution, per
DECISIONS.md #47. The original in `source/` stays gitignored and never ships.

### the ASCII portrait (currently unrendered — #47)

Tuned locally against the source photograph, then the finished `.txt` is
committed and rendered in a `<pre>`. DECISIONS.md #41, #44, #45.

**The source photograph never enters this repository.** `scripts/portrait/source/`
and image files directly under `scripts/portrait/` are gitignored. The face is
never published in any form — that is the entire point of the ASCII treatment,
and it also sidesteps appearance bias.

Requirements the generator output has to meet:

- Real selectable text, monochrome, no colour spans
- A real `alt` on the `<pre>` — `"ASCII portrait of Luis at his 2026 graduation"` —
  because a screen reader reading 2,000 punctuation characters is a disaster
- A narrower character-width variant for viewports under ~640px; ASCII art does
  not reflow

## `corpus/` — the chatbot corpus builder

Reads `site/src/data/profile.ts` and `posts.ts` and emits
`site/public/corpus.json`, which `astro build` copies into `dist/` and
site.yml's existing S3 sync publishes. The Lambda fetches it on cold start.

Wired as the site's `prebuild` script, so it regenerates on every build whether
or not anyone remembers — one source of truth, and drift is impossible rather
than merely discouraged. DECISIONS.md #20, #29, #33; ADR-0004.

It **fails the build if the corpus exceeds 120 kB**. Context stuffing is only
defensible while everything fits in the prompt; the gate is there so that
boundary is enforced rather than assumed.

## `photos/` — capstone install photos (post-launch)

`photos/original/` is gitignored. Every phone photo carries GPS coordinates and
a timestamp; publishing one geotags a real client's server room to the metre.
EXIF stripping is a **CI gate**, not a manual step — manual steps get forgotten.
Each image is also reviewed by hand for device labels, monitors, hostnames,
badges and faces. DECISIONS.md #41(b).
