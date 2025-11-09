resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name = "${local.name_prefix}-s3-object-created"

  event_pattern = jsonencode({
    source     = ["aws.s3"]
    detailType = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.lambda_artifacts.bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "deployer" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "lambda-deployer"
  arn       = aws_lambda_function.deployer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}
