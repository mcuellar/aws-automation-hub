
# Serverless API Blueprint


This blueprint provisions an AWS API Gateway (HTTP API or REST API, selectable) backed by a Lambda function with optional AWS WAF protection. It enforces configurable CORS restrictions, integrates with AWS Secrets Manager, and configures CloudWatch logging for both the API and the function.



## Features

- Regional AWS API Gateway (HTTP API v2 or REST API v1) with proxy routing to a hello-world Lambda function.
- Lambda execution role with least-privilege permissions and optional read access to AWS Secrets Manager secrets supplied by consumers.
- Configurable CORS enforcement handled within the Lambda handler and API Gateway configuration (HTTP API supports native CORS, REST API requires Lambda logic).
- CloudWatch execution logging for Lambda and API Gateway.
- Optional AWS WAFv2 Web ACL using AWS managed rule groups (disabled by default).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.4.2 |
| aws | >= 5.0.0 |
| archive | >= 2.3.0 |


## Usage


```hcl
# HTTP API (default)
module "serverless_api" {
  source = "../"
  project_name          = "my-service"
  environment           = "dev"
  cors_allowed_origins  = ["https://app.example.com"]
  secret_arns           = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret"]
  enable_waf            = false
  create_api_gateway    = true
  # api_gateway_type    = "HTTP" # (default)
}

# REST API
module "serverless_api" {
  source = "../"
  project_name          = "my-service"
  environment           = "dev"
  cors_allowed_origins  = ["https://app.example.com"]
  secret_arns           = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret"]
  enable_waf            = false
  create_api_gateway    = true
  api_gateway_type      = "REST"
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
| `api_gateway_type` | Type of API Gateway to create: `"HTTP"` (default, API Gateway v2) or `"REST"` (API Gateway v1). | `string` | `"HTTP"` | no |
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
| `target_lambda_arn` | Optional: Full ARN of the Lambda function that the deployer should update when new artifacts arrive in the S3 bucket. If provided, the module will scope the deployer IAM policy to this exact function. | `string` | `""` | no |
| `target_lambda_name` | Optional: Name of an existing Lambda function in the same account/region. If provided, the module will look up its ARN and use it as the target. Either `target_lambda_arn` or `target_lambda_name` must be provided when using the deployer. | `string` | `""` | no |


## Outputs

| Name | Description |
|------|-------------|
| `api_invoke_url` | Invoke URL for the optional API Gateway stage (null if not created). |
| `waf_web_acl_arn` | ARN of the provisioned AWS WAFv2 Web ACL, if enabled. |

## Deployer / artifact workflow


This module creates an S3 bucket for Lambda artifacts (with versioning suspended and a lifecycle rule to expire objects older than 3 days). It also creates a `deployer` Lambda that listens for S3 Object Created events via EventBridge and calls `UpdateFunctionCode` on the `target_lambda_arn` you provide.

How to use the deployer

1. Ensure you pass a valid `target_lambda_arn` or `target_lambda_name` when calling the module. The module accepts either a full ARN (recommended when available) or a function name. Examples:

```hcl
module "serverless_api" {
  source = "../"

  project_name        = "my-service"
  environment         = "dev"
  # Option A: pass the full ARN (recommended)
  target_lambda_arn   = aws_lambda_function.my_target.arn

  # Option B: or pass the function name and let the module look up the ARN
  # target_lambda_name  = aws_lambda_function.my_target.function_name
  # ...other inputs
}
```


2. Upload a zip artifact to the created artifacts bucket (see `artifact_bucket_name` output):

```bash
aws s3 cp my_function_build.zip s3://$(terraform output -raw artifact_bucket_name)/builds/my_function_build.zip
```

3. The deployer Lambda will be invoked via EventBridge. It reads the S3 object key and calls `UpdateFunctionCode` with `Publish=True` to deploy the uploaded package to the target Lambda.



Notes & security

- The module provisions either an HTTP API (API Gateway v2, default) or a REST API (API Gateway v1) depending on the `api_gateway_type` variable. All integrations, permissions, and outputs are updated for the selected API type.
- HTTP API is recommended for most new use cases due to lower cost and latency, but does not support all REST API features (API keys, usage plans, request validation, advanced throttling, etc.).
- The module accepts either `target_lambda_arn` (full ARN) or `target_lambda_name` (function name). If you provide a name, the module will perform an internal lookup of the function's ARN and scope permissions to it. Providing a full ARN is still recommended when available to avoid reliance on lookups.
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
