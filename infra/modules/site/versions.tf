terraform {
  required_version = ">= 1.11"

  required_providers {
    # Floors only. The ceiling lives in the root's versions.tf, and Terraform
    # takes the intersection — so a `~>` here would have to be edited in every
    # module the day the root moves to a new major. A minimum says what this
    # module needs without constraining what the caller may use.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
      # The certificate must be issued in us-east-1 no matter where the rest of
      # the stack lives, so this module takes two AWS providers.
      configuration_aliases = [aws.us_east_1]
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
  }
}
