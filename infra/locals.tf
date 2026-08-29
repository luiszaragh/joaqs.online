locals {
  # Derived, never written literally. DECISIONS.md #25.
  www_domain = "www.${var.domain_name}"

  # Both names go on the certificate and both are CloudFront aliases; the
  # CloudFront Function then 301s www to the apex so there is one canonical
  # hostname. Two hostnames serving the same content would split the access
  # logs and quietly weaken the Athena analysis in DECISIONS.md #22.
  site_aliases = [var.domain_name, local.www_domain]

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
    Repo      = "github.com/luiszaragh/joaqs.online"
  }
}
