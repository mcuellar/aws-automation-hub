variable "prefix_name" {
  type        = string
  description = "Prefix for resource names. Used for local.name_prefix."
  default     = "tailorai"
}
variable "api_gateway_type" {
  type        = string
  description = "Type of API Gateway to create: \"HTTP\" (default, API Gateway v2) or \"REST\" (API Gateway v1)."
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "REST"], upper(var.api_gateway_type))
    error_message = "api_gateway_type must be either 'HTTP' or 'REST'."
  }
}
variable "project_name" {
  type        = string
  description = "Name of the project this serverless API belongs to."
}

variable "environment" {
  type        = string
  description = "Deployment environment name used for tagging and resource naming."
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in. Leave null to use the provider default or environment configuration."
  default     = null
}

variable "stage_name" {
  type        = string
  description = "HTTP API stage name."
  default     = "v1"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime to use for the hello world handler."
  default     = "python3.10"
}

variable "lambda_memory_size" {
  type        = number
  description = "Memory size for the Lambda function in MB."
  default     = 128
}

variable "lambda_timeout" {
  type        = number
  description = "Timeout for the Lambda function in seconds."
  default     = 10
}

variable "lambda_environment" {
  type        = map(string)
  description = "Additional environment variables for the Lambda function."
  default     = {}
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "List of allowed origins for CORS. The Lambda function dynamically enforces these origins at runtime."
  default     = []
}

variable "cors_allowed_methods" {
  type        = list(string)
  description = "List of allowed HTTP methods for CORS responses."
  default     = ["GET", "OPTIONS"]
}

variable "cors_allowed_headers" {
  type        = list(string)
  description = "List of allowed headers for CORS responses."
  default     = ["Content-Type", "Authorization"]
}

variable "secret_arns" {
  type        = list(string)
  description = "List of AWS Secrets Manager secret ARNs the Lambda function is allowed to read."
  default     = []
}

variable "target_lambda_arn" {
  type        = string
  description = "Optional: Full ARN of the Lambda function that the deployer should update when new artifacts arrive in the S3 bucket. If empty, provide `target_lambda_name` instead."
  default     = ""
  validation {
    # allow empty string or a valid Lambda ARN
    condition     = var.target_lambda_arn == "" || can(regex("^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:[^\\s]+$", var.target_lambda_arn))
    error_message = "target_lambda_arn must be empty or a valid Lambda function ARN (arn:aws:lambda:<region>:<account-id>:function:<name>)."
  }
}

variable "target_lambda_name" {
  type        = string
  description = "Optional: Name of an existing Lambda function in the same account/region. If provided, the module will look up its ARN and use it as the target. Either `target_lambda_arn` or `target_lambda_name` must be provided."
  default     = ""
}

variable "deploy_bucket_name" {
  type        = string
  description = "Optional explicit S3 bucket name to host lambda artifacts. If empty, the module creates a bucket with a generated name prefix."
  default     = ""
}

variable "log_retention_in_days" {
  type        = number
  description = "Number of days to retain CloudWatch Logs for the API and Lambda."
  default     = 14
}

variable "enable_waf" {
  type        = bool
  description = "Whether to provision an AWS WAFv2 Web ACL and associate it with the API Gateway stage."
  default     = false
}

variable "waf_override_action" {
  type        = string
  description = "Override action to apply to AWS managed rule group requests. Valid values: NONE, COUNT."
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "COUNT"], upper(var.waf_override_action))
    error_message = "waf_override_action must be either NONE or COUNT."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources created by this blueprint."
  default     = {}
}

variable "create_api_gateway" {
  type        = bool
  description = "Whether to create an API Gateway pointing at a configured Lambda. Disabled by default."
  default     = false
}

variable "api_lambda_arn" {
  type        = string
  description = "ARN of the Lambda function the optional API Gateway should invoke. Required if create_api_gateway = true."
  default     = ""
}
