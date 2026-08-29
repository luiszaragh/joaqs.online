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
