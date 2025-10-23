  terraform {
    required_providers {
      aws = { source = "hashicorp/aws" }
    }
  }

  provider "aws" {
    region = "us-east-1"
  }

  resource "aws_kms_key" "example" {
    description = "KMS key for S3 bucket SSE-KMS"
    deletion_window_in_days = 7
  }

  module "s3_versioned_encrypted" {
    source = "../.."

    create_unique_bucket = true
    versioning_enabled   = true
    force_destroy        = true
    kms_key_id           = aws_kms_key.example.arn

    tags = {
      Environment = "staging"
      Project     = "example"
    }

    lifecycle_rules = [
      {
        id      = "expire-old-versions"
        enabled = true
        noncurrent_version_expiration = { days = 30 }
      },
      {
        id = "transition-to-ia"
        enabled = true
        prefix = "logs/"
        transitions = [
          { days = 30, storage_class = "STANDARD_IA" }
          , { days = 90, storage_class = "GLACIER" }
        ]
      }
    ]
  }

  output "bucket_name" {
    value = module.s3_versioned_encrypted.bucket_id
  }
