import boto3
import os

lambda_client = boto3.client("lambda")

def handler(event, context):
    print(event)
    # EventBridge for S3 object created events places object info in event['detail']
    # The event may contain records differently depending on S3 -> EventBridge structure.
    # We attempt to extract the key(s) defensively.
    detail = event.get("detail", {})

    # detail may contain object key at detail.object.key (string) or list depending on source
    # Normalize to list of keys
    keys = []
    obj = detail.get("object") or {}
    key_val = obj.get("key")
    if isinstance(key_val, str):
        keys = [key_val]
    elif isinstance(key_val, list):
        keys = key_val

    bucket = detail.get("bucket", {}).get("name")

    if not bucket or not keys:
        print("No bucket or keys found in event detail; nothing to do.")
        return

    for key in keys:
        try:
            response = lambda_client.update_function_code(
                FunctionName=os.environ.get("TARGET_LAMBDA_ARN"),
                S3Bucket=bucket,
                S3Key=key,
                Publish=True
            )
            print(f"Updated {os.environ.get('TARGET_LAMBDA_ARN')} with {key}")
        except Exception as e:
            print(f"Failed to update function code for {key}: {e}")
