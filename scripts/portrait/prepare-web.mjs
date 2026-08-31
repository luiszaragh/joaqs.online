/**
 * Prepares the graduation photograph for the web. DECISIONS.md #47.
 *
 * Local-only. Run it, inspect, commit the output, done:
 *
 *     node scripts/portrait/prepare-web.mjs
 *
 * Reads the original from scripts/portrait/source/ (gitignored) and writes a
 * cleaned, committed copy to site/src/assets/graduation.jpg. Two things make
 * the copy safe to publish where the original is not:
 *
 *   - sharp strips all metadata unless told otherwise — EXIF, GPS, timestamps,
 *     device identifiers all gone. The script verifies that instead of
 *     assuming it (#41(b): every camera file carries more than the pixels).
 *   - It is resized to display resolution. Publishing a 2836x3673 original
 *     hands out far more face than the page ever shows.
 */

import { readdirSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(resolve(here, '../../site/package.json'));
const sharp = require('sharp');

const sourceDir = resolve(here, 'source');
const outFile = resolve(here, '../../site/src/assets/graduation.jpg');

const candidates = readdirSync(sourceDir).filter((f) => /\.(jpe?g|png|webp|tiff?)$/i.test(f));
if (candidates.length === 0) {
  console.error(`No image found in ${sourceDir}`);
  process.exit(1);
}

mkdirSync(dirname(outFile), { recursive: true });

// 720px wide serves a ~14rem display slot at 3x density. `.rotate()` bakes the
// EXIF orientation into the pixels before the EXIF is dropped, so the image
// cannot come out sideways once the tag that said "rotate me" is gone.
await sharp(resolve(sourceDir, candidates[0]))
  .rotate()
  .resize({ width: 720 })
  .jpeg({ quality: 82, mozjpeg: true })
  .toFile(outFile);

// Trust, then verify: read the written file back and confirm the metadata is
// actually gone. A silent regression here would publish EXIF to a public repo.
const meta = await sharp(outFile).metadata();
if (meta.exif || meta.xmp || meta.iptc) {
  console.error('Metadata survived the rewrite — refusing to leave the file in place.');
  process.exit(1);
}

console.log(`wrote ${outFile} (${meta.width}x${meta.height}, metadata verified clean)`);

// ---------------------------------------------------------------------------
// The dithered variant (DECISIONS.md #51): a 4x4 Bayer ordered dither,
// rendered black-on-TRANSPARENT. The page uses it as a CSS mask over an
// ink-coloured layer, so the dots take the theme's ink automatically — one
// file serves light and dark without a filter hack or a second image.
//
// Dithered small (180px) and upscaled 4x with nearest-neighbour: at full
// resolution the dots would be sub-pixel grey mush; chunky pixels are the
// look. The output is exactly the base photo's dimensions so the hover
// crossfade aligns pixel-for-pixel.
// ---------------------------------------------------------------------------

const ditherFile = resolve(here, '../../site/src/assets/graduation-dither.png');
const SMALL_W = 180;

const { data, info } = await sharp(outFile)
  .resize({ width: SMALL_W })
  .grayscale()
  .normalise()
  .raw()
  .toBuffer({ resolveWithObject: true });

// Bayer 4x4: thresholds spread evenly over the cell so flat tones become
// stable dot patterns instead of noise.
const BAYER = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];

const rgba = Buffer.alloc(info.width * info.height * 4);
for (let y = 0; y < info.height; y++) {
  for (let x = 0; x < info.width; x++) {
    const lum = data[y * info.width + x] / 255;
    const threshold = (BAYER[y % 4][x % 4] + 0.5) / 16;
    const inked = lum < threshold; // darker than the cell's threshold -> a dot
    const o = (y * info.width + x) * 4;
    rgba[o + 3] = inked ? 255 : 0; // alpha only; colour comes from CSS
  }
}

await sharp(rgba, { raw: { width: info.width, height: info.height, channels: 4 } })
  .resize({ width: meta.width, height: meta.height, kernel: 'nearest' })
  .png()
  .toFile(ditherFile);

const ditherMeta = await sharp(ditherFile).metadata();
console.log(`wrote ${ditherFile} (${ditherMeta.width}x${ditherMeta.height}, Bayer 4x4 at ${SMALL_W}px)`);
