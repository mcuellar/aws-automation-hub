data "archive_file" "hello" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda_package.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

resource "aws_lambda_function" "hello" {
  function_name = "${local.name_prefix}-handler"
  description   = "Hello world Lambda function exposed through API Gateway."
  filename      = data.archive_file.hello.output_path
  handler       = "handler.lambda_handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda.arn
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  environment {
    variables = merge({
      ALLOWED_ORIGINS = jsonencode(var.cors_allowed_origins)
      ALLOWED_METHODS = jsonencode(var.cors_allowed_methods)
      ALLOWED_HEADERS = jsonencode(var.cors_allowed_headers)
      SECRET_ARNS     = jsonencode(var.secret_arns)
    }, var.lambda_environment)
  }

  source_code_hash = data.archive_file.hello.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = local.tags
}
