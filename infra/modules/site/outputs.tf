output "bucket_name" {
  description = "Site bucket. site.yml syncs into this in M2."
  value       = aws_s3_bucket.site.bucket
}

output "bucket_arn" {
  description = "Site bucket ARN, for the M2 deploy role's policy."
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_domain_name" {
  description = "The d111111abcdef8.cloudfront.net name the Cloudflare records point at."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID. site.yml invalidates against this in M2."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "Distribution ARN, for the M2 deploy role's invalidation policy."
  value       = aws_cloudfront_distribution.this.arn
}

output "certificate_arn" {
  description = "The validated ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}
