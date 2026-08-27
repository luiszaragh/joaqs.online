# joaqs.online

Portfolio site for **Luis Zara — Cloud & DevOps Engineer**. A static Astro site
on S3 and CloudFront, provisioned entirely in Terraform, deployed from GitHub
Actions over OIDC with no long-lived AWS keys, with a Claude-backed assistant on
a Lambda Function URL behind the same distribution.

Click-to-deploy hosting would have taken an afternoon. That was the point of not
using it: for a DevOps portfolio, the deployment is half the pitch.

## Architecture

```
                      Cloudflare DNS (DNS-only, Terraform-managed)
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

Two Terraform providers, `aws` and `cloudflare`. State in S3 with native
locking. No Route 53 — DNS already lives at Cloudflare, so buying a second
hosted zone would have been ceremony.

## Layout

| Path | What |
|---|---|
| [`site/`](site/) | Astro site — pages, components, design tokens, content |
| [`lambda/`](lambda/) | Chatbot handler (M5) |
| [`infra/`](infra/) | Terraform — `modules/{site,chatbot,dns,observability}` + root |
| [`scripts/`](scripts/) | ASCII-portrait generator, chatbot corpus builder |
| [`docs/adr/`](docs/adr/) | Six architecture decision records |
| [`.github/workflows/`](.github/workflows/) | Three path-filtered pipelines |

## Running the site locally

```sh
cd site
npm install
npm run dev      # http://localhost:4321
npm run build    # -> site/dist
```

Node 24 (`.nvmrc`). No environment variables are needed to build the site.

## Secrets

This repository is public, and that constraint shaped the design rather than
being worked around afterwards.

- No AWS keys anywhere — GitHub Actions authenticates over OIDC into one
  least-privilege role per workflow.
- The Anthropic API key is a Secrets Manager reference resolved at runtime by
  the Lambda's execution role. It never appears in a variable, a workflow, or
  Terraform state in plaintext.
- Gitleaks runs as a blocking CI gate against [`.gitleaks.toml`](.gitleaks.toml),
  which extends the default ruleset with a rule that fails the build if a
  Philippine mobile number in any common format lands in the tree — the public
  résumé variant ships without one.
- The source photograph behind the ASCII portrait is gitignored and never
  published in any form.

```sh
gitleaks detect --config .gitleaks.toml --redact --verbose
```

## Why anything here is the way it is

- [`DECISIONS.md`](DECISIONS.md) — all 45 decisions, chronological, with the
  reasoning and the rejected alternatives. Written for me.
- [`docs/adr/`](docs/adr/) — six short ADRs. Written for someone reading this
  before an interview.
- [`PLAN.md`](PLAN.md) — the build order and current milestone.

## Status

**M0 complete** — repo skeleton, Astro scaffold, design tokens, secret-scanning
rules. What is currently on the site is small but real; the full document
treatment lands in M3, after the pipeline that deploys it exists in M2.
