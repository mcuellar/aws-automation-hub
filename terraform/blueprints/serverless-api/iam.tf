# If the caller provided a target Lambda name, look it up here so the module can
# resolve its ARN and scope the deployer IAM policy to that exact function.
data "aws_lambda_function" "target" {
  count         = var.target_lambda_name != "" ? 1 : 0
  function_name = var.target_lambda_name
}

# Lambda execution role for the target Lambda function
resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_secrets" {
  count       = length(var.secret_arns) > 0 ? 1 : 0
  name        = "${local.name_prefix}-lambda-secrets"
  description = "Allow Lambda to read specified secrets from AWS Secrets Manager."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  count      = length(var.secret_arns) > 0 ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_secrets[0].arn
}
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


## REST API-specific IAM resources removed for HTTP API migration

data "aws_iam_policy_document" "deployer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "deployer" {
  name               = "${local.name_prefix}-lambda-deployer-role"
  assume_role_policy = data.aws_iam_policy_document.deployer_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "deployer_inline" {
  name = "${local.name_prefix}-lambda-deployer-inline"
  role = aws_iam_role.deployer.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:PublishVersion"
        ],
        Resource = [local.target_lambda_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = ["arn:aws:s3:::${aws_s3_bucket.lambda_artifacts.bucket}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deployer_basic" {
  role       = aws_iam_role.deployer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
