Examples for the S3 module

There are two example configurations in this folder that show how to call the `terraform/modules/s3` module.

Prerequisites
- Terraform installed (version 1.1+ recommended)
- AWS credentials available in your environment (environment variables, shared credentials file, or a configured provider in a parent module)

Example: basic

1. Change into the example directory:

```bash
cd terraform/examples/basic
```

2. Initialize providers and modules (no backend configured here):

```bash
terraform init -backend=false
```

3. Validate the configuration:

```bash
terraform validate
```

4. (Optional) Plan and apply — these will make real changes in your AWS account and require credentials and permissions:

```bash
terraform plan -out=plan.tfout
terraform apply plan.tfout
```

Example: versioned_encrypted

This example demonstrates a versioned bucket with a KMS key and lifecycle rules. It creates a KMS key in the example. Follow the same steps as above in `terraform/examples/versioned_encrypted`.

Notes and troubleshooting
- Provider/plugin timeouts: In CI or constrained environments, provider plugin startup can time out. If you see "timeout while waiting for plugin to start", retry `terraform init` or run on a machine with network access to fetch providers. You can also increase host resources or rerun.
- The examples use `-backend=false` to avoid configuring a backend; for production use configure a proper remote backend.
- The `versioned_encrypted` example will create a KMS key; ensure the IAM identity you run Terraform with has permissions to create/manage KMS keys and S3 buckets.

Module variables reference: see `terraform/modules/s3/variables.tf` for inputs and types. Outputs are documented in `terraform/modules/s3/outputs.tf`.
