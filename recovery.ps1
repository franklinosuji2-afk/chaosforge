param(
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = "Continue"

$IncidentFile = Join-Path $PSScriptRoot "reports\incidents.json"

New-Item `
    -ItemType Directory `
    -Force `
    -Path (Split-Path $IncidentFile) |
    Out-Null


# ============================================================
# TIME
# ============================================================

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


# ============================================================
# INCIDENT STORAGE
# ============================================================

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

        # New format: array
        if ($data -is [System.Array]) {

            return @($data)
        }

        # Backwards compatibility:
        # old single incident object
        if (
            $data.PSObject.Properties["incident_id"]
        ) {

            return @($data)
        }

        return @()
    }
    catch {

        Write-Host `
            "[STORAGE] Failed to read incidents.json" `
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


# ============================================================
# API HEALTH
# ============================================================

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


# ============================================================
# INCIDENT CREATION
# ============================================================

function New-Incident {

    param(
        [array]$Incidents
    )

    $epoch = Get-EpochMs

    $id = Get-NextIncidentId $Incidents

    return [ordered]@{

        incident_id = $id

        type = "API_DOWN"

        service = "api"

        severity = "CRITICAL"

        detected_at = Convert-EpochToIso $epoch

        detected_epoch_ms = $epoch

        status = "OPEN"

        recovery_action = $null

        recovered_at = $null

        recovered_epoch_ms = $null

        mttr_seconds = $null
    }
}


# ============================================================
# API RECOVERY
# ============================================================

function Recover-Api {

    Write-Host ""
    Write-Host `
        "[RECOVERY] Starting API recovery..." `
        -ForegroundColor Yellow

    docker compose start api

    if ($LASTEXITCODE -ne 0) {

        Write-Host `
            "[RECOVERY] Failed to start API." `
            -ForegroundColor Red

        return $false
    }

    Write-Host `
        "[RECOVERY] Waiting for API..." `
        -ForegroundColor Yellow

    for ($attempt = 1; $attempt -le 15; $attempt++) {

        Start-Sleep -Seconds 1

        if (Test-Api) {

            Write-Host `
                "[RECOVERY] API recovered" `
                -ForegroundColor Green

            return $true
        }
    }

    Write-Host `
        "[RECOVERY] API recovery failed" `
        -ForegroundColor Red

    return $false
}


# ============================================================
# COMPLETE INCIDENT
# ============================================================

function Complete-Incident {

    param(
        $Incident,
        [array]$Incidents
    )

    $recoveredEpoch = Get-EpochMs

    $detectedEpoch =
        [long]$Incident.detected_epoch_ms

    $durationMs =
        $recoveredEpoch - $detectedEpoch

    if ($durationMs -lt 0) {

        Write-Host `
            "[METRICS] Invalid MTTR calculation." `
            -ForegroundColor Red

        return
    }

    $mttr = [Math]::Round(
        ($durationMs / 1000.0),
        3
    )


    $Incident.status =
        "RECOVERED"

    $Incident.recovery_action =
        "docker compose start api"

    $Incident.recovered_epoch_ms =
        $recoveredEpoch

    $Incident.recovered_at =
        Convert-EpochToIso $recoveredEpoch

    $Incident.mttr_seconds =
        $mttr


    # Find the matching incident and replace it
    for ($i = 0; $i -lt $Incidents.Count; $i++) {

        if (
            $Incidents[$i].incident_id `
            -eq $Incident.incident_id
        ) {

            $Incidents[$i] = $Incident

            break
        }
    }


    Write-Incidents $Incidents


    Write-Host ""
    Write-Host `
        "[INCIDENT] $($Incident.incident_id) RECOVERED" `
        -ForegroundColor Green

    Write-Host `
        "[INCIDENT] MTTR: $mttr seconds" `
        -ForegroundColor Green
}


# ============================================================
# BANNER
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CHAOSFORGE CONTROL PLANE         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Monitoring: http://localhost:8000/health"
Write-Host "Interval:   $IntervalSeconds seconds"
Write-Host "Reports:    $IncidentFile"

Write-Host ""


# ============================================================
# CONTROL LOOP
# ============================================================

while ($true) {

    $healthy = Test-Api

    $incidents = Read-Incidents

    $openIncident = $null

    foreach ($item in $incidents) {

        if ($item.status -eq "OPEN") {

            $openIncident = $item

            break
        }
    }


    # ========================================================
    # HEALTHY
    # ========================================================

    if ($healthy) {

        Write-Host `
            "$(Get-Date -Format 'HH:mm:ss') [OK] API healthy" `
            -ForegroundColor Green


        # API recovered outside the controller
        if ($null -ne $openIncident) {

            Write-Host ""
            Write-Host `
                "[RECOVERY] Existing incident recovered externally" `
                -ForegroundColor Yellow

            Complete-Incident `
                $openIncident `
                $incidents
        }
    }


    # ========================================================
    # DOWN
    # ========================================================

    else {

        Write-Host `
            "$(Get-Date -Format 'HH:mm:ss') [ALERT] API DOWN" `
            -ForegroundColor Red


        if ($null -ne $openIncident) {

            Write-Host `
                "[INCIDENT] Existing incident $($openIncident.incident_id)" `
                -ForegroundColor Yellow
        }

        else {

            $incident =
                New-Incident $incidents


            $incidents += $incident

            Write-Incidents $incidents


            Write-Host ""
            Write-Host `
                "[INCIDENT] $($incident.incident_id)" `
                -ForegroundColor Red

            Write-Host `
                "[INCIDENT] API_DOWN / CRITICAL" `
                -ForegroundColor Red


            $recovered =
                Recover-Api


            if ($recovered) {

                # Reload in case the file changed
                $incidents =
                    Read-Incidents

                Complete-Incident `
                    $incident `
                    $incidents
            }
        }
    }


    Start-Sleep `
        -Seconds $IntervalSeconds
}

