terraform {
  # 1.11 is the floor, not a preference: `use_lockfile` below went GA in 1.11
  # (it shipped experimentally in 1.10). Native S3 locking is what lets this
  # config skip a DynamoDB lock table entirely — DECISIONS.md #13.
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    # M5. `random` holds the rate-limiter's IP salt; `archive` builds the
    # placeholder package that Terraform creates the function with before
    # lambda.yml deploys the real code.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }

  # The bucket is created by hand before the first `init` — see
  # bootstrap/README.md. A config cannot bootstrap the bucket that stores its
  # own state, and pretending otherwise is the shortcut that bites later.
  #
  # The account ID is committed here on purpose. It is an identifier, not a
  # credential: an account ID grants nothing without a matching IAM principal
  # and trust policy. Hiding it would imply the security of this stack depends
  # on it staying secret, which is the opposite of the claim this repo makes.
  # The controls that actually matter are the OIDC trust conditions in M2 and
  # the bucket policy in modules/site.
  backend "s3" {
    bucket       = "joaqs-online-tfstate-377510222046"
    key          = "joaqs-online/prod/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
