/**
 * Prepares the capstone figures and evidence photos for the web.
 * DECISIONS.md #18, #35, #41(b), #57.
 *
 * Local-only. Run it, inspect the output, commit the output, done:
 *
 *     node scripts/capstone/redact.mjs
 *
 * Reads originals from scripts/capstone/source/ (gitignored) and writes
 * redacted copies to site/public/capstone/. The originals never enter this
 * public repo, because redaction that happens after publication has not
 * happened at all.
 *
 * Three things make the copies safe to publish where the originals are not:
 *
 *   - FACES AND BADGES ARE BLURRED. #41(b) says every evidence photo is a
 *     sanitization target, reviewed for faces and badges. The people in these
 *     photos agreed to appear in a school submission; nobody agreed to appear
 *     on a public job-hunting site. The regions are declared below as data so
 *     a reviewer can read what was covered without running anything.
 *   - METADATA IS STRIPPED AND VERIFIED. sharp drops it unless told otherwise;
 *     this checks rather than assumes, because a phone photo carries GPS to
 *     the metre and these were taken inside a real client's building.
 *   - THEY ARE RESIZED to roughly what the page displays. Publishing a
 *     full-resolution original hands out far more detail than the page shows,
 *     including detail a viewer could sharpen back out of a light blur.
 *
 * The blur radius is deliberately heavy and applied to a downscale-then-
 * upscale of the region, not a soft blur of the original pixels. A gentle
 * gaussian over a face is reversible enough to be worthless.
 */

import { readdirSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(resolve(here, '../../site/package.json'));
const sharp = require('sharp');

const sourceDir = resolve(here, 'source');
const outDir = resolve(here, '../../site/public/capstone');

/**
 * What ships, and what is covered before it does.
 *
 * `redact` regions are fractions of the image (0–1), not pixels, so they
 * survive the resize below and stay readable as "the top-right quarter"
 * rather than as a magic number.
 */
const plan = [
  {
    from: 'Figure1.png',
    to: 'floor-plan.png',
    width: 900,
    // A schematic with no name, address, dimensions or scale on it. The room
    // labels are generic ("Study Hub", "Gym"). Nothing to cover.
    redact: [],
  },
  {
    from: 'Figure2.png',
    to: 'topology-before.png',
    width: 900,
    redact: [],
  },
  {
    from: 'Figure5.png',
    to: 'topology-after.png',
    width: 900,
    redact: [],
  },
  {
    from: 'Proof1_Installation of Hardwares.png',
    to: 'evidence-installation.png',
    width: 720,
    // Verified against a box overlay rather than estimated — the first pass
    // at these numbers blurred the wall and left both faces untouched, which
    // is the failure mode that matters here. Check the output, every time.
    redact: [
      // Left figure: whole head, generously. A face is not half-covered.
      { x: 0.53, y: 0.25, w: 0.27, h: 0.25 },
      // Right figure: head. Turned away, but a profile identifies a person.
      { x: 0.74, y: 0.17, w: 0.26, h: 0.35 },
      // Shirt print and lanyard on the left figure, which name an organisation.
      { x: 0.62, y: 0.45, w: 0.26, h: 0.14 },
    ],
  },
  {
    from: 'Proof2_Configuration_of_Hardwares.png',
    to: 'evidence-configuration.png',
    width: 720,
    redact: [
      // The monitor, which is showing a live server config file. The photo's
      // value is "this was configured on real hardware in a real room", and
      // none of that value is in the text. Illegible at display size is not
      // the same as unpublished — a reader can upscale a PNG.
      { x: 0.0, y: 0.08, w: 0.33, h: 0.63 },
      // Seated figure beside the monitor.
      { x: 0.27, y: 0.4, w: 0.18, h: 0.22 },
      // Notice on the wall, which carries printed text that may name the site.
      { x: 0.51, y: 0.01, w: 0.13, h: 0.14 },
    ],
  },
];

if (!existsSync(sourceDir)) {
  console.error(`No source directory: ${sourceDir}`);
  console.error('Put the capstone originals there. They are gitignored on purpose.');
  process.exit(1);
}

const present = new Set(readdirSync(sourceDir));
mkdirSync(outDir, { recursive: true });

let failures = 0;

for (const item of plan) {
  if (!present.has(item.from)) {
    console.error(`missing: ${item.from}`);
    failures += 1;
    continue;
  }

  const input = resolve(sourceDir, item.from);
  const output = join(outDir, item.to);

  // Resize first, so the redaction regions are computed against the exact
  // pixels that ship. Covering the original and then scaling could reveal an
  // edge the blur was sized to hide.
  const resized = await sharp(input).resize({ width: item.width }).png().toBuffer();
  const { width, height } = await sharp(resized).metadata();

  const patches = [];
  for (const region of item.redact) {
    // Clamp to the image: a region that runs off the edge is an error in the
    // table above, and sharp would throw a less obvious one.
    const left = Math.max(0, Math.round(region.x * width));
    const top = Math.max(0, Math.round(region.y * height));
    const w = Math.min(width - left, Math.round(region.w * width));
    const h = Math.min(height - top, Math.round(region.h * height));
    if (w <= 0 || h <= 0) continue;

    // Destroy the information, then scale the wreckage back up: throw the
    // region away at ~12px wide and enlarge that with nearest-neighbour, so
    // what lands is a hard mosaic. A gaussian blur only smears pixels that
    // are all still there, and reads as a bad photo rather than as a
    // decision.
    //
    // TWO pipelines, not one chain. sharp applies only the LAST resize in a
    // pipeline, so `.resize(small).resize(big)` silently returns the region
    // at its original detail — which is exactly what shipped on the first
    // attempt at this: three regions composited perfectly, none of them
    // actually redacted.
    const shrunk = await sharp(resized)
      .extract({ left, top, width: w, height: h })
      .resize({ width: Math.max(4, Math.round(w / 18)), fit: 'fill' })
      .png()
      .toBuffer();

    const patch = await sharp(shrunk)
      .resize({ width: w, height: h, fit: 'fill', kernel: 'nearest' })
      .png()
      .toBuffer();

    patches.push({ input: patch, left, top });
  }

  await sharp(resized).composite(patches).png({ compressionLevel: 9 }).toFile(output);

  // Trust, then verify. A silent regression here publishes a real client's
  // building, geotagged, to a public repo.
  const meta = await sharp(output).metadata();
  const dirty = ['exif', 'icc', 'iptc', 'xmp'].filter((key) => meta[key]);
  if (dirty.length > 0) {
    console.error(`  !! ${item.to} still carries ${dirty.join(', ')}`);
    failures += 1;
    continue;
  }

  console.log(
    `${item.to}  ${meta.width}x${meta.height}  ${patches.length} region(s) redacted  metadata clean`,
  );
}

if (failures > 0) {
  console.error(`\n${failures} problem(s). Nothing here is safe to commit until they are fixed.`);
  process.exit(1);
}

console.log(`\nWrote ${plan.length} file(s) to site/public/capstone/`);
console.log('Look at every one of them before committing. This script cannot see faces.');
