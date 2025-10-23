#!/bin/bash
# Creates an S3 bucket using awscli
# Follows repository bash.prompt.md guidelines

set -euo pipefail
IFS=$'\n\t'

function log_info() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] $*"
}

function log_error() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2
}

function log_header() {
    echo "==================== $* ===================="
}

function usage() {
    cat <<EOF
Usage: $(basename "$0") --bucket BUCKET_NAME [--region REGION] [--profile PROFILE]

Creates an S3 bucket, enables versioning, and sets default encryption (AES256).

Options:
  --bucket    Name of the S3 bucket to create (required)
  --region    AWS region (default: us-east-1)
  --profile   AWS CLI profile to use (optional)
  -h, --help  Show this help message

Examples:
  $(basename "$0") --bucket my-unique-bucket-123 --region us-west-2
  $(basename "$0") --bucket my-unique-bucket-123 --profile myprofile
EOF
}

function check_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command '$cmd' not found. Please install it and try again."
        return 1
    fi
}

function aws_check_connection() {
    local profile_arg=( )
    if [[ -n "${AWS_CLI_PROFILE:-}" ]]; then
        profile_arg=("--profile" "${AWS_CLI_PROFILE}")
    fi

    # Quick check: call sts get-caller-identity
    if ! aws "${profile_arg[@]}" sts get-caller-identity >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

function create_bucket() {
    local bucket_name="$1"
    local region="$2"
    local profile_arg=( )
    if [[ -n "${AWS_CLI_PROFILE:-}" ]]; then
        profile_arg=("--profile" "${AWS_CLI_PROFILE}")
    fi

    # Create bucket. For us-east-1, CLI differs: no LocationConstraint allowed.
    if [[ "$region" == "us-east-1" ]]; then
        aws "${profile_arg[@]}" s3api create-bucket --bucket "$bucket_name" || return 1
    else
        aws "${profile_arg[@]}" s3api create-bucket --bucket "$bucket_name" --create-bucket-configuration LocationConstraint="$region" || return 1
    fi

    # Enable versioning
    aws "${profile_arg[@]}" s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled || return 1

    # Enable default encryption with AES256
    aws "${profile_arg[@]}" s3api put-bucket-encryption --bucket "$bucket_name" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' || return 1

    return 0
}

function main() {
    local BUCKET=""
    local REGION="us-east-1"
    local PROFILE=""

    if [[ ${#@} -eq 0 ]]; then
        usage
        exit 1
    fi

    # Parse args
    while [[ ${#@} -gt 0 ]]; do
        case "$1" in
            --bucket)
                BUCKET="$2"; shift 2;;
            --region)
                REGION="$2"; shift 2;;
            --profile)
                PROFILE="$2"; shift 2;;
            -h|--help)
                usage; exit 0;;
            *)
                log_error "Unknown argument: $1"; usage; exit 1;;
        esac
    done

    if [[ -z "$BUCKET" ]]; then
        log_error "--bucket is required"
        usage
        exit 1
    fi

    if [[ -n "$PROFILE" ]]; then
        readonly AWS_CLI_PROFILE="$PROFILE"
    fi

    # Check required commands
    check_command aws

    log_header "S3 bucket creation"
    log_info "Bucket: $BUCKET"
    log_info "Region: $REGION"
    if [[ -n "${AWS_CLI_PROFILE:-}" ]]; then
        log_info "Profile: ${AWS_CLI_PROFILE}"
    fi

    log_info "Checking AWS connectivity..."
    if ! aws_check_connection; then
        log_error "No active AWS connection found. Please configure your AWS CLI (aws configure) or set credentials."
        exit 2
    fi
    log_info "AWS connectivity OK"

    # Check if bucket already exists
    local profile_arg=( )
    if [[ -n "${AWS_CLI_PROFILE:-}" ]]; then
        profile_arg=("--profile" "${AWS_CLI_PROFILE}")
    fi

    if aws "${profile_arg[@]}" s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
        log_error "Bucket '$BUCKET' already exists or you don't have access to it. Aborting."
        exit 3
    fi

    log_info "Creating bucket..."
    if create_bucket "$BUCKET" "$REGION"; then
        log_info "Bucket '$BUCKET' created successfully"
    else
        log_error "Failed to create bucket '$BUCKET'"
        exit 4
    fi

    log_info "Done"
}

main "$@"
