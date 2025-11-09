# Serverless API Blueprint

This blueprint provisions an AWS API Gateway REST API backed by a Lambda function with optional AWS WAF protection. It enforces configurable CORS restrictions, integrates with AWS Secrets Manager, and configures CloudWatch logging for both the API and the function.

## Features

- Regional API Gateway REST API with proxy routing to a hello-world Lambda function.
- Lambda execution role with least-privilege permissions and optional read access to AWS Secrets Manager secrets supplied by consumers.
- Configurable CORS enforcement handled within the Lambda handler.
- CloudWatch execution and access logging with IAM roles managed by Terraform.
- Optional AWS WAFv2 Web ACL using AWS managed rule groups (disabled by default).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.4.2 |
| aws | >= 5.0.0 |
| archive | >= 2.3.0 |

## Usage

```hcl
module "serverless_api" {
  source = "../"

  project_name          = "my-service"
  environment           = "dev"
  cors_allowed_origins  = ["https://app.example.com"]
  secret_arns           = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret"]
  enable_waf            = false
}
```

Refer to the [examples](examples/README.md) directory for both minimal and fully configured scenarios.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | Name of the project this serverless API belongs to. | `string` | n/a | yes |
| `environment` | Deployment environment name used for tagging and resource naming. | `string` | `"dev"` | no |
| `aws_region` | AWS region to deploy resources in. Leave null to use the provider default or environment configuration. | `string` | `null` | no |
| `stage_name` | API Gateway stage name. | `string` | `"dev"` | no |
| `lambda_runtime` | Lambda runtime to use for the hello world handler. | `string` | `"python3.10"` | no |
| `lambda_memory_size` | Memory size for the Lambda function in MB. | `number` | `128` | no |
| `lambda_timeout` | Timeout for the Lambda function in seconds. | `number` | `10` | no |
| `lambda_environment` | Additional environment variables for the Lambda function. | `map(string)` | `{}` | no |
| `cors_allowed_origins` | List of allowed origins for CORS. The Lambda function dynamically enforces these origins at runtime. | `list(string)` | `[]` | no |
| `cors_allowed_methods` | List of allowed HTTP methods for CORS responses. | `list(string)` | `["GET", "OPTIONS"]` | no |
| `cors_allowed_headers` | List of allowed headers for CORS responses. | `list(string)` | `["Content-Type", "Authorization"]` | no |
| `secret_arns` | List of AWS Secrets Manager secret ARNs the Lambda function is allowed to read. | `list(string)` | `[]` | no |
| `log_retention_in_days` | Number of days to retain CloudWatch Logs for the API and Lambda. | `number` | `14` | no |
| `enable_waf` | Whether to provision an AWS WAFv2 Web ACL and associate it with the API Gateway stage. | `bool` | `false` | no |
| `waf_override_action` | Override action to apply to AWS managed rule group requests. Valid values: NONE, COUNT. | `string` | `"NONE"` | no |
| `tags` | Additional tags to apply to all resources created by this blueprint. | `map(string)` | `{}` | no |
| `create_api_gateway` | Whether to create an API Gateway that routes to a configured Lambda. | `bool` | `false` | no |
| `api_lambda_arn` | ARN of the Lambda the optional API Gateway should invoke (required if `create_api_gateway` = true). | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| `api_invoke_url` | Invoke URL for the optional API Gateway stage (null if not created). |
| `waf_web_acl_arn` | ARN of the provisioned AWS WAFv2 Web ACL, if enabled. |

## Deployer / artifact workflow

This module creates an S3 bucket for Lambda artifacts (with versioning suspended and a lifecycle rule to expire objects older than 3 days). It also creates a `deployer` Lambda that listens for S3 Object Created events via EventBridge and calls `UpdateFunctionCode` on the `target_lambda_arn` you provide.

How to use the deployer

1. Ensure you pass a valid `target_lambda_arn` when calling the module (examples show how the example target lambda is created and its ARN passed in). Example:

```hcl
module "serverless_api" {
  source = "../"

  project_name        = "my-service"
  environment         = "dev"
  target_lambda_arn   = aws_lambda_function.my_target.arn
  # ...other inputs
}
```

2. Upload a zip artifact to the created artifacts bucket (see `artifact_bucket_name` output):

```bash
aws s3 cp my_function_build.zip s3://$(terraform output -raw artifact_bucket_name)/builds/my_function_build.zip
```

3. The deployer Lambda will be invoked via EventBridge. It reads the S3 object key and calls `UpdateFunctionCode` with `Publish=True` to deploy the uploaded package to the target Lambda.

Notes & security

- The module requires `target_lambda_arn` to be a full ARN. This allows the deployer IAM policy to be locked to the exact function and follow least-privilege principles.
- If your target Lambda resides in a different AWS account, prefer an assume-role pattern where the deployer assumes a role in the target account with `lambda:UpdateFunctionCode` permission. I can add that pattern if you need cross-account support.
- If you use KMS encryption for the S3 bucket, ensure the deployer has `kms:Decrypt` for the CMK.

## Testing

Run the standard Terraform workflows from the blueprint directory:

```bash
terraform init
terraform fmt -check
terraform validate
```

The Lambda handler enforces the CORS origin list and attempts to read any configured Secrets Manager ARNs on every invocation, returning only metadata about access successes or failures.
