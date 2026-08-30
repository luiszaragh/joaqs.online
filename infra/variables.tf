# Every value here has a default, so `terraform plan` runs with no tfvars file
# and no arguments. The only thing that must come from the environment is
# CLOUDFLARE_API_TOKEN, because it is the only secret.

variable "domain_name" {
  description = <<-EOT
    The apex domain. DECISIONS.md #25 — this is one of exactly two places the
    domain appears in the whole repo (the other is `site` in
    site/astro.config.mjs). Everything else derives from it. Migration to a
    real-name domain is: change these two values, apply, add a redirect.
  EOT
  type        = string
  default     = "joaqs.online"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9-]+)+$", var.domain_name))
    error_message = "domain_name must be a bare apex domain with no scheme, port or trailing dot."
  }
}

variable "aws_region" {
  description = "Region for everything except the ACM certificate and the budget."
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Name prefix and tag value for every resource in this config."
  type        = string
  default     = "joaqs-online"
}

variable "monthly_budget_usd" {
  description = <<-EOT
    Hard ceiling for the AWS Budget alarm. DECISIONS.md #5 — the target is
    around $5/mo and the alarm sits at $10. A cost control that is not in code
    is exactly the thing an interviewer asks whether you actually did.
  EOT
  type        = number
  default     = 10
}

variable "budget_alert_email" {
  description = <<-EOT
    Where budget notifications land. AWS sends a subscription confirmation to
    this address on first apply and the subscription stays "pending
    confirmation" until the link is clicked — Terraform cannot do that step.
  EOT
  type        = string
  default     = "luisjoaquinzara@gmail.com"
}

variable "github_owner" {
  description = "GitHub account that owns the repo. Half of the OIDC subject claim."
  type        = string
  default     = "luiszaragh"
}

variable "github_repo" {
  description = "Repository name. The other half of the OIDC subject claim."
  type        = string
  default     = "joaqs.online"
}

variable "github_owner_id" {
  description = <<-EOT
    GitHub's immutable numeric ID for the owner account.

    Since 2026-07-15 every newly created repository sends OIDC subject claims of
    the form `repo:owner@ownerID/repo@repoID:ref:...` rather than
    `repo:owner/repo:ref:...`. The IDs are what make the claim immutable: a name
    can be released and re-registered by someone else, an ID cannot.

    Find it with:  gh api users/luiszaragh --jq .id
  EOT
  type        = number
  default     = 181682822
}

variable "github_repo_id" {
  description = <<-EOT
    GitHub's immutable numeric ID for the repository.

    THIS CHANGES IF THE REPOSITORY IS DELETED AND RECREATED. That is the entire
    point of the claim — a recreated repo does not inherit the trust of the one
    it replaced — and it is also the thing that will break deploys the day it
    happens. This repo was recreated on 2026-08-30 to purge a leaked commit,
    which is exactly how the first value here became stale.

    Find it with:  gh api repos/luiszaragh/joaqs.online --jq .id
    Or read it out of a failed AssumeRoleWithWebIdentity event in CloudTrail.
  EOT
  type        = number
  default     = 1350745463
}

variable "deploy_branch" {
  description = <<-EOT
    The only branch allowed to assume the deploy role. Changing this widens who
    can publish to production, so it is a variable rather than a literal buried
    in the trust policy.
  EOT
  type        = string
  default     = "main"
}

variable "cloudfront_price_class" {
  description = <<-EOT
    PriceClass_100 is US + Europe only, which is the wrong shape for a site
    whose readers are mostly in Metro Manila. PriceClass_200 adds Asia-Pacific
    edges; at portfolio traffic the difference sits inside the free tier.
  EOT
  type        = string
  default     = "PriceClass_200"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Must be one of PriceClass_100, PriceClass_200, PriceClass_All."
  }
}
