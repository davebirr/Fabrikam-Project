# Fabrikam Testing - Simple Modular Runner
# Uses existing servers or starts them temporarily for testing
# Designed to work with Manage-Project.ps1 for server management

param(
    [switch]$ApiOnly,           # Test API endpoints only
    [switch]$McpOnly,           # Test MCP server only  
    [switch]$AuthOnly,          # Test authentication endpoints only
    [switch]$IntegrationOnly,   # Test integration between API and MCP
    [switch]$Quick,             # Run essential tests only (faster)
    [switch]$Verbose,           # Show detailed output and debugging info
    [switch]$UseRunningServers, # Use existing running servers (no start/stop)
    [switch]$Help,              # Show usage information
    [int]$TimeoutSeconds = 30   # HTTP request timeout
)

if ($Help) {
    Write-Host @"
🧪 Fabrikam Modular Testing Suite

PURPOSE:
    Demonstrates Issue #11 solution: Modular testing to replace monolithic Test-Development.ps1
    
USAGE:
    .\Test-Modular.ps1 [OPTIONS]

SERVER MANAGEMENT:
    Option 1 - Use existing running servers:
        .\scripts\Manage-Project.ps1 start        # Start servers in visible terminals
        .\Test-Modular.ps1 -UseRunningServers     # Run tests against running servers
        
    Option 2 - Let script manage servers temporarily:
        .\Test-Modular.ps1                        # Script starts/stops servers automatically

TEST OPTIONS:
    -ApiOnly            Test API endpoints only
    -AuthOnly           Test authentication only  
    -McpOnly            Test MCP server only
    -IntegrationOnly    Test integration only
    -Quick              Fast essential tests only
    -Verbose            Detailed output
    -UseRunningServers  Don't start/stop servers, use existing ones

EXAMPLES:
    .\Test-Modular.ps1 -Quick                    # Quick test with temporary servers
    .\Test-Modular.ps1 -AuthOnly -Verbose        # Detailed auth tests
    .\Test-Modular.ps1 -UseRunningServers        # Use servers started by Manage-Project.ps1
    
MODULAR BENEFITS:
    ✅ Focused, maintainable test modules instead of one large script
    ✅ Easy to run specific test categories  
    ✅ Reduced complexity and better separation of concerns
    ✅ Compatible with existing server management tools
"@
    exit 0
}

$ErrorActionPreference = "Stop"

# Import shared utilities
if (!(Test-Path "$PSScriptRoot\testing\Test-Shared.ps1")) {
    Write-Error "❌ Test-Shared.ps1 not found. Please run from the scripts directory."
    exit 1
}

. "$PSScriptRoot\testing\Test-Shared.ps1"

# Initialize test results
Initialize-TestResults -Verbose:$Verbose

Write-Host "🧪 Fabrikam Modular Testing Suite" -ForegroundColor Magenta
Write-Host "📦 Issue #11: Demonstrating modular test architecture" -ForegroundColor Gray

# Configuration
$config = Get-TestConfiguration
$apiUrl = $config.ApiBaseUrl
$mcpUrl = $config.McpBaseUrl

Write-Host ""
Write-Host "🌐 API Base URL: $apiUrl" -ForegroundColor Cyan
Write-Host "🤖 MCP Base URL: $mcpUrl" -ForegroundColor Cyan

# Check if servers are already running
$apiRunning = $false
$mcpRunning = $false

try {
    $apiHealth = Test-ServerHealth -BaseUrl $apiUrl -ServerName "API" -TimeoutSeconds 5
    $apiRunning = $apiHealth.Success
    if ($apiRunning) { Write-Success "✅ API Server already running" }
}
catch { }

try {
    $mcpHealth = Test-ServerHealth -BaseUrl $mcpUrl -ServerName "MCP" -TimeoutSeconds 5  
    $mcpRunning = $mcpHealth.Success
    if ($mcpRunning) { Write-Success "✅ MCP Server already running" }
}
catch { }

# Server management strategy
$needsApiServer = (-not $McpOnly -and -not $IntegrationOnly) -or (-not $ApiOnly -and -not $AuthOnly -and -not $McpOnly)
$needsMcpServer = (-not $ApiOnly -and -not $AuthOnly) -or $McpOnly -or $IntegrationOnly

$startedServers = @()

