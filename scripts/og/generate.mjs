/**
 * Generates the site's Open Graph card. DECISIONS.md #38 — one static image
 * for the whole site, not per-page generation. This link gets pasted into
 * LinkedIn posts, applications and DMs, and a link with no preview card looks
 * broken before anyone has clicked it.
 *
 * Local-only. Run it, look at it, commit the PNG:
 *
 *     node scripts/og/generate.mjs
 *
 * The card is a portrait of the site, so it has to be redrawn whenever the
 * site stops looking like it. The first version drew a title bar and a
 * File/View/Help menu — chrome that #46, #47 and #51 removed — and it kept
 * being handed to recruiters for weeks afterwards, because nothing about a
 * stale preview image is visible from inside the repo.
 *
 * NOTHING HERE IS TYPED TWICE. The name, role, certifications and sections
 * come from the same modules the page renders (#20's rule, applied to the
 * preview card), and the domain from astro.config.mjs (#25). A card that
 * claimed three certifications after a fourth was earned would be a small
 * public lie that no test could catch.
 *
 * Uses sharp, which the Astro site already depends on. Colours are the hex
 * equivalents of tokens.css, because SVG rasterisers do not universally
 * understand oklch(); if the palette changes, change both.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const out = resolve(here, '../../site/public/og.png');

// sharp is a dependency of the Astro site, not of this directory, and Node
// resolves modules from the importing file's location rather than the working
// directory. Run `npm install` in site/ first if this throws.
const require = createRequire(resolve(here, '../../site/package.json'));
const sharp = require('sharp');

// Imported as .ts directly via Node's type stripping, the same way
// scripts/corpus/build.mjs reads them (Node >= 22.18; .nvmrc pins 24).
const { profile } = await import(new URL('../../site/src/data/profile.ts', import.meta.url).href);
const { sections } = await import(new URL('../../site/src/data/sections.ts', import.meta.url).href);
const { default: astroConfig } = await import(
  new URL('../../site/astro.config.mjs', import.meta.url).href
);

/**
 * XML-escape anything interpolated into the SVG below.
 *
 * Not optional and not defensive: `profile.role` is "Cloud & DevOps Engineer",
 * and a bare ampersand is a parse error, not a rendering quirk. The previous
 * version wrote `&amp;` by hand because the string was typed here; now that the
 * text comes from the data files, every value has to be escaped on the way in
 * or the next apostrophe or ampersand anyone adds breaks image generation.
 */
const xml = (value) =>
  String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const domain = new URL(astroConfig.site).host;
const certs = profile.certifications.earned.map((c) => c.code).join(' · ');
// The masthead's own line, shortened to what fits: the full availability
// sentence overruns the card at a legible size.
const where = [profile.location.region, ...profile.location.arrangements.slice(1)].join(' · ');

const paper = '#faf8f5';
const chrome = '#e9e5dd';
const rule = '#d5d0c6';
const ink = '#111111';
const ink2 = '#4a463f';
const ink3 = '#6a655b';
const accent = '#1d4e89';

// Requested by family name rather than embedded: the rasteriser resolves these
// against system fonts. The stack is ordered so the result stays a serif and a
// monospace on any machine that runs this.
const serif = 'Source Serif 4, Source Serif Pro, Georgia, Times New Roman, serif';
const mono = 'IBM Plex Mono, Consolas, DejaVu Sans Mono, Courier New, monospace';

const SIDEBAR = 250;
const DOC = SIDEBAR + 70; // the document's left margin

