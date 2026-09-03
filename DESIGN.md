---
name: joaqs.online
description: A deployed document — a typeset reading column wrapped in live chrome that reports the commit that built it.
colors:
  paper: "oklch(98.0% 0.0045 78.3)"
  paper-2: "oklch(95.3% 0.0086 84.6)"
  chrome: "oklch(92.3% 0.0116 84.6)"
  rule: "oklch(85.9% 0.0147 84.6)"
  ink: "oklch(17.8% 0 0)"
  ink-2: "oklch(39.6% 0.0127 81.8)"
  ink-3: "oklch(50.8% 0.0167 84.6)"
  accent: "oklch(42.3% 0.1112 255.1)"
  accent-hover: "oklch(35.9% 0.0925 255.0)"
  dot: "oklch(17.8% 0 0 / 0.07)"
  selection: "oklch(42.3% 0.1112 255.1 / 0.18)"
  paper-dark: "oklch(19.5% 0.0117 99.5)"
  paper-2-dark: "oklch(22.9% 0.0131 100.6)"
  chrome-dark: "oklch(26.2% 0.0162 102.2)"
  rule-dark: "oklch(33.9% 0.0203 99.5)"
  ink-dark: "oklch(94.3% 0.0124 91.5)"
  ink-2-dark: "oklch(76.7% 0.0203 90.6)"
  ink-3-dark: "oklch(67.7% 0.0213 87.5)"
  accent-dark: "oklch(74.4% 0.0969 252.4)"
  accent-hover-dark: "oklch(82.0% 0.0800 252.4)"
  dot-dark: "oklch(94.3% 0.0124 91.5 / 0.07)"
typography:
  display:
    fontFamily: "'Source Serif 4', 'Source Serif Pro', Georgia, Cambria, 'Times New Roman', serif"
    fontSize: "clamp(2.5rem, 1.7rem + 3.6vw, 4.25rem)"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-0.011em"
  display-small:
    fontFamily: "'Source Serif 4', 'Source Serif Pro', Georgia, Cambria, 'Times New Roman', serif"
    fontSize: "clamp(2rem, 1.45rem + 2.4vw, 3.25rem)"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-0.011em"
  headline:
    fontFamily: "'Source Serif 4', 'Source Serif Pro', Georgia, Cambria, 'Times New Roman', serif"
    fontSize: "1.875rem"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-0.011em"
  title:
    fontFamily: "'Source Serif 4', 'Source Serif Pro', Georgia, Cambria, 'Times New Roman', serif"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: 1.12
    letterSpacing: "-0.011em"
  body:
    fontFamily: "'Source Serif 4', 'Source Serif Pro', Georgia, Cambria, 'Times New Roman', serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
  label:
    fontFamily: "'IBM Plex Mono', ui-monospace, SFMono-Regular, 'Cascadia Mono', Consolas, 'Liberation Mono', monospace"
    fontSize: "0.8125rem"
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: "0.06em"
  meta:
    fontFamily: "'IBM Plex Mono', ui-monospace, SFMono-Regular, 'Cascadia Mono', Consolas, 'Liberation Mono', monospace"
    fontSize: "0.75rem"
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: "0.06em"
  chat:
    fontFamily: "system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: "normal"
rounded:
  sm: "2px"
  bubble: "1.125rem"
  bubble-tight: "0.25rem"
  pill: "999px"
  circle: "50%"
spacing:
  3xs: "0.25rem"
  2xs: "0.5rem"
  xs: "0.75rem"
  sm: "1rem"
  md: "1.5rem"
  lg: "2.5rem"
  xl: "4rem"
  2xl: "6rem"
