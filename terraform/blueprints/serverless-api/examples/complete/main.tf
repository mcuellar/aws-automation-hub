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

# A minimal target Lambda to demonstrate the deployer updating a function.
data "archive_file" "target" {
  type        = "zip"
  source_file = "${path.module}/target_handler.py"
  output_path = "${path.module}/target_handler_package.zip"
}

data "aws_iam_policy_document" "target_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "target_lambda_role" {
  name               = "example-complete-target-role"
  assume_role_policy = data.aws_iam_policy_document.target_assume_role.json
}

resource "aws_iam_role_policy_attachment" "target_basic" {
  role       = aws_iam_role.target_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "target" {
  function_name = "example-complete-target"
  filename      = data.archive_file.target.output_path
  handler       = "target_handler.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.target_lambda_role.arn
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

  # Point the deployer at the example target Lambda created above.
  target_lambda_arn = aws_lambda_function.target.arn

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
