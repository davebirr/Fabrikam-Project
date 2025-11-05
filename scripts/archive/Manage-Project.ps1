# Project Management Script for Fabrikam Project
# 
# ⚠️ DEPRECATED: This script has been consolidated into the modular test architecture
# 
# NEW USAGE:
#   .\test.ps1 -Status    # Show project status (replaces .\Manage-Project.ps1 status)
#   .\test.ps1 -Stop      # Stop all servers (replaces .\Manage-Project.ps1 stop)
#
# The modular architecture provides enhanced functionality with the same interface
# See: scripts/Test-Development-Modular.ps1 and scripts/testing/Test-ServerManagement.ps1
#
param(
    [string]$Action = "status"
)

Write-Host ""
Write-Host "⚠️  DEPRECATION NOTICE" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script has been consolidated into the modular test architecture." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please use these commands instead:" -ForegroundColor Cyan
Write-Host "  .\test.ps1 -Status    # Show project status" -ForegroundColor White
Write-Host "  .\test.ps1 -Stop      # Stop all servers" -ForegroundColor White
Write-Host "  .\test.ps1 -Quick     # Quick test suite" -ForegroundColor White
Write-Host ""
Write-Host "Running equivalent command using modular architecture..." -ForegroundColor Green
Write-Host ""

# Redirect to the new modular approach
switch ($Action.ToLower()) {
    "status" { 
        & "$PSScriptRoot\test.ps1" -Status
    }
    "stop" { 
        & "$PSScriptRoot\test.ps1" -Stop
    }
    default { 
        Write-Host "Legacy Usage: .\Manage-Project.ps1 [status|stop]" -ForegroundColor Gray
        Write-Host "New Usage: .\test.ps1 -Status | -Stop" -ForegroundColor Green
        & "$PSScriptRoot\test.ps1" -Help
    }
}

# Legacy functions below - kept for reference but deprecated

function Show-ProjectStatus {
    Write-Host "📊 Fabrikam Project Status" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Check API Server (Port 7297)
    $apiPort = Get-NetTCPConnection -LocalPort 7297 -ErrorAction SilentlyContinue
    if ($apiPort) {
        Write-Host "✅ API Server: Running on port 7297" -ForegroundColor Green
    } else {
        Write-Host "❌ API Server: Not running on port 7297" -ForegroundColor Red
    }
    
    # Check MCP Server (Port 5000/5001)
    $mcpPort5000 = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
    $mcpPort5001 = Get-NetTCPConnection -LocalPort 5001 -ErrorAction SilentlyContinue
    if ($mcpPort5000 -or $mcpPort5001) {
        Write-Host "✅ MCP Server: Running on ports 5000/5001" -ForegroundColor Green
    } else {
        Write-Host "❌ MCP Server: Not running on ports 5000/5001" -ForegroundColor Red
    }
    
    # Show all dotnet processes
    $dotnetProcesses = Get-Process dotnet -ErrorAction SilentlyContinue
    if ($dotnetProcesses) {
        Write-Host "`n🔍 Active .NET Processes:" -ForegroundColor Yellow
        $dotnetProcesses | ForEach-Object {
            Write-Host "   PID: $($_.Id) - $($_.ProcessName)" -ForegroundColor White
        }
    } else {
        Write-Host "`n❌ No .NET processes running" -ForegroundColor Red
    }
    
    Write-Host "`n📋 Available VS Code Tasks:" -ForegroundColor Cyan
    Write-Host "   - 🌐 Start Both Servers" -ForegroundColor White
    Write-Host "   - 🚀 Start API Server" -ForegroundColor White
    Write-Host "   - 🤖 Start MCP Server" -ForegroundColor White
    Write-Host "   - 🛑 Stop All Servers" -ForegroundColor White
    Write-Host "   - 🏗️ Build Solution" -ForegroundColor White
}

function Stop-AllServers {
    Write-Host "🛑 Stopping all servers..." -ForegroundColor Yellow
    
    $dotnetProcesses = Get-Process dotnet -ErrorAction SilentlyContinue
    if ($dotnetProcesses) {
        Write-Host "Stopping .NET processes..." -ForegroundColor Yellow
        $dotnetProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "✅ All .NET processes stopped" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No .NET processes to stop" -ForegroundColor Blue
    }
}

switch ($Action.ToLower()) {
    "status" { Show-ProjectStatus }
    "stop" { Stop-AllServers }
    default { 
        Write-Host "Usage: .\Manage-Project.ps1 [status|stop]" -ForegroundColor Yellow
        Write-Host "  status - Show project status"
        Write-Host "  stop   - Stop all servers"
    }
}
