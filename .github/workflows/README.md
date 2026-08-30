# Workflows

Path-filtered workflows deploy; `ci.yml` guards. One least-privilege OIDC role
per credentialed job, no long-lived AWS keys anywhere. DECISIONS.md #21.

| File | Trigger | Does |
|---|---|---|
| `ci.yml` | every push and PR | gitleaks (history) · résumé PDF text scan · astro build · link check · Lighthouse (advisory) |
| `site.yml` | `site/**` on main | build → S3 sync → invalidate HTML only → verify the apex returns 200 |
| `infra.yml` | `infra/**` | fmt · validate · tflint · checkov, then `plan` on PR as a comment, `apply` on main behind an Environment approval |
| `lambda.yml` | `lambda/**` | package → update function (M5) |

## Roles

| Role | Assumed by | Subject claim | Can do |
|---|---|---|---|
| `joaqs-online-site-deploy` | `site.yml` | `…:ref:refs/heads/main` | write the site bucket, invalidate one distribution |
| `joaqs-online-infra-plan` | `infra.yml` plan | `…:pull_request` | read the account, hold the state lock |
| `joaqs-online-infra-apply` | `infra.yml` apply | `…:environment:production` | write the stack |

Subject claims carry GitHub's immutable owner and repository IDs — see
`infra/modules/cicd/infra-roles.tf`. **Declaring `environment:` on a job changes
its subject claim**, which is why the apply role trusts
`…:environment:production` and not a branch.

## One-time setup

Neither can be created by Terraform; both are GitHub-side.

**1. The `production` Environment.** Settings → Environments → New environment →
`production` → tick **Required reviewers** and add yourself.

Without a protection rule the Environment approves instantly and the gate is
decorative. The name must match `var.apply_environment` in `infra/variables.tf`,
because it appears in the apply role's trust policy.

**2. The `CLOUDFLARE_API_TOKEN` secret.** Settings → Secrets and variables →
Actions → New repository secret. Scoped to `Zone → DNS → Edit` and
`Zone → Zone → Read` on this zone only.

Terraform needs it to manage DNS records. It is the only secret in the
repository, and it is a secret rather than a variable so it is masked in logs.

## Conventions

- **Every third-party action is pinned to a full commit SHA.** A tag is a
  movable pointer, and these jobs hold credentials to a live AWS account.
- **`permissions: {}` at the workflow level**, with each job opting into
  exactly what it needs. The default is nothing.
- **The plan job refuses to run for a pull request opened from a fork.** GitHub
  restricts elevated permissions for fork PRs already, but relying on that
  alone puts the safety in someone else's default rather than in this file.
- **Checkov findings are triaged, never suppressed silently.** Each skip in
  `infra/` carries the reason inline. New findings fail the build; that ratchet
  is the whole point.
