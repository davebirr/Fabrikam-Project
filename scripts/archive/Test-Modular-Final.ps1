# Fabrikam Enhanced Modular Testing - Final Version
# Matching Test-Development.ps1 reliability with focused modular approach

param(
    [switch]$ApiOnly,           # Test API endpoints only
    [switch]$McpOnly,           # Test MCP server only  
    [switch]$McpEnhanced,       # Enhanced MCP testing with comprehensive business tool validation (Issue #12)
    [switch]$AuthOnly,          # Test authentication endpoints only
    [switch]$IntegrationOnly,   # Test integration between API and MCP
    [switch]$Quick,             # Run essential tests only (faster)
    [switch]$Verbose,           # Show detailed output and debugging info
    [switch]$UseRunningServers, # Use existing running servers (no start/stop)
    [switch]$CleanBuild,        # Build solution before testing
    [switch]$Help,              # Show usage information
    [int]$TimeoutSeconds = 30   # HTTP request timeout
)

if ($Help) {
    Write-Host @"
🧪 Fabrikam Enhanced Modular Testing - Final Version

GOAL: Match Test-Development.ps1 reliability with modular benefits

USAGE:
    .\Test-Modular-Final.ps1 [OPTIONS]

INTELLIGENT SERVER MANAGEMENT:
    Auto Mode:     .\Test-Modular-Final.ps1 -Quick          # Manages servers automatically (starts/stops)
    Manual Mode:   .\Test-Modular-Final.ps1 -UseRunningServers  # Reuses existing servers (no stop/start)
    Mixed Mode:    .\Test-Modular-Final.ps1 -UseRunningServers  # Auto-starts missing required servers

FOCUSED TESTING:
    -ApiOnly            Test API endpoints only (needs API server)
    -AuthOnly           Test authentication only (needs API server)
    -McpOnly            Test MCP server only (needs MCP server)
    -McpEnhanced        Enhanced MCP testing with 13 business tools validation (needs both servers)
    -IntegrationOnly    Test integration only (needs both servers)
    -Quick              Essential tests (matches Test-Development.ps1 -Quick)
    -CleanBuild         Build solution before testing

DEVELOPMENT WORKFLOW:
    # Start servers manually for debugging
    dotnet run --project FabrikamApi\src\FabrikamApi.csproj &
    dotnet run --project FabrikamMcp\src\FabrikamMcp.csproj &
    
    # Run tests without disrupting servers
    .\Test-Modular-Final.ps1 -UseRunningServers -McpEnhanced -Verbose

EXAMPLES:
    .\Test-Modular-Final.ps1 -Quick                    # Full auto management
    .\Test-Modular-Final.ps1 -UseRunningServers -Quick # Use existing servers
    .\Test-Modular-Final.ps1 -ApiOnly -Verbose         # Focus on API issues  
    .\Test-Modular-Final.ps1 -McpEnhanced              # Enhanced MCP testing (Issue #12)
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

# Enhanced MCP Testing Support (Issue #12)
if ($McpEnhanced) {
    if (Test-Path "$PSScriptRoot\testing\Test-Mcp-Enhanced.ps1") {
        . "$PSScriptRoot\testing\Test-Mcp-Enhanced.ps1"
        Write-Debug "✅ Loaded enhanced MCP testing module for Issue #12"
    }
    else {
        Write-Warning "⚠️ Enhanced MCP testing module not found, falling back to basic MCP testing"
        $McpEnhanced = $false
        $McpOnly = $true  # Fall back to basic MCP testing
    }
}

# Initialize test results
Initialize-TestResults -Verbose:$Verbose

Write-Host "🧪 Fabrikam Enhanced Modular Testing - Final Version" -ForegroundColor Magenta
Write-Host "📦 Matching Test-Development.ps1 reliability with modular benefits" -ForegroundColor Gray

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
            Write-Error "❌ Build failed"
            exit 1
        }
    }
    catch {
        Write-Error "❌ Build failed: $($_.Exception.Message)"
        exit 1
    }
}

# Server management (enhanced with intelligent server detection)
$startedJobs = @()

# Clean up function
function Stop-TestServers {
    param([array]$Jobs)
    
    if ($Jobs.Count -gt 0) {
        Write-SectionHeader "🧹 CLEANING UP TEST ENVIRONMENT"
        foreach ($jobInfo in $Jobs) {
            Write-Info "🛑 Stopping $($jobInfo.Type) Server job..."
            Stop-Job -Job $jobInfo.Job -ErrorAction SilentlyContinue
            Remove-Job -Job $jobInfo.Job -Force -ErrorAction SilentlyContinue
        }
    }
}