if (-not $UseRunningServers) {
    # Start servers if needed and not running
    if ($needsApiServer -and -not $apiRunning) {
        Write-Info "🌐 Starting API Server temporarily..."
        try {
            $apiProcess = Start-Process -FilePath "dotnet" -ArgumentList "run", "--project", "FabrikamApi\src\FabrikamApi.csproj", "--launch-profile", "https" -PassThru -WindowStyle Hidden
            $startedServers += @{ Type = "API"; Process = $apiProcess }
            Write-Success "✅ API Server started (PID: $($apiProcess.Id))"
            
            # Wait for API server to be ready
            if (Wait-ForServerStartup "$apiUrl/api/info" "API Server" 30) {
                Write-Success "✅ API Server is ready and responding"
            }
            else {
                Write-Warning "⚠️ API Server may not be fully ready, tests may fail"
            }
        }
        catch {
            Write-Error "❌ Failed to start API server: $($_.Exception.Message)"
            exit 1
        }
    }
    
    if ($needsMcpServer -and -not $mcpRunning) {
        Write-Info "🤖 Starting MCP Server temporarily..."
        try {
            $mcpProcess = Start-Process -FilePath "dotnet" -ArgumentList "run", "--project", "FabrikamMcp\src\FabrikamMcp.csproj" -PassThru -WindowStyle Hidden
            $startedServers += @{ Type = "MCP"; Process = $mcpProcess }
            Write-Success "✅ MCP Server started (PID: $($mcpProcess.Id))"
            
            # Wait for MCP server to be ready
            if (Wait-ForServerStartup "$mcpUrl/status" "MCP Server" 20) {
                Write-Success "✅ MCP Server is ready and responding"
            }
            else {
                Write-Warning "⚠️ MCP Server may not be fully ready, tests may fail"
            }
        }
        catch {
            Write-Error "❌ Failed to start MCP server: $($_.Exception.Message)"
            exit 1
        }
    }

}
else {
    if ($needsApiServer -and -not $apiRunning) {
        Write-Error "❌ API Server required but not running. Start with: .\scripts\Manage-Project.ps1 start"
        exit 1
    }
    if ($needsMcpServer -and -not $mcpRunning) {
        Write-Error "❌ MCP Server required but not running. Start with: .\scripts\Manage-Project.ps1 start"
        exit 1
    }
}

# Run modular tests
try {
    $testCategories = @()
    
    # Determine what to test
    if ($ApiOnly) {
        $testCategories += "API"
    }
    elseif ($AuthOnly) {
        $testCategories += "Auth"
    }
    elseif ($McpOnly) {
        $testCategories += "MCP"
    }
    elseif ($IntegrationOnly) {
        $testCategories += "Integration"
    }
    else {
        # Default: run all applicable tests
        if ($needsApiServer) { $testCategories += "API" }
        if ($needsApiServer) { $testCategories += "Auth" }
        if ($needsMcpServer) { $testCategories += "MCP" }
        if ($needsApiServer -and $needsMcpServer -and -not $Quick) { $testCategories += "Integration" }
    }
    
    # Execute test modules
    foreach ($category in $testCategories) {
        switch ($category) {
            "API" {
                Write-SectionHeader "🌐 API ENDPOINT TESTS"
                . "$PSScriptRoot\testing\Test-Api.ps1"
                Test-ApiEndpoints -ApiBaseUrl $apiUrl -Quick:$Quick -Verbose:$Verbose
            }
            "Auth" {
                Write-SectionHeader "🔐 AUTHENTICATION TESTS"  
                . "$PSScriptRoot\testing\Test-Authentication.ps1"
                Test-Authentication -ApiBaseUrl $apiUrl -Quick:$Quick -Verbose:$Verbose
            }
            "MCP" {
                Write-SectionHeader "🤖 MCP SERVER TESTS"
                . "$PSScriptRoot\testing\Test-Mcp.ps1" 
                Test-McpServer -McpBaseUrl $mcpUrl -Quick:$Quick -Verbose:$Verbose
            }
            "Integration" {
                Write-SectionHeader "🔗 INTEGRATION TESTS"
                . "$PSScriptRoot\testing\Test-Integration.ps1"
                Test-Integration -ApiBaseUrl $apiUrl -McpBaseUrl $mcpUrl -Verbose:$Verbose
            }
        }
    }
}
catch {
    Write-Error "❌ Test execution failed: $($_.Exception.Message)"
    $success = $false
}
finally {
    # Show test summary
    Write-Host ""
    $summary = Show-TestSummary
    
    # Cleanup servers we started
    if (-not $UseRunningServers -and $startedServers.Count -gt 0) {
        Write-Host ""
        Write-Info "🧹 Cleaning up temporary servers..."
        foreach ($server in $startedServers) {
            try {
                if (-not $server.Process.HasExited) {
                    Stop-Process -Id $server.Process.Id -Force
                    Write-Success "✅ Stopped $($server.Type) Server"
                }
            }
            catch {
                Write-Warning "⚠️ Could not stop $($server.Type) Server: $($_.Exception.Message)"
            }
        }
    }
    
    Write-Host ""
    Write-Host "💡 Modular Testing Benefits Demonstrated:" -ForegroundColor Green
    Write-Host "   ✅ Focused test modules instead of monolithic script" -ForegroundColor Gray
    Write-Host "   ✅ Flexible server management (use existing or temporary)" -ForegroundColor Gray
    Write-Host "   ✅ Easy to test specific components" -ForegroundColor Gray
    Write-Host "   ✅ Better maintainability and debugging" -ForegroundColor Gray
    
    if ($UseRunningServers) {
        Write-Host ""
        Write-Host "🏃 Using running servers - no cleanup needed" -ForegroundColor Cyan
        Write-Host "   Use 'Manage-Project.ps1 stop' to stop servers when done" -ForegroundColor Gray
    }
}

# Exit with appropriate code
exit $(if ($summary.TotalFailed -eq 0) { 0 } else { 1 })
