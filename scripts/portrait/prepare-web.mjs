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
