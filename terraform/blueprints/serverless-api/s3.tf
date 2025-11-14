resource "aws_s3_bucket" "lambda_artifacts" {
  bucket_prefix = "${local.name_prefix}-lambda-artifacts-"

  lifecycle {
    prevent_destroy = false
  }
  force_destroy = true

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

resource "aws_s3_bucket_notification" "lambda_artifacts_notify" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.deployer.arn
    events              = ["s3:ObjectCreated:Put", "s3:ObjectCreated:CompleteMultipartUpload"]
    filter_prefix       = ""
    filter_suffix       = ".zip"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3InvokeDeployer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda_artifacts.arn
}

