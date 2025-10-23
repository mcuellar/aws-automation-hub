terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

locals {
  bucket_name = var.name != null ? var.name : (
    var.create_unique_bucket ? "terraform-s3-${random_id.bucket_id[0].hex}" : (throw("name must be provided when create_unique_bucket is false"))
  )
}

resource "random_id" "bucket_id" {
  byte_length = 4
  keepers = {
    name = var.name
  }
  count = var.create_unique_bucket ? 1 : 0
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  acl    = var.acl

  force_destroy = var.force_destroy

  tags = merge({
    Name = local.bucket_name
  }, var.tags)
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls   = var.block_public_acls
  block_public_policy = var.block_public_policy
  ignore_public_acls  = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Server side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.kms_key_id != null || var.server_side_encryption != null ? [1] : []

    content {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.kms_key_id != null ? "aws:kms" : (var.server_side_encryption == "AES256" ? "AES256" : var.server_side_encryption)
        kms_master_key_id = var.kms_key_id
      }
    }
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id      = lookup(rule.value, "id", null)
      status  = lookup(rule.value, "enabled", true) ? "Enabled" : "Disabled"

      filter {
        # If no prefix is provided we apply the rule to the whole bucket by using an empty prefix
        prefix = lookup(rule.value, "prefix", "")

        dynamic "tag" {
          for_each = lookup(rule.value, "tags", {})
          content {
            key   = tag.key
            value = tag.value
          }
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [1] : []
        content {
          days = rule.value.expiration.days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration.days
        }
      }
    }
  }
}
