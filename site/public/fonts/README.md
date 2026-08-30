# Fonts

Both faces are licensed under the SIL Open Font License 1.1, which permits
redistribution and self-hosting. This file carries the required attribution.

| File | Face | Source |
|---|---|---|
| `source-serif-4-latin-var.woff2` | Source Serif 4, variable, weight 400–600, Latin subset | [github.com/adobe-fonts/source-serif](https://github.com/adobe-fonts/source-serif) |
| `ibm-plex-mono-400-latin.woff2` | IBM Plex Mono, regular, Latin subset | [github.com/IBM/plex](https://github.com/IBM/plex) |

**Source Serif 4** — Copyright 2014–2023 Adobe (https://adobe.com/), with
Reserved Font Name 'Source'. Licensed under SIL OFL 1.1.

**IBM Plex Mono** — Copyright 2017 IBM Corp. Licensed under SIL OFL 1.1.

Full licence text: <https://openfontlicense.org/>

Both were taken from the Google Fonts CDN as the Latin subset only, then
committed here so the site serves them from its own origin (DECISIONS.md #30).
Nothing was modified.

## Why the subset matters

The full families ship Cyrillic, Greek, Vietnamese and Latin-Extended ranges.
This site renders none of them — the widest characters it uses are `é`, en and
em dashes, the middle dot and curly quotes, all inside the Latin range. Serving
the other subsets would roughly triple the download for glyphs no page contains.
