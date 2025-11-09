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

module "serverless_api" {
  source = "../.."

  project_name         = "example-simple"
  environment          = "dev"
  cors_allowed_origins = ["https://app.example.com"]
}

output "api_invoke_url" {
  value = module.serverless_api.api_invoke_url
}
