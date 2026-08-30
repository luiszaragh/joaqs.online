# The zone is looked up by name rather than pinned to a zone ID, so no
# Cloudflare identifier has to be committed or passed in. This is also the
# earliest, clearest place for the "is the zone actually live?" check: if the
# nameserver delegation at the registrar has not finished, the zone is not
# `active`, the list comes back empty, and the postcondition says so — instead
# of ACM validation hanging for an hour and looking like a Terraform bug.
data "aws_caller_identity" "current" {}

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

  # M5 — the chatbot behind the same distribution (DECISIONS.md #11). Null
  # until the module below exists, which is why the site module treats them as
  # optional rather than required.
  chatbot_origin_domain            = module.chatbot.function_url_domain
  chatbot_origin_access_control_id = module.chatbot.origin_access_control_id

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

  project         = var.project
  github_owner    = var.github_owner
  github_repo     = var.github_repo
  github_owner_id = var.github_owner_id
  github_repo_id  = var.github_repo_id
  deploy_branch   = var.deploy_branch

  site_bucket_arn             = module.site.bucket_arn
  cloudfront_distribution_arn = module.site.cloudfront_distribution_arn
  state_bucket_arn            = "arn:aws:s3:::${var.state_bucket_name}"
  account_id                  = data.aws_caller_identity.current.account_id
  apply_environment           = var.apply_environment
  chat_function_arn           = module.chatbot.function_arn
}

# The chatbot: Lambda, its Function URL, the rate-limit table and the
# execution role. It deliberately knows nothing about CloudFront — see the
# permission below for why.
module "chatbot" {
  source = "./modules/chatbot"

  project            = var.project
  corpus_bucket_name = module.site.bucket_name
  corpus_bucket_arn  = module.site.bucket_arn
}

# This lives in the root rather than inside either module, and that is
# load-bearing. The site module needs the chatbot's Function URL to build its
# origin; this permission needs the site's distribution ARN to scope who may
# invoke it. Putting it in the chatbot module would make the two modules
# reference each other and Terraform would refuse the cycle.
#
# The SourceArn condition is the whole point: it allows exactly one
# distribution to invoke this function, so the IAM-authenticated Function URL
# cannot be called by anything else in the account either.
resource "aws_lambda_permission" "chat_from_cloudfront" {
  statement_id           = "AllowCloudFrontInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = module.chatbot.function_name
  principal              = "cloudfront.amazonaws.com"
  source_arn             = module.site.cloudfront_distribution_arn
  function_url_auth_type = "AWS_IAM"
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
