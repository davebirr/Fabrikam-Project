#!/usr/bin/env pwsh
# Start-Services.ps1 - Reliably start all Fabrikam services

param(
    [switch]$Stop,
    [switch]$Status
)

$ErrorActionPreference = "Stop"

# Service configurations
$services = @(
    @{
        Name = "FabrikamApi"
        Project = "FabrikamApi\src\FabrikamApi.csproj"
        Port = 7297
        Color = "Green"
    },
    @{
        Name = "FabrikamMcp"
        Project = "FabrikamMcp\src\FabrikamMcp.csproj"
        Port = 5001
        Color = "Cyan"
    },
    @{
        Name = "FabrikamSimulator"
        Project = "FabrikamSimulator\src\FabrikamSimulator.csproj"
        Port = 5152
        Color = "Yellow"
    }
)

function Show-Status {
    Write-Host "`n=== Fabrikam Services Status ===" -ForegroundColor Magenta
    
    $processes = Get-Process | Where-Object { $_.ProcessName -like "*Fabrikam*" }
    
    foreach ($service in $services) {
        $proc = $processes | Where-Object { $_.ProcessName -eq $service.Name }
        
        if ($proc) {
            $uptime = (Get-Date) - $proc.StartTime
            Write-Host "✅ $($service.Name) - Running (PID: $($proc.Id), Uptime: $([math]::Round($uptime.TotalMinutes, 1))m)" -ForegroundColor $service.Color
        } else {
            Write-Host "❌ $($service.Name) - Not running" -ForegroundColor Red
        }
    }
    Write-Host ""
}

function Stop-Services {
    Write-Host "`n=== Stopping All Services ===" -ForegroundColor Red
    
    $processes = Get-Process | Where-Object { $_.ProcessName -like "*Fabrikam*" }
    
    if ($processes) {
        $processes | ForEach-Object {
            Write-Host "Stopping $($_.ProcessName) (PID: $($_.Id))..." -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force
        }
        Start-Sleep -Seconds 1
        Write-Host "✅ All services stopped" -ForegroundColor Green
    } else {
        Write-Host "No services running" -ForegroundColor Gray
    }
}

function Start-Services {
    Write-Host "`n=== Starting Fabrikam Services ===" -ForegroundColor Magenta
    
    # Stop any existing processes first
    $existing = Get-Process | Where-Object { $_.ProcessName -like "*Fabrikam*" }
    if ($existing) {
        Write-Host "Stopping existing processes..." -ForegroundColor Yellow
        Stop-Services
    }
    
    # Start each service in a new PowerShell window
    foreach ($service in $services) {
        Write-Host "Starting $($service.Name)..." -ForegroundColor $service.Color
        
        $command = "dotnet run --project $($service.Project) --launch-profile https"
        
        Start-Process pwsh -ArgumentList "-NoExit", "-Command", $command -WindowStyle Minimized
        
        Start-Sleep -Milliseconds 500  # Stagger starts slightly
    }
    
    Write-Host "`nWaiting for services to initialize..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    
    Show-Status
    
    Write-Host "💡 Tip: Services are running in minimized PowerShell windows" -ForegroundColor Cyan
    Write-Host "💡 Use 'Stop-Services.ps1' or './Start-Services.ps1 -Stop' to stop them" -ForegroundColor Cyan
}

# Main execution
if ($Stop) {
    Stop-Services
} elseif ($Status) {
    Show-Status
} else {
    Start-Services
}
