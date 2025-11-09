output "api_invoke_url" {
  description = "Invoke URL for the API Gateway stage."
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}"
}

output "lambda_function_arn" {
  description = "ARN of the hello world Lambda function."
  value       = aws_lambda_function.hello.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda function."
  value       = aws_iam_role.lambda.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the provisioned AWS WAFv2 Web ACL, if enabled."
  value       = try(aws_wafv2_web_acl.this[0].arn, null)
  sensitive   = false
}
