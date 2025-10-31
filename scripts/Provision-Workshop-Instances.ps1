<#
.SYNOPSIS
    Provision Azure App Services for 20 workshop team instances

.DESCRIPTION
    Creates a resource group, shared App Service Plan, and 60 App Services
    (3 per team: API, MCP, SIM) for the Agent-a-thon workshop.

.PARAMETER TeamCount
    Number of teams to provision (default: 20)

.PARAMETER ResourceGroup
    Resource group name (default: rg-fabrikam-workshop)

.PARAMETER Location
    Azure region (default: westus2)

.PARAMETER AppServicePlanSku
    App Service Plan SKU (default: B2 - Basic with 2 cores)

.EXAMPLE
    .\Provision-Workshop-Instances.ps1 -TeamCount 20

.EXAMPLE
    .\Provision-Workshop-Instances.ps1 -TeamCount 5 -Location eastus
#>

param(
    [int]$TeamCount = 20,
    [string]$ResourceGroup = "rg-fabrikam-workshop",
    [string]$Location = "westus2",
    [string]$AppServicePlan = "asp-fabrikam-workshop",
    [string]$AppServicePlanSku = "B2",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Fabrikam Workshop Instance Provisioning                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Teams:              $TeamCount"
Write-Host "  Resource Group:     $ResourceGroup"
Write-Host "  Location:           $Location"
Write-Host "  App Service Plan:   $AppServicePlan ($AppServicePlanSku)"
Write-Host "  Total App Services: $($TeamCount * 3) (API + MCP + SIM per team)"
Write-Host "  WhatIf Mode:        $WhatIf`n"

if (-not $WhatIf) {
    $confirm = Read-Host "Proceed with provisioning? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Provisioning cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Create resource group
Write-Host "`n[1/3] Creating resource group: $ResourceGroup" -ForegroundColor Cyan
if (-not $WhatIf) {
    az group create --name $ResourceGroup --location $Location --output table
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create resource group"
    }
} else {
    Write-Host "  [WHATIF] Would create resource group: $ResourceGroup in $Location" -ForegroundColor Gray
}

# Create App Service Plan (shared by all instances)
Write-Host "`n[2/3] Creating shared App Service Plan: $AppServicePlan" -ForegroundColor Cyan
if (-not $WhatIf) {
    az appservice plan create `
        --name $AppServicePlan `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku $AppServicePlanSku `
        --is-linux `
        --output table
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create App Service Plan"
    }
} else {
    Write-Host "  [WHATIF] Would create App Service Plan: $AppServicePlan (SKU: $AppServicePlanSku)" -ForegroundColor Gray
}

# Provision instances for each team
Write-Host "`n[3/3] Provisioning team instances..." -ForegroundColor Cyan

$successCount = 0
$failedInstances = @()

for ($team = 1; $team -le $TeamCount; $team++) {
    $teamId = $team.ToString("00")
    Write-Host "`n  ═══ Team $teamId ═══" -ForegroundColor Green
    
    # API App Service
    $apiName = "fabrikam-api-team-$teamId"
    Write-Host "  Creating $apiName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $apiName `
                --resource-group $ResourceGroup `
                --plan $AppServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none
            
            az webapp config appsettings set `
                --name $apiName `
                --resource-group $ResourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    TeamId=$teamId `
                --output none
            
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
    Write-Host "  Creating $mcpName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $mcpName `
                --resource-group $ResourceGroup `
                --plan $AppServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none
            
            az webapp config appsettings set `
                --name $mcpName `
                --resource-group $ResourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    "FabrikamApi__BaseUrl=$apiUrl" `
                    TeamId=$teamId `
                --output none
            
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
    Write-Host "  Creating $simName..." -ForegroundColor Yellow -NoNewline
    if (-not $WhatIf) {
        try {
            az webapp create `
                --name $simName `
                --resource-group $ResourceGroup `
                --plan $AppServicePlan `
                --runtime "DOTNETCORE:9.0" `
                --output none
            
            az webapp config appsettings set `
                --name $simName `
                --resource-group $ResourceGroup `
                --settings `
                    ASPNETCORE_ENVIRONMENT=Workshop `
                    "FabrikamApi__BaseUrl=$apiUrl" `
                    TeamId=$teamId `
                --output none
            
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
    Write-Host "  Total Teams:       $TeamCount"
    Write-Host "  Successful:        $successCount / $($TeamCount * 3) instances"
    
    if ($failedInstances.Count -gt 0) {
        Write-Host "  Failed Instances:  $($failedInstances.Count)" -ForegroundColor Red
        Write-Host "`nFailed instances:" -ForegroundColor Red
        $failedInstances | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    } else {
        Write-Host "  Status:            ✓ All instances provisioned successfully!" -ForegroundColor Green
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "  1. Configure GitHub Actions secret: AZURE_CREDENTIALS"
    Write-Host "  2. Push to workshop-stable branch to trigger deployment"
    Write-Host "  3. Run .\Verify-Workshop-Deployment.ps1 to validate"
    Write-Host "  4. Generate team URLs: .\Generate-Team-URLs.ps1"
    Write-Host "`nView in Azure Portal: https://portal.azure.com/#resource/subscriptions/<sub-id>/resourceGroups/$ResourceGroup" -ForegroundColor Gray
} else {
    Write-Host "WhatIf mode - no changes made" -ForegroundColor Gray
}
