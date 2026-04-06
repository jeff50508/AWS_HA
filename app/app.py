from fastapi import FastAPI
import time
import random
from prometheus_client import start_http_server, Summary, Counter, Histogram

app = FastAPI()

# Metrics
REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')
REQUEST_COUNT = Counter('request_count', 'Total number of requests', ['method', 'endpoint', 'http_status'])
LATENCY = Histogram('request_latency_seconds', 'Request latency', ['endpoint'])

@app.get("/")
@REQUEST_TIME.time()
async def read_root():
    REQUEST_COUNT.labels(method='GET', endpoint='/', http_status=200).inc()
    return {"message": "Hello from AWS DevOps Platform!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/heavy-load")
@REQUEST_TIME.time()
async def heavy_load():
    # Simulate some CPU work
    start = time.time()
    while time.time() - start < 0.1: # 100ms of busy work
        pass
    REQUEST_COUNT.labels(method='GET', endpoint='/heavy-load', http_status=200).inc()
    return {"message": "Processed some heavy load!"}

if __name__ == "__main__":
    # Start prometheus metrics server on port 8001
    start_http_server(8001)
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