// The sidebar's numbered list, from the same data the real panel renders.
const navRows = sections
  .map((section, i) => {
    const y = 168 + i * 36;
    return `
    <text x="40" y="${y}" font-family="${mono}" font-size="17" fill="${ink3}" letter-spacing="1">${xml(section.id)}</text>
    <text x="82" y="${y}" font-family="${mono}" font-size="17" fill="${ink3}" letter-spacing="1">${xml(section.label)}</text>`;
  })
  .join('');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <!-- #51's dotted ground. Same 22px cell and same near-invisible ink as
         global.css, so the card carries the site's texture rather than a flat
         rectangle. -->
    <pattern id="dots" width="22" height="22" patternUnits="userSpaceOnUse">
      <circle cx="1.5" cy="1.5" r="1.5" fill="${ink}" fill-opacity="0.07"/>
    </pattern>
  </defs>

  <rect width="1200" height="630" fill="${paper}"/>
  <rect width="1200" height="630" fill="url(#dots)"/>

  <!-- navigation panel (#47): brand, numbered sections, resume at the foot -->
  <rect x="0" y="0" width="${SIDEBAR}" height="630" fill="${paper}"/>
  <line x1="${SIDEBAR}" y1="0" x2="${SIDEBAR}" y2="630" stroke="${rule}" stroke-width="2"/>
  <text x="40" y="72" font-family="${mono}" font-size="20" font-weight="500" fill="${ink}" letter-spacing="1.6">${xml(profile.name)}</text>
  ${navRows}
  <text x="40" y="560" font-family="${mono}" font-size="16" fill="${ink2}" letter-spacing="1">Download résumé ↓</text>

  <!-- the document -->
  <text x="${DOC}" y="250" font-family="${serif}" font-size="66" font-weight="600" fill="${ink}">${xml(profile.fullName)}</text>
  <text x="${DOC}" y="312" font-family="${serif}" font-size="36" fill="${ink2}">${xml(profile.role)}</text>

  <line x1="${DOC}" y1="356" x2="1140" y2="356" stroke="${rule}" stroke-width="2"/>

  <text x="${DOC}" y="404" font-family="${mono}" font-size="21" fill="${ink3}" letter-spacing="1.4">${xml(certs)}</text>
  <text x="${DOC}" y="446" font-family="${mono}" font-size="21" fill="${ink3}" letter-spacing="1.4">${xml(where)}</text>

  <!-- the assistant (#51/#52), where it actually sits on the page -->
  <g transform="translate(1046, 452) scale(1.5)">
    <circle cx="24" cy="24" r="23" fill="${chrome}" stroke="${rule}" stroke-width="1.5"/>
    <line x1="24" y1="10" x2="24" y2="15" stroke="${ink2}" stroke-width="1.5"/>
    <circle cx="24" cy="7.5" r="2.5" fill="${accent}"/>
    <rect x="11" y="15" width="26" height="20" rx="6" fill="${paper}" stroke="${ink2}" stroke-width="1.5"/>
    <circle cx="19" cy="24" r="2.6" fill="${accent}"/>
    <circle cx="29" cy="24" r="2.6" fill="${accent}"/>
    <path d="M20 29.5h8" stroke="${ink2}" stroke-width="1.5" stroke-linecap="round"/>
    <path d="M11 27H7.5" stroke="${ink2}" stroke-width="1.5" stroke-linecap="round"/>
    <path d="M37 27c3 0 4.5-2 4.5-5" fill="none" stroke="${ink2}" stroke-width="1.5" stroke-linecap="round"/>
    <circle cx="41.5" cy="20.5" r="2" fill="${accent}"/>
  </g>

  <!-- status bar (#51c), across the full width as it is on the page -->
  <rect x="0" y="574" width="1200" height="56" fill="${chrome}"/>
  <line x1="0" y1="574" x2="1200" y2="574" stroke="${rule}" stroke-width="2"/>
  <text x="40" y="610" font-family="${mono}" font-size="19" fill="${ink3}" letter-spacing="1.2">${xml(domain)}</text>
  <text x="1160" y="610" text-anchor="end" font-family="${mono}" font-size="19" fill="${accent}" letter-spacing="1.2">Terraform · CloudFront · OIDC</text>
</svg>`;

mkdirSync(dirname(out), { recursive: true });

const png = await sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer();
writeFileSync(out, png);

const meta = await sharp(png).metadata();
console.log(`wrote ${out}`);
console.log(`${meta.width}x${meta.height}, ${(png.length / 1024).toFixed(1)} kB`);
console.log(`certifications drawn: ${certs}`);
console.log('\nLook at it. It is a portrait of the site, and only your eyes can');
console.log('tell you whether it still resembles one.');
