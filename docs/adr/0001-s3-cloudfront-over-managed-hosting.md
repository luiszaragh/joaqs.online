# ADR-0001 — Serve the site from S3 and CloudFront, provisioned in Terraform

- **Status:** accepted
- **Date:** 2026-08-30
- **Milestone:** M1
- **DECISIONS.md:** #2, #17

## Context

This site is a hiring asset for Cloud/DevOps roles. Its readers are recruiters
and engineers deciding whether to run an interview.

Cloudflare Pages, Netlify, Vercel and AWS Amplify would each host a static Astro
build on a free tier, deploy on `git push`, and provide TLS and a global CDN with
no infrastructure code at all. Any of them would have had the site live in an
afternoon.

## Decision

Provision the hosting explicitly: a private S3 bucket, CloudFront with Origin
Access Control, an ACM certificate, and Cloudflare DNS — all in Terraform, all in
a public repository, deployed from GitHub Actions over OIDC with no long-lived
AWS credentials.

## Consequences

**What it buys.** The infrastructure becomes the portfolio piece rather than a
delivery detail. A reviewer can read the Terraform, the OIDC trust policy, the
bucket policy and the CloudFront function, and see the reasoning behind each. A
candidate whose DevOps portfolio deploys by clicking a button in a hosting
dashboard has left the most on-message evidence on the table.

**What it costs.** Roughly a day of work that managed hosting would have done for
free, plus the ongoing surface: certificates renew, a distribution has to be
invalidated on deploy, and a private bucket behind OAC does not serve directory
indexes without a CloudFront Function. Those are real maintenance obligations,
not incidental.

**What it does not buy.** Nothing about this is faster, cheaper or more reliable
than Cloudflare Pages for a static site of this size. Claiming otherwise would be
dishonest. It is chosen for what it demonstrates.

**Cost.** S3, CloudFront and ACM sit inside the free tier at portfolio traffic —
realistically under $1/month, guarded by the budget alarm in ADR terms below and
in `infra/modules/observability`.

## Alternatives considered

**Cloudflare Pages.** Strongest option on merit: free, fast, git-integrated,
already the DNS provider so one less vendor. Rejected because it makes the
deployment invisible, which is the opposite of the goal.

**AWS Amplify Hosting.** Keeps the work inside AWS while hiding most of it behind
a managed abstraction. Rejected for the same reason as Pages, with less upside —
it is neither the simplest option nor the most instructive one.

**S3 static website hosting** (the website endpoint, without CloudFront).
Rejected because it cannot serve HTTPS on a custom domain, and requires a public
bucket. Both are the wrong lesson to publish.
