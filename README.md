# ChaosForge

## SRE and Chaos Engineering Lab

ChaosForge is a local-first reliability engineering lab for controlled failure injection, incident detection, automated recovery, MTTR measurement, SLO evaluation, and observability.

The project combines Docker Compose, PowerShell automation, Python/FastAPI services, Prometheus, Grafana, incident persistence, and recovery workflows.

## What it demonstrates

- Controlled container failure injection
- Health-check based incident detection
- Automated service recovery
- MTTR measurement
- SLO and error-budget evaluation
- Incident history and reporting
- Prometheus metrics
- Grafana dashboards
- Reproducible local SRE experiments

## Architecture

```text
PowerShell CLI
     |
     +-------------------+
     |                   |
     v                   v
Chaos Experiments     Operations
     |                   |
     +---------+---------+
               |
               v
        Docker Compose
               |
     +---------+---------+
     |         |         |
     v         v         v
   API      Metrics   Prometheus
     |         |         |
     |         |         v
     |         +----> Grafana
     |
     v
Incident / Recovery Data
```

## Repository structure

```text
chaosforge/
â”œâ”€â”€ chaos/
â”œâ”€â”€ monitoring/
â”œâ”€â”€ reports/
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ api/
â”‚   â””â”€â”€ metrics/
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/
â”‚       â””â”€â”€ ci.yml
â”œâ”€â”€ docker-compose.yml
â”œâ”€â”€ forge.ps1
â”œâ”€â”€ recovery.ps1
â””â”€â”€ README.md
```

## Quick start

Prerequisites:

- Docker Desktop
- Docker Compose
- PowerShell 7 recommended

Start the platform:

```powershell
.\forge.ps1 start
```

Check status:

```powershell
.\forge.ps1 status
```

Check API health:

```powershell
.\forge.ps1 health
```

Open Grafana:

```powershell
.\forge.ps1 dashboard
```

Open Prometheus:

```powershell
.\forge.ps1 prometheus
```

Stop the platform:

```powershell
.\forge.ps1 stop
```

## Chaos experiments

Available experiments include:

```powershell
.\forge.ps1 chaos cpu
.\forge.ps1 chaos memory
.\forge.ps1 chaos kill
```

Run the complete failure and recovery experiment:

```powershell
.\forge.ps1 experiment
```

The experiment records the incident, injects a controlled API failure, starts the service again, waits for health recovery, and calculates MTTR.

## Reliability reporting

View incident history:

```powershell
.\forge.ps1 incidents
```

Generate a reliability report:

```powershell
.\forge.ps1 report
```

Evaluate the configured recovery SLO:

```powershell
.\forge.ps1 slo
```

## Observability

Prometheus collects application and exporter metrics. Grafana provides local dashboards for operational visibility.

Default local endpoints:

| Service | URL |
| --- | --- |
| API | http://localhost:8000 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 |
| API health | http://localhost:8000/health |

## CI

GitHub Actions validates:

1. Python service syntax
2. Docker Compose configuration
3. PowerShell syntax

The workflow is located at:

```text
.github/workflows/ci.yml
```

## Engineering focus

ChaosForge is intended to demonstrate practical SRE concepts rather than a production chaos platform. The experiments are designed to run locally and safely against the project's own containers.

## License

See the repository license and source files for project-specific terms.