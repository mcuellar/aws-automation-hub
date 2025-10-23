#!/bin/bash
# Delete an S3 bucket safely (empties objects, versions, and deletes bucket)
# Follows project bash guidelines in .github/prompts/bash.prompt.md

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

Delete an AWS S3 bucket. This will first empty the bucket (delete all objects
and object versions, if applicable), then delete the bucket itself.

Dependencies: aws CLI v2+, jq (optional, for nicer JSON parsing but not required)

Options:
  -y            Skip confirmation prompt (use with caution)
  -r PROFILE    Use AWS profile (pass to --profile)
  -h            Show this help message

Examples:
  $SCRIPT_NAME my-bucket-name
  $SCRIPT_NAME -y -r myprofile my-bucket-name

EOF
}

function check_dependencies() {
    local missing=()
    command -v aws >/dev/null 2>&1 || missing+=("aws")
    command -v jq >/dev/null 2>&1 || missing+=("jq")

    if (( ${#missing[@]} )); then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Please install the missing commands (aws, jq) and try again."
        return 1
    fi
    return 0
}

# Delete all objects in a non-versioned bucket using aws s3api delete-objects in batches
function empty_bucket_objects() {
    local bucket=$1
    local profile_args=(${!2})

    log_info "Deleting all objects (including delete markers) from bucket: $bucket"

    # Use paginator to list object keys and delete in batches of 1000
    while true; do
        # Fetch up to 1000 object keys
        local json
        json=$(aws "${profile_args[@]}" s3api list-object-versions --bucket "$bucket" --max-items 1000 2>&1) || {
            log_error "Failed to list objects/object-versions: $json"
            return 1
        }

        # Extract object identifiers (Key + VersionId for versions) if present
        local identifiers
        identifiers=$(echo "$json" | jq -r '
            ([.Versions[]? | {Key:.Key, VersionId:.VersionId}] + [.DeleteMarkers[]? | {Key:.Key, VersionId:.VersionId}])
            | map({Key: .Key, VersionId: .VersionId})
            | if length == 0 then empty else (.[] | @base64) end
        ')

        if [[ -z "$identifiers" ]]; then
            # No objects or versions
            break
        fi

        # Build delete payload
        local payload
        payload='{"Objects":['
        local first=true
        while read -r item; do
            local decoded
            decoded=$(echo "$item" | base64 --decode)
            local key
            local vid
            key=$(echo "$decoded" | jq -r '.Key')
            vid=$(echo "$decoded" | jq -r '.VersionId')
            if [[ "$first" == true ]]; then
                first=false
            else
                payload+=","
            fi
            payload+="{\"Key\":$(jq -Rn --arg k "$key" '$k')"
            if [[ "$vid" != "null" && -n "$vid" ]]; then
                payload+=",\"VersionId\":$(jq -Rn --arg v "$vid" '$v')"
            fi
            payload+="}"
        done <<< "$identifiers"
        payload+='],"Quiet":true}'

        # Call delete-objects
        local resp
        resp=$(aws "${profile_args[@]}" s3api delete-objects --bucket "$bucket" --delete "$payload" 2>&1) || {
            log_error "Failed to delete objects: $resp"
            return 1
        }

        # Continue loop until no more items
    done

    log_info "All objects and versions removed from bucket: $bucket"
    return 0
}

function delete_bucket() {
    local bucket=$1
    local profile_args=(${!2})

    log_info "Deleting bucket: $bucket"
    if ! aws "${profile_args[@]}" s3api delete-bucket --bucket "$bucket" >/dev/null 2>&1; then
        log_error "Failed to delete bucket: $bucket"
        return 1
    fi
    log_info "Bucket deleted: $bucket"
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

function main() {
    local profile=""
    local bucket=""
    ASSUME_YES=false

    # Parse args
    while getopts ":yr:h" opt; do
        case $opt in
            y) ASSUME_YES=true ;;
            r) profile="$OPTARG" ;;
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

    # Build profile args; default to 'default' if not provided
    local profile_args
    if [[ -z "$profile" ]]; then
        profile="default"
    fi
    profile_args=("--profile" "$profile")

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    log_header "S3 Delete: $bucket"

    if ! aws "${profile_args[@]}" s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
        log_error "Bucket does not exist or you don't have access: $bucket"
        exit 1
    fi

    if ! confirm "Really delete bucket '$bucket' and all its contents?"; then
        log_info "Aborted by user"
        exit 0
    fi

    # Empty bucket (objects and versions)
    if ! empty_bucket_objects "$bucket" profile_args[@]; then
        log_error "Failed to empty bucket: $bucket"
        exit 1
    fi

    # Delete bucket
    if ! delete_bucket "$bucket" profile_args[@]; then
        log_error "Failed to delete bucket: $bucket"
        exit 1
    fi

    log_header "Completed: $bucket deleted"
}

main "$@"
