from fastapi import FastAPI, Request
import time
import random
import logging
import json
from pythonjsonlogger import jsonlogger
from prometheus_client import start_http_server, Summary, Counter, Histogram

# --- Senior Practice: Structured JSON Logging ---
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
# --- Senior Practice: Secrets Management ---
# In production, this would use boto3 to fetch from AWS Secrets Manager
# Currently simulating by reading environment variables set by the deployment
def get_db_secret():
    db_host = os.environ.get("DB_HOST", "titandb.cluster-placeholder.aws.com")
    logger.info(f"Connecting to database at {db_host}...")
    return f"Connected to {db_host}"

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
        "version": "v2.0 (Senior Grade)",
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
