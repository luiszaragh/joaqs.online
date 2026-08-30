variable "project" {
  description = "Name prefix for every resource in this module."
  type        = string
}

variable "domain_name" {
  description = "Apex domain. Becomes the certificate's common name."
  type        = string
}

variable "aliases" {
  description = "Every hostname the distribution answers on, apex first."
  type        = list(string)
}

variable "cloudflare_zone_id" {
  description = "Zone that receives the ACM DNS validation records."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
}

variable "tags" {
  description = "Tags merged into every taggable resource."
  type        = map(string)
  default     = {}
}

# --- the chatbot origin (M5, DECISIONS.md #11) -------------------------------
# Optional so the site stands alone: with these unset the distribution has one
# origin and no /api behaviour, which is exactly what M1 through M4 shipped.

variable "chatbot_origin_domain" {
  description = <<-EOT
    Host of the chatbot's Lambda Function URL. When set, the distribution gains
    an `/api/*` behaviour routing to it — one hostname for the site and its
    API, which is what lets a WAF be added later without moving anything.
  EOT
  type        = string
  default     = null
}

variable "chatbot_origin_access_control_id" {
  description = "OAC that signs origin requests to the Function URL. Required when chatbot_origin_domain is set."
  type        = string
  default     = null

  validation {
    condition     = (var.chatbot_origin_domain == null) == (var.chatbot_origin_access_control_id == null)
    error_message = "chatbot_origin_domain and chatbot_origin_access_control_id must be set together — an unsigned Function URL origin would be rejected by Lambda on every request."
  }
}
