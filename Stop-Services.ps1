#!/usr/bin/env pwsh
# Stop-Services.ps1 - Stop all Fabrikam services

Write-Host "`n=== Stopping All Fabrikam Services ===" -ForegroundColor Red

$processes = Get-Process | Where-Object { $_.ProcessName -like "*Fabrikam*" }

if ($processes) {
    $processes | ForEach-Object {
        Write-Host "Stopping $($_.ProcessName) (PID: $($_.Id))..." -ForegroundColor Yellow
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep -Seconds 1
    
    # Verify they stopped
    $remaining = Get-Process | Where-Object { $_.ProcessName -like "*Fabrikam*" }
    if (-not $remaining) {
        Write-Host "✅ All services stopped successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some services may still be running" -ForegroundColor Yellow
    }
} else {
    Write-Host "No Fabrikam services running" -ForegroundColor Gray
}

Write-Host ""
