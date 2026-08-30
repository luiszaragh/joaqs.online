# These are the handoff to M2. site.yml needs the bucket to sync into and the
# distribution to invalidate; the deploy role's policy needs the two ARNs so it
# can be scoped to exactly those resources rather than "s3:*" on "*".

output "site_bucket_name" {
  description = "Sync target for site.yml."
  value       = module.site.bucket_name
}

output "site_bucket_arn" {
  value = module.site.bucket_arn
}

output "cloudfront_distribution_id" {
  description = "Invalidation target for site.yml."
  value       = module.site.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  value = module.site.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "Useful for testing the distribution before DNS has propagated."
  value       = module.site.cloudfront_domain_name
}

output "site_url" {
  description = "Derived from var.domain_name — never written literally. DECISIONS.md #25."
  value       = "https://${var.domain_name}"
}

output "budget_topic_arn" {
  value = module.observability.budget_topic_arn
}

output "site_deploy_role_arn" {
  description = "role-to-assume in .github/workflows/site.yml."
  value       = module.cicd.site_deploy_role_arn
}

output "oidc_provider_arn" {
  description = "One provider per account; lambda.yml (M5) reuses it."
  value       = module.cicd.oidc_provider_arn
}

output "infra_plan_role_arn" {
  description = "role-to-assume for infra.yml's plan job (pull requests, read-only)."
  value       = module.cicd.infra_plan_role_arn
}

output "infra_apply_role_arn" {
  description = "role-to-assume for infra.yml's apply job (behind Environment approval)."
  value       = module.cicd.infra_apply_role_arn
}
