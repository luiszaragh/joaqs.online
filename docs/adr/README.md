# Architecture Decision Records

Six records, aimed at an interviewer with five minutes. The chronological,
unabridged version of the same reasoning — all 45 decisions — lives in
[`DECISIONS.md`](../../DECISIONS.md) at the repo root. These two files serve
different readers on purpose (DECISIONS.md #31).

Each ADR is written in the milestone that implements it, not before. An ADR
written ahead of the work is a plan; an ADR written alongside it is a record.

| # | Decision | Milestone | Sources in DECISIONS.md |
|---|---|---|---|
| 0001 | Static site on S3 + CloudFront rather than Cloudflare Pages or Amplify — the infrastructure is the artifact | M1 | #2, #17 |
| 0002 | Cloudflare DNS managed in Terraform, DNS-only (grey cloud), no Route 53 | M1 | #17, #24, #32 |
| 0003 | Lambda Function URL rather than API Gateway | M5 | #11 |
| 0004 | Context-stuffing with prompt caching rather than RAG, for a six-document corpus | M5 | #11 |
| 0005 | Production only — no staging environment, no PR previews | M4 | #29 |
| 0006 | A third-person, clearly-labelled AI persona rather than first-person-as-Luis | M5 | #20 |

Use [`template.md`](template.md). Number files `NNNN-kebab-case-title.md`.