components:
  button-quiet:
    backgroundColor: "{colors.chrome}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "0.25rem 1rem"
  button-quiet-hover:
    backgroundColor: "{colors.paper-2}"
    textColor: "{colors.ink}"
  button-send:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.paper}"
    rounded: "{rounded.circle}"
    height: "2.125rem"
    width: "2.125rem"
  badge:
    backgroundColor: "transparent"
    textColor: "{colors.ink-3}"
    typography: "{typography.meta}"
    rounded: "{rounded.sm}"
    padding: "2px 0.5rem"
  badge-live:
    textColor: "{colors.accent}"
  card-cert:
    backgroundColor: "{colors.paper-2}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "1.5rem 1rem"
    width: "13.5rem"
  input-chat:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.chat}"
    rounded: "{rounded.pill}"
    padding: "0.5rem 0.75rem"
  suggestion-pill:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.meta}"
    rounded: "{rounded.pill}"
    padding: "0.5rem 0.75rem"
  suggestion-pill-hover:
    textColor: "{colors.accent}"
  nav-link:
    backgroundColor: "transparent"
    textColor: "{colors.ink-3}"
    typography: "{typography.label}"
  nav-link-active:
    textColor: "{colors.accent}"
  bubble-in:
    backgroundColor: "{colors.chrome}"
    textColor: "{colors.ink}"
    typography: "{typography.chat}"
    rounded: "{rounded.bubble}"
    padding: "0.5rem 0.75rem"
  bubble-out:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.paper}"
    typography: "{typography.chat}"
    rounded: "{rounded.bubble}"
    padding: "0.5rem 0.75rem"
---

# Design System: joaqs.online

## Overview

**Creative North Star: "The Deployed Document"**

This is a page that reports its own provenance. The centre of the screen is a
quiet typeset document — warm paper, a serif column no wider than 46rem,
numbered sections, generous rests between them. Around that column sits chrome
that never lets you forget the page was produced by a pipeline: a fixed
navigation panel on the left, and a status bar along the bottom carrying the
section you are reading, the short SHA of the commit that built the page, the
build timestamp, and a live count of who else is here. The document is the
argument; the chrome is the evidence that the argument is true.

The system runs on a strict division of labour between two typefaces. Source
Serif 4 sets everything a person wrote — headings, body copy, project summaries,
certification names. IBM Plex Mono sets everything a machine reports — section
numbers, status readouts, technology lists, badges, field labels. A reader never
has to be told which is which; the shift in voice does it. Nothing is italic
anywhere: emphasis is carried by weight and by the single accent.

Depth is almost entirely absent by design. The document plane is flat — hairline
rules and three tonal steps of paper do all the structural work, and not one
shadow touches it. Shadow is reserved exclusively for the assistant in the
bottom-right corner, which is the only thing on the site that genuinely floats
above the page. That restraint is what keeps a page this instrumented from
reading as a dashboard. The ancestry here was a literal WordPad window; three
successive revisions stripped the title bar, the menu bar and the margin list
until only the functional chrome survived. **The costume is a road already
travelled and rejected — do not walk back down it.**

**Key Characteristics:**

- A single 46rem document column, centred, on a sub-threshold dotted ground
- Two voices: serif for authored prose, mono for machine-reported fact
- One accent, used only where something is interactive or verifiable
- A completely flat document plane; shadow only in the floating assistant corner
- Warm paper and warm-olive dark, never neutral grey
- Hairline-drawn components: edges recolour on hover, surfaces do not fill
- Two reveal registers: headings on the home page and blog index assemble
  letter by letter; longer-form pages fade in as one piece

## Colors

A warm office-document palette — paper and ink, with one cool blue doing all the
signalling. Both themes share a warm hue band (78–103); the dark theme is a warm
olive-black rather than the neutral grey most sites default to, so the two themes
read as the same material under different light. **The frontmatter's OKLCH values
are normative**; the hex codes below are the sRGB renderings carried as comments
in `site/src/styles/tokens.css`.

### Primary

- **Ledger Blue** (`#1d4e89` light / `#7fb0e8` dark): the fountain-pen blue on
  accounting paper, and the system's only accent. It marks links, the active
  section in the navigation panel, the Verify buttons on certification cards, the
  deployed-commit link in the status bar, the `Live` project badge, the robot's
  eyes and antenna, the send key, and the visitor's own chat bubbles. It appears
  nowhere that is merely decorative.

### Neutral

- **Bond Paper** (`#faf8f5` light / `#16150f` dark): the page itself, and the
  ground of the navigation panel. The paper a résumé prints on.
