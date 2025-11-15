import boto3
import os
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO, force=True)
logger = logging.getLogger()

lambda_client = boto3.client("lambda")

def handler(event, context):
    logger.info(f"Received event:\n{json.dumps(event, indent=2)}")

    lambda_arn = os.environ.get("TARGET_LAMBDA_ARN")
    s3_bucket = os.environ.get("S3_BUCKET_NAME")

    try:
        response = lambda_client.update_function_code(
            FunctionName=lambda_arn,
            S3Bucket=s3_bucket,
            S3Key="package.zip",
            Publish=True
        )
        status = response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        if status == 200:
            logger.info(f"Lambda function code updated successfully with status: {status}")
        else:
            logger.warning(f"Lambda function code update returned unexpected status: {status}")
            
            pretty_response = json.dumps(response, indent=2)
            logger.error(f"Failed to update function code with package.zip: {pretty_response}")
    except Exception as e:
        logger.error(f"Failed to update function code with package.zip: {e}")
