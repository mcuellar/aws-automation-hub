locals {
  name_prefix = lower(replace(join("-", compact([var.project_name, var.environment])), " ", "-"))

  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)

  lambda_log_group_name = "/aws/lambda/${local.name_prefix}-handler"
  api_log_group_name    = "/aws/apigateway/${local.name_prefix}-${var.stage_name}"
}
