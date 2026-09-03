# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary: recruiters and hiring managers screening for Cloud/DevOps roles.** Luis Zara is
actively job-hunting as of 2026-09-03 — Quezon City, hybrid around Metro Manila, or remote,
open to entry-level and associate positions.

The confirmed arrival path is **the link on his LinkedIn profile**. That single fact sets the
job of the first viewport: visitors already know the name and the headline before they land,
so the site owes them depth and proof, not an introduction.

A second, smaller audience arrives from the GitHub profile or from the repository itself.
These readers are technical, and they read the Terraform, the workflows, and the ADRs. The
repository is part of the product surface, not a backstage area.

## Product Purpose

A hiring asset. The site exists to convert a recruiter's click into an interview, and to give
that interview ten minutes of concrete material to open with.

It is explicitly **not** a personal creative presence (DECISIONS.md #1). Creativity makes the
site memorable *after* it has done its job; it is not what the site leads with.

Success is a reply, not a session length.

## Positioning

**The infrastructure is the artifact.** This is a DevOps portfolio deployed by the means it
claims competence in: Terraform-provisioned S3 and CloudFront, GitHub Actions deploying over
OIDC with no long-lived AWS keys, a public repository with zero secrets in it by construction,
and a serverless assistant on a Lambda Function URL behind the same distribution.

Click-to-deploy hosting would have taken an afternoon. Not using it was the point — a DevOps
candidate whose portfolio deploys by clicking a button in Vercel has left the single most
on-message point on the table (DECISIONS.md #2).

This is the claim a neighboring portfolio cannot truthfully copy without doing the same work.
**Do not revisit it by proposing Netlify, Vercel, or Cloudflare Pages** — the more laborious
path was chosen against the cheaper one deliberately.

## Operating Context

- **Phones are a primary target, not a fallback.** Roughly half of recruiter traffic lands on
  a phone (DECISIONS.md #7), which is why the WordPad metaphor stayed hybrid rather than fully
  skeuomorphic — full period chrome is charming for five seconds and then it is a usability
  problem on a small screen.
- **Asynchronous by design.** A recruiter reading at 11pm gets the AI assistant, not silence
  and not an unmoderated live chatroom (DECISIONS.md #3).
- **Cross-checking is the expected behavior.** Recruiters open the site with the résumé PDF
  already in hand. The two must never disagree.
- **Claims are meant to be verified.** Each certification carries its official Credly emblem
  and a public verification URL — the point is "click through and check," not "he says so."
- **The repository gets read.** `docs/adr/` is written for someone reading it before an
  interview; `DECISIONS.md` is the private-facing long record of the same reasoning.

## Capabilities and Constraints

**Shipped and live:**

- Static Astro 5 site on S3 + CloudFront, all infrastructure in Terraform (`aws` and
  `cloudflare` providers, state in S3 with native locking, no Route 53).
- Three path-filtered GitHub Actions workflows, one least-privilege OIDC role each.
- An AI assistant on a Lambda Function URL reached through **Amazon Bedrock** (Claude Haiku
  4.5 via an inference profile — DECISIONS.md #49 replaced the original Anthropic API key
  path, and `README.md` and `PLAN.md` still describe the older arrangement).
- Full-context stuffing with prompt caching over a build-time corpus, no RAG (ADR-0004).
- CloudFront access logs with a 90-day lifecycle, Athena on demand, and a live view counter.

**Hard constraints future work must preserve:**

- **The repository is public, and zero secrets ever enter it.** Gitleaks runs as a blocking CI
  gate with a custom rule that fails the build if a Philippine mobile number in any common
  format lands in the tree.
- **The source photograph behind the ASCII portrait is gitignored and never published in any
  form.** The face does not enter a public repo.
- The published résumé PDF ships with the phone number stripped.
- **The skills list may never exceed the résumé.** Prometheus, Grafana, CloudFront, and ACM
  are all demonstrably used in shipped work and are still absent from both, on purpose. Fix
  the résumé first, then the site — in that order.
- The domain string lives in `site/astro.config.mjs` and Terraform's `var.domain_name` and
  nowhere else, because a migration to a real-name domain is already anticipated
  (DECISIONS.md #25).
- Budget target ~$5/mo with a hard $10 AWS Budget alarm defined in Terraform.
- Assistant guardrails: third person, labeled as AI, declines anything outside the profile,
  10 messages/hour per IP, 400-token replies, 12-turn cap, and a graceful canned message on
  budget exhaustion rather than a broken widget.
- Production only — no staging environment and no PR previews (ADR-0005).

**Explicitly undecided:**

- The `aws-eks-three-tier` project is shelved, not scheduled. Its card returns when there is
  something real to link to, and not before (DECISIONS.md #39, #43, #57).

## Brand Commitments

- **Name:** `Luis Zara` in compact identity positions (browser tab, sidebar, OG metadata);
  `Luis Joaquin V. Zara` on the masthead.
- **Role label:** `Cloud & DevOps Engineer`. One label, no slashes. **The word "Junior" never
  appears in the H1** — it belongs in About, framed as "open to entry-level and associate
  roles." A junior listing Cloud / DevOps / Platform / SRE / Security reads as someone who
  has not chosen, and screeners pattern-match on one label (DECISIONS.md #26).
- **The About intro is Luis's own words.** Use close to verbatim. Do not "improve" it into
  marketing copy.
- **No proficiency bars.** A bar claiming "Terraform 85%" is a number nobody can defend in an
  interview (DECISIONS.md #6).
- **No "coming soon" cards.** An honest absence beats an advertised placeholder, which
  actively costs credibility (DECISIONS.md #4).
- **The assistant speaks in third person and is labeled AI.** It never impersonates Luis
  (ADR-0006).

## Evidence on Hand

Real, verifiable, and already in the repository:

- Three earned AWS certifications with public Credly verification URLs — DOP-C02 (DevOps
  Engineer – Professional), SAA-C03 (Solutions Architect – Associate), SOA-C03 (CloudOps
  Engineer – Associate). AIF-C01 (AI Practitioner) is in progress and ships visually
  separated. Official emblems in `site/public/`.
- **DevSecOps CI/CD pipeline** — a fifteen-stage Jenkins pipeline with five security and
  quality tools, public repo, dedicated page at `/projects/devsecops-cicd-pipeline/`.
- **Campus wireless network redesign** — the UST capstone, shipped sanitized with redacted
  figures and real site photographs (`site/public/capstone/`), at
  `/projects/network-capstone/`.
- Noventiq delivery internship, Feb–Jun 2026, with concrete bullets (300+ users, 1,000+
  records, hybrid Entra ID).
- `site/public/resume.pdf` — the source of record for skills and titles.
- ASCII graduation portrait rendered from a gitignored source photograph, with real alt text.
- Blog post: "how this site is deployed."
- Six ADRs in `docs/adr/`, and 64 numbered decisions in `DECISIONS.md`.
- The running infrastructure itself, which is the largest piece of evidence on the site.

**Absences that must never be fabricated:** there are no testimonials, no client or employer
endorsements, no case-study metrics, no performance or traffic claims beyond the real view
counter, no pricing, and no proficiency scores. Nothing in this list may be invented to fill
a layout.

## Product Principles

1. **Showing beats claiming.** Every assertion on the site carries something a reader can
   click through and verify — a Credly URL, a public repo, a live endpoint, an ADR.
2. **The delivery mechanism is the evidence.** How this site is built and deployed is itself
   the strongest argument it makes. Decisions that make the site easier to ship at the cost of
   that argument are losing trades.
3. **An honest absence beats an advertised placeholder.** Empty is credible; "coming soon" is
   not.
4. **The site and the résumé are one claim in two formats.** When they disagree, the résumé
   is the source of record and the discrepancy is the bug.
5. **Zero secrets, by construction.** The public repository is a design constraint that shaped
   the architecture, not a risk managed after the fact.

## Accessibility & Inclusion

- **WCAG AA contrast is a standing practice, not an aspiration.** `site/src/styles/tokens.css`
  records the measured ratio for every ink/surface pair in both themes; `--color-ink-3` exists
  as the floor precisely because it must clear AA on both paper and chrome.
  Every focus ring clears 3:1.
- `prefers-reduced-motion: reduce` is honored globally in `site/src/styles/global.css`.
- Both themes are real: system-default dark, with an explicit toggle that wins in both
  directions.
- The ASCII portrait carries real alt text and a narrow variant under 640px — it is content
  with a text alternative, not decoration.
- Mobile is a primary target because half of the audience is on it.
