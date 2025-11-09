def handler(event, context):
    """Simple example Lambda handler used for CI/demo purposes."""
    return {
        "statusCode": 200,
        "body": "Hello from example lambda",
    }
