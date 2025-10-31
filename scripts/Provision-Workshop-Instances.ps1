<#
.SYNOPSIS
    Provision Azure App Services for workshop team instances with dedicated isolation

.DESCRIPTION
    Creates dedicated resource groups and App Service Plans for each team.
    Each team gets:
    - 1 Resource Group (rg-fabrikam-team-XX)
    - 1 App Service Plan (asp-fabrikam-team-XX) with B2 SKU
    - 3 App Services (API, MCP, SIM)
    
    Total resources: TeamCount × (1 RG + 1 ASP + 3 Apps)

.PARAMETER TeamCount
    Number of teams to provision (default: 20, does NOT include team-00 proctor)

.PARAMETER IncludeProctor
    Include team-00 for proctors (default: true)

.PARAMETER Location
    Azure region (default: westus2)

.PARAMETER AppServicePlanSku
    App Service Plan SKU (default: B2 - Basic with 2 cores, 3.5GB RAM)

.EXAMPLE
    .\Provision-Workshop-Instances.ps1 -TeamCount 20
    Creates teams 00-20 (21 total with proctor)

.EXAMPLE
    .\Provision-Workshop-Instances.ps1 -TeamCount 5 -IncludeProctor:$false
    Creates teams 01-05 only (no proctor)

.EXAMPLE
    .\Provision-Workshop-Instances.ps1 -TeamCount 1 -Location eastus
    Creates team-00 proctor only in East US
#>