- **Sunk Paper** (`#f2efe9` light / `#1e1d16` dark): one tonal step down, for
  surfaces that sit *in* the page rather than on it — certification cards, the
  hover state of quiet buttons, bubble avatars.
- **Chrome** (`#e9e5dd` light / `#26251c` dark): the instrument surface. The
  status bar, the chat panel header, the greeting card header, quiet buttons, and
  the assistant's incoming message bubbles.
- **Rule** (`#d5d0c6` light / `#3a382c` dark): every hairline in the system —
  borders, dividers, the underline beneath each section heading.
- **Lamp Black** (`#111111` light / `#efece3` dark): body text and headings.
- **Lamp Black 2** (`#4a463f` light / `#b8b3a5` dark): secondary prose — the role
  line under the masthead, muted paragraphs, status bar values.
- **Lamp Black 3** (`#6a655b` light / `#9d9789` dark): metadata — section numbers,
  status bar keys, field labels, technology lists, inactive navigation.

### Named Rules

**The One Ink Rule.** There is exactly one accent in this system, and it means
"this is interactive, or this is checkable." A colour that decorates is a colour
that has stopped signalling. Do not introduce a second accent, a semantic colour
scale, or a success/warning/error palette; states are carried by the accent, by
`ink-3`, and by words.

**The Ink-3 Floor Rule.** `ink-3` is the lightest text this system permits,
because it is the only muted value that clears 4.5:1 on **both** paper and chrome
— and the status bar puts small text on chrome. Nothing lighter is a text colour.

**The Sub-Threshold Ground Rule.** The dotted grid behind the page sits at 7%
ink, deliberately far below any contrast threshold. It is texture, never content,
and must never be raised into a range where it competes with type.

## Typography

**Display Font:** Source Serif 4 (variable, 400–600, with Georgia and Cambria as
fallbacks)
**Body Font:** Source Serif 4 — the display face is the body face; this is a
document, not a poster
**Label/Mono Font:** IBM Plex Mono 400 (with `ui-monospace` and Consolas as
fallbacks)
**Chat Font:** the system sans stack, scoped to the assistant panel only

**Character:** A working serif with a real optical-size axis, set against a
technical mono. Source Serif 4 ships as one variable file precisely so the same
face can be set at 17px for body copy and up to 68px for the masthead with the
optical sizing that demands. Both faces are self-hosted and Latin-subset — on a
site whose premise is "I control my own infrastructure," fetching type from
someone else's CDN would be a contradiction a careful reader would notice.

### Hierarchy

- **Display** (600, `clamp(2.5rem, 1.7rem + 3.6vw, 4.25rem)`, 1.12, -0.011em):
  the masthead name only. One per page.
- **Display Small** (600, `clamp(2rem, 1.45rem + 2.4vw, 3.25rem)`, 1.12): every
  page title that is not the masthead — project write-ups, the blog index, a
  blog post, and the 404. There is no third page-title size.
- **Headline** (600, 1.875rem, 1.12): numbered section headings, each with a
  hairline rule beneath it and its mono number above.
- **Title** (600, 1.5rem, 1.12): project names, role entries, certification names
  on cards.
- **Body** (400, 1.0625rem, 1.6): all prose, capped at a 68ch measure; 56ch for
  narrow columns like the masthead subline.
- **Label** (400, 0.8125rem, 0.06em tracking, frequently uppercase): field labels,
  navigation entries, Verify links, quiet buttons.
- **Meta** (400, 0.75rem, 0.06em tracking, uppercase): section numbers, status bar
  fields, badges, technology lists, view counts. Always `tabular-nums`.

### Named Rules

**The Two Voices Rule.** Serif sets what a person wrote. Mono sets what a machine
reports. A section heading is serif; the `03` above it is mono. A project summary
is serif; its technology list is mono. When adding anything new, decide which
voice is speaking before choosing a face.

**The Roman Rule.** Every heading is roman. There is no italic anywhere in this
system — emphasis is weight and the accent, never slant.

**The Tabular Figures Rule.** Any number that changes in place or aligns in a
column — section numbers, view counts, commit SHAs, dates — is set with
`font-variant-numeric: tabular-nums` so it does not jitter as it updates.

