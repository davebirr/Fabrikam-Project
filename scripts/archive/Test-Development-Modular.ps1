# Test-Development-Modular.ps1 - Authentication-Aware Testing Orchestrator
# Comprehensive testing with automatic authentication mode detection and server management

param(
    [string]$ApiBaseUrl = "",
    [string]$McpBaseUrl = "",
    [string]$DeploymentName = "local",
    [switch]$Quick,
    [switch]$ApiOnly,
    [switch]$McpOnly,
    [switch]$AuthOnly,
    [switch]$Verbose,
    [switch]$CleanBuild,
    [switch]$SkipBuild,
    [switch]$CleanArtifacts,
    [switch]$Visible,
    [switch]$Production
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Import shared testing utilities
$SharedScript = Join-Path $PSScriptRoot "testing/Test-Shared.ps1"
if (Test-Path $SharedScript) {
    . $SharedScript
} else {
    Write-Host "❌ Could not find Test-Shared.ps1 at $SharedScript" -ForegroundColor Red
    exit 1
}

# Import server management utilities
$ServerManagementScript = Join-Path $PSScriptRoot "testing/Test-ServerManagement.ps1"
if (Test-Path $ServerManagementScript) {
    . $ServerManagementScript
} else {
    Write-Host "⚠️  Could not find Test-ServerManagement.ps1 - server management will be limited" -ForegroundColor Yellow
}

function Show-TestMenu {
    Write-Host ""
    Write-Host "🧪 Authentication-Aware Fabrikam Testing Suite" -ForegroundColor Magenta
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "�� Available Test Modules:" -ForegroundColor Cyan
    Write-Host "   1. 🔗 API Testing (Test-Api.ps1)" -ForegroundColor White
    Write-Host "   2. 🔐 Authentication Testing (Test-Authentication.ps1)" -ForegroundColor White
    Write-Host "   3. 🤖 MCP Testing (Test-Mcp.ps1)" -ForegroundColor White
    Write-Host "   4. 🔄 Integration Testing (Test-Integration.ps1)" -ForegroundColor White
    Write-Host ""
    Write-Host "🎛️ Test Modes:" -ForegroundColor Cyan
    Write-Host "   • Full Suite (default)" -ForegroundColor Gray
    Write-Host "   • -ApiOnly: API endpoints only" -ForegroundColor Gray
    Write-Host "   • -McpOnly: MCP tools only" -ForegroundColor Gray
    Write-Host "   • -AuthOnly: Authentication only" -ForegroundColor Gray
    Write-Host "   • -Quick: Fast testing mode" -ForegroundColor Gray
    Write-Host ""
}

function Test-SystemRequirements {
    Write-TestSection "System Requirements Check"
    
    $requirements = @()
    
    # Check if API is running
    try {
        $response = Invoke-RestMethod -Uri "$ApiBaseUrl/api/info" -Method Get -TimeoutSec 10
        Write-Host "✅ API Server: Running" -ForegroundColor Green
        Write-Host "   URL: $ApiBaseUrl" -ForegroundColor Gray
        Write-Host "   Version: $($response.Version)" -ForegroundColor Gray
        $requirements += @{ Service = "API"; Status = "Running"; Url = $ApiBaseUrl }
    }
    catch {
        Write-Host "❌ API Server: Not accessible at $ApiBaseUrl" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        $requirements += @{ Service = "API"; Status = "Failed"; Url = $ApiBaseUrl; Error = $_.Exception.Message }
    }
    
    # Check if MCP is running (if not McpOnly mode)
    if (-not $ApiOnly -and -not $AuthOnly) {
        try {
            $response = Invoke-RestMethod -Uri "$McpBaseUrl/mcp/v1/info" -Method Get -TimeoutSec 10
            Write-Host "✅ MCP Server: Running" -ForegroundColor Green
            Write-Host "   URL: $McpBaseUrl" -ForegroundColor Gray
            Write-Host "   Version: $($response.version)" -ForegroundColor Gray
            $requirements += @{ Service = "MCP"; Status = "Running"; Url = $McpBaseUrl }
        }
        catch {
            Write-Host "⚠️  MCP Server: Not accessible at $McpBaseUrl" -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
            $requirements += @{ Service = "MCP"; Status = "Warning"; Url = $McpBaseUrl; Error = $_.Exception.Message }
        }
    }
    
    return $requirements
}

function Start-TestingWorkflow {
    $startTime = Get-Date
    $testResults = @{
        Api = $null
        Authentication = $null
        Mcp = $null
        Integration = $null
        StartTime = $startTime
        EndTime = $null
        Duration = $null
        OverallSuccess = $false
    }
    
    # Resolve URLs from deployment configuration if needed
    if ([string]::IsNullOrEmpty($ApiBaseUrl) -or [string]::IsNullOrEmpty($McpBaseUrl)) {
        # Load shared testing utilities to get deployment configuration
        $SharedScript = Join-Path $PSScriptRoot "testing/Test-Shared.ps1"
        if (Test-Path $SharedScript) {
            . $SharedScript
            $deploymentInfo = Get-DeploymentUrls -DeploymentName $DeploymentName -Production:$Production
            
            if ([string]::IsNullOrEmpty($ApiBaseUrl)) {
                $script:ApiBaseUrl = $deploymentInfo.ApiUrl
            }
            if ([string]::IsNullOrEmpty($McpBaseUrl)) {
                $script:McpBaseUrl = $deploymentInfo.McpUrl
            }
        }
    }
    
    Write-Host "🚀 Starting Authentication-Aware Testing Workflow" -ForegroundColor Magenta
    Write-Host "   Started: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "   API URL: $ApiBaseUrl" -ForegroundColor Gray
    Write-Host "   MCP URL: $McpBaseUrl" -ForegroundColor Gray
    Write-Host "   Mode: $(if ($Quick) { 'Quick' } elseif ($ApiOnly) { 'API Only' } elseif ($McpOnly) { 'MCP Only' } elseif ($AuthOnly) { 'Auth Only' } else { 'Full Suite' })" -ForegroundColor Gray
    Write-Host ""
    
    # Server Management - Local Development Only
    $testJobs = $null
    if (-not $Production) {
        # Check current server status
        $processStatus = Get-ProcessStatus
        $serversRunning = $processStatus.ApiRunning -and $processStatus.McpRunning
        
        # Smart server management logic:
        # 1. Force rebuild if CleanBuild is requested
        # 2. Build and start if SkipBuild is not set AND servers not running AND doing comprehensive testing
        $needsRebuild = $CleanBuild -or (-not $SkipBuild -and -not $serversRunning -and -not ($AuthOnly -or $ApiOnly -or $McpOnly -or $Quick))
        
        # Always start servers if they're not running (regardless of test mode)
        $needsServerStart = -not $serversRunning
        
        if ($needsRebuild) {
            # Stop any running servers first
            Stop-AllServers
            
            # Build the solution
            if (-not $SkipBuild) {
                $buildSuccess = Build-Solution -Clean:$CleanBuild
                if (-not $buildSuccess) {
                    Write-Host "❌ Build failed. Cannot proceed with testing." -ForegroundColor Red
                    $testResults.OverallSuccess = $false
                    return $testResults
                }
            }
            
            # Start servers for testing
            $testJobs = Start-ServersForTesting -ApiBaseUrl $ApiBaseUrl -McpBaseUrl $McpBaseUrl -ApiOnly:$ApiOnly -McpOnly:$McpOnly -Visible:$Visible
            
            # Give servers a moment to fully initialize
            Write-Host "⏳ Allowing servers to fully initialize..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
        elseif ($needsServerStart) {
            Write-Host "🚀 No servers running - starting servers without rebuild (use -CleanBuild to force rebuild)" -ForegroundColor Cyan
            
            # Start servers for testing without rebuilding
            $testJobs = Start-ServersForTesting -ApiBaseUrl $ApiBaseUrl -McpBaseUrl $McpBaseUrl -ApiOnly:$ApiOnly -McpOnly:$McpOnly -Visible:$Visible
            
            # Give servers a moment to fully initialize
            Write-Host "⏳ Allowing servers to fully initialize..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
        else {
            Write-Host "🔍 Using existing running servers (API: ✅, MCP: ✅)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "🌍 Production Testing Mode - Skipping local server management" -ForegroundColor Cyan
    }
    
    # Initialize test environment with deployment configuration support
    Initialize-TestEnvironment -ApiBaseUrl $ApiBaseUrl -McpBaseUrl $McpBaseUrl -DeploymentName $DeploymentName -Production:$Production
    
    # Check system requirements
    $requirements = Test-SystemRequirements
    $apiAvailable = ($requirements | Where-Object { $_.Service -eq "API" -and $_.Status -eq "Running" }).Count -gt 0
    $mcpAvailable = ($requirements | Where-Object { $_.Service -eq "MCP" -and $_.Status -eq "Running" }).Count -gt 0
    
    if (-not $apiAvailable) {
        Write-Host "❌ Cannot proceed without API server. Please start the API server first." -ForegroundColor Red
        Write-Host "   Run: dotnet run --project FabrikamApi/src/FabrikamApi.csproj" -ForegroundColor Gray
        return $testResults
    }
    
    # 1. API Testing
    if (-not $McpOnly -and -not $AuthOnly) {
        Write-TestSection "Running API Tests"
        
        try {
            $apiScript = Join-Path $PSScriptRoot "testing/Test-Api.ps1"
            if (Test-Path $apiScript) {
                Write-Host "🔗 Running API tests..." -ForegroundColor Yellow
                
                # Execute the script and check exit code
                $apiExitCode = 0
                if ($Quick) {
                    & $apiScript -ApiBaseUrl $ApiBaseUrl -Quick | Out-Host
                    $apiExitCode = $LASTEXITCODE
                } else {
                    & $apiScript -ApiBaseUrl $ApiBaseUrl | Out-Host
                    $apiExitCode = $LASTEXITCODE
                }
                
                $testResults.Api = ($apiExitCode -eq 0)
                
                if ($testResults.Api) {
                    Write-Host "✅ API tests completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  API tests completed with issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ API test script not found: $apiScript" -ForegroundColor Red
                $testResults.Api = $false
            }
        }
        catch {
            Write-Host "❌ API testing failed: $($_.Exception.Message)" -ForegroundColor Red
            $testResults.Api = $false
        }
    }
    
    # 2. Authentication Testing
    if (-not $McpOnly) {
        Write-TestSection "Running Authentication Tests"
        
        try {
            $authScript = Join-Path $PSScriptRoot "testing/Test-Authentication.ps1"
            if (Test-Path $authScript) {
                Write-Host "🔐 Running authentication tests..." -ForegroundColor Yellow
                
                # Execute the script and check exit code
                $authExitCode = 0
                if ($Quick) {
                    & $authScript -ApiBaseUrl $ApiBaseUrl -Quick | Out-Host
                    $authExitCode = $LASTEXITCODE
                } else {
                    & $authScript -ApiBaseUrl $ApiBaseUrl | Out-Host  
                    $authExitCode = $LASTEXITCODE
                }
                
                # Ensure no script output leaks to the pipeline
                $null = $authExitCode
                
                $testResults.Authentication = ($authExitCode -eq 0)
                
                if ($testResults.Authentication) {
                    Write-Host "✅ Authentication tests completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  Authentication tests completed with issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ Authentication test script not found: $authScript" -ForegroundColor Red
                $testResults.Authentication = $false
            }
        }
        catch {
            Write-Host "❌ Authentication testing failed: $($_.Exception.Message)" -ForegroundColor Red
            $testResults.Authentication = $false
        }
    }
    
    # 3. MCP Testing
    if (-not $ApiOnly -and -not $AuthOnly -and $mcpAvailable) {
        Write-TestSection "Running MCP Tests"
        
        try {
            $mcpScript = Join-Path $PSScriptRoot "testing/Test-Mcp.ps1"
            if (Test-Path $mcpScript) {
                Write-Host "🤖 Running MCP tests..." -ForegroundColor Yellow
                
                # Execute the script and check exit code
                $mcpExitCode = 0
                if ($Quick) {
                    & $mcpScript -McpBaseUrl $McpBaseUrl -Quick | Out-Host
                    $mcpExitCode = $LASTEXITCODE
                } else {
                    & $mcpScript -McpBaseUrl $McpBaseUrl | Out-Host
                    $mcpExitCode = $LASTEXITCODE
                }
                
                $testResults.Mcp = ($mcpExitCode -eq 0)
                
                if ($testResults.Mcp) {
                    Write-Host "✅ MCP tests completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  MCP tests completed with issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ MCP test script not found: $mcpScript" -ForegroundColor Red
                $testResults.Mcp = $false
            }
        }
        catch {
            Write-Host "❌ MCP testing failed: $($_.Exception.Message)" -ForegroundColor Red
            $testResults.Mcp = $false
        }
    }
    
    # 4. Integration Testing (only in full mode)
    if (-not $Quick -and -not $ApiOnly -and -not $McpOnly -and -not $AuthOnly -and $apiAvailable -and $mcpAvailable) {
        Write-TestSection "Running Integration Tests"
        
        try {
            $integrationScript = Join-Path $PSScriptRoot "testing/Test-Integration.ps1"
            if (Test-Path $integrationScript) {
                Write-Host "🔄 Running integration tests..." -ForegroundColor Yellow
                
                # Execute the script and check exit code
                & $integrationScript -ApiBaseUrl $ApiBaseUrl -McpBaseUrl $McpBaseUrl | Out-Host
                $integrationExitCode = $LASTEXITCODE
                $testResults.Integration = ($integrationExitCode -eq 0)
                
                if ($testResults.Integration) {
                    Write-Host "✅ Integration tests completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  Integration tests completed with issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ Integration test script not found: $integrationScript" -ForegroundColor Red
                $testResults.Integration = $false
            }
        }
        catch {
            Write-Host "❌ Integration testing failed: $($_.Exception.Message)" -ForegroundColor Red
            $testResults.Integration = $false
        }
    }
    
    # Calculate results
    $testResults.EndTime = Get-Date
    $testResults.Duration = $testResults.EndTime - $testResults.StartTime
    
    # Determine overall success
    $completedTests = @()
    if ($testResults.Api -ne $null) { $completedTests += $testResults.Api }
    if ($testResults.Authentication -ne $null) { $completedTests += $testResults.Authentication }
    if ($testResults.Mcp -ne $null) { $completedTests += $testResults.Mcp }
    if ($testResults.Integration -ne $null) { $completedTests += $testResults.Integration }
    
    $testResults.OverallSuccess = $completedTests.Count -gt 0 -and ($completedTests | Where-Object { $_ -eq $false }).Count -eq 0
    
    # Cleanup: Stop any jobs we started (only for local development)
    if ($testJobs -and -not $Production) {
        try {
            Stop-TestJobs $testJobs
        }
        catch {
            Write-Host "⚠️  Error during cleanup: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Clean build artifacts if requested (prevents VS Code memory issues)
    if ($CleanArtifacts -and -not $Production) {
        try {
            Remove-BuildArtifacts | Out-Null
        }
        catch {
            Write-Host "⚠️  Error cleaning build artifacts: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Return the hashtable directly and suppress any pipeline pollution
    Write-Output $testResults
}

function Show-TestingSummary {
    param([hashtable]$TestResults)
    
    Write-TestSection "Testing Summary"
    
    Write-Host "⏱️  Test Duration: $([math]::Round($TestResults.Duration.TotalSeconds, 2)) seconds" -ForegroundColor Cyan
    Write-Host "🔐 Authentication Mode: $($script:TestConfig.AuthenticationMode)" -ForegroundColor Cyan
    Write-Host ""
    
    # Collect failures for detailed reporting
    $failures = @()
    
    # Individual test results
    Write-Host "📊 Test Results:" -ForegroundColor White
    
    if ($TestResults.Api -ne $null) {
        $status = if ($TestResults.Api) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($TestResults.Api) { "Green" } else { "Red" }
        Write-Host "   API Tests: $status" -ForegroundColor $color
        if (-not $TestResults.Api) {
            $failures += "API Tests - Check endpoint connectivity and authentication"
        }
    }
    
    if ($TestResults.Authentication -ne $null) {
        $status = if ($TestResults.Authentication) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($TestResults.Authentication) { "Green" } else { "Red" }
        Write-Host "   Authentication Tests: $status" -ForegroundColor $color
        if (-not $TestResults.Authentication) {
            $failures += "Authentication Tests - Check authentication mode configuration"
        }
    }
    
    if ($TestResults.Mcp -ne $null) {
        $status = if ($TestResults.Mcp) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($TestResults.Mcp) { "Green" } else { "Red" }
        Write-Host "   MCP Tests: $status" -ForegroundColor $color
        if (-not $TestResults.Mcp) {
            $failures += "MCP Tests - Check MCP server connectivity and tools"
        }
    }
    
    if ($TestResults.Integration -ne $null) {
        $status = if ($TestResults.Integration) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($TestResults.Integration) { "Green" } else { "Red" }
        Write-Host "   Integration Tests: $status" -ForegroundColor $color
        if (-not $TestResults.Integration) {
            $failures += "Integration Tests - Check API-MCP communication"
        }
    }
    
    Write-Host ""
    
    # Show detailed failures at the end
    if ($failures.Count -gt 0) {
        Write-Host "🚨 Test Failures Detected:" -ForegroundColor Red
        foreach ($failure in $failures) {
            Write-Host "   ❌ $failure" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "💡 Troubleshooting Tips:" -ForegroundColor Yellow
        Write-Host "   • Run individual test modules with -Verbose for detailed output" -ForegroundColor Gray
        Write-Host "   • Use .\test.ps1 -CleanBuild to rebuild and restart servers" -ForegroundColor Gray
        Write-Host "   • Check server logs for specific error details" -ForegroundColor Gray
        Write-Host "   • Verify authentication configuration matches test mode" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Overall result
    if ($TestResults.OverallSuccess) {
        Write-Host "🎉 All tests completed successfully!" -ForegroundColor Green
        Write-Host "   The Fabrikam platform is ready for use with $($script:TestConfig.AuthenticationMode) authentication." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed or had issues." -ForegroundColor Yellow
        Write-Host "   Please review the failure details above and test output for specifics." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📚 Next Steps:" -ForegroundColor Cyan
    Write-Host "   • Review test.ps1 for individual module testing" -ForegroundColor Gray
    Write-Host "   • Check api-tests.http for manual API testing" -ForegroundColor Gray
    Write-Host "   • Use GitHub Copilot to test MCP tools interactively" -ForegroundColor Gray
}

# Main execution
try {
    Show-TestMenu
    
    # Start the testing workflow and capture only the hashtable result
    $testResults = Start-TestingWorkflow
    
    # Ensure we have a hashtable (filter out any stray values)
    if ($testResults -is [array] -and $testResults.Count -gt 0) {
        # Find the hashtable in the array
        $hashtableResult = $testResults | Where-Object { $_ -is [hashtable] } | Select-Object -First 1
        if ($hashtableResult) {
            $testResults = $hashtableResult
        }
    }
    
    if ($testResults -is [hashtable]) {
        Show-TestingSummary -TestResults $testResults
    } else {
        Write-Host "❌ Error: testResults is not a hashtable, it's a $($testResults.GetType().Name)" -ForegroundColor Red
        Write-Host "   This indicates a problem in the workflow execution." -ForegroundColor Gray
        exit 1
    }
    
    # Exit with appropriate code
    exit $(if ($testResults.OverallSuccess) { 0 } else { 1 })
}
catch {
    Write-Host ""
    Write-Host "❌ Testing workflow failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Gray
    exit 1
}
