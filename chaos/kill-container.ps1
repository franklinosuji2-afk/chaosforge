param(
    [string]$Service = "api"
)

$container = "chaosforge-$Service"

Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "       CHAOSFORGE FAILURE TEST          " -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

Write-Host "Target container: $container" -ForegroundColor Yellow
Write-Host ""

$containerState = docker inspect `
    --format "{{.State.Status}}" `
    $container 2>$null

if (-not $containerState) {

    Write-Host "ERROR: Container does not exist." `
        -ForegroundColor Red

    exit 1
}

if ($containerState -ne "running") {

    Write-Host "Container is already $containerState." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Start it with:"
    Write-Host "  docker compose up -d $Service"

    exit 1
}

Write-Host "Current state: $containerState" `
    -ForegroundColor Green

Write-Host ""
Write-Host "Injecting container failure..." `
    -ForegroundColor Yellow

docker kill $container

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "Failure injection failed." `
        -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "FAILURE INJECTED" `
    -ForegroundColor Red

Write-Host ""
Write-Host "Container '$container' has been killed." `
    -ForegroundColor Yellow

Write-Host ""
Write-Host "Check:"
Write-Host "  .\forge.ps1 status"
Write-Host "  .\forge.ps1 health"
Write-Host ""