**The 16px Composer Rule.** No text input may be set below 16px. iOS Safari zooms
the whole page when a focused input is smaller and does not zoom back out; the
chat composer therefore uses `max(16px, var(--text-sm))` as a deliberate literal
rather than a token. This is a browser threshold, not a design preference.

## Layout

**The document column.** A single centred column with a `46rem` maximum,
`1.5rem` gutters, and `4rem` of padding above and `6rem` below. Everything a
reader actually reads lives inside it. Sections are separated by `4rem`; a
section's heading sits under its mono number with `4px` between them, carries a
hairline rule beneath, and gives its body `1.5rem` of air.

**The chrome around it.** Two fixed elements frame the column and are not part of
it. The navigation panel is a `14rem` full-height column on the left — the name
at the top, the numbered sections down the middle, the view counts and résumé
link pinned to the bottom — separated from the document by a single hairline.
The status bar is a `2.25rem` strip fixed to the bottom edge, running from the
panel's right edge to the window's, on the chrome surface.

**Spacing rhythm.** A 4pt scale from `0.25rem` to `6rem`. Component internals use
the bottom four steps (`0.25`–`1rem`); the structural steps (`1.5`, `2.5`, `4`,
`6rem`) separate sections and set page padding. The two registers do not mix.

**Responsive behaviour.** Four breakpoints, each earning its place:

- **60rem** — the load-bearing one. Above it the navigation panel is visible and
  the document is offset by `14rem`; below it the panel is hidden entirely and the
  document reclaims the full width. There is no hamburger and no drawer: the page
  is a single scroll on a phone, and the status bar still carries the section
  readout and the theme control.
- **40rem** — the About block stacks, and the graduation portrait widens to
  `min(16rem, 100%)`.
- **34rem** — the two-column definition grids (certifications, contact, skills)
  collapse to a single column, and the assistant's robot shrinks to `3rem`.
- **30rem** — the status bar drops its build-timestamp field. The section readout
  is the field that must survive, so it is the one that keeps its place.

### Named Rules

**The 46rem Rule.** The reading column never exceeds `46rem` and body prose never
exceeds a 68ch measure. Wide content — diagrams, code, tables — scrolls inside
its own container rather than widening the column.

**The Chrome-Clearance Rule.** The status bar is fixed over the bottom of every
page, so any element that could sit beneath it must clear it explicitly:
`calc(var(--chrome-height) + var(--space-md))`. The assistant corner measures
from `--launcher-inset-y`, which already carries that clearance.

## Elevation & Depth

**This system is flat by construction.** The document plane uses no shadows at
all. Depth on the page is built from exactly two materials: three tonal steps of
surface (paper → sunk paper → chrome) and `1px` hairline rules in the rule
colour. A card is a rectangle of sunk paper inside a hairline. A section break is
a hairline. The navigation panel is separated from the document by a hairline.
That is the entire vocabulary.

Shadow exists in one place only: the floating assistant in the bottom-right
corner, which is the sole element that genuinely sits above the page rather than
in it. Its three shadows scale with how far each object has lifted.

### Shadow Vocabulary

- **Launcher lift** (`box-shadow: 0 4px 14px oklch(0% 0 0 / 0.16)`): the robot
  button, resting just above the page.
- **Greeting card** (`box-shadow: 0 8px 26px oklch(0% 0 0 / 0.18)`): the message
  box that pops out of the robot.
- **Chat panel** (`box-shadow: 0 10px 30px oklch(0% 0 0 / 0.2)`): the assistant
  panel, the highest object in the system.

### Named Rules

**The Flat Page Rule.** No shadow may touch the document plane — not on cards,
not on buttons, not on the navigation panel, not on hover. If something needs to
separate from its surroundings, it gets a hairline or a tonal step. Shadow is
reserved for objects that float above the page, and today that means the
assistant corner and nothing else.

**The Hairline Rule.** Every border in this system is `1px` in the rule colour.
The `2px` weight exists for exactly two purposes: the focus ring, and the
project card's left marker. There is no third border weight.

## Shapes

The form language is near-square for anything that behaves like chrome, and fully
round for anything that behaves like a control.

