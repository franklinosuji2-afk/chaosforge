param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Argument
)

$ErrorActionPreference = "Continue"

$IncidentFile = Join-Path $PSScriptRoot "reports\incidents.json"

New-Item `
    -ItemType Directory `
    -Force `
    -Path (Split-Path $IncidentFile) |
    Out-Null


function Get-EpochMs {

    return [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}


function Convert-EpochToIso {

    param(
        [long]$Epoch
    )

    return [DateTimeOffset]::FromUnixTimeMilliseconds(
        $Epoch
    ).ToUniversalTime().ToString("o")
}


function Read-Incidents {

    if (-not (Test-Path $IncidentFile)) {
        return @()
    }

    try {

        $raw = Get-Content `
            $IncidentFile `
            -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @()
        }

        $data = $raw | ConvertFrom-Json

        if ($null -eq $data) {
            return @()
        }

        if ($data -is [System.Array]) {
            return @($data)
        }

        if ($data.PSObject.Properties["incident_id"]) {
            return @($data)
        }

        return @()
    }
    catch {

        Write-Host `
            "Could not read incident history." `
            -ForegroundColor Red

        return @()
    }
}


function Write-Incidents {

    param(
        [array]$Incidents
    )

    $json = ConvertTo-Json `
        -InputObject ([array]$Incidents) `
        -Depth 20

    $json |
        Set-Content `
            -Path $IncidentFile `
            -Encoding UTF8
}


function Get-NextIncidentId {

    param(
        [array]$Incidents
    )

    $highest = 0

    foreach ($incident in $Incidents) {

        if ($incident.incident_id -match "^INC-(\d+)$") {

            $number = [int]$Matches[1]

            if ($number -gt $highest) {
                $highest = $number
            }
        }
    }

    return "INC-{0:D4}" -f ($highest + 1)
}


function Test-Api {

    try {

        Invoke-RestMethod `
            -Uri "http://localhost:8000/health" `
            -TimeoutSec 3 |
            Out-Null

        return $true
    }
    catch {

        return $false
    }
}


function Show-Banner {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "              CHAOSFORGE               " -ForegroundColor Cyan
    Write-Host "       SRE & Chaos Engineering Lab      " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}


function Run-Experiment {

    Show-Banner

    Write-Host "        CHAOSFORGE EXPERIMENT           " -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""

    # --------------------------------------------------------
    # Verify API
    # --------------------------------------------------------

    Write-Host "[1/5] Checking API..." -ForegroundColor Yellow

    if (-not (Test-Api)) {

        Write-Host ""
        Write-Host "API is unavailable." -ForegroundColor Red
        Write-Host ""
        Write-Host "Start it with:"
        Write-Host "  docker compose start api"
        Write-Host ""

        return
    }

    Write-Host "API is healthy." -ForegroundColor Green


    # --------------------------------------------------------
    # Read history
    # --------------------------------------------------------

    $incidents = @(Read-Incidents)

    $incidentId =
        Get-NextIncidentId $incidents


    # --------------------------------------------------------
    # Create incident
    # --------------------------------------------------------

    $detectedEpoch =
        Get-EpochMs

    $incident = [ordered]@{

        incident_id = $incidentId

        type = "API_DOWN"

        service = "api"

        severity = "CRITICAL"

        detected_at =
            Convert-EpochToIso $detectedEpoch

        detected_epoch_ms =
            $detectedEpoch

        status = "OPEN"

        recovery_action = $null

        recovered_at = $null

        recovered_epoch_ms = $null

        mttr_seconds = $null
    }


    Write-Host ""
    Write-Host "[2/5] Creating incident $incidentId..." `
        -ForegroundColor Yellow

    $incidents = @($incidents) + @($incident)

    Write-Incidents $incidents

    Write-Host "Incident created." `
        -ForegroundColor Green


    # --------------------------------------------------------
    # Inject failure
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "[3/5] Injecting API failure..." `
        -ForegroundColor Yellow

    docker kill chaosforge-api | Out-Null

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "Failed to kill API container." `
            -ForegroundColor Red

        return
    }

    Write-Host "API failure injected." `
        -ForegroundColor Red


    # --------------------------------------------------------
    # Recovery
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "[4/5] Recovering API..." `
        -ForegroundColor Yellow

    $recoveryStart =
        Get-EpochMs

    docker compose start api | Out-Null

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "Recovery command failed." `
            -ForegroundColor Red

        return
    }


    $recovered = $false

    for ($attempt = 1; $attempt -le 20; $attempt++) {

        Start-Sleep -Milliseconds 500

        if (Test-Api) {

            $recovered = $true

            break
        }
    }


    if (-not $recovered) {

        Write-Host ""
        Write-Host "API did not recover." `
            -ForegroundColor Red

        return
    }


    # --------------------------------------------------------
    # Calculate MTTR
    # --------------------------------------------------------

    $recoveredEpoch =
        Get-EpochMs

    $durationMs =
        $recoveredEpoch -
        $detectedEpoch

    $mttr =
        [Math]::Round(
            ($durationMs / 1000.0),
            3
        )


    # --------------------------------------------------------
    # Update incident
    # --------------------------------------------------------

    $incident.status =
        "RECOVERED"

    $incident.recovery_action =
        "docker compose start api"

    $incident.recovered_epoch_ms =
        $recoveredEpoch

    $incident.recovered_at =
        Convert-EpochToIso $recoveredEpoch

    $incident.mttr_seconds =
        $mttr


    for ($i = 0; $i -lt $incidents.Count; $i++) {

        if (
            $incidents[$i].incident_id `
            -eq $incidentId
        ) {

            $incidents[$i] =
                $incident

            break
        }
    }


    Write-Incidents $incidents


    # --------------------------------------------------------
    # Result
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "[5/5] EXPERIMENT COMPLETE" `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host " Incident : $incidentId"
    Write-Host " Type     : API_DOWN"
    Write-Host " Severity : CRITICAL"
    Write-Host " Status   : RECOVERED"
    Write-Host " MTTR     : $mttr seconds"
    Write-Host "----------------------------------------"
    Write-Host ""

    Write-Host "API is healthy again." `
        -ForegroundColor Green

    Write-Host ""
}


