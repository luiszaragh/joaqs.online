/**
 * Generates the ASCII graduation portrait. DECISIONS.md #41/#44/#45.
 *
 * Local-only. Run it, inspect, commit the .txt files, done:
 *
 *     node scripts/portrait/generate.mjs
 *
 * Reads the photograph from scripts/portrait/source/ (gitignored — the photo
 * never enters the repository; only the text leaves this machine) and writes
 * two fixed-width variants, because ASCII art does not reflow:
 *
 *     site/src/assets/portrait/portrait-wide.txt    (~72 columns, >=640px)
 *     site/src/assets/portrait/portrait-narrow.txt  (~42 columns, below)
 *
 * How a photo becomes text: shrink the image until one pixel is one character
 * cell, then swap each pixel for a glyph by how much ink it carries — '@' is
 * nearly solid, '.' is nearly empty, ' ' is bare paper. Dense glyphs read as
 * dark on the light theme; the dark toggle turns the portrait into a
 * photographic negative, which is accepted and is half the charm.
 *
 * The studio backdrop is erased geometrically, not tonally. Its grey overlaps
 * the hair in brightness, so no brightness cut can blank one without eating
 * the other — and edge-following fills turned out to leak through the soft
 * bokeh edges of this particular photograph. A silhouette mask is hand-fitted
 * to the figure instead: a head ellipse, a neck, and a shoulder line, in
 * fractions of the source frame. Everything outside it is paper. The numbers
 * are tuned to this one photo and say so; a different photo means retuning
 * them against a luminance probe, which is a ten-minute job, not a framework.
 */

import { readdirSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));

// sharp is a dependency of the Astro site; resolve against site/ rather than
// carrying a second node_modules for one local script (same pattern as
// scripts/og/generate.mjs).
const require = createRequire(resolve(here, '../../site/package.json'));
const sharp = require('sharp');

const sourceDir = resolve(here, 'source');
const outDir = resolve(here, '../../site/src/assets/portrait');

const candidates = readdirSync(sourceDir).filter((f) => /\.(jpe?g|png|webp|tiff?)$/i.test(f));
if (candidates.length === 0) {
  console.error(`No image found in ${sourceDir}`);
  process.exit(1);
}
const source = resolve(sourceDir, candidates[0]);

// Darkest to lightest. Ten steps is enough tonal range for a face; longer
// ramps add glyph variety but read as noise at this size.
const RAMP = '@%#*+=-:. ';

// Head-and-shoulders crop, as fractions of the source frame. Hand-tuned to
// this photograph against a coarse luminance grid.
const CROP = { left: 0.05, top: 0.06, width: 0.9, height: 0.85 };

// A monospace cell is taller than it is wide — IBM Plex Mono at line-height
// 1.05 is roughly 1.75x taller — so sampling must compensate or the face
// comes out stretched.
const CELL_ASPECT = 1.75;

// ---- the silhouette mask ---------------------------------------------------
// All coordinates are fractions of the FULL source frame, measured off a
// 24x30 luminance probe of this photograph.

const HEAD = { cx: 0.5, cy: 0.42, rx: 0.225, ry: 0.31 };
const NECK = { halfWidth: 0.13, top: 0.6, bottom: 0.74 };
// The gown line rises from y=SHOULDER.atNeck beside the neck to
// y=SHOULDER.atEdge at the frame edge; everything below it is figure.
const SHOULDER = { atNeck: 0.69, atEdge: 0.76 };

function inFigure(x, y) {
  const dx = (x - HEAD.cx) / HEAD.rx;
  const dy = (y - HEAD.cy) / HEAD.ry;
  if (dx * dx + dy * dy <= 1) return true;

  if (Math.abs(x - HEAD.cx) <= NECK.halfWidth && y >= NECK.top && y <= NECK.bottom) return true;

  const d = Math.max(0, Math.abs(x - HEAD.cx) - NECK.halfWidth);
  const shoulderY =
    SHOULDER.atNeck + (d / (0.5 - NECK.halfWidth)) * (SHOULDER.atEdge - SHOULDER.atNeck);
  return y >= shoulderY;
}

// ---- tone mapping ----------------------------------------------------------

// Luminance to ink (0 = paper, 1 = solid), as an anchored curve rather than a
// single gamma, so each region of this photograph can be placed deliberately:
// gown and hair solid, the hood's grey and red mid-weight, the face carrying
// only its features.
const CURVE = [
  [0.0, 1.0],
  [0.08, 0.92],
  [0.18, 0.72],
  [0.32, 0.45],
  [0.48, 0.28],
  [0.62, 0.12],
  [0.76, 0.02],
  [1.0, 0.0],
];

function ink(lumValue) {
  for (let k = 1; k < CURVE.length; k++) {
    const [x1, y1] = CURVE[k - 1];
    const [x2, y2] = CURVE[k];
    if (lumValue <= x2) return y1 + ((lumValue - x1) / (x2 - x1)) * (y2 - y1);
  }
  return 0;
}

// ---- rendering -------------------------------------------------------------

async function render(cols) {
  const meta = await sharp(source).rotate().metadata();
  const displayAspect = (CROP.height / CROP.width) * (meta.height / meta.width);
  const rows = Math.round((cols * displayAspect) / CELL_ASPECT);

  const { data, info } = await sharp(source)
    .rotate()
    .extract({
      left: Math.round(meta.width * CROP.left),
      top: Math.round(meta.height * CROP.top),
      width: Math.round(meta.width * CROP.width),
      height: Math.round(meta.height * CROP.height),
    })
    .resize({ width: cols, height: rows, fit: 'fill' })
    .grayscale()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const lines = [];
  for (let y = 0; y < rows; y++) {
    let line = '';
    for (let x = 0; x < info.width; x++) {
      // This cell's position, mapped back to full-frame fractions for the mask.
      const frameX = CROP.left + ((x + 0.5) / cols) * CROP.width;
      const frameY = CROP.top + ((y + 0.5) / rows) * CROP.height;
      if (!inFigure(frameX, frameY)) {
        line += ' ';
        continue;
      }
      const inkValue = ink(data[y * info.width + x] / 255);
      const idx = Math.min(RAMP.length - 1, Math.round((1 - inkValue) * (RAMP.length - 1)));
      line += RAMP[idx];
    }
    lines.push(line.trimEnd());
  }
  while (lines.length && lines[0] === '') lines.shift();
  while (lines.length && lines[lines.length - 1] === '') lines.pop();
  return lines.join('\n') + '\n';
}

mkdirSync(outDir, { recursive: true });
writeFileSync(resolve(outDir, 'portrait-wide.txt'), await render(72));
writeFileSync(resolve(outDir, 'portrait-narrow.txt'), await render(42));
console.log(`wrote ${outDir}/portrait-{wide,narrow}.txt`);
