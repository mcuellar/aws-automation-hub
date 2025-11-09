terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy the example in."
  default     = "us-east-1"
}

resource "random_password" "example" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "example" {
  name = "example/complete/serverless-api"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = random_password.example.result
}

module "serverless_api" {
  source = "../.."

  project_name = "example-complete"
  environment  = "staging"
  stage_name   = "staging"

  cors_allowed_origins = [
    "https://staging.example.com",
    "https://admin.example.com",
  ]
  cors_allowed_methods = ["GET", "OPTIONS", "POST"]
  cors_allowed_headers = ["Content-Type", "Authorization", "X-Requested-With"]

  secret_arns = [aws_secretsmanager_secret.example.arn]

  lambda_environment = {
    LOG_LEVEL = "INFO"
  }

  lambda_memory_size = 256
  lambda_timeout     = 15

  log_retention_in_days = 30

  enable_waf          = true
  waf_override_action = "COUNT"

  tags = {
    Application = "serverless-api"
    Owner       = "platform-team"
  }
}

output "api_invoke_url" {
  description = "Invoke URL for the deployed API."
  value       = module.serverless_api.api_invoke_url
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL associated with the API stage."
  value       = module.serverless_api.waf_web_acl_arn
}
