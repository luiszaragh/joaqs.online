# ---------------------------------------------------------------------------
# The records that point visitors at the distribution.
#
# proxied = false on both, and this is not a preference. Putting Cloudflare's
# proxy in front of CloudFront stacks two CDNs: an extra latency hop, SNI and
# certificate awkwardness, and — the part that actually decides it —
# CloudFront's access logs would record Cloudflare edge IPs instead of visitor
# IPs, silently destroying the analytics decision in DECISIONS.md #22.
#
# DECISIONS.md #24 / #32: grey cloud, non-negotiable.
# ---------------------------------------------------------------------------

variable "zone_id" {
  description = "Cloudflare zone for the apex domain."
  type        = string
}

variable "domain_name" {
  description = "Apex domain."
  type        = string
}

variable "www_domain" {
  description = "The www hostname. Redirected to the apex at the edge, but it still needs a record to reach CloudFront in the first place."
  type        = string
}

variable "cloudfront_domain_name" {
  description = "Distribution domain name to point both records at."
  type        = string
}

variable "record_ttl" {
  description = "Low enough to re-point quickly during a migration, high enough not to be silly."
  type        = number
  default     = 300
}

# A CNAME at the zone apex is not legal DNS. Cloudflare resolves this by
# flattening the record — answering with the target's A/AAAA addresses at query
# time — which works on DNS-only records, not just proxied ones. This is the
# reason the stack needs no Route 53 alias record and no ALIAS-capable
# registrar. DECISIONS.md #17.
resource "cloudflare_dns_record" "apex" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "CNAME"
  content = var.cloudfront_domain_name
  ttl     = var.record_ttl
  proxied = false
  comment = "Apex -> CloudFront, DNS-only (terraform)"
}

resource "cloudflare_dns_record" "www" {
  zone_id = var.zone_id
  name    = var.www_domain
  type    = "CNAME"
  content = var.cloudfront_domain_name
  ttl     = var.record_ttl
  proxied = false
  comment = "www -> CloudFront, 301s to apex at the edge (terraform)"
}

output "records" {
  description = "Hostnames now resolving to the distribution."
  value       = [cloudflare_dns_record.apex.name, cloudflare_dns_record.www.name]
}
