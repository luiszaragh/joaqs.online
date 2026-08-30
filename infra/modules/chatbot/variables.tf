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

variable "bedrock_model_id" {
  description = <<-EOT
    The Bedrock inference profile to invoke. DECISIONS.md #49.

    NOT a bare foundation-model id. In ap-southeast-1 Claude Haiku 4.5 reports
    `inferenceTypesSupported: ["INFERENCE_PROFILE"]`, so invoking
    `anthropic.claude-haiku-4-5-20251001-v1:0` directly fails validation. The
    `global.` profile routes the request across regions for capacity, which is
    why the IAM policy must allow the foundation model in every region rather
    than only this one.

    Check what a region actually offers before changing this:
      aws bedrock list-inference-profiles --region ap-southeast-1
  EOT
  type        = string
  default     = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
}

variable "bedrock_foundation_model_id" {
  description = <<-EOT
    The foundation model the profile above routes to. Named separately because
    the IAM policy needs both: the profile is what the call names, the model is
    what actually runs, and Bedrock authorises each separately.
  EOT
  type        = string
  default     = "anthropic.claude-haiku-4-5-20251001-v1:0"
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
