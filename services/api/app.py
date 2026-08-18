from fastapi import FastAPI
from prometheus_client import Counter, generate_latest
from fastapi.responses import Response
import socket

app = FastAPI(
    title="ChaosForge API",
    version="1.0.0"
)

REQUESTS = Counter(
    "chaosforge_requests_total",
    "Total HTTP requests",
    ["endpoint"]
)


@app.get("/")
def root():

    REQUESTS.labels("/").inc()

    return {
        "service": "chaosforge-api",
        "status": "operational",
        "hostname": socket.gethostname()
    }


@app.get("/health")
def health():

    REQUESTS.labels("/health").inc()

    return {
        "status": "healthy",
        "service": "api",
        "hostname": socket.gethostname()
    }


@app.get("/work")
def work():

    REQUESTS.labels("/work").inc()

    result = sum(
        i * i
        for i in range(100000)
    )

    return {
        "status": "completed",
        "result": result
    }


@app.get("/metrics")
def metrics():

    return Response(
        generate_latest(),
        media_type="text/plain"
    )