param(
    [int]$TeamCount = 20,
    [bool]$IncludeProctor = $true,
    [string]$Location = "westus2",
    [string]$AppServicePlanSku = "B2",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Calculate team range
$startTeam = if ($IncludeProctor) { 0 } else { 1 }
$endTeam = $TeamCount
$totalTeams = if ($IncludeProctor) { $TeamCount + 1 } else { $TeamCount }

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Fabrikam Workshop Instance Provisioning                    ║" -ForegroundColor Cyan
Write-Host "║   Dedicated Resource Groups Per Team                         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Team Range:         $(if ($IncludeProctor) { '00 (proctor) + ' })01-$($TeamCount.ToString('00'))"
Write-Host "  Total Teams:        $totalTeams"
Write-Host "  Location:           $Location"
Write-Host "  ASP SKU:            $AppServicePlanSku (2 cores, 3.5GB RAM per team)"
Write-Host "  Total Resources:    $($totalTeams) RGs + $($totalTeams) ASPs + $($totalTeams * 3) Apps"
Write-Host "  Estimated Cost:     ~`$$($totalTeams * 26)/month (B2 × $totalTeams teams)"
Write-Host "  WhatIf Mode:        $WhatIf`n"

if (-not $WhatIf) {
    Write-Host "⚠️  This will create:" -ForegroundColor Yellow
    Write-Host "   - $totalTeams Resource Groups" -ForegroundColor Yellow
    Write-Host "   - $totalTeams App Service Plans (B2)" -ForegroundColor Yellow
    Write-Host "   - $($totalTeams * 3) App Services" -ForegroundColor Yellow
    Write-Host "   - Estimated cost: ~`$$($totalTeams * 26)/month`n" -ForegroundColor Yellow
    
    $confirm = Read-Host "Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Provisioning cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Provision instances for each team
Write-Host "Provisioning teams $($startTeam.ToString('00')) through $($endTeam.ToString('00'))...`n" -ForegroundColor Cyan

$successCount = 0
$failedTeams = @()
$failedInstances = @()

for ($team = $startTeam; $team -le $endTeam; $team++) {
    $teamId = $team.ToString("00")
    $resourceGroup = "rg-fabrikam-team-$teamId"
    $appServicePlan = "asp-fabrikam-team-$teamId"
    
    $teamLabel = if ($team -eq 0) { "Team $teamId (Proctor)" } else { "Team $teamId" }
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  $teamLabel" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # Step 1: Create Resource Group
    Write-Host "  [1/3] Creating resource group: $resourceGroup" -ForegroundColor Cyan -NoNewline
    if (-not $WhatIf) {
        try {
            az group create --name $resourceGroup --location $Location --output none 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓" -ForegroundColor Green
            } else {
                throw "Failed to create resource group"
            }
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            $failedTeams += $teamId
            Write-Host "  Skipping team $teamId due to RG creation failure" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host " [WHATIF]" -ForegroundColor Gray
    }
    
    # Step 2: Create App Service Plan
    Write-Host "  [2/3] Creating App Service Plan: $appServicePlan ($AppServicePlanSku)" -ForegroundColor Cyan -NoNewline
    if (-not $WhatIf) {
        try {
            az appservice plan create `
                --name $appServicePlan `
                --resource-group $resourceGroup `
                --location $Location `
                --sku $AppServicePlanSku `
                --is-linux `
                --output none 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓" -ForegroundColor Green
            } else {
                throw "Failed to create App Service Plan"
            }
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            $failedTeams += $teamId
            Write-Host "  Skipping team $teamId due to ASP creation failure" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host " [WHATIF]" -ForegroundColor Gray
    }
    
    # Step 3: Create App Services
    Write-Host "  [3/3] Creating App Services:" -ForegroundColor Cyan
    
    # API App Service
    $apiName = "fabrikam-api-team-$teamId"
    Write-Host "    • $apiName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $apiName `
                --resource-group $resourceGroup `
                --plan $appServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none 2>&1 | Out-Null
            
            az webapp config appsettings set `
                --name $apiName `
                --resource-group $resourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    TeamId=$teamId `
                --output none 2>&1 | Out-Null
            
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            $failedInstances += $apiName
        }
    } else {
        Write-Host " [WHATIF]" -ForegroundColor Gray
    }
    
    # MCP App Service
    $mcpName = "fabrikam-mcp-team-$teamId"
    $apiUrl = "https://$apiName.azurewebsites.net"
    Write-Host "    • $mcpName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $mcpName `
                --resource-group $resourceGroup `
                --plan $appServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none 2>&1 | Out-Null
            
            az webapp config appsettings set `
                --name $mcpName `
                --resource-group $resourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    "FabrikamApi__BaseUrl=$apiUrl" `
                    TeamId=$teamId `
                --output none 2>&1 | Out-Null
            
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            $failedInstances += $mcpName
        }
    } else {
        Write-Host " [WHATIF]" -ForegroundColor Gray
    }
    
    # SIM App Service
    $simName = "fabrikam-sim-team-$teamId"
    Write-Host "    • $simName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $simName `
                --resource-group $resourceGroup `
                --plan $appServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none 2>&1 | Out-Null
            
            az webapp config appsettings set `
                --name $simName `
                --resource-group $resourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    "FabrikamApi__BaseUrl=$apiUrl" `
                    TeamId=$teamId `
                --output none 2>&1 | Out-Null
            
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            $failedInstances += $simName
        }
    } else {
        Write-Host " [WHATIF]" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Provisioning Complete                                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if (-not $WhatIf) {
    Write-Host "Results:" -ForegroundColor Yellow
    Write-Host "  Total Teams:       $totalTeams"
    Write-Host "  Resource Groups:   $totalTeams created"
    Write-Host "  ASPs Created:      $totalTeams (B2 × $totalTeams = ~`$$($totalTeams * 26)/month)"
    Write-Host "  Successful Apps:   $successCount / $($totalTeams * 3) instances"
    
    if ($failedTeams.Count -gt 0) {
        Write-Host "`n  ⚠️  Failed Teams:" -ForegroundColor Red
        $failedTeams | ForEach-Object { Write-Host "    - Team $_" -ForegroundColor Red }
    }
    
    if ($failedInstances.Count -gt 0) {
        Write-Host "`n  ⚠️  Failed App Services:" -ForegroundColor Red
        $failedInstances | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    }
    
    if ($failedTeams.Count -eq 0 -and $failedInstances.Count -eq 0) {
        Write-Host "`n✅ All teams provisioned successfully!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "  1. Deploy code using GitHub Actions workflow"
        Write-Host "  2. Verify deployments with health checks"
        Write-Host "  3. Generate team URLs document"
        Write-Host "`nTeam Resource Groups:" -ForegroundColor Cyan
        for ($team = $startTeam; $team -le $endTeam; $team++) {
            $teamId = $team.ToString("00")
            Write-Host "  • rg-fabrikam-team-$teamId" -ForegroundColor Gray
        }
    } else {
        exit 1
    }
} else {
    Write-Host "WhatIf mode - no changes made" -ForegroundColor Gray
}
