# Fabrikam Testing - Enhanced Modular Runner
# Improved version matching Test-Development.ps1 reliability
# Full server lifecycle management with proper cleanup

param(
    [switch]$ApiOnly,           # Test API endpoints only
    [switch]$McpOnly,           # Test MCP server only  
    [switch]$AuthOnly,          # Test authentication endpoints only
    [switch]$IntegrationOnly,   # Test integration between API and MCP
    [switch]$Quick,             # Run essential tests only (faster)
    [switch]$Verbose,           # Show detailed output and debugging info
    [switch]$UseRunningServers, # Use existing running servers (no start/stop)
    [switch]$CleanBuild,        # Build solution before testing
    [switch]$CleanArtifacts,    # Clean up after testing
    [switch]$Help,              # Show usage information
    [int]$TimeoutSeconds = 30   # HTTP request timeout
)

if ($Help) {
    Write-Host @"
🧪 Fabrikam Enhanced Modular Testing Suite

PURPOSE:
    Issue #11 Solution: Reliable modular testing matching Test-Development.ps1 quality
    
USAGE:
    .\Test-Modular-Enhanced.ps1 [OPTIONS]

ENHANCED FEATURES:
    ✅ Intelligent server management (start/stop/cleanup)
    ✅ Build integration (-CleanBuild)
    ✅ Complete test coverage matching unified approach
    ✅ Proper server lifecycle management
    ✅ Clean environment setup and teardown

TEST OPTIONS:
    -ApiOnly            Test API endpoints only
    -AuthOnly           Test authentication only  
    -McpOnly            Test MCP server only
    -IntegrationOnly    Test integration only
    -Quick              Fast essential tests only
    -Verbose            Detailed output
    -UseRunningServers  Don't start/stop servers, use existing ones
    -CleanBuild         Build solution before testing
    -CleanArtifacts     Clean up after testing

EXAMPLES:
    .\Test-Modular-Enhanced.ps1 -Quick                    # Quick modular test
    .\Test-Modular-Enhanced.ps1 -CleanBuild -Verbose      # Full build and test
    .\Test-Modular-Enhanced.ps1 -AuthOnly -CleanBuild     # Build + auth tests
    .\Test-Modular-Enhanced.ps1 -UseRunningServers        # Use existing servers
    
MODULAR BENEFITS:
    ✅ Same reliability as Test-Development.ps1
    ✅ Focused test modules for better maintainability
    ✅ Intelligent server management
    ✅ Easy component-specific testing
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

Write-Host "🧪 Fabrikam Enhanced Modular Testing Suite" -ForegroundColor Magenta
Write-Host "📦 Issue #11: Reliable modular testing architecture" -ForegroundColor Gray

# Configuration
$config = Get-TestConfiguration
$apiUrl = $config.ApiBaseUrl
$mcpUrl = $config.McpBaseUrl

Write-Host ""
Write-Host "🌐 API Base URL: $apiUrl" -ForegroundColor Cyan
Write-Host "🤖 MCP Base URL: $mcpUrl" -ForegroundColor Cyan

# Build solution if requested
if ($CleanBuild) {
    Write-SectionHeader "🔨 BUILDING SOLUTION"
    try {
        Write-Info "🔨 Building solution..."
        $buildOutput = & dotnet build --configuration Debug --verbosity minimal 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "✅ Solution built successfully"
        }
        else {
            Write-Error "❌ Build failed: $buildOutput"
            exit 1
        }
    }
    catch {
        Write-Error "❌ Build failed: $($_.Exception.Message)"
        exit 1
    }
}

# Determine what servers we need
$needsApiServer = (-not $McpOnly) -and (-not ($IntegrationOnly -and $McpOnly))
$needsMcpServer = (-not $ApiOnly -and -not $AuthOnly) -or $McpOnly -or $IntegrationOnly

# Track what we start so we can clean up
$startedServers = @()
$stoppedExistingServers = $false

