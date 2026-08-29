provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# CloudFront will only accept a certificate issued in us-east-1, regardless of
# where anything else lives. This alias exists for the ACM certificate and for
# AWS Budgets, and for nothing else. DECISIONS.md #13.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

# Credentials come from CLOUDFLARE_API_TOKEN in the environment. The token is
# scoped to Zone:DNS:Edit + Zone:Zone:Read on this zone only, and it is never
# written to a file in this repo — the repo is public. DECISIONS.md #17.
provider "cloudflare" {}