**Chrome radius (`2px`).** Cards, panels, badges, quiet buttons, the greeting
card, the chat panel, the portrait frame. This is the inherited WordPad-era
near-square, and it is what makes the page read as a document rather than as an
app.

**Pill radius (`999px`).** Things a finger operates or that carry conversational
content: the theme wheel and its sliding knob, the chat composer input,
suggestion chips.

**Circle (`50%`).** The robot launcher, avatars, the send key, the status pip,
the typing dots.

**Message bubbles (`1.125rem`, tightening to `0.25rem`).** The one deliberate
departure from near-square chrome. A `2px` message bubble does not read as a
message. Within a stack from one speaker, only the corners that face an adjacent
bubble tighten to `4px`; a lone bubble keeps all four round.

### Named Rules

**The Near-Square Chrome Rule.** If it is chrome, its radius is `2px`. Rounder
values are reserved for controls and for conversation, and each one needs a
reason that is not "it looks softer."

## Components

Components are **precise and unfilled**: drawn with hairlines rather than filled
with colour, with their weight carried by the border and the type inside it. On
hover the *edge* takes the accent — the surface does not fill. The only filled
components in the system are the send key and the visitor's chat bubbles, both
of which are solid accent.

### Buttons

- **Shape:** near-square (`2px`) for document buttons; fully round for the send
  key and suggestion chips.
- **Quiet button** (`.button`): chrome background, ink text, hairline border,
  mono label at `0.8125rem`, padding `0.25rem 1rem`. Used for "All posts →" and
  the assistant's closed-state actions.
- **Hover:** background steps to sunk paper; on the closed-state actions the
  border and text also take the accent. No lift, no shadow.
- **Send key:** a `2.125rem` accent-filled circle with a paper-coloured arrow,
  scaling to `1.08` on hover. The word "Send" would cost a third of the composer
  at this width, so the accessible name carries it instead.
- **Copy button:** no border, no background — accent text over a dashed hairline
  underline. Used for the click-to-copy email address, which confirms in place
  with "Copied to clipboard" for 1.6 seconds.

### Chips

- **Badge:** transparent, hairline border, `2px` radius, uppercase mono at
  `0.75rem` with `0.06em` tracking, `ink-3` text. Carries project and post status.
- **Live badge:** the same shape with both border and text in the accent — the
  status that means "there is something real to click."
- **Suggestion chip:** full pill, paper background, hairline border, left-aligned
  mono text. On hover the border and text take the accent and the chip slides
  `2px` right.

### Cards / Containers

- **Corner style:** `2px`.
- **Background:** sunk paper, one tonal step below the page.
- **Shadow strategy:** none. See The Flat Page Rule.
- **Border:** `1px` hairline.
- **Internal padding:** `1.5rem` vertical, `1rem` horizontal on certification
  cards (`13.5rem` wide).
- **Hover:** lifts `3px` on transform and takes an accent border, guarded behind
  `@media (hover: hover)` so a touch device never gets a stuck hover state.

### Inputs / Fields

- **Style:** full pill, paper background, `1px` hairline, system-sans at no less
  than 16px. The composer deliberately uses the sans stack rather than the site's
  serif — a serif input under sans bubbles reads as two different applications.
- **Focus:** the global ring — `2px` solid accent at `2px` offset, applied
  instantly and never transitioned or animated.

### Navigation

- **Panel:** `14rem` fixed column, paper ground, hairline right border, mono
  throughout. The brand name sits at `0.9375rem` medium with wide tracking;
  section entries are `0.8125rem` in `ink-3`, each a mono number and a label on a
  shared baseline.
- **Hover:** the label goes to full ink and the *number* slides `3px` right in the
  accent — the number moves, not the word.
- **Active:** both number and label take the accent via `aria-current="true"`,
  driven by the same IntersectionObserver that feeds the status bar. One source of
  "where is the reader", two displays.
- **Mobile:** hidden entirely below `60rem`. No hamburger, no drawer.

### Status Bar

