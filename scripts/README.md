# scripts

Local-only tooling. Nothing here runs in CI except the corpus builder.

## `portrait/` — the ASCII graduation portrait (M3)

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

## `corpus/` — the chatbot corpus builder (M5)

Reads the site's own content (`site/src/data/profile.ts`, the project pages, the
capstone summary, the blog posts) and emits `corpus.json`, which the site build
uploads to S3. One source of truth, so the bot cannot drift from the page.
DECISIONS.md #20, #29, #33.

## `photos/` — capstone install photos (post-launch)

`photos/original/` is gitignored. Every phone photo carries GPS coordinates and
a timestamp; publishing one geotags a real client's server room to the metre.
EXIF stripping is a **CI gate**, not a manual step — manual steps get forgotten.
Each image is also reviewed by hand for device labels, monitors, hostnames,
badges and faces. DECISIONS.md #41(b).
