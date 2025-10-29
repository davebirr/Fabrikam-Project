#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test sequential MCP tool calls to verify stateless behavior
.DESCRIPTION
    Simulates Copilot Studio's sequence: business_dashboard → get_orders
    to verify the MCP server handles sequential calls correctly.
#>

param(
    [string]$McpUrl = "https://fabrikam-mcp-development-tzjeje.azurewebsites.net",
    [string]$UserGuid = "00000000-0000-0000-0000-000000000001"
)

$ErrorActionPreference = "Stop"

Write-Host "`n🧪 Testing Sequential MCP Tool Calls (Copilot Studio Simulation)" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor DarkGray
Write-Host "MCP URL: $McpUrl" -ForegroundColor Gray
Write-Host "User GUID: $UserGuid" -ForegroundColor Gray
Write-Host ""

# Headers for MCP protocol
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json, text/event-stream"
    "X-User-GUID" = $UserGuid
}

function Invoke-McpTool {
    param(
        [string]$ToolName,
        [hashtable]$Arguments = @{}
    )
    
    $body = @{
        jsonrpc = "2.0"
        id = [DateTime]::UtcNow.Ticks
        method = "tools/call"
        params = @{
            name = $ToolName
            arguments = $Arguments
        }
    } | ConvertTo-Json -Depth 10

    Write-Host "📞 Calling tool: $ToolName" -ForegroundColor Yellow
    Write-Host "   Arguments: $(if ($Arguments.Count -eq 0) { '(none)' } else { ($Arguments | ConvertTo-Json -Compress) })" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod `
            -Uri "$McpUrl/mcp" `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -SkipCertificateCheck

        Write-Host "   ✅ Success!" -ForegroundColor Green
        Write-Host "   Response ID: $($response.id)" -ForegroundColor Gray
        
        # Show content preview
        if ($response.result.content) {
            $firstContent = $response.result.content[0]
            if ($firstContent.text) {
                $preview = $firstContent.text.Substring(0, [Math]::Min(150, $firstContent.text.Length))
                Write-Host "   Preview: $preview..." -ForegroundColor DarkGray
            }
        }
        
        return $response
    }
    catch {
        Write-Host "   ❌ Failed!" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        return $null
    }
}

# Test Sequence 1: Same as Copilot Studio scenario
Write-Host "`n🔬 Test 1: Business Dashboard → Get Orders (Copilot Studio sequence)" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

Start-Sleep -Milliseconds 500
$dashboard = Invoke-McpTool -ToolName "get_business_dashboard"

Start-Sleep -Milliseconds 500
$orders = Invoke-McpTool -ToolName "get_orders"

if ($dashboard -and $orders) {
    Write-Host "`n✅ PASS: Both sequential calls succeeded" -ForegroundColor Green
} else {
    Write-Host "`n❌ FAIL: One or both calls failed" -ForegroundColor Red
}

# Test Sequence 2: Multiple get_orders calls
Write-Host "`n🔬 Test 2: Multiple get_orders calls (3x)" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

$callResults = @()
for ($i = 1; $i -le 3; $i++) {
    Write-Host "`nCall $i/3:" -ForegroundColor White
    Start-Sleep -Milliseconds 500
    $result = Invoke-McpTool -ToolName "get_orders" -Arguments @{ pageSize = 5 }
    $callResults += ($null -ne $result)
}

$successCount = ($callResults | Where-Object { $_ }).Count
if ($successCount -eq 3) {
    Write-Host "`n✅ PASS: All 3 calls succeeded" -ForegroundColor Green
} else {
    Write-Host "`n❌ FAIL: Only $successCount/3 calls succeeded" -ForegroundColor Red
}

# Test Sequence 3: Different tools in sequence
Write-Host "`n🔬 Test 3: Different tools in sequence" -ForegroundColor Cyan
Write-Host "-" * 70 -ForegroundColor DarkGray

$tools = @("get_customers", "get_products", "get_support_tickets", "get_orders")
$toolResults = @()

foreach ($tool in $tools) {
    Start-Sleep -Milliseconds 500
    $result = Invoke-McpTool -ToolName $tool -Arguments @{ pageSize = 3 }
    $toolResults += ($null -ne $result)
}

$successCount = ($toolResults | Where-Object { $_ }).Count
if ($successCount -eq $tools.Count) {
    Write-Host "`n✅ PASS: All $($tools.Count) different tools succeeded" -ForegroundColor Green
} else {
    Write-Host "`n❌ FAIL: Only $successCount/$($tools.Count) tools succeeded" -ForegroundColor Red
}

# Summary
Write-Host "`n" + "=" * 70 -ForegroundColor DarkGray
Write-Host "📊 Test Summary" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor DarkGray
Write-Host "If all tests PASS, the MCP server is stateless and handles sequential calls correctly."
Write-Host "This means the Copilot Studio issue is likely a Studio bug, not your code."
Write-Host ""
