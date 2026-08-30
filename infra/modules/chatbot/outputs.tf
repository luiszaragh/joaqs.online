output "function_name" {
  description = "Update target for lambda.yml, and the subject of the root module's CloudFront permission."
  value       = aws_lambda_function.chat.function_name
}

output "function_arn" {
  value = aws_lambda_function.chat.arn
}

output "function_url_domain" {
  description = <<-EOT
    Host of the Function URL, without scheme or trailing slash — the shape
    CloudFront's `origin.domain_name` expects.
  EOT
  value       = replace(replace(aws_lambda_function_url.chat.function_url, "https://", ""), "/", "")
}

output "origin_access_control_id" {
  description = "Attached to the CloudFront origin so requests to the Function URL are SigV4-signed."
  value       = aws_cloudfront_origin_access_control.chat.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.chat.name
}

output "state_table_name" {
  description = "Rate-limit counters and cached answers, both TTL-expiring."
  value       = aws_dynamodb_table.chat_state.name
}
