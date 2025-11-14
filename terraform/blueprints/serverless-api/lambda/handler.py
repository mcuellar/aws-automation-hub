
import json
import os
import boto3
from botocore.exceptions import ClientError

_secrets_client = boto3.client("secretsmanager")

def _parse_list(env_key: str):
    raw_value = os.getenv(env_key, "[]")
    try:
        parsed = json.loads(raw_value)
    except json.JSONDecodeError:
        return []
    return parsed if isinstance(parsed, list) else []

SECRET_ARNS = _parse_list("SECRET_ARNS")



def lambda_handler(event, _context):
    secrets_retrieved = []
    secrets_failed = {}

    for arn in SECRET_ARNS:
        try:
            # We only confirm access without returning secret payloads to avoid leakage.
            _secrets_client.get_secret_value(SecretId=arn)
            secrets_retrieved.append(arn)
        except ClientError as error:
            secrets_failed[arn] = error.response.get("Error", {}).get("Code", "Unknown")

    body = {
        "message": "Hello from the serverless API!",
        "secrets_accessible": secrets_retrieved,
        "secrets_failed": secrets_failed,
    }

    return {
        "statusCode": 200,
        "body": json.dumps(body),
    }
