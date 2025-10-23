# S3 helper scripts

This directory contains helper scripts for working with Amazon S3 using the AWS CLI.

## s3_create.sh

Creates a new S3 bucket, enables versioning, and configures default server-side encryption (AES256).

Usage:

```bash
# Create a bucket in a specific region
./s3_create.sh --bucket my-unique-bucket-123 --region us-west-2

# Create a bucket using a named AWS CLI profile
./s3_create.sh --bucket my-unique-bucket-123 --profile myprofile
```

Notes:
- The script requires the AWS CLI to be installed and configured.
- It checks AWS connectivity by calling `aws sts get-caller-identity` and will exit if credentials are missing or invalid.
- The script will abort if the bucket already exists or you don't have access to it.
- Default region is `us-east-1` when `--region` is not provided.

Security and caution:
- Make sure your bucket name is globally unique.
- Review and adapt the script if you need KMS-based encryption or custom bucket policies.

Contributions:
- Pull requests welcome. Consider adding a `--dry-run` flag or support for KMS key ARNs if needed.
