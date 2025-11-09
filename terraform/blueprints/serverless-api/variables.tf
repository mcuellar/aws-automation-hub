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
  description = "API Gateway stage name."
  default     = "dev"
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
