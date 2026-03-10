<#
.SYNOPSIS
    Deploy code to all workshop team instances

.DESCRIPTION
    Discovers actual web app names in each team's resource group and deploys
    the latest code from the repository. Builds once, deploys to all teams.

.PARAMETER TeamNumber
    Optional: Deploy to a specific team (e.g., "05"). If not specified, deploys to all teams.

.EXAMPLE
    .\Deploy-Code-AllTeams.ps1
    Deploy to all teams (00-24)

.EXAMPLE
    .\Deploy-Code-AllTeams.ps1 -TeamNumber 05
    Deploy only to Team-05
#>

param(
    [string]$TeamNumber = $null
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Workshop Code Deployment                                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Get repository root
$repoRoot = Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Parent
$tempDir = Join-Path $repoRoot "temp-publish"

# Step 1: Build projects
Write-Host "[Step 1/3] Building projects..." -ForegroundColor Cyan

if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Build API
Write-Host "  Building API..." -ForegroundColor Gray
$apiProject = Join-Path $repoRoot "FabrikamApi\src\FabrikamApi.csproj"
$apiPublish = Join-Path $tempDir "api"
dotnet publish $apiProject -c Release -o $apiPublish --nologo -v quiet
if ($LASTEXITCODE -ne 0) {
    throw "API build failed"
}
Write-Host "  ✓ API build complete" -ForegroundColor Green

# Build MCP
Write-Host "  Building MCP..." -ForegroundColor Gray
$mcpProject = Join-Path $repoRoot "FabrikamMcp\src\FabrikamMcp.csproj"
$mcpPublish = Join-Path $tempDir "mcp"
dotnet publish $mcpProject -c Release -o $mcpPublish --nologo -v quiet
if ($LASTEXITCODE -ne 0) {
    throw "MCP build failed"
}
Write-Host "  ✓ MCP build complete" -ForegroundColor Green

# Create ZIP files
Write-Host "  Creating deployment packages..." -ForegroundColor Gray
$apiZip = Join-Path $tempDir "api.zip"
$mcpZip = Join-Path $tempDir "mcp.zip"

Push-Location (Join-Path $tempDir "api")
Compress-Archive -Path * -DestinationPath $apiZip -Force
Pop-Location

Push-Location (Join-Path $tempDir "mcp")
Compress-Archive -Path * -DestinationPath $mcpZip -Force
Pop-Location

Write-Host "  ✓ Deployment packages ready" -ForegroundColor Green

# Step 2: Determine teams to deploy
Write-Host "`n[Step 2/3] Determining deployment targets..." -ForegroundColor Cyan

$teams = @()
if ($TeamNumber) {
    $teams = @($TeamNumber)
    Write-Host "  ℹ️  Deploying to Team-$TeamNumber only" -ForegroundColor Yellow
} else {
    # Get all resource groups that match the pattern
    $allRGs = az group list --query "[?starts_with(name, 'rg-fabrikam-team-')].name" -o tsv
    foreach ($rg in $allRGs) {
        if ($rg -match 'rg-fabrikam-team-(\d{2})') {
            $teams += $matches[1]
        }
    }
    $teams = $teams | Sort-Object
    Write-Host "  ✓ Found $($teams.Count) teams: $($teams -join ', ')" -ForegroundColor Green
}

# Step 3: Deploy to teams
Write-Host "`n[Step 3/3] Deploying to teams..." -ForegroundColor Cyan

$deploymentResults = @()
$successCount = 0
$failureCount = 0

foreach ($team in $teams) {
    $teamId = $team.PadLeft(2, '0')
    $resourceGroup = "rg-fabrikam-team-$teamId"
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║   Team-$teamId" -ForegroundColor DarkCyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    
    $result = [PSCustomObject]@{
        Team = $teamId
        ResourceGroup = $resourceGroup
        ApiStatus = "Not Started"
        McpStatus = "Not Started"
    }
    
    try {
        # Check if resource group exists
        $rgExists = az group exists --name $resourceGroup
        if ($rgExists -ne "true") {
            Write-Host "  ⚠️  Resource group not found: $resourceGroup" -ForegroundColor Yellow
            $result.ApiStatus = "RG Not Found"
            $result.McpStatus = "RG Not Found"
            $deploymentResults += $result
            $failureCount++
            continue
        }
        
        # Get web app names from resource group
        $webApps = az webapp list -g $resourceGroup --query "[].{name:name, type:kind}" -o json | ConvertFrom-Json
        
        $apiApp = $webApps | Where-Object { $_.name -like "*api*" } | Select-Object -First 1
        $mcpApp = $webApps | Where-Object { $_.name -like "*mcp*" } | Select-Object -First 1
        
        # Deploy API
        if ($apiApp) {
            Write-Host "  Deploying API to $($apiApp.name)..." -ForegroundColor Gray
            try {
                az webapp deploy --resource-group $resourceGroup --name $apiApp.name --src-path $apiZip --type zip --async false 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ API deployed" -ForegroundColor Green
                    $result.ApiStatus = "Success"
                } else {
                    throw "Deployment failed"
                }
            } catch {
                Write-Host "  ✗ API deployment failed: $_" -ForegroundColor Red
                $result.ApiStatus = "Failed"
            }
        } else {
            Write-Host "  ⚠️  No API app found" -ForegroundColor Yellow
            $result.ApiStatus = "App Not Found"
        }
        
        # Deploy MCP
        if ($mcpApp) {
            Write-Host "  Deploying MCP to $($mcpApp.name)..." -ForegroundColor Gray
            try {
                az webapp deploy --resource-group $resourceGroup --name $mcpApp.name --src-path $mcpZip --type zip --async false 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ MCP deployed" -ForegroundColor Green
                    $result.McpStatus = "Success"
                } else {
                    throw "Deployment failed"
                }
            } catch {
                Write-Host "  ✗ MCP deployment failed: $_" -ForegroundColor Red
                $result.McpStatus = "Failed"
            }
        } else {
            Write-Host "  ⚠️  No MCP app found" -ForegroundColor Yellow
            $result.McpStatus = "App Not Found"
        }
        
        if ($result.ApiStatus -eq "Success" -and $result.McpStatus -eq "Success") {
            $successCount++
        } else {
            $failureCount++
        }
        
    } catch {
        Write-Host "  ✗ Error processing team: $_" -ForegroundColor Red
        $result.ApiStatus = "Error: $_"
        $result.McpStatus = "Error: $_"
        $failureCount++
    }
    
    $deploymentResults += $result
}

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Deployment Summary                                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Total Teams:  $($teams.Count)" -ForegroundColor White
Write-Host "Successful:   $successCount" -ForegroundColor Green
Write-Host "Failed:       $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })

Write-Host "`nDetailed Results:" -ForegroundColor White
$deploymentResults | Format-Table -AutoSize

# Cleanup
Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✅ Deployment complete!" -ForegroundColor Green
