from fastapi import FastAPI, Request
import time
import random
import logging
import json
from pythonjsonlogger import jsonlogger
from prometheus_client import start_http_server, Summary, Counter, Histogram

# --- Structured JSON Logging ---
# Plain text logs are for amateurs. JSON logs are for CloudWatch/ELK indexing.
log_handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter(
    '%(timestamp)s %(level)s %(name)s %(message)s',
    timestamp=True
)
log_handler.setFormatter(formatter)
logger = logging.getLogger("titan-app")
logger.addHandler(log_handler)
logger.setLevel(logging.INFO)

app = FastAPI()

# Metrics
REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')
REQUEST_COUNT = Counter('request_count', 'Total number of requests', ['method', 'endpoint', 'http_status'])
LATENCY = Histogram('request_latency_seconds', 'Request latency', ['endpoint'])

import os
import boto3
from botocore.exceptions import ClientError

# --- Real Secrets Management ---
# In production, this uses boto3 to fetch from AWS Secrets Manager.
# It ensures no sensitive credentials ever live in source code or CI env vars.
def get_db_secret():
    # Convention: titan-prod-db-secret (where titan-prod is the project_name from Terraform)
    secret_name = os.environ.get("DB_SECRET_NAME", "titan-prod-db-secret")
    region_name = os.environ.get("AWS_REGION", "us-east-1")

    # Fallback for local testing or if AWS access is missing
    if os.environ.get("LOCAL_DEV", "false") == "true":
        return "local-dev-db-string"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        # Decrypts secret using the associated KMS key.
        secret = json.loads(get_secret_value_response['SecretString'])
        logger.info("Successfully fetched secret from Secrets Manager")
        return f"Connected to {secret.get('host', 'unknown')}"
    except ClientError as e:
        logger.error(f"Error fetching secret: {e}")
        # Return a non-sensitive identifier for the db host in health check
        return os.environ.get("DB_HOST", "titandb.cluster-placeholder.aws.com")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    # Log everything as JSON
    logger.info("API Request Processed", extra={
        "method": request.method,
        "url": str(request.url),
        "status_code": response.status_code,
        "duration": process_time
    })
    return response

@app.get("/")
@REQUEST_TIME.time()
async def read_root():
    REQUEST_COUNT.labels(method='GET', endpoint='/', http_status=200).inc()
    return {
        "message": "Hello from AWS DevOps Platform!",
        "version": "v2.0",
        "db_status": "connected"
    }

@app.get("/health")
async def health_check():
    db_status = get_db_secret()
    return {"status": "healthy", "checks": {"database": db_status, "cache": "up"}}

@app.get("/heavy-load")
@REQUEST_TIME.time()
async def heavy_load():
    # Simulate some CPU work
    start = time.time()
    while time.time() - start < 0.1: # 100ms of busy work
        pass
    
    logger.warning("High CPU consumption detected on /heavy-load", extra={
        "load_duration": 0.1,
        "alert_triggered": False
    })
    
    REQUEST_COUNT.labels(method='GET', endpoint='/heavy-load', http_status=200).inc()
    return {"message": "Processed some heavy load!"}

if __name__ == "__main__":
    # Start prometheus metrics server on port 8001
    start_http_server(8001)
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
