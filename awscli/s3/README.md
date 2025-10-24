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

## s3_delete.sh

Delete an S3 bucket and all of its contents (objects, delete markers, and versions).

Important: This script permanently deletes data. Use with extreme caution.

Dependencies:
- AWS CLI (v2 recommended)
- jq (used for JSON handling)

Usage:

```bash
# Interactive confirmation (uses the `default` AWS profile if none provided)
./s3_delete.sh my-bucket-name

# Skip confirmation and specify a profile
./s3_delete.sh -y -r myprofile my-bucket-name
```

Options:
- `-y` : Skip interactive confirmation (dangerous for production buckets)
- `-r PROFILE` : Use the given AWS CLI profile; if omitted the script uses the `default` profile
- `-h` : Show help/usage

What the script does:
- Verifies required dependencies (aws, jq).
- Checks that the bucket exists and you have access.
- Iteratively removes objects, delete markers and versions in batches.
- Deletes the bucket when it is empty.

Safety notes:
- There is no built-in undo. Ensure you have backups if needed before running.
- Consider running in a test account or using a `--dry-run` (not currently implemented) to validate behavior first.

Contributions:
- Feel free to add a `--dry-run` mode, region flag, or support for different pagination strategies for very large buckets.

## s3_upload.sh

Upload files from the local `data/` directory to an S3 bucket. The script supports uploading a single file (path relative to `data/`) or all files recursively.

Important: uploading will transfer data to the target S3 bucket. Verify the target and profile before proceeding.

Dependencies:
- AWS CLI (v2 recommended)

Usage:

```bash
# Upload all files under data/ using the default profile (interactive confirmation)
./s3_upload.sh -a my-bucket-name

# Upload a single file 'sample1.txt' from data/ using profile 'myprofile' and skip confirmation
./s3_upload.sh -y -r myprofile -f sample1.txt my-bucket-name
```

Options:
- `-a` : Upload all files from `data/` recursively
- `-f FILE` : Upload a single file (FILE is path relative to `data/`)
- `-r PROFILE` : AWS CLI profile to use (defaults to `default` if omitted)
- `-y` : Skip interactive confirmation
- `-h` : Show help/usage

Behavior:
- Verifies the AWS CLI is installed.
- Checks that the target bucket exists and you have access.
- For `-a`, uses `aws s3 cp --recursive` to copy the `data/` directory contents to the bucket root.
- For `-f`, uploads the single file path provided (source: `data/<FILE>`) to the bucket root.

Notes & tips:
- The script expects a `data/` directory located next to the script (e.g., `awscli/s3/data/`). Sample files are provided for testing.
- The script always passes `--profile <PROFILE>` to AWS CLI; when `-r` is not supplied it defaults to `default`.
- Consider adding a `--dry-run` mode if you want to preview files before uploading.

Contributions:
- Add `--dry-run`, progress output for large uploads, or support for specifying a destination prefix in the bucket.
