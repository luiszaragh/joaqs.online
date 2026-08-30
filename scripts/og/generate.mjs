/**
 * Generates the site's Open Graph card. DECISIONS.md #38 — one static image
 * for the whole site, not per-page generation. This link gets pasted into
 * LinkedIn posts, applications and DMs, and a link with no preview card looks
 * broken before anyone has clicked it.
 *
 * Local-only. Run it, commit the PNG, done:
 *
 *     node scripts/og/generate.mjs
 *
 * Uses sharp, which Astro already depends on, so there is no extra dependency
 * to install. Colours are the same values as site/src/styles/tokens.css,
 * converted to hex because SVG rasterisers do not universally understand
 * oklch(). If the palette changes, change both.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const out = resolve(here, '../../site/public/og.png');

// sharp is a dependency of the Astro site, not of this directory, and Node
// resolves modules from the importing file's location rather than the working
// directory. Resolving explicitly against site/ keeps the generator in
// scripts/ (repo tooling, per the layout) without adding a second
// node_modules tree for one build-time script. Run `npm install` in site/
// first if this throws.
const require = createRequire(resolve(here, '../../site/package.json'));
const sharp = require('sharp');

// DECISIONS.md #25 — the domain lives in astro.config.mjs and Terraform, and
// nowhere else. Baking a literal into this generator would put a third copy
// inside a binary, which is the hardest kind to find on migration day.
const { default: astroConfig } = await import(
  new URL('../../site/astro.config.mjs', import.meta.url).href
);
const domain = new URL(astroConfig.site).host;

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

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <rect width="1200" height="630" fill="${paper}"/>

  <!-- title bar -->
  <rect x="0" y="0" width="1200" height="56" fill="${accent}"/>
  <text x="40" y="36" font-family="${mono}" font-size="20" fill="${paper}" letter-spacing="1.2">luis_zara.rtf</text>

  <!-- menu bar -->
  <rect x="0" y="56" width="1200" height="44" fill="${chrome}"/>
  <line x1="0" y1="100" x2="1200" y2="100" stroke="${rule}" stroke-width="2"/>
  <text x="40" y="85" font-family="${mono}" font-size="18" fill="${ink2}">File</text>
  <text x="110" y="85" font-family="${mono}" font-size="18" fill="${ink2}">View</text>
  <text x="190" y="85" font-family="${mono}" font-size="18" fill="${ink2}">Help</text>

  <!-- document body -->
  <text x="80" y="250" font-family="${serif}" font-size="82" font-weight="600" fill="${ink}">Luis Zara</text>
  <text x="80" y="316" font-family="${serif}" font-size="40" fill="${ink2}">Cloud &amp; DevOps Engineer</text>

  <line x1="80" y1="360" x2="1120" y2="360" stroke="${rule}" stroke-width="2"/>

  <text x="80" y="408" font-family="${mono}" font-size="22" fill="${ink3}" letter-spacing="1.5">DOP-C02 · SAA-C03 · SOA-C03</text>
  <text x="80" y="452" font-family="${mono}" font-size="22" fill="${ink3}" letter-spacing="1.5">Metro Manila · hybrid · remote</text>

  <!-- status bar -->
  <rect x="0" y="574" width="1200" height="56" fill="${chrome}"/>
  <line x1="0" y1="574" x2="1200" y2="574" stroke="${rule}" stroke-width="2"/>
  <text x="40" y="610" font-family="${mono}" font-size="20" fill="${ink3}" letter-spacing="1.2">${domain}</text>
  <text x="1160" y="610" text-anchor="end" font-family="${mono}" font-size="20" fill="${accent}" letter-spacing="1.2">Terraform · CloudFront · OIDC</text>
</svg>`;

mkdirSync(dirname(out), { recursive: true });

const png = await sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer();
writeFileSync(out, png);

const meta = await sharp(png).metadata();
console.log(`wrote ${out}`);
console.log(`${meta.width}x${meta.height}, ${(png.length / 1024).toFixed(1)} kB`);
