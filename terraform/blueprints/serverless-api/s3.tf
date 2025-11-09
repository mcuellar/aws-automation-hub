resource "aws_s3_bucket" "lambda_artifacts" {
  bucket_prefix = "${local.name_prefix}-lambda-artifacts-"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "lambda_artifacts_ver" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda_artifacts_lifecycle" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    expiration {
      days = 3
    }

    filter {
      prefix = ""
    }
  }
}

