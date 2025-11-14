locals {
  name_prefix = var.prefix_name

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)

  lambda_log_group_name = "/aws/lambda/${local.name_prefix}-handler"
  deployer_log_group_name = "/aws/lambda/${local.name_prefix}-deployer"
  api_log_group_name    = "/aws/apigateway/${local.name_prefix}-${var.stage_name}"
}

# Resolved target lambda ARN: prefer explicit ARN, otherwise use the lookup by name (data.aws_lambda_function.target)
locals {
  target_lambda_arn = var.target_lambda_arn != "" ? var.target_lambda_arn : (
    var.target_lambda_name != "" ? data.aws_lambda_function.target[0].arn : (
      length(aws_lambda_function.target) > 0 ? aws_lambda_function.target[0].arn : ""
    )
  )
}

# Resolved API lambda ARN: prefer explicit API lambda override, otherwise use the target lambda ARN
locals {
  api_lambda_arn = var.api_lambda_arn != "" ? var.api_lambda_arn : local.target_lambda_arn
}