The signature component. A `2.25rem` chrome strip fixed to the bottom of every
page, carrying three key/value pairs in `0.75rem` mono: **Section** (live, from
the observer), **Commit** (the short SHA, an accent link out to the exact source
that produced the page), and **Built** (a timestamp). Keys are uppercase `ink-3`;
values are `ink-2` with tabular figures. The readouts scroll horizontally on
narrow screens with the scrollbar hidden, while the theme wheel keeps its corner.

The commit link is the point of the whole component: it tells an engineer that the
site is CI-deployed, and it is falsifiable — follow it and you get the source
that built what you are looking at.

### Theme Wheel

Three positions — light, system, dark — as a pill of icon buttons with a knob
that slides between them. **System is a real position, not a reset buried in a
menu.** Buttons use `aria-pressed` rather than a hand-rolled radio group. The
knob is the one place in the system that overshoots
(`cubic-bezier(0.34, 1.4, 0.44, 1)` over 320ms), so it reads as a physical
control settling into a detent.

### Certification Carousel

A strip of cards drifting right-to-left at 34px/second, masked to transparent for
`3rem` at both edges so cards dissolve rather than clip. It pauses on hover,
focus, or drag, and can be thrown by hand or scrolled sideways. Both the drift
and the drag write to one offset value, which is why dragging works at all.
Without JavaScript or under reduced motion it degrades to an ordinary scrollable
row — the clone and the mask disappear and the script never starts.

### Assistant

A non-modal `<dialog>` anchored to the launcher, scaling out of the robot's
corner from a shared `transform-origin: bottom right`. The page behind stays lit,
scrollable, and readable — most questions are about something the reader can see,
and a modal that blacks out the page makes them close it to check. Messages are
rows, not paragraphs: incoming bubbles are chrome, outgoing are accent, and
consecutive bubbles from one speaker tighten their facing corners into a stack.
The header always states that a model wrote the answers and that it can be wrong.

## Do's and Don'ts

### Do:

- **Do** decide which of the two voices is speaking before choosing a face. Serif
  for authored prose, mono for machine-reported fact.
- **Do** separate things with a hairline (`1px`, rule colour) or a tonal step
  (paper → sunk paper → chrome). These are the only two depth materials on the
  page.
- **Do** keep the accent rare. It marks what is interactive or verifiable and
  nothing else.
- **Do** set every changing or aligned number with `tabular-nums`.
- **Do** guard hover affordances behind `@media (hover: hover)` so touch devices
  never inherit a stuck state.
- **Do** animate only `transform` and `opacity`, using the three named easings and
  the `120ms` / `200ms` durations.
- **Do** give every new interactive element the global focus ring — `2px` accent
  at `2px` offset, applied instantly.
- **Do** define new colours in OKLCH in `tokens.css` and reference them by name.
  Page and component CSS carries no colour or font-family literals.
- **Do** keep both themes in step. Any new colour needs its light value, its
  `prefers-color-scheme: dark` value, and its `[data-theme='dark']` value, or the
  explicit toggle will disagree with the system default.
- **Do** let features degrade to something real without JavaScript. The carousel
  becomes a scroll row; the reveal animations simply never hide anything.

### Don't:

- **Don't** reintroduce WordPad skeuomorphism. Title bars, menu bars, bevelled
  buttons and faux-Windows chrome were removed deliberately across three
  revisions. This is the one confirmed anti-reference.
- **Don't** put a shadow on the document plane. Shadow belongs to the floating
  assistant corner and nowhere else.
- **Don't** add a second accent or a semantic colour scale. One ink.
- **Don't** use italic. Emphasis is weight and the accent.
- **Don't** use a text colour lighter than `ink-3`; it is the floor because it
  must clear AA on both paper and chrome.
- **Don't** set any text input below 16px.
- **Don't** introduce a third border weight. `1px` for hairlines, `2px` for the
  focus ring and the project marker.
- **Don't** add a third self-hosted face. Two are downloaded; the assistant's sans
  is a system stack precisely so it costs nothing.
- **Don't** raise the dotted ground above 7% opacity or let it become content.
- **Don't** turn vertical scroll into horizontal motion in the carousel. A
  horizontal widget inside a vertical document only claims horizontal gestures.
- **Don't** widen the reading column past `46rem` or prose past 68ch. Wide content
  scrolls inside its own container.
