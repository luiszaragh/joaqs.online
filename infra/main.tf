# The zone is looked up by name rather than pinned to a zone ID, so no
# Cloudflare identifier has to be committed or passed in. This is also the
# earliest, clearest place for the "is the zone actually live?" check: if the
# nameserver delegation at the registrar has not finished, the zone is not
# `active`, the list comes back empty, and the postcondition says so — instead
# of ACM validation hanging for an hour and looking like a Terraform bug.
data "cloudflare_zones" "this" {
  name   = var.domain_name
  status = "active"

  lifecycle {
    postcondition {
      condition     = length(self.result) == 1
      error_message = "No active Cloudflare zone for ${var.domain_name}. Check that the registrar's nameservers point at Cloudflare and that the zone shows Active, not Pending, then re-run."
    }
  }
}

# ACM certificate, its DNS validation records, S3, OAC, the request-router
# function and CloudFront. The certificate lives here rather than in its own
# module because splitting it would make the graph circular: the certificate
# needs DNS records, and the DNS records that point at the site need
# CloudFront, which needs the certificate.
module "site" {
  source = "./modules/site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  project            = var.project
  domain_name        = var.domain_name
  aliases            = local.site_aliases
  cloudflare_zone_id = data.cloudflare_zones.this.result[0].id
  price_class        = var.cloudfront_price_class

  # Project / ManagedBy / Repo arrive via the providers' default_tags; passing
  # them again here would duplicate every key. var.tags is left for anything
  # that is genuinely module-specific.
}

# The records that actually point visitors at the site. Grey cloud, always.
module "dns" {
  source = "./modules/dns"

  providers = {
    cloudflare = cloudflare
  }

  zone_id                = data.cloudflare_zones.this.result[0].id
  domain_name            = var.domain_name
  www_domain             = local.www_domain
  cloudfront_domain_name = module.site.cloudfront_domain_name
}

# GitHub Actions OIDC trust and the deploy role. Separate module because IAM is
# the part a reviewer should be able to read on its own, without wading through
# CloudFront configuration to find the trust policy.
module "cicd" {
  source = "./modules/cicd"

  project       = var.project
  github_owner  = var.github_owner
  github_repo   = var.github_repo
  deploy_branch = var.deploy_branch

  site_bucket_arn             = module.site.bucket_arn
  cloudfront_distribution_arn = module.site.cloudfront_distribution_arn
}

# Budget alarm and its SNS topic. Pinned to us-east-1: AWS Budgets is a global
# service anchored there, and budget notifications are documented and tooled
# around a us-east-1 topic. The alternative is an apply-time failure that is
# tedious to diagnose for zero benefit.
module "observability" {
  source = "./modules/observability"

  providers = {
    aws = aws.us_east_1
  }

  project            = var.project
  monthly_budget_usd = var.monthly_budget_usd
  alert_email        = var.budget_alert_email
}
