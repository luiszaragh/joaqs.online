# infra — Terraform

Two providers (`aws`, `cloudflare`) managing one cross-vendor stack.

    infra/
      versions.tf        required_version, provider constraints, S3 backend
      providers.tf       aws (ap-southeast-1), aws.us_east_1, cloudflare
      variables.tf       every value defaulted — no tfvars file needed
      locals.tf          derived names and tags
      main.tf            zone lookup + module wiring
      outputs.tf         the handoff to M2
      bootstrap/         the by-hand state bucket, and why it is by hand
      modules/
        site/            ACM cert + DNS validation, S3, OAC, router fn, CloudFront
        dns/             apex + www records -> CloudFront, grey cloud
        observability/   budget alarm + SNS
        chatbot/         M5

## Before the first run

1. **AWS credentials** for account `377510222046` — `aws configure`, or an
   Identity Center profile.
2. **A Cloudflare API token** exported as `CLOUDFLARE_API_TOKEN`, scoped to
   `Zone → DNS → Edit` and `Zone → Zone → Read` on this zone only. It is never
   written to a file in this repo.
3. **The state bucket** — see [`bootstrap/README.md`](bootstrap/README.md). Four
   commands, run once.

```powershell
$env:CLOUDFLARE_API_TOKEN = "<token>"
terraform init
terraform plan
```

No `-var` flags and no `terraform.tfvars`: every variable has a default, and the
only secret comes from the environment.

## Regions

- `ap-southeast-1` — S3, and everything else by default
- `us-east-1` — the ACM certificate **only** because CloudFront will not accept
  a certificate from anywhere else, and AWS Budgets because that service is
  anchored there

DECISIONS.md #13.

## The domain

`var.domain_name` is the only place the domain appears in this directory, and
one of two in the whole repo (the other is `site` in `site/astro.config.mjs`).
DECISIONS.md #25.

## Gotchas this config already handles

Written down because each one costs an afternoon the first time.

- **S3 with OAC does not serve directory indexes.** The origin is the S3 REST
  endpoint, not the website endpoint, so `GET /about/` would 404. The
  CloudFront Function in `modules/site/functions/router.js` rewrites `/about`
  and `/about/` to `/about/index.html` on viewer request.
- **A private bucket returns 403, not 404, for a missing key**, because the
  policy grants `s3:GetObject` and not `s3:ListBucket`. Both codes are mapped
  to `/404.html` with a 404 response, so a typo does not surface an S3 XML
  error document.
- **Cloudflare must stay DNS-only.** Proxying in front of CloudFront makes
  CloudFront's access logs record Cloudflare edge IPs instead of visitor IPs,
  which quietly destroys the Athena analysis in DECISIONS.md #22.
  `proxied = false` is set explicitly on every record.
- **A CNAME at the zone apex is not legal DNS.** Cloudflare flattens it, on
  DNS-only records as well as proxied ones. That is what removes the need for
  Route 53 alias records.
- **ACM validation is cross-provider.** AWS emits the validation records,
  Cloudflare creates them, and `aws_acm_certificate_validation` blocks until
  ACM sees them. The `data "cloudflare_zones"` postcondition in `main.tf`
  catches the common cause of this hanging — a zone that is still `pending`
  because the registrar's nameserver delegation has not finished.
- **The budget's SNS topic needs a topic policy** allowing
  `budgets.amazonaws.com` to publish, or the notifications silently go nowhere.
- **The email subscription is not finished when `apply` finishes.** AWS sends a
  confirmation link; until it is clicked the subscription delivers nothing.

## Still to come

- **M2** — OIDC provider and one least-privilege deploy role per workflow. The
  outputs in `outputs.tf` exist so those policies can name exact ARNs rather
  than `*`.
- **M4** — `infra.yml`: `plan` on PR as a comment, `apply` on main behind an
  Environment approval, with tflint and checkov as blocking gates.
- **M5** — `modules/chatbot`.
- **M6** — CloudFront standard access logs to S3 with a 90-day lifecycle, and
  Athena. Deliberately not built yet: it would mean paying to store logs nobody
  is reading. This is also the one checkov finding on the site bucket
  (`S3 access logging`) that is a known deferral rather than an oversight.
