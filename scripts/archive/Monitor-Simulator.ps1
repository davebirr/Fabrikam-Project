#!/usr/bin/env pwsh
<#
.SYNOPSIS
Monitor the FabrikamSimulator working against the production API

.DESCRIPTION
Displays real-time status of the simulator workers and their effect on the API data

.PARAMETER Interval
Number of seconds between status checks (default: 30)

.PARAMETER Count
Number of times to check status (default: continuous until Ctrl+C)

.EXAMPLE
.\Monitor-Simulator.ps1
# Monitor continuously every 30 seconds

.EXAMPLE
.\Monitor-Simulator.ps1 -Interval 60 -Count 10
# Monitor 10 times with 60 second intervals
#>

param(
    [int]$Interval = 30,
    [int]$Count = 0  # 0 means continuous
)

$simUrl = "https://fabrikam-sim-development-tzjeje.azurewebsites.net"
$apiUrl = "https://fabrikam-api-development-tzjeje.azurewebsites.net"

function Get-SimulatorStatus {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Fabrikam Simulator Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Get Simulator Status
    try {
        $status = Invoke-RestMethod -Uri "$simUrl/api/simulator/status" -ErrorAction Stop
        
        Write-Host "`n📊 Worker Status:" -ForegroundColor Yellow
        Write-Host "  ┌─ Order Progression: " -NoNewline -ForegroundColor White
        if ($status.orderProgression.enabled) {
            Write-Host "🟢 RUNNING" -ForegroundColor Green -NoNewline
            Write-Host " (Runs: $($status.orderProgression.runCount))" -ForegroundColor Gray
        } else {
            Write-Host "🔴 STOPPED" -ForegroundColor Red
        }
        
        Write-Host "  ├─ Order Generator: " -NoNewline -ForegroundColor White
        if ($status.orderGenerator.enabled) {
            Write-Host "🟢 RUNNING" -ForegroundColor Green -NoNewline
            Write-Host " (Runs: $($status.orderGenerator.runCount))" -ForegroundColor Gray
        } else {
            Write-Host "🔴 STOPPED" -ForegroundColor Red
        }
        
        Write-Host "  └─ Ticket Generator: " -NoNewline -ForegroundColor White
        if ($status.ticketGenerator.enabled) {
            Write-Host "🟢 RUNNING" -ForegroundColor Green -NoNewline
            Write-Host " (Runs: $($status.ticketGenerator.runCount))" -ForegroundColor Gray
        } else {
            Write-Host "🔴 STOPPED" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "`n❌ Simulator Error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Get API Data
    try {
        # First, get the total count from headers
        $response = Invoke-WebRequest -Uri "$apiUrl/api/orders?page=1&pageSize=50" -ErrorAction Stop
        $totalCount = [int]$response.Headers['X-Total-Count'][0]
        $orders = $response.Content | ConvertFrom-Json
        
        # If there are more orders, fetch remaining pages
        if ($totalCount -gt 50) {
            $page = 2
            while ($orders.Count -lt $totalCount) {
                $nextResponse = Invoke-RestMethod -Uri "$apiUrl/api/orders?page=$page&pageSize=50" -ErrorAction Stop
                if ($nextResponse.Count -eq 0) { break }
                $orders += $nextResponse
                $page++
            }
        }
        
        Write-Host "`n📦 Orders (Total: $($orders.Count)):" -ForegroundColor Yellow
        
        $byStatus = $orders | Group-Object status | Sort-Object Name
        foreach ($group in $byStatus) {
            $icon = switch ($group.Name) {
                "Pending" { "⏳" }
                "InProduction" { "🏭" }
                "Shipped" { "📫" }
                "Delivered" { "✅" }
                default { "📋" }
            }
            $bar = "█" * [Math]::Min($group.Count, 20)
            Write-Host "  $icon $($group.Name): " -NoNewline -ForegroundColor White
            Write-Host "$bar $($group.Count)" -ForegroundColor Cyan
        }
        
        # Show recent orders
        $recentOrders = $orders | Sort-Object orderDate -Descending | Select-Object -First 3
        Write-Host "`n🕐 Most Recent Orders:" -ForegroundColor Yellow
        foreach ($order in $recentOrders) {
            $age = (Get-Date) - [DateTime]::Parse($order.orderDate)
            Write-Host "  • Order #$($order.orderNumber) - $($order.status) ($(($age.TotalHours).ToString('F1'))h ago)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "`n❌ API Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Try to get tickets
    try {
        $tickets = Invoke-RestMethod -Uri "$apiUrl/api/supporttickets" -ErrorAction SilentlyContinue
        if ($tickets) {
            Write-Host "`n🎫 Support Tickets: $($tickets.Count)" -ForegroundColor Yellow
            
            $byStatus = $tickets | Group-Object status | Sort-Object Name
            foreach ($group in $byStatus) {
                Write-Host "  • $($group.Name): $($group.Count)" -ForegroundColor Gray
            }
        }
    } catch {
        # Tickets endpoint might not exist
    }
}

# Main monitoring loop
$iteration = 0
Write-Host "🔍 Starting Fabrikam Simulator Monitor..." -ForegroundColor Green
Write-Host "   Simulator: $simUrl" -ForegroundColor Gray
Write-Host "   API: $apiUrl" -ForegroundColor Gray
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Gray

while ($true) {
    Get-SimulatorStatus
    
    $iteration++
    if ($Count -gt 0 -and $iteration -ge $Count) {
        Write-Host "`n✅ Monitoring complete ($iteration checks)" -ForegroundColor Green
        break
    }
    
    Write-Host "`n⏱️  Next check in $Interval seconds... (Check $($iteration + 1))" -ForegroundColor DarkGray
    Start-Sleep -Seconds $Interval
}
