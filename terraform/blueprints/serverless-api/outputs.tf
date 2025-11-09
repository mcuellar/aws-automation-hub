

output "waf_web_acl_arn" {
  description = "ARN of the provisioned AWS WAFv2 Web ACL, if enabled."
  value       = try(aws_wafv2_web_acl.this[0].arn, null)
  sensitive   = false
}

output "artifact_bucket_name" {
  description = "Name of the S3 bucket created to hold lambda artifacts."
  value       = aws_s3_bucket.lambda_artifacts.bucket
}

output "api_invoke_url" {
  description = "Invoke URL for the optional API Gateway stage."
  value       = var.create_api_gateway ? "https://${aws_api_gateway_rest_api.this[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.this[0].stage_name}" : null
}