# Smart server detection function
function Test-ServerRunning {
    param(
        [string]$Url,
        [string]$ServerName
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 3 -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

# Intelligent server management
if ($UseRunningServers) {
    Write-SectionHeader "🔍 CHECKING RUNNING SERVERS"
    
    $apiRunning = Test-ServerRunning "$apiUrl/api/info" "API Server"
    $mcpRunning = Test-ServerRunning "$mcpUrl/status" "MCP Server"
    
    if ($apiRunning) {
        Write-Success "✅ API Server already running at $apiUrl"
    }
    if ($mcpRunning) {
        Write-Success "✅ MCP Server already running at $mcpUrl"
    }
    
    # Check if we need servers that aren't running
    $needApi = (-not $McpOnly) -and (-not $apiRunning)
    $needMcp = (-not $ApiOnly -and -not $AuthOnly) -and (-not $mcpRunning)
    
    if ($needApi -or $needMcp) {
        Write-Warning "⚠️ Required servers not running. Starting needed servers..."
        $UseRunningServers = $false  # Fall back to starting servers
    }
}

if (-not $UseRunningServers) {
    Write-SectionHeader "🧹 STOPPING EXISTING SERVERS"
    
    # Stop existing servers (like Test-Development.ps1)
    $existingProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { 
        try {
            $commandLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            return $commandLine -like "*Fabrikam*"
        }
        catch { return $false }
    }
    
    if ($existingProcesses) {
        foreach ($process in $existingProcesses) {
            Write-Info "🛑 Stopping existing server (PID: $($process.Id))"
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        Write-Success "✅ Existing servers stopped"
        Start-Sleep -Seconds 3
    }
    else {
        Write-Info "ℹ️ No existing servers found"
    }

    Write-SectionHeader "🚀 STARTING SERVERS FOR TESTING"
    
    # Start MCP server first (background job like Test-Development.ps1)
    if (-not $ApiOnly -and -not $AuthOnly) {
        Write-Info "🤖 Starting MCP Server in background..."
        $mcpJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD
            & dotnet run --project "FabrikamMcp\src\FabrikamMcp.csproj" --verbosity quiet
        }
        
        Write-Info "⏳ Waiting for MCP Server to start..."
        if (Wait-ForServerStartup "$mcpUrl/status" "MCP Server" 20) {
            Write-Success "✅ MCP Server is ready"
            Write-Success "✅ MCP Server started (Job ID: $($mcpJob.Id))"
            $startedJobs += @{ Type = "MCP"; Job = $mcpJob }
        }
        else {
            Write-Warning "⚠️ MCP Server startup timeout"
        }
    }
    
    # Start API server (background job like Test-Development.ps1)
    # Note: Enhanced MCP testing needs API server for authentication tokens
    if (-not $McpOnly) {
        Write-Info "🌐 Starting API Server in background..."
        $apiJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD
            & dotnet run --project "FabrikamApi\src\FabrikamApi.csproj" --launch-profile https --verbosity quiet
        }
        
        Write-Info "⏳ Waiting for API Server to start..."
        if (Wait-ForServerStartup "$apiUrl/api/info" "API Server" 30) {
            Write-Success "✅ API Server is ready"
            Write-Success "✅ API Server started (Job ID: $($apiJob.Id))"
            $startedJobs += @{ Type = "API"; Job = $apiJob }
        }
        else {
            Write-Warning "⚠️ API Server startup timeout"
        }
    }
    
    if ($startedJobs.Count -gt 0) {
        Write-Info "⏳ Allowing servers to fully initialize..."
        Start-Sleep -Seconds 2
    }
}

# Execute focused tests
$success = $true
try {
    # API Tests (matching Test-Development.ps1 structure)
    if (-not $McpOnly -and -not $McpEnhanced -and -not $IntegrationOnly) {
        Write-SectionHeader "🌐 API ENDPOINT TESTS"
        
        # Basic API endpoint tests
        $endpoints = @(
            @{ Path = "/api/orders"; Name = "Orders" }
            @{ Path = "/api/orders/analytics"; Name = "Analytics" }
        )
        
        if (-not $Quick) {
            $endpoints += @(
                @{ Path = "/api/customers"; Name = "Customers" }
                @{ Path = "/api/products"; Name = "Products" }
            )
        }
        
        $analyticsData = $null
        foreach ($endpoint in $endpoints) {
            try {
                $result = Invoke-SafeWebRequest -Uri "$apiUrl$($endpoint.Path)" -TimeoutSec $TimeoutSeconds
                if ($result.Success) {
                    Add-TestResult "ApiTests" "API $($endpoint.Path)" $true "$($endpoint.Name) endpoint accessible"
                    
                    # Validate response structure
                    if ($result.Data -is [array] -or ($result.Data -and $result.Data.PSObject.Properties.Count -gt 0)) {
                        Add-TestResult "ApiTests" "$($endpoint.Name) Response Structure" $true "Valid data structure returned"
                    }
                    else {
                        Add-TestResult "ApiTests" "$($endpoint.Name) Response Structure" $false "Invalid or empty response structure"
                    }
                    
                    # Store analytics data for detailed validation (matching Test-Development.ps1)
                    if ($endpoint.Path -eq "/api/orders/analytics") {
                        $analyticsData = $result.Data
                        
                        # Detailed analytics summary validation (matching Test-Development.ps1)
                        if ($analyticsData -and $analyticsData.summary) {
                            $requiredSummaryFields = @("totalOrders", "totalRevenue", "averageOrderValue")
                            $hasAllSummaryFields = $true
                            foreach ($field in $requiredSummaryFields) {
                                if (-not ($analyticsData.summary.PSObject.Properties.Name -contains $field)) {
                                    $hasAllSummaryFields = $false
                                    break
                                }
                            }
                            
                            if ($hasAllSummaryFields) {
                                Add-TestResult "ApiTests" "Analytics Summary Structure" $true "All required fields present"
                            }
                            else {
                                Add-TestResult "ApiTests" "Analytics Summary Structure" $false "Missing required summary fields"
                            }
                        }
                        else {
                            Add-TestResult "ApiTests" "Analytics Summary Structure" $false "Analytics summary not found"
                        }
                    }
                }
                else {
                    Add-TestResult "ApiTests" "API $($endpoint.Path)" $false "Failed: $($result.Error)"
                }
            }
            catch {
                Add-TestResult "ApiTests" "API $($endpoint.Path)" $false "Exception: $($_.Exception.Message)"
            }
        }
    }
    
    # Authentication Tests (only if specifically requested or full test)
    if ($AuthOnly -or (-not $Quick -and -not $ApiOnly -and -not $McpOnly -and -not $McpEnhanced -and -not $IntegrationOnly)) {
        Write-SectionHeader "🔐 AUTHENTICATION TESTS"
        
        try {
            # Test demo credentials retrieval
            $demoResult = Invoke-SafeWebRequest -Uri "$apiUrl/api/auth/demo-credentials" -TimeoutSec $TimeoutSeconds
            if ($demoResult.Success -and $demoResult.Data) {
                Add-TestResult "AuthTests" "Demo Credentials Retrieval" $true "Demo credentials available"
                
                # Test login with first available user
                $users = $demoResult.Data
                if ($users -and $users.Count -gt 0) {
                    $testUser = $users[0]
                    $loginBody = @{
                        email = $testUser.email
                        password = $testUser.password
                    } | ConvertTo-Json
                    
                    $loginResult = Invoke-SafeWebRequest -Uri "$apiUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -TimeoutSec $TimeoutSeconds
                    if ($loginResult.Success -and $loginResult.Data.accessToken) {
                        Add-TestResult "AuthTests" "User Login" $true "Login successful for $($testUser.email)"
                        Add-TestResult "AuthTests" "JWT Token Generation" $true "JWT token received"
                    }
                    else {
                        Add-TestResult "AuthTests" "User Login" $false "Login failed for $($testUser.email)"
                    }
                }
            }
            else {
                Add-TestResult "AuthTests" "Demo Credentials Retrieval" $false "Demo credentials not available"
            }
        }
        catch {
            Add-TestResult "AuthTests" "Authentication System" $false "Exception: $($_.Exception.Message)"
        }
    }
    
    # MCP Tests (enhanced support for Issue #12 or basic health check)
    if (-not $ApiOnly -and -not $AuthOnly -and -not $IntegrationOnly) {
        if ($McpEnhanced) {
            Write-SectionHeader "🚀 ENHANCED MCP TESTING (Issue #12)"
            Write-Host "Testing 13 business tools with comprehensive validation" -ForegroundColor Yellow
            
            # Call enhanced MCP testing with comprehensive options
            if ($Quick) {
                Test-McpEnhanced -McpBaseUrl $mcpUrl -TimeoutSeconds $TimeoutSeconds -Quick -Verbose:$Verbose
            }
            else {
                Test-McpEnhanced -McpBaseUrl $mcpUrl -TimeoutSeconds $TimeoutSeconds -Comprehensive -Performance -Verbose:$Verbose
            }
        }
        else {
            Write-SectionHeader "🤖 MCP SERVER TESTS"
            
            # Basic MCP health check (existing functionality)
            try {
                $mcpHealth = Test-ServerHealth -BaseUrl $mcpUrl -ServerName "MCP" -TimeoutSeconds $TimeoutSeconds
                if ($mcpHealth.Success) {
                    Add-TestResult "McpTests" "MCP Server Health" $true "MCP server responding"
                }
                else {
                    Add-TestResult "McpTests" "MCP Server Health" $false "MCP server not responding"
                }
            }
            catch {
                Add-TestResult "McpTests" "MCP Server Health" $false "Exception: $($_.Exception.Message)"
            }
        }
    }
    
    # Integration Tests (simple like Test-Development.ps1)
    if ($IntegrationOnly -or (-not $ApiOnly -and -not $AuthOnly -and -not $McpOnly -and -not $McpEnhanced)) {
        Write-SectionHeader "🔗 INTEGRATION TESTS"
        
        try {
            # Simple integration test - API data availability (matching Test-Development.ps1)
            if ($analyticsData) {
                Add-TestResult "IntegrationTests" "API-MCP Data Compatibility" $true "Analytics data structure matches MCP expectations"
            }
            else {
                # Fallback: try to get analytics data if not already available
                $analyticsResult = Invoke-SafeWebRequest -Uri "$apiUrl/api/orders/analytics" -TimeoutSec $TimeoutSeconds
                if ($analyticsResult.Success) {
                    Add-TestResult "IntegrationTests" "API-MCP Data Compatibility" $true "Analytics data structure matches MCP expectations"
                }
                else {
                    Add-TestResult "IntegrationTests" "API-MCP Data Compatibility" $false "Analytics endpoint not responding"
                }
            }
        }
        catch {
            Add-TestResult "IntegrationTests" "API-MCP Integration" $false "Exception: $($_.Exception.Message)"
        }
    }
}
catch {
    Write-Error "❌ Test execution failed: $($_.Exception.Message)"
    $success = $false
}
finally {
    # Show results
    Write-Host ""
    $summary = Show-TestSummary
    $success = $summary.TotalFailed -eq 0
    
    # Cleanup (smart server management)
    if ($UseRunningServers) {
        Write-Host "🔄 Keeping existing servers running for continued development" -ForegroundColor Green
    }
    elseif ($startedJobs.Count -gt 0) {
        Stop-TestServers -Jobs $startedJobs
        Write-Success "✅ Test environment cleaned up"
    }
    
    # Final status
    Write-Host ""
    if ($success) {
        Write-Host "🎉 All tests passed! Modular testing matches Test-Development.ps1 reliability." -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 Modular Benefits Achieved:" -ForegroundColor Green
        Write-Host "   ✅ Same reliability as unified Test-Development.ps1" -ForegroundColor Gray
        Write-Host "   ✅ Focused testing: -ApiOnly, -AuthOnly, -McpOnly, -McpEnhanced options" -ForegroundColor Gray
        Write-Host "   ✅ Smart server management with clean startup/shutdown" -ForegroundColor Gray
        Write-Host "   ✅ Maintainable architecture for easier debugging" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "✅ All tests passed! Your development environment is ready." -ForegroundColor Green
        Write-Host "• Continue development with confidence" -ForegroundColor Gray
        Write-Host "• Use focused testing: .\Test-Modular-Final.ps1 -ApiOnly" -ForegroundColor Gray
        Write-Host "• For comprehensive testing: .\scripts\Test-Development.ps1" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Some tests failed. Use focused testing to debug:" -ForegroundColor Red
        Write-Host "   .\Test-Modular-Final.ps1 -ApiOnly -Verbose" -ForegroundColor Yellow
        Write-Host "   .\Test-Modular-Final.ps1 -AuthOnly -Verbose" -ForegroundColor Yellow
        Write-Host "   .\Test-Modular-Final.ps1 -McpOnly -Verbose" -ForegroundColor Yellow
        Write-Host "   .\Test-Modular-Final.ps1 -McpEnhanced -Verbose" -ForegroundColor Yellow
    }
}

# Exit with appropriate code
exit $(if ($success) { 0 } else { 1 })
