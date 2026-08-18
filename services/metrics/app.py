from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
from pathlib import Path
import json
import os

app = FastAPI(
    title="ChaosForge Metrics",
    version="1.1.0"
)

REPORT_FILE = Path(
    os.getenv(
        "INCIDENT_FILE",
        "/reports/incidents.json"
    )
)


def load_incidents():

    if not REPORT_FILE.exists():
        return []

    try:

        raw = REPORT_FILE.read_text(
            encoding="utf-8-sig"
        ).strip()

        if not raw:
            return []

        data = json.loads(raw)

        # Current ChaosForge format:
        # one incident object.
        if isinstance(data, dict):

            if "incident_id" in data:
                return [data]

            # Also support a wrapper containing incidents.
            if "incidents" in data:
                incidents = data["incidents"]

                if isinstance(incidents, list):
                    return incidents

                if isinstance(incidents, dict):
                    return [incidents]

            return []

        # Future format:
        # array of incidents.
        if isinstance(data, list):
            return [
                item
                for item in data
                if isinstance(item, dict)
            ]

        return []

    except Exception as exc:

        print(
            f"ERROR reading {REPORT_FILE}: {exc}",
            flush=True
        )

        return []


def calculate_metrics():

    incidents = load_incidents()

    total = len(incidents)

    recovered = sum(
        1
        for incident in incidents
        if incident.get("status") == "RECOVERED"
    )

    open_incidents = sum(
        1
        for incident in incidents
        if incident.get("status") == "OPEN"
    )

    mttrs = []

    for incident in incidents:

        value = incident.get("mttr_seconds")

        if value is None:
            continue

        try:

            value = float(value)

            if value >= 0:
                mttrs.append(value)

        except (TypeError, ValueError):

            continue


    average_mttr = (
        sum(mttrs) / len(mttrs)
        if mttrs
        else 0.0
    )

    fastest_mttr = (
        min(mttrs)
        if mttrs
        else 0.0
    )

    slowest_mttr = (
        max(mttrs)
        if mttrs
        else 0.0
    )

    recovery_rate = (
        recovered / total
        if total > 0
        else 1.0
    )

    return {
        "total": total,
        "recovered": recovered,
        "open": open_incidents,
        "recovery_rate": recovery_rate,
        "average_mttr": average_mttr,
        "fastest_mttr": fastest_mttr,
        "slowest_mttr": slowest_mttr,
    }


def render_metrics():

    metrics = calculate_metrics()

    return f"""# HELP chaosforge_incidents_total Total incidents detected
# TYPE chaosforge_incidents_total gauge
chaosforge_incidents_total {metrics["total"]}

# HELP chaosforge_incidents_recovered_total Total recovered incidents
# TYPE chaosforge_incidents_recovered_total gauge
chaosforge_incidents_recovered_total {metrics["recovered"]}

# HELP chaosforge_incidents_open_total Currently open incidents
# TYPE chaosforge_incidents_open_total gauge
chaosforge_incidents_open_total {metrics["open"]}

# HELP chaosforge_recovery_success_rate Incident recovery success rate
# TYPE chaosforge_recovery_success_rate gauge
chaosforge_recovery_success_rate {metrics["recovery_rate"]}

# HELP chaosforge_mttr_seconds Average mean time to recovery
# TYPE chaosforge_mttr_seconds gauge
chaosforge_mttr_seconds {metrics["average_mttr"]}

# HELP chaosforge_mttr_fastest_seconds Fastest recovery
# TYPE chaosforge_mttr_fastest_seconds gauge
chaosforge_mttr_fastest_seconds {metrics["fastest_mttr"]}

# HELP chaosforge_mttr_slowest_seconds Slowest recovery
# TYPE chaosforge_mttr_slowest_seconds gauge
chaosforge_mttr_slowest_seconds {metrics["slowest_mttr"]}
"""


@app.get("/")
def root():

    return {
        "service": "chaosforge-metrics",
        "status": "operational"
    }


@app.get("/health")
def health():

    return {
        "status": "healthy",
        "service": "metrics"
    }


@app.get("/debug")
def debug():

    incidents = load_incidents()

    return {
        "file": str(REPORT_FILE),
        "exists": REPORT_FILE.exists(),
        "incident_count": len(incidents),
        "incidents": incidents
    }


@app.get(
    "/metrics",
    response_class=PlainTextResponse
)
def metrics():

    return render_metrics()


