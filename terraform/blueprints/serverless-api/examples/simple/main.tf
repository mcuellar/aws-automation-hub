terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
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


# To use REST API, set api_gateway_type = "REST"
module "serverless_api" {
  source = "../.."
  project_name         = "tailorai"
  environment          = "dev"
  create_api_gateway   = true
  cors_allowed_origins = ["*"]
  # api_gateway_type   = "HTTP" # default, or "REST"
  # No target_lambda_name or target_lambda_arn provided: the module will create a hello-world target lambda automatically.
  # tags = {
  #   Application = "tailorai-api"
  #   Owner       = "tailorai-team"
  # }
}


output "api_invoke_url" {
  value = module.serverless_api.api_invoke_url
}

output "artifact_bucket_name" {
  value = module.serverless_api.artifact_bucket_name
}
