resource "aws_cloudwatch_event_rule" "s3_object_created" {
  count = var.create_eventbridge_rule ? 1 : 0
  name = "${local.name_prefix}-s3-object-created"
  description = "Triggers lambda deployer on S3 object creation in the lambda artifacts bucket"

  event_pattern = jsonencode({
    source     = ["aws.s3"]
    detail-type = ["Object Created"]
    resources = [aws_s3_bucket.lambda_artifacts.arn]
  })
}

resource "aws_cloudwatch_event_target" "deployer" {
  count     = var.create_eventbridge_rule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.s3_object_created[0].name
  target_id = "lambda-deployer"
  arn       = aws_lambda_function.deployer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.create_eventbridge_rule ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created[0].arn
}
