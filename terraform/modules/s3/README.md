Terraform module: S3 bucket

Features
- Create S3 bucket with optional generated unique name
- Enable versioning
- Configure public access block
- Configure server-side encryption (SSE-S3 or SSE-KMS)
- Apply lifecycle rules
- Tagging

Inputs
- See `variables.tf` for full list and types.

Outputs
- `bucket_id`, `bucket_arn`, `bucket_domain_name`

Example

module "s3_basic" {
  source = "../modules/s3"
  name   = "my-app-bucket"
}
