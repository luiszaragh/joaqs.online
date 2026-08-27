# Workflows

Three path-filtered workflows, one least-privilege OIDC role each. No long-lived
AWS keys anywhere. DECISIONS.md #21.

| File | Trigger | Does | Lands in |
|---|---|---|---|
| `site.yml` | `site/**` | astro build → S3 sync → CloudFront invalidation, **HTML only** (assets are content-hashed) | M2 |
| `lambda.yml` | `lambda/**` | package → update function | M5 |
| `infra.yml` | `infra/**` | `terraform plan` on PR, posted as a PR comment → `apply` on `main` behind a GitHub Environment approval | M4 |

**Mandatory gates** (blocking): astro build · Gitleaks (`.gitleaks.toml`, includes
a custom rule that fails on a Philippine mobile number) · tflint · checkov ·
link checker.
**Advisory** (non-blocking): Lighthouse.

Pin every third-party action to a full commit SHA, not a tag. `permissions:` is
declared per job, never inherited from the repo default.
