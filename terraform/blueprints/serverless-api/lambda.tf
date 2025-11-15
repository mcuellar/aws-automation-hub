resource "null_resource" "fail_if_no_target" {
  count = var.target_lambda_arn == "" && var.target_lambda_name == "" && length(aws_lambda_function.target) == 0 ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: You must provide target_lambda_arn, target_lambda_name, or allow the module to create the default target lambda.' && exit 1"
  }
}
data "archive_file" "deployer" {
  type        = "zip"
  source_file = "${path.module}/lambda_deployer/handler.py"
  output_path = "${path.module}/lambda_deployer_package.zip"
}

# Package the example target (hello) Lambda
data "archive_file" "target" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda_target_package.zip"
}

resource "aws_cloudwatch_log_group" "deployer" {
  name              = local.deployer_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
  lifecycle {
    create_before_destroy = true
    prevent_destroy = false
  }
}

# CloudWatch log group for the target (hello) Lambda
resource "aws_cloudwatch_log_group" "target" {
  count             = var.target_lambda_arn == "" && var.target_lambda_name == "" ? 1 : 0
  name              = local.lambda_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
  lifecycle {
    create_before_destroy = true
    prevent_destroy = false
  }
}

resource "aws_lambda_function" "deployer" {
  function_name = "${local.name_prefix}-deployer"
  description   = "Deploys Lambda code when new artifacts arrive in S3 via EventBridge."
  filename      = data.archive_file.deployer.output_path
  handler       = "handler.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.deployer.arn
  memory_size   = 128
  timeout       = 30

  environment {
    variables = merge({
      TARGET_LAMBDA_ARN = local.target_lambda_arn
      S3_BUCKET_NAME    = aws_s3_bucket.lambda_artifacts.bucket
    }, var.lambda_environment)
  }

  source_code_hash = data.archive_file.deployer.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.deployer]

  tags = local.tags
}

# Minimal target Lambda that the deployer will update. This function is a
# lightweight hello-world handler and is the default target for the API Gateway.
resource "aws_lambda_function" "target" {
  count         = var.target_lambda_arn == "" && var.target_lambda_name == "" ? 1 : 0
  function_name = "${local.name_prefix}-handler"
  description   = "Example target Lambda (hello world) for the serverless API blueprint."
  filename      = data.archive_file.target.output_path
  handler       = "handler.lambda_handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda.arn
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  environment {
    variables = merge({
      ALLOWED_ORIGINS = jsonencode(var.cors_allowed_origins),
      ALLOWED_METHODS = jsonencode(var.cors_allowed_methods),
      ALLOWED_HEADERS = jsonencode(var.cors_allowed_headers),
      SECRET_ARNS     = jsonencode(var.secret_arns)
    }, var.lambda_environment)
  }

  # Ignore changes to the Lambda function's source code and hash, as well as
  # environment, to avoid unnecessary updates outside of deployer actions.
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      # optional: ignore changes AWS makes internally
      # last_modified,
      environment,
    ]
  }

  source_code_hash = data.archive_file.target.output_base64sha256

  # Depend on the target log group if present. Using the bare resource address here
  # is a static list expression (required by Terraform); when the log group is
  # not created the reference becomes an empty list and Terraform handles it.
  depends_on = [aws_cloudwatch_log_group.target]

  tags = local.tags
}
