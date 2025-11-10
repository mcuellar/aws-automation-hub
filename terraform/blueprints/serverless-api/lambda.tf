data "archive_file" "deployer" {
  type        = "zip"
  source_file = "${path.module}/lambda_deployer/handler.py"
  output_path = "${path.module}/lambda_deployer_package.zip"
}

resource "aws_cloudwatch_log_group" "deployer" {
  name              = local.lambda_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
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
    }, var.lambda_environment)
  }

  source_code_hash = data.archive_file.deployer.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.deployer]

  tags = local.tags
}
