# ---------------------------------------------------------------------------
# ACM certificate, validated over DNS through Cloudflare.
#
# This is the one genuinely cross-vendor piece of the stack: AWS issues the
# certificate, Cloudflare proves ownership. Both providers appear in the same
# dependency chain, which is exactly the thing DECISIONS.md #24 wanted the
# config to demonstrate.
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "this" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = [for a in var.aliases : a if a != var.domain_name]
  validation_method         = "DNS"

  # A certificate cannot be replaced while a distribution references it, so the
  # replacement has to exist before the old one is destroyed.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = var.domain_name })
}

# One CNAME per name on the certificate. ACM returns fully-qualified values
# with a trailing dot; Cloudflare wants them without one.
resource "cloudflare_dns_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name  = trimsuffix(dvo.resource_record_name, ".")
      type  = dvo.resource_record_type
      value = trimsuffix(dvo.resource_record_value, ".")
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value

  # Short TTL: these records matter for minutes, then never again. Grey cloud
  # is irrelevant for a TXT-style validation CNAME but is set explicitly so no
  # record in this config is proxied by accident. DECISIONS.md #24.
  ttl     = 60
  proxied = false
  comment = "ACM DNS validation for ${each.key} (terraform)"
}

# Blocks until ACM sees the records and issues. Without this, CloudFront would
# be handed a PENDING_VALIDATION certificate and fail the apply with a much
# less obvious error.
resource "aws_acm_certificate_validation" "this" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in cloudflare_dns_record.acm_validation : r.name]

  timeouts {
    create = "10m"
  }
}
