# Example Lambda repository

This repository is a minimal example of a single Python AWS Lambda function with a CI pipeline that builds, tests, packages, computes a content-hash, and uploads the zip artifact to S3.

Purpose
- Demonstrate how to maintain Lambda source code in a separate repository.
- Provide a GitHub Actions pipeline that publishes artifacts to S3 for Terraform or other infra pipelines to consume.

What is included
- `handler.py` - minimal Lambda handler
- `requirements.txt` - python deps for local development/tests
- `tests/test_handler.py` - simple pytest
- `Makefile` - common tasks: install, test, package
- `.github/workflows/ci.yml` - CI pipeline that builds and uploads artifact to S3

Usage
1. Edit the handler and tests locally.
2. Push to GitHub and configure repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `S3_BUCKET` (target artifacts bucket)
3. CI will upload `build/lambda.zip` to `s3://${S3_BUCKET}/lambda-artifacts/<repo>-<sha>.zip` and expose `sha256` in the job outputs.

Next steps
- Optionally switch to container images (ECR) for large dependencies.
- Integrate the artifact metadata (s3 key + sha256) into your Terraform pipeline (see blueprint inputs TODO).