# Stop any existing servers if we're managing them (like Test-Development.ps1 does)
if (-not $UseRunningServers) {
    Write-SectionHeader "🧹 STOPPING EXISTING SERVERS"
    
    # Find and stop existing API servers
    if ($needsApiServer) {
        $existingApiProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { 
            try {
                $commandLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                return $commandLine -like "*FabrikamApi*"
            }
            catch { return $false }
        }
        
        if ($existingApiProcesses) {
            foreach ($process in $existingApiProcesses) {
                Write-Info "🛑 Stopping API Server (PID: $($process.Id))"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            Write-Success "✅ API Server stopped"
            $stoppedExistingServers = $true
        }
    }
    
    # Find and stop existing MCP servers  
    if ($needsMcpServer) {
        $existingMcpProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { 
            try {
                $commandLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                return $commandLine -like "*FabrikamMcp*"
            }
            catch { return $false }
        }
        
        if ($existingMcpProcesses) {
            foreach ($process in $existingMcpProcesses) {
                Write-Info "🛑 Stopping MCP Server (PID: $($process.Id))"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            Write-Success "✅ MCP Server stopped"
            $stoppedExistingServers = $true
        }
    }
    
    if ($stoppedExistingServers) {
        Write-Info "⏳ Waiting for cleanup to complete..."
        Start-Sleep -Seconds 3
    }
    else {
        Write-Info "ℹ️ No existing servers found"
    }
}

# Start servers if needed
if (-not $UseRunningServers) {
    Write-SectionHeader "🚀 STARTING SERVERS FOR TESTING"
    
    # Start MCP server first (typically faster to start)
    if ($needsMcpServer) {
        Write-Info "🤖 Starting MCP Server in background..."
        try {
            # Use background job approach like Test-Development.ps1
            $mcpJob = Start-Job -ScriptBlock {
                Set-Location $using:PWD
                & dotnet run --project "FabrikamMcp\src\FabrikamMcp.csproj" --verbosity quiet
            }
            
            Write-Info "⏳ Waiting for MCP Server to start..."
            if (Wait-ForServerStartup "$mcpUrl/status" "MCP Server" 20) {
                Write-Success "✅ MCP Server is ready"
                Write-Success "✅ MCP Server started (Job ID: $($mcpJob.Id))"
                $startedServers += @{ Type = "MCP"; Job = $mcpJob }
            }
            else {
                Write-Warning "⚠️ MCP Server startup timeout"
                Stop-Job -Job $mcpJob -ErrorAction SilentlyContinue
                Remove-Job -Job $mcpJob -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "❌ Failed to start MCP server: $($_.Exception.Message)"
            exit 1
        }
    }
    
    # Start API server
    if ($needsApiServer) {
        Write-Info "🌐 Starting API Server in background..."
        try {
            # Use background job approach like Test-Development.ps1
            $apiJob = Start-Job -ScriptBlock {
                Set-Location $using:PWD
                & dotnet run --project "FabrikamApi\src\FabrikamApi.csproj" --launch-profile https --verbosity quiet
            }
            
            Write-Info "⏳ Waiting for API Server to start..."
            if (Wait-ForServerStartup "$apiUrl/api/info" "API Server" 30) {
                Write-Success "✅ API Server is ready"
                Write-Success "✅ API Server started (Job ID: $($apiJob.Id))"
                $startedServers += @{ Type = "API"; Job = $apiJob }
            }
            else {
                Write-Warning "⚠️ API Server startup timeout"
                Stop-Job -Job $apiJob -ErrorAction SilentlyContinue
                Remove-Job -Job $apiJob -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "❌ Failed to start API server: $($_.Exception.Message)"
            exit 1
        }
    }
    
    # Final initialization wait (like Test-Development.ps1)
    if ($startedServers.Count -gt 0) {
        Write-Info "⏳ Allowing servers to fully initialize..."
        Start-Sleep -Seconds 2
    }
}
else {
    # Validate required servers are running
    Write-SectionHeader "🔍 VALIDATING RUNNING SERVERS"
    
    if ($needsApiServer) {
        try {
            $apiHealth = Test-ServerHealth -BaseUrl $apiUrl -ServerName "API" -TimeoutSeconds 5
            if ($apiHealth.Success) {
                Write-Success "✅ API Server is running and healthy"
            }
            else {
                Write-Error "❌ API Server required but not responding. Start with: .\scripts\Manage-Project.ps1 start"
                exit 1
            }
        }
        catch {
            Write-Error "❌ API Server required but not running. Start with: .\scripts\Manage-Project.ps1 start"
            exit 1
        }
    }
    
    if ($needsMcpServer) {
        try {
            $mcpHealth = Test-ServerHealth -BaseUrl $mcpUrl -ServerName "MCP" -TimeoutSeconds 5  
            if ($mcpHealth.Success) {
                Write-Success "✅ MCP Server is running and healthy"
            }
            else {
                Write-Error "❌ MCP Server required but not responding. Start with: .\scripts\Manage-Project.ps1 start"
                exit 1
            }
        }
        catch {
            Write-Error "❌ MCP Server required but not running. Start with: .\scripts\Manage-Project.ps1 start"
            exit 1
        }
    }
}

# Run modular tests
$success = $true
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
        if ($needsApiServer) { 
            $testCategories += "API"
            if (-not $Quick) { $testCategories += "Auth" }
        }
        if ($needsMcpServer) { $testCategories += "MCP" }
        if ($needsApiServer -and $needsMcpServer -and -not $Quick) { 
            $testCategories += "Integration" 
        }
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
    $success = $summary.TotalFailed -eq 0
    
    # Cleanup servers we started (like Test-Development.ps1)
    if (-not $UseRunningServers -and $startedServers.Count -gt 0) {
        Write-SectionHeader "🧹 CLEANING UP TEST ENVIRONMENT"
        
        foreach ($server in $startedServers) {
            try {
                Write-Info "🛑 Stopping $($server.Type) Server job..."
                Stop-Job -Job $server.Job -ErrorAction SilentlyContinue
                Remove-Job -Job $server.Job -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "⚠️ Could not stop $($server.Type) Server job: $($_.Exception.Message)"
            }
        }
        
        # Additional cleanup - kill any remaining processes
        Write-SectionHeader "🧹 STOPPING ALL RUNNING SERVERS"
        
        if ($needsApiServer) {
            $remainingApiProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { 
                try {
                    $commandLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                    return $commandLine -like "*FabrikamApi*"
                }
                catch { return $false }
            }
            
            if ($remainingApiProcesses) {
                foreach ($process in $remainingApiProcesses) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
                Write-Success "✅ API Server processes cleaned up"
            }
        }
        
        if ($needsMcpServer) {
            $remainingMcpProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { 
                try {
                    $commandLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                    return $commandLine -like "*FabrikamMcp*"
                }
                catch { return $false }
            }
            
            if ($remainingMcpProcesses) {
                foreach ($process in $remainingMcpProcesses) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
                Write-Success "✅ MCP Server processes cleaned up"
            }
        }
        
        Write-Success "✅ Test environment cleaned up"
    }
    
    if ($UseRunningServers) {
        Write-Host ""
        Write-Host "🏃 Using running servers - no cleanup needed" -ForegroundColor Cyan
        Write-Host "   Use 'scripts\Manage-Project.ps1 stop' to stop servers when done" -ForegroundColor Gray
    }
    
    # Show results summary
    Write-Host ""
    if ($success) {
        Write-Host "🎉 All tests passed! Modular testing architecture is working perfectly." -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 Modular Testing Benefits Demonstrated:" -ForegroundColor Green
        Write-Host "   ✅ Same reliability as Test-Development.ps1" -ForegroundColor Gray
        Write-Host "   ✅ Focused test modules for better maintainability" -ForegroundColor Gray
        Write-Host "   ✅ Intelligent server management" -ForegroundColor Gray
        Write-Host "   ✅ Easy component-specific testing" -ForegroundColor Gray
        Write-Host "   ✅ Clean environment setup and teardown" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Some tests failed. Check the summary above for details." -ForegroundColor Red
    }
    
    if ($CleanArtifacts) {
        Write-Host ""
        Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Yellow
        try {
            & dotnet clean --verbosity minimal > $null
            Write-Success "✅ Build artifacts cleaned"
        }
        catch {
            Write-Warning "⚠️ Could not clean build artifacts: $($_.Exception.Message)"
        }
    }
}

# Exit with appropriate code
exit $(if ($success) { 0 } else { 1 })
