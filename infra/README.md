# infra — Terraform

Two providers (`aws`, `cloudflare`) managing one cross-vendor stack. Lands in **M1**.

    infra/
      modules/
        site/            S3 (private) + OAC + CloudFront + ACM
        chatbot/         Lambda Function URL + DynamoDB + IAM
        dns/             Cloudflare records
        observability/   budget alarm + SNS + access-log bucket + Athena
      *.tf               root module, wires the above

## State

S3 backend with **native S3 locking** (`use_lockfile`, Terraform >= 1.10) — no
DynamoDB lock table. The state bucket is bootstrapped once by hand and then
documented; the bootstrap is deliberately not managed by the config that stores
its own state in it. DECISIONS.md #13.

## Regions

- `ap-southeast-1` — Lambda, DynamoDB, S3
- `us-east-1` — ACM certificate only. **CloudFront will not accept a certificate
  from any other region.** A second aliased provider block exists solely for this.

DECISIONS.md #13.

## The domain

`var.domain_name` is the only place the domain appears in this directory, and
one of only two in the whole repo (the other is `site` in
`site/astro.config.mjs`). DECISIONS.md #25.

## Known gotchas to handle in M1

- **S3 OAC does not serve directory indexes.** The origin is the S3 REST
  endpoint, not the website endpoint, so `GET /about/` returns 404 rather than
  `/about/index.html`. Astro emits `build.format: 'directory'`. A CloudFront
  Function on *viewer request* must append `index.html` to URIs ending in `/`
  and to extensionless URIs. Without it every page except `/` 404s.
- **Cloudflare records must be DNS-only (grey cloud).** Proxying in front of
  CloudFront stacks two CDNs and — the part that actually matters — makes
  CloudFront's access logs record Cloudflare edge IPs instead of visitor IPs,
  silently destroying the Athena analytics in DECISIONS.md #22. Set
  `proxied = false` and say why in a comment.
- **ACM DNS validation is cross-provider.** The `aws_acm_certificate`
  validation records are created by the `cloudflare` provider. Expect a
  two-apply dance on first run unless the dependency is wired explicitly.
- **Budget alarm at $10 → SNS → email**, in code, not the console. DECISIONS.md #5.