Show-Banner

switch ($Command) {

    "start" {

        docker compose up -d --build
    }


    "stop" {

        docker compose down
    }


    "restart" {

        docker compose down

        docker compose up -d --build
    }


    "status" {

        docker compose ps
    }


    "logs" {

        docker compose logs --tail=100
    }


    "health" {

        try {

            $result =
                Invoke-RestMethod `
                    -Uri "http://localhost:8000/health" `
                    -TimeoutSec 5

            Write-Host `
                "API: HEALTHY" `
                -ForegroundColor Green

            $result |
                ConvertTo-Json
        }
        catch {

            Write-Host `
                "API: UNAVAILABLE" `
                -ForegroundColor Red
        }
    }


    "chaos" {

        switch ($Argument) {

            "cpu" {

                & ".\chaos\cpu.ps1"
            }


            "memory" {

                & ".\chaos\memory.ps1"
            }


            "kill" {

                & ".\chaos\kill-container.ps1"
            }


            default {

                Write-Host `
                    "Available chaos experiments:" `
                    -ForegroundColor Yellow

                Write-Host "  cpu"
                Write-Host "  memory"
                Write-Host "  kill"
            }
        }
    }


    "experiment" {

        Run-Experiment
    }


    "incidents" {

        $incidents =
            Read-Incidents

        if ($incidents.Count -eq 0) {

            Write-Host `
                "No incidents recorded." `
                -ForegroundColor Yellow

            break
        }


        Write-Host `
            "CHAOSFORGE INCIDENT HISTORY" `
            -ForegroundColor Cyan

        Write-Host ""

        $incidents |
            ForEach-Object {

                [PSCustomObject]@{

                    ID =
                        $_.incident_id

                    Service =
                        $_.service

                    Severity =
                        $_.severity

                    Status =
                        $_.status

                    MTTR =
                        $_.mttr_seconds
                }

            } |
            Format-Table -AutoSize
    }


    "slo" {

        $incidents = @(Read-Incidents)

        $targetSeconds = 30

        $total = $incidents.Count

        $recovered = @(
            $incidents |
                Where-Object {
                    $_.status -eq "RECOVERED" -and
                    $null -ne $_.mttr_seconds
                }
        )

        $withinSlo = @(
            $recovered |
                Where-Object {
                    [double]$_.mttr_seconds -le $targetSeconds
                }
        )

        $breached = @(
            $recovered |
                Where-Object {
                    [double]$_.mttr_seconds -gt $targetSeconds
                }
        )

        if ($recovered.Count -gt 0) {

            $compliance = [Math]::Round(
                ($withinSlo.Count / $recovered.Count) * 100,
                2
            )

        }
        else {

            $compliance = 100
        }

        $errorBudgetPercent = 1.0

        $allowedBreaches = [Math]::Floor(
            $recovered.Count * ($errorBudgetPercent / 100)
        )

        $budgetUsed = if ($recovered.Count -gt 0) {

            [Math]::Round(
                ($breached.Count / $recovered.Count) * 100,
                2
            )

        }
        else {
            0
        }

        $budgetRemaining = [Math]::Max(
            0,
            [Math]::Round(
                $errorBudgetPercent - $budgetUsed,
                2
            )
        )


        Write-Host ""
        Write-Host "========================================" `
            -ForegroundColor Cyan

        Write-Host "           CHAOSFORGE SLO               " `
            -ForegroundColor Cyan

        Write-Host "========================================" `
            -ForegroundColor Cyan

        Write-Host ""

        Write-Host "SLO target        : <$targetSeconds seconds"
        Write-Host "Experiments       : $total"
        Write-Host "Recovered         : $($recovered.Count)"
        Write-Host "Within SLO        : $($withinSlo.Count)"
        Write-Host "SLO breaches      : $($breached.Count)"
        Write-Host "SLO compliance    : $compliance%"
        Write-Host ""
        Write-Host "Error budget      : $errorBudgetPercent%"
        Write-Host "Budget used       : $budgetUsed%"
        Write-Host "Budget remaining  : $budgetRemaining%"
        Write-Host ""

        if ($breached.Count -eq 0) {

            Write-Host `
                "SLO STATUS: HEALTHY" `
                -ForegroundColor Green
        }
        else {

            Write-Host `
                "SLO STATUS: BREACHED" `
                -ForegroundColor Red
        }

        Write-Host ""
    }

    "report" {

        $incidents =
            Read-Incidents


        if ($incidents.Count -eq 0) {

            Write-Host `
                "No incidents recorded." `
                -ForegroundColor Yellow

            break
        }


        $recovered =
            @(
                $incidents |
                    Where-Object {
                        $_.status -eq "RECOVERED"
                    }
            )


        $open =
            @(
                $incidents |
                    Where-Object {
                        $_.status -eq "OPEN"
                    }
            )


        $mttrs =
            @(
                $recovered |
                    Where-Object {
                        $null -ne $_.mttr_seconds
                    } |
                    ForEach-Object {
                        [double]$_.mttr_seconds
                    }
            )


        if ($mttrs.Count -gt 0) {

            $average =
                [Math]::Round(
                    (($mttrs | Measure-Object -Average).Average),
                    3
                )

            $fastest =
                [Math]::Round(
                    (($mttrs | Measure-Object -Minimum).Minimum),
                    3
                )

            $slowest =
                [Math]::Round(
                    (($mttrs | Measure-Object -Maximum).Maximum),
                    3
                )
        }
        else {

            $average = 0
            $fastest = 0
            $slowest = 0
        }


        $total =
            $incidents.Count


        $successRate =
            if ($total -gt 0) {
                [Math]::Round(
                    ($recovered.Count / $total),
                    4
                )
            }
            else {
                0
            }


        Write-Host ""
        Write-Host "========================================" `
            -ForegroundColor Cyan

        Write-Host "          CHAOSFORGE REPORT             " `
            -ForegroundColor Cyan

        Write-Host "========================================" `
            -ForegroundColor Cyan

        Write-Host ""

        Write-Host "Total incidents : $total"
        Write-Host "Recovered       : $($recovered.Count)"
        Write-Host "Open            : $($open.Count)"
        Write-Host "Success rate    : $($successRate * 100)%"
        Write-Host ""
        Write-Host "Average MTTR    : $average s"
        Write-Host "Fastest MTTR    : $fastest s"
        Write-Host "Slowest MTTR    : $slowest s"

        Write-Host ""
    }


    "dashboard" {

        Start-Process `
            "http://localhost:3000"
    }


    "prometheus" {

        Start-Process `
            "http://localhost:9090"
    }


    default {

        Write-Host "Usage:" `
            -ForegroundColor Yellow

        Write-Host ""

        Write-Host "  .\forge.ps1 start"
        Write-Host "  .\forge.ps1 stop"
        Write-Host "  .\forge.ps1 restart"
        Write-Host "  .\forge.ps1 status"
        Write-Host "  .\forge.ps1 health"
        Write-Host "  .\forge.ps1 logs"

        Write-Host ""

        Write-Host "Chaos:"
        Write-Host "  .\forge.ps1 chaos cpu"
        Write-Host "  .\forge.ps1 chaos memory"
        Write-Host "  .\forge.ps1 chaos kill"

        Write-Host ""

        Write-Host "Experiments:"
        Write-Host "  .\forge.ps1 experiment"
        Write-Host "  .\forge.ps1 incidents"
        Write-Host "  .\forge.ps1 report"
        Write-Host "  .\forge.ps1 slo"

        Write-Host ""

        Write-Host "Dashboards:"
        Write-Host "  .\forge.ps1 dashboard"
        Write-Host "  .\forge.ps1 prometheus"
    }
}


