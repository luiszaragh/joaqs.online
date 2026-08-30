# Portfolio Site — Build Plan

**joaqs.online** · a hiring asset for Cloud/DevOps roles, where the deployment *is* half the pitch.

Every decision behind this plan is recorded in [DECISIONS.md](DECISIONS.md). Nothing below is a
fresh choice — it is the execution of 45 settled ones. **Status: M2 complete — the site is live and
deploys from `main` over OIDC.** Next step is M3.

---

## Architecture

```
                      Cloudflare DNS (grey cloud, Terraform-managed)
                                    |
                                    v
   Browser --HTTPS-->  CloudFront  --+-->  S3 (private, OAC)      <- static site
                       (ACM us-east-1)|
                                      +-->  Lambda Function URL   <- chatbot
                                              |-- Claude Haiku 4.5
                                              |-- DynamoDB (per-IP rate limit)
                                              +-- S3: corpus.json (cold-start fetch)
                                    |
                       access logs --+-->  S3 (90-day lifecycle) -> Athena on demand
```

Everything above the browser is Terraform. Two providers: `aws` + `cloudflare`. State in S3 with
native locking. No Route53 — DNS already lives at Cloudflare.

**Regions:** `ap-southeast-1` for Lambda/DynamoDB/S3, `us-east-1` for the ACM certificate
(CloudFront requires it).

---

## Repo — `luiszaragh/joaqs.online`, public

```
site/                Astro: src/{components,layouts,pages,content}, public/
lambda/              chatbot handler + deps
infra/               Terraform: modules/{site,chatbot,dns,observability} + root
scripts/             ascii-portrait generator (local-only), corpus builder
docs/adr/            6 ADRs
DECISIONS.md         chronological record of all 45 decisions
.github/workflows/   site.yml · lambda.yml · infra.yml
```

**Zero secrets in git, ever** — the repo is public and that constraint shapes everything.

---

## Information architecture

| # | Section | Contents |
|---|---|---|
| 00 | header | Luis Zara — Cloud & DevOps Engineer · certs line · "Open to Cloud/DevOps roles — Metro Manila, hybrid, or remote" |
| 01 | about | ASCII graduation portrait · networking-origin paragraph · BSIT UST 2026, entry-level/associate |
| 02 | certifications | DOP-C02 · SAA-C03 · SOA-C03 · *In progress:* AI Practitioner (visually separated) |
| 03 | projects | DevSecOps CI/CD **(live)** · aws-eks-three-tier *(slot, pending rework)* · UST capstone *(slot, pending sanitized summary)* |
| 04 | blog | Post #1: how this site is deployed · RSS · no tags |
| 05 | experience | Noventiq · capstone framed as professional work |
| 06 | skills | grouped, no proficiency bars |
| 07 | contact | click-to-copy email · LinkedIn · GitHub · résumé PDF (phone stripped) |

Each project also gets a **dedicated page**: problem → architecture diagram → key decisions →
what broke → outcome.

---

## Design

**Chrome.** Menu bar **File** (résumé, copy email, view source) / **View** (dark toggle, jump to
section) — no Edit or Help menu · status bar with current section, deployed commit SHA linking to
GitHub, build timestamp · section headers down the left margin on wide screens.
Mobile: menu collapses to a hamburger, status bar stays. (Revised by DECISIONS.md #46 — the
title bar and Help menu are gone; scroll-reveal and letter-build animations added.)

**Type and color.** Source Serif 4 body, IBM Plex Mono chrome, both self-hosted and Latin-subset.
Paper `#faf8f5`, ink `#111`, dark toggle. Document-glyph favicon. One static OG image.

**ASCII portrait.** Tuned locally, committed as `.txt`, rendered in a `<pre>`, monochrome, real
`alt` text, narrow variant under 640px. **Source photo gitignored — the face never enters a
public repo.**

---

## Chatbot

Lambda Function URL behind CloudFront · Claude Haiku 4.5 (`claude-haiku-4-5-20251001`) ·
full-context stuffing with prompt caching, no RAG · corpus generated from site content at build
time → S3 → fetched on cold start, cached in module scope · **third person, labeled AI**, scoped
to decline anything outside the profile · 10 msg/hr per IP (DynamoDB), 400-token replies, 12-turn
cap · prompts logged to CloudWatch, 30-day retention · budget hit → graceful canned message,
never a broken widget.

---

## Pipeline

Three path-filtered workflows, one least-privilege OIDC role each.

| Workflow | Trigger | Does |
|---|---|---|
| `site.yml` | `site/**` | build → S3 sync → invalidate HTML only (assets are hashed) |
| `lambda.yml` | `lambda/**` | package → update function |
| `infra.yml` | `infra/**` | `plan` on PR (posted as comment) → `apply` on main behind Environment approval |

**Mandatory gates:** astro build · Gitleaks (with a custom rule failing on the phone number) ·
tflint · checkov · link checker. **Advisory:** Lighthouse.

---

## ADRs to write

1. Static on S3+CloudFront over Cloudflare Pages/Amplify — the infra is the artifact
2. Cloudflare DNS in Terraform, grey cloud, no Route53
3. Lambda Function URL over API Gateway
4. Context-stuffing over RAG for a six-document corpus
5. Prod-only, no staging or PR previews
6. Third-person AI persona over first-person-as-Luis

---

## Build order

| | Milestone |
|---|---|
| ~~**M0**~~ | ~~repo skeleton, Astro scaffold, DECISIONS.md, Gitleaks rules~~ — **done 2026-08-28** |
| ~~**M1**~~ | ~~Terraform: state backend, ACM, S3+OAC, CloudFront, Cloudflare DNS, budget alarm~~ — **done 2026-08-30** |
| ~~**M2**~~ | ~~OIDC roles + `site.yml` — first real deploy~~ — **done 2026-08-30** |
| **M3** | the site: chrome, tokens, sections 00–07, ASCII portrait, OG image |
| **M4** | `infra.yml` + all gates |
| **M5** | chatbot end-to-end |
| **M6** | blog + post #1 + access logs |
| | **launch** |

Launch ships with **one project** (DevSecOps). 3-Tier and the capstone land in their slots when
ready.

---

## Cost

Domain paid through next year. S3 + CloudFront + Lambda + DynamoDB sit inside free tier at
portfolio traffic — realistically **under $1/mo**, with the Claude API the only variable, capped.
Budget alarm at $10 → SNS → email, defined in Terraform. The $100 in AWS credits covers it regardless.

---

## Three things worth pushing back on before M0

1. Launching with only one project in the projects section
2. Six ADRs — is that the right list, and is six the right number
3. Whether **M3 should come before M2**, so there is something on screen sooner
