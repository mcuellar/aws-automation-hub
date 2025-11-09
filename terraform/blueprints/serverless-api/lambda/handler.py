import json
import os
from typing import Dict, List

import boto3
from botocore.exceptions import ClientError

_secrets_client = boto3.client("secretsmanager")


def _parse_list(env_key: str) -> List[str]:
  raw_value = os.getenv(env_key, "[]")
  try:
    parsed = json.loads(raw_value)
  except json.JSONDecodeError:
    return []

  return parsed if isinstance(parsed, list) else []


def _cors_headers(origin: str | None, methods: List[str], headers: List[str]) -> Dict[str, str]:
  base_headers: Dict[str, str] = {
    "Access-Control-Allow-Methods": ",".join(sorted(set(methods))) or "GET",
    "Access-Control-Allow-Headers": ",".join(sorted(set(headers))) or "Content-Type",
  }

  if origin:
    base_headers["Access-Control-Allow-Origin"] = origin
  return base_headers


ALLOWED_ORIGINS = _parse_list("ALLOWED_ORIGINS")
ALLOWED_METHODS = _parse_list("ALLOWED_METHODS") or ["GET", "OPTIONS"]
ALLOWED_HEADERS = _parse_list("ALLOWED_HEADERS") or ["Content-Type", "Authorization"]
SECRET_ARNS = _parse_list("SECRET_ARNS")


def lambda_handler(event, _context):
  # Determine the caller origin, if any, to enforce CORS restrictions.
  headers = event.get("headers") or {}
  request_origin = headers.get("origin") or headers.get("Origin")
  allow_origin = request_origin if not ALLOWED_ORIGINS else None
  if request_origin and request_origin in ALLOWED_ORIGINS:
    allow_origin = request_origin

  if ALLOWED_ORIGINS and not allow_origin:
    return {
      "statusCode": 403,
      "headers": _cors_headers(None, ALLOWED_METHODS, ALLOWED_HEADERS),
      "body": json.dumps({
        "message": "Origin is not allowed."
      }),
    }

  http_method = event.get("httpMethod", "GET").upper()
  cors_headers = _cors_headers(allow_origin, ALLOWED_METHODS, ALLOWED_HEADERS)

  if http_method == "OPTIONS":
    return {
      "statusCode": 204,
      "headers": cors_headers,
      "body": "",
    }

  secrets_retrieved = []
  secrets_failed: Dict[str, str] = {}

  for arn in SECRET_ARNS:
    try:
      # We only confirm access without returning secret payloads to avoid leakage.
      _secrets_client.get_secret_value(SecretId=arn)
      secrets_retrieved.append(arn)
    except ClientError as error:
      secrets_failed[arn] = error.response.get("Error", {}).get("Code", "Unknown")

  body = {
    "message": "Hello from the serverless API!",
    "method": http_method,
    "secrets_accessible": secrets_retrieved,
    "secrets_failed": secrets_failed,
  }

  return {
    "statusCode": 200,
    "headers": cors_headers,
    "body": json.dumps(body),
  }
