#!/bin/bash
# Upload files from the local `data/` directory to an S3 bucket.
# Supports uploading all files or a single file from data/.
# Follows guidelines in .github/prompts/bash.prompt.md

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

readonly SCRIPT_NAME="$(basename "$0")"

function usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] BUCKET_NAME

Upload files from the local 'data/' directory (next to this script) to an S3 bucket.

Options:
  -y            Skip confirmation prompt
  -r PROFILE    AWS CLI profile to use (defaults to 'default' if omitted)
  -f FILE       Upload a single file named FILE (path relative to data/)
  -a            Upload all files under data/ (recursive)
  -h            Show this help message

Examples:
  # Upload all files using default profile
  $SCRIPT_NAME -a my-bucket-name

  # Upload a single file 'example.csv' from data/ using profile 'myprofile'
  $SCRIPT_NAME -r myprofile -f example.csv my-bucket-name

EOF
}

function check_dependencies() {
    local missing=()
    command -v aws >/dev/null 2>&1 || missing+=("aws")

    if (( ${#missing[@]} )); then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Please install the missing commands and try again."
        return 1
    fi
    return 0
}

function confirm() {
    local prompt="$1"
    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi
    read -r -p "$prompt [y/N]: " answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Upload all files recursively from data/ to bucket
function upload_all() {
    local bucket=$1
    local profile_args=(${!2})
    local data_dir="$SCRIPT_DIR/data"

    if [[ ! -d "$data_dir" ]]; then
        log_error "Data directory not found: $data_dir"
        return 1
    fi

    # Ensure there are files to upload
    if ! find "$data_dir" -type f | read -r; then
        log_info "No files to upload in: $data_dir"
        return 0
    fi

    log_info "Uploading all files from $data_dir to s3://$bucket/"
    aws "${profile_args[@]}" s3 cp --recursive "$data_dir/" "s3://$bucket/"
}

# Upload a single file (path is relative to data/)
function upload_file() {
    local bucket=$1
    local file_rel=$2
    local profile_args=(${!3})
    local data_dir="$SCRIPT_DIR/data"
    local src="$data_dir/$file_rel"

    if [[ ! -f "$src" ]]; then
        log_error "File not found: $src"
        return 1
    fi

    log_info "Uploading $src to s3://$bucket/"
    aws "${profile_args[@]}" s3 cp "$src" "s3://$bucket/"
}

function main() {
    local profile=""
    local bucket=""
    local upload_single=""
    local upload_all_flag=false
    ASSUME_YES=false

    # location of this script (used to find data/)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    while getopts ":yr:f:ah" opt; do
        case $opt in
            y) ASSUME_YES=true ;;
            r) profile="$OPTARG" ;;
            f) upload_single="$OPTARG" ;;
            a) upload_all_flag=true ;;
            h) usage; exit 0 ;;
            :) log_error "Option -$OPTARG requires an argument"; usage; exit 2 ;;
            \?) log_error "Unknown option: -$OPTARG"; usage; exit 2 ;;
        esac
    done
    shift $((OPTIND -1))

    if [[ $# -lt 1 ]]; then
        log_error "Bucket name is required"
        usage
        exit 2
    fi
    bucket=$1

    # Default profile to 'default' if not set
    if [[ -z "$profile" ]]; then
        profile="default"
    fi
    profile_args=("--profile" "$profile")

    if ! check_dependencies; then
        exit 1
    fi

    # Validate mutually exclusive options
    if [[ -n "$upload_single" && "$upload_all_flag" == true ]]; then
        log_error "Options -f and -a are mutually exclusive"
        usage
        exit 2
    fi

    if [[ -z "$upload_single" && "$upload_all_flag" == false ]]; then
        log_error "Either -f FILE or -a (all) must be specified"
        usage
        exit 2
    fi

    log_header "S3 Upload to: $bucket"

    if ! aws "${profile_args[@]}" s3 ls "s3://$bucket" >/dev/null 2>&1; then
        log_error "Bucket does not exist or you don't have access: $bucket"
        exit 1
    fi

    if ! confirm "Proceed with upload to 's3://$bucket/'?"; then
        log_info "Aborted by user"
        exit 0
    fi

    if [[ "$upload_all_flag" == true ]]; then
        if ! upload_all "$bucket" profile_args[@]; then
            log_error "Failed to upload all files"
            exit 1
        fi
    else
        if ! upload_file "$bucket" "$upload_single" profile_args[@]; then
            log_error "Failed to upload file: $upload_single"
            exit 1
        fi
    fi

    log_header "Upload completed"
}

main "$@"
