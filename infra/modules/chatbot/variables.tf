variable "project" {
  description = "Name prefix and tag value for every resource in this module."
  type        = string
}

variable "corpus_bucket_name" {
  description = "The site bucket. The corpus is written into it by the site build (DECISIONS.md #29)."
  type        = string
}

variable "corpus_bucket_arn" {
  type = string
}

variable "corpus_key" {
  description = "Object key of the corpus inside the site bucket."
  type        = string
  default     = "corpus.json"
}

variable "api_key_parameter_name" {
  description = <<-EOT
    SSM Parameter Store name holding the Anthropic API key as a SecureString.

    Created OUTSIDE Terraform, on purpose. A value passed into Terraform lands
    in the state file in plaintext, and this repository is public — the state
    bucket is private, but "the secret is safe because the bucket is private"
    is exactly the assumption worth not making. Terraform is given the
    parameter's name and the permission to read it; it never sees the value.

    Create it once with:
      aws ssm put-parameter --name /joaqs-online/anthropic-api-key \
        --type SecureString --value sk-ant-... --region ap-southeast-1
  EOT
  type        = string
}

variable "log_retention_days" {
  description = "DECISIONS.md #12 — prompts are logged, kept 30 days, then gone."
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
