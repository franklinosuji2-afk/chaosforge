# ChaosForge

## SRE and Chaos Engineering Lab

ChaosForge is a local-first Site Reliability Engineering (SRE) and chaos engineering lab for practicing controlled failure injection, incident detection, automated recovery, MTTR measurement, SLO evaluation, and observability.

The project combines Docker Compose, PowerShell automation, Python/FastAPI services, Prometheus, Grafana, incident persistence, and recovery workflows to demonstrate practical reliability engineering patterns in a reproducible local environment.

## What It Demonstrates

- Controlled container failure injection
- Health-check-based incident detection
- Automated service recovery
- Mean Time To Recovery (MTTR) measurement
- Service Level Objective (SLO) evaluation
- Error-budget evaluation
- Incident history and reporting
- Prometheus metrics collection
- Grafana dashboards
- Reproducible local SRE experiments
- Operational automation with PowerShell

## Architecture

```text
                         +------------------+
                         |  PowerShell CLI  |
                         |    forge.ps1     |
                         +--------+---------+
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
            +---------------+           +---------------+
            | Chaos         |           | Operations    |
            | Experiments   |           | & Recovery    |
            +-------+-------+           +-------+-------+
                    |                           |
                    +-------------+-------------+
                                  |
                                  v
                         +------------------+
                         | Docker Compose   |
                         +--------+---------+
                                  |
              +-------------------+-------------------+
              |                   |                   |
              v                   v                   v
        +-----------+       +-----------+       +-----------+
        | API       |       | Metrics   |       | Prometheus|
        | :8000     |       | :9101     |       | :9090     |
        +-----+-----+       +-----+-----+       +-----+-----+
              |                   |                   |
              |                   +-------------------+
              |                                       |
              |                                       v
              |                                +-----------+
              |                                | Grafana   |
              |                                | :3000     |
              |                                +-----------+
              |
              v
        +----------------------+
        | Incident / Recovery  |
        | Data and Reports     |
        +----------------------+

chaosforge/
|-- chaos/
|-- monitoring/
|-- reports/
|-- services/
|   |-- api/
|   `-- metrics/
|-- .github/
|   `-- workflows/
|       `-- ci.yml
|-- docker-compose.yml
|-- forge.ps1
|-- recovery.ps1
`-- README.md
Technology Stack
Area	Technology
API	Python, FastAPI
Containers	Docker, Docker Compose
Automation	PowerShell
Metrics	Prometheus
Dashboards	Grafana
Reliability	SRE, SLOs, MTTR, error budgets
Platform	Local-first development environment
Quick Start
Prerequisites
Docker Desktop
Docker Compose
PowerShell 7 recommended
Start the Platform
.\forge.ps1 start
Check Status
.\forge.ps1 status
Check API Health
.\forge.ps1 health
Open Grafana
.\forge.ps1 dashboard
Open Prometheus
.\forge.ps1 prometheus
Stop the Platform
.\forge.ps1 stop
Chaos Experiments

ChaosForge provides controlled failure scenarios for testing recovery workflows.

CPU Experiment
.\forge.ps1 chaos cpu
Memory Experiment
.\forge.ps1 chaos memory
Container Failure
.\forge.ps1 chaos kill
Complete Failure and Recovery Experiment
.\forge.ps1 experiment

The experiment records the incident, injects a controlled API failure, starts the service again, waits for health recovery, and calculates MTTR.

Reliability Reporting
View Incident History
.\forge.ps1 incidents
Generate a Reliability Report
.\forge.ps1 report
Evaluate the Recovery SLO
.\forge.ps1 slo

These workflows provide a local view of incident history, recovery performance, and configured reliability objectives.

Observability

Prometheus collects application and exporter metrics, while Grafana provides local dashboards for operational visibility.

Local Endpoints
Service	URL
API	http://localhost:8000
API Health	http://localhost:8000/health
Prometheus	http://localhost:9090
Grafana	http://localhost:3000
CI

GitHub Actions validates the repository on pushes and pull requests.

The CI workflow validates:

Python service syntax
Docker Compose configuration
PowerShell script syntax

Workflow:

.github/workflows/ci.yml
Engineering Focus

ChaosForge is designed as a practical SRE and chaos engineering lab rather than a production chaos platform.

The project focuses on demonstrating how engineers can:

Introduce controlled failures
Detect service degradation
Execute recovery workflows
Measure recovery time
Track SLO performance
Evaluate error-budget consumption
Observe system behavior through metrics and dashboards
Automate operational workflows

All experiments are designed to run locally against the project's own containers.

Local-First Design

ChaosForge is designed to operate without requiring external cloud infrastructure.

This makes it suitable for repeatable SRE experiments, reliability testing, and infrastructure practice without introducing cloud infrastructure costs.

License

See the repository license and source files for project-specific terms.
