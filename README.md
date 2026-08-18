# ⚔️ ChaosForge

### SRE & Chaos Engineering Lab for Failure Injection, Automated Recovery & Reliability Engineering

ChaosForge is a local-first **Site Reliability Engineering (SRE) and Chaos Engineering platform** designed to intentionally introduce service failures, detect incidents, recover failed workloads, and measure the resulting reliability characteristics.

Instead of asking *"Does the application work?"*, ChaosForge asks:

> **"What happens when it stops working and how quickly can we recover it?"**

The platform combines **Docker, PowerShell, Prometheus, Grafana, Python/FastAPI, automated incident recovery, MTTR measurement, SLO tracking, and error-budget analysis** into a reproducible local reliability laboratory.

---

## 🎯 Why ChaosForge?

Production systems eventually fail.

Containers crash. APIs become unavailable. Dependencies disappear. Resources become exhausted. Deployments introduce unexpected behaviour.

A reliable engineering team needs more than uptime monitoring.

It needs the ability to:

- Detect failures quickly
- Identify affected services
- Trigger controlled failure experiments
- Automatically recover workloads
- Measure Mean Time to Recovery (MTTR)
- Track incident history
- Define and evaluate SLOs
- Measure error-budget consumption
- Validate that recovery mechanisms actually work

ChaosForge provides a controlled environment for practicing exactly that.

---

# 🏗️ Architecture

```text
                         ┌─────────────────────────┐
                         │       PowerShell        │
                         │      forge.ps1 CLI       │
                         └────────────┬────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
       Chaos Experiments        Health Checks            SRE Reports
              │                       │                       │
              ▼                       ▼                       ▼
      ┌────────────────────────────────────────────────────────┐
      │                    Docker Compose                       │
      │                                                        │
      │   ┌─────────────┐      ┌──────────────────────────┐   │
      │   │ FastAPI API  │─────▶│ Recovery / Incident     │   │
      │   │   :8000      │      │ Control Plane            │   │
      │   └──────┬──────┘      └────────────┬─────────────┘   │
      │          │                          │                 │
      │          │ /metrics                 │                 │
      │          ▼                          ▼                 │
      │   ┌─────────────┐           ┌──────────────┐         │
      │   │ Prometheus  │◀──────────│ Metrics      │         │
      │   │    :9090    │           │ Exporter     │         │
      │   └──────┬──────┘           │    :9101     │         │
      │          │                  └──────────────┘         │
      │          ▼                                             │
      │   ┌─────────────┐                                      │
      │   │   Grafana   │                                      │
      │   │    :3000    │                                      │
      │   └─────────────┘                                      │
      │                                                        │
      └────────────────────────────────────────────────────────┘

                         ▲
                         │
                  Chaos Injection
                         │
             ┌───────────┴───────────┐
             │                       │
       Container Kill           Resource Chaos
             │                       │
             └───────────┬───────────┘
                         │
                         ▼
                    API Failure
                         │
                         ▼
                  Detection → Recovery
                         │
                         ▼
                    MTTR / SLO

🧰 Technology Stack
Technology	Purpose
PowerShell	SRE CLI, automation and chaos orchestration
Python / FastAPI	Application/API workload
Docker	Containerization and failure isolation
Docker Compose	Local service orchestration
Prometheus	Metrics collection and querying
Grafana	Observability and visualization
REST API	Health and workload endpoints
JSON	Incident persistence
Git	Version control
⚡ Core Capabilities
💥 Chaos Engineering

ChaosForge can intentionally terminate the API container to simulate a production service failure.

.\forge.ps1 chaos kill

Example:

Target container: chaosforge-api


Current state: running


Injecting container failure...
chaosforge-api


FAILURE INJECTED


Container 'chaosforge-api' has been killed.

The failure is intentional and controlled.

🚨 Incident Detection

The recovery control plane continuously monitors the API health endpoint:

http://localhost:8000/health

When the API becomes unavailable:

[ALERT] API DOWN


[INCIDENT] INC-0001
[INCIDENT] API_DOWN / CRITICAL

ChaosForge records:

Incident ID
Incident type
Service
Severity
Detection timestamp
Recovery timestamp
Recovery action
MTTR
🔄 Automated Recovery

Once the failure is detected, ChaosForge attempts to recover the service:

[RECOVERY] Starting API recovery...


[+] start 1/1
✔ Container chaosforge-api Started


[RECOVERY] Waiting for API...
[RECOVERY] API recovered

The system then records the recovery event and calculates MTTR.

Example:

Incident : INC-0003
Type     : API_DOWN
Severity : CRITICAL
Status   : RECOVERED
MTTR     : 7.462 seconds
⏱️ MTTR Tracking

ChaosForge measures Mean Time to Recovery (MTTR) for every recovered incident.

Current verified experiment results:

Incident	MTTR
INC-0001	5.241s
INC-0002	7.463s
INC-0003	7.462s
Current reliability results
Total incidents : 3
Recovered       : 3
Open            : 0
Success rate    : 100%


Average MTTR    : 6.722s
Fastest MTTR    : 5.241s
Slowest MTTR    : 7.463s

Average MTTR:

(5.241 + 7.463 + 7.462) / 3
= 6.722 seconds
🎯 SLO Monitoring

ChaosForge currently evaluates recovery against a defined SLO:

Recovery SLO: < 30 seconds

Current result:

Experiments       : 3
Recovered         : 3
Within SLO        : 3
SLO breaches      : 0
SLO compliance    : 100%


Error budget      : 1%
Budget used       : 0%
Budget remaining  : 1%


SLO STATUS: HEALTHY

This allows the project to demonstrate the relationship between:

Failure
   ↓
Detection
   ↓
Recovery
   ↓
MTTR
   ↓
SLO compliance
   ↓
Error budget
📊 Prometheus Metrics

ChaosForge exposes operational metrics through the metrics service.

Current metrics include:

chaosforge_incidents_total


chaosforge_incidents_recovered_total


chaosforge_incidents_open_total


chaosforge_recovery_success_rate


chaosforge_mttr_seconds


chaosforge_mttr_fastest_seconds


chaosforge_mttr_slowest_seconds

Example:

chaosforge_incidents_total 3
chaosforge_incidents_recovered_total 3
chaosforge_incidents_open_total 0


chaosforge_recovery_success_rate 1.0


chaosforge_mttr_seconds 6.722
chaosforge_mttr_fastest_seconds 5.241
chaosforge_mttr_slowest_seconds 7.463

Prometheus is available at:

http://localhost:9090
📈 Grafana

Grafana provides the observability layer for ChaosForge.

Open:

http://localhost:3000

The dashboard is designed around key SRE indicators such as:

Total incidents
Recovery success rate
Open incidents
Average MTTR
Fastest recovery
Slowest recovery
SLO compliance
Error budget
Incident history
🖥️ ChaosForge CLI

The project includes a PowerShell-based operational CLI.

Start the platform
.\forge.ps1 start
Stop the platform
.\forge.ps1 stop
Restart the platform
.\forge.ps1 restart
Check service status
.\forge.ps1 status
Check API health
.\forge.ps1 health
View logs
.\forge.ps1 logs
💣 Chaos Experiments
Kill the API container
.\forge.ps1 chaos kill

Additional chaos experiment commands are available through the CLI:

.\forge.ps1 chaos cpu


.\forge.ps1 chaos memory
🧪 Run a Complete Experiment

ChaosForge also provides an end-to-end experiment workflow:

.\forge.ps1 experiment

The experiment performs:

1. Check API health
        ↓
2. Create incident
        ↓
3. Inject API failure
        ↓
4. Recover API
        ↓
5. Calculate MTTR
        ↓
6. Record experiment

Example:

[1/5] Checking API...
API is healthy.


[2/5] Creating incident INC-0003...
Incident created.


[3/5] Injecting API failure...
API failure injected.


[4/5] Recovering API...
Container chaosforge-api Started


[5/5] EXPERIMENT COMPLETE


Incident : INC-0003
Type     : API_DOWN
Severity : CRITICAL
Status   : RECOVERED
MTTR     : 7.462 seconds
📋 Incident History

View historical incidents:

.\forge.ps1 incidents

Example:

ID       Service Severity Status     MTTR
--       ------- -------- ------     ----
INC-0001 api     CRITICAL RECOVERED 5.241
INC-0002 api     CRITICAL RECOVERED 7.463
INC-0003 api     CRITICAL RECOVERED 7.462
📊 Reliability Report

Generate the current reliability report:

.\forge.ps1 report

Example:

CHAOSFORGE REPORT


Total incidents : 3
Recovered       : 3
Open            : 0
Success rate    : 100%


Average MTTR    : 6.722 s
Fastest MTTR    : 5.241 s
Slowest MTTR    : 7.463 s
🎯 SLO Report

Run:

.\forge.ps1 slo

Example:

CHAOSFORGE SLO


SLO target        : <30 seconds
Experiments       : 3
Recovered         : 3
Within SLO        : 3
SLO breaches      : 0
SLO compliance    : 100%


Error budget      : 1%
Budget used       : 0%
Budget remaining  : 1%


SLO STATUS: HEALTHY
🚀 Getting Started
Prerequisites

You need:

Windows
PowerShell
Docker Desktop
Docker Compose
Git

Verify Docker:

docker --version
docker compose version
Clone the repository
git clone https://github.com/franklinosuji2-afk/chaosforge.git
cd chaosforge
Start ChaosForge
.\forge.ps1 start

Check the services:

.\forge.ps1 status

Expected services:

api
metrics
prometheus
grafana
🔍 Verify the Platform
API
.\forge.ps1 health
Metrics
Invoke-WebRequest http://localhost:9101/metrics -UseBasicParsing |
    Select-Object -ExpandProperty Content
Prometheus

Open:

http://localhost:9090
Grafana

Open:

http://localhost:3000
🧪 Try Your First Chaos Experiment

Start with:

.\forge.ps1 health

Then:

.\forge.ps1 chaos kill

Confirm the API is unavailable:

.\forge.ps1 health

Run the recovery control plane:

.\recovery.ps1

Once recovery completes:

.\forge.ps1 health

Finally inspect the results:

.\forge.ps1 incidents
.\forge.ps1 report
.\forge.ps1 slo
📁 Project Structure
chaosforge/
│
├── chaos/
│   └── kill-container.ps1
│
├── detector/
│
├── docs/
│
├── monitoring/
│   └── prometheus/
│       └── prometheus.yml
│
├── recovery/
│
├── reports/
│   └── incidents.json
│
├── services/
│   ├── api/
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── requirements.txt
│   │
│   └── metrics/
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
│
├── tests/
│
├── docker-compose.yml
├── forge.ps1
├── recovery.ps1
└── .gitignore
🔐 Design Principles

ChaosForge follows several practical SRE principles:

1. Fail intentionally

Failures should be tested under controlled conditions rather than discovered unexpectedly in production.

2. Automate recovery

A recovery mechanism should be executable and measurable, not merely documented.

3. Measure reliability

Recovery success alone isn't enough. MTTR and SLO compliance provide measurable reliability indicators.

4. Observe everything

Metrics provide evidence that the recovery system is actually behaving as expected.

5. Keep experiments reproducible

The entire environment runs locally using Docker Compose and PowerShell.

💡 Engineering Lessons

ChaosForge demonstrates several important operational concepts:

Failure injection
Health checks
Incident lifecycle management
Automated remediation
Container lifecycle management
Observability
Prometheus metric design
Grafana visualization
MTTR calculation
SLO evaluation
Error-budget concepts
PowerShell automation
Docker Compose orchestration
Local-first infrastructure testing
🔮 Roadmap

The project is intentionally designed to evolve.

Phase 1 — Core Platform
 Dockerized API
 Docker Compose
 PowerShell CLI
 Health monitoring
 Container failure injection
Phase 2 — Automated Recovery
 Incident creation
 Automated recovery
 Incident persistence
 MTTR calculation
 Incident history
Phase 3 — Observability
 Prometheus
 Custom metrics exporter
 Grafana
 Recovery metrics
Phase 4 — Reliability Engineering
 SLO definition
 SLO compliance
 Error-budget tracking
 Reliability reporting
Phase 5 — Future Enhancements
 Incident-level Prometheus labels
 Historical MTTR time-series
 CPU exhaustion experiments
 Memory exhaustion experiments
 Network latency injection
 Dependency failure simulation
 Multi-service failure scenarios
 Alertmanager integration
 Automated incident summaries
 Grafana dashboard provisioning
 CI-based chaos experiments
 Kubernetes deployment
 GitOps integration
🧠 What This Project Demonstrates

ChaosForge is designed to demonstrate practical experience across:

DevOps
  │
  ├── Docker
  ├── Automation
  ├── CI/CD concepts
  └── Operational tooling
       │
       ▼
Cloud / Platform Engineering
       │
       ├── Service orchestration
       ├── Reliability
       ├── Infrastructure automation
       └── Observability
            │
            ▼
SRE
       │
       ├── Incident response
       ├── MTTR
       ├── SLOs
       ├── Error budgets
       └── Chaos Engineering
👨🏾‍💻 Author

Franklin Chinonso Osuji

Cloud & DevOps Engineer | SRE | Platform Engineering

Berlin, Germany

GitHub:
https://github.com/franklinosuji2-afk

⭐ Why ChaosForge?

ChaosForge isn't designed to demonstrate that a container can be stopped.

It demonstrates a complete reliability loop:

                    ┌───────────────┐
                    │   Healthy     │
                    │    Service    │
                    └───────┬───────┘
                            │
                     Inject Failure
                            │
                            ▼
                    ┌───────────────┐
                    │    Failure    │
                    │    Detected   │
                    └───────┬───────┘
                            │
                     Create Incident
                            │
                            ▼
                    ┌───────────────┐
                    │    Automated  │
                    │    Recovery   │
                    └───────┬───────┘
                            │
                     Measure Recovery
                            │
                            ▼
                    ┌───────────────┐
                    │  MTTR / SLO   │
                    │   Evaluation  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   Reliability │
                    │    Insight    │
                    └───────────────┘

Break it. Detect it. Recover it. Measure it. Improve it.

📜 License

This project is available for educational and portfolio purposes.




