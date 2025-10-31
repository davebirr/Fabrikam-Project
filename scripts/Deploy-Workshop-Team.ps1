<#
.SYNOPSIS
    Deploy a Fabrikam workshop team instance using Azure CLI

.DESCRIPTION
    Deploys a complete Fabrikam instance (API, MCP, SIM) for a workshop team.
    Creates resource group with unique suffix, deploys ARM template with workshop defaults.
    Based on the Deploy-to-Azure button process but adapted for CLI.

.PARAMETER TeamId
    Team identifier (00 for proctor, 01-20 for participants)

.PARAMETER Location
    Azure region (default: eastus2)

.PARAMETER SkuName
    App Service Plan SKU (default: B2)

.PARAMETER WhatIf
    Preview what would be created without actually deploying

.EXAMPLE
    .\Deploy-Workshop-Team.ps1 -TeamId 00
    Deploy proctor instance (team-00)

.EXAMPLE
    .\Deploy-Workshop-Team.ps1 -TeamId 05 -Location westus2
    Deploy team-05 in West US 2

.EXAMPLE
    .\Deploy-Workshop-Team.ps1 -TeamId 10 -WhatIf
    Preview deployment for team-10 without creating resources
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d{2}$')]
    [string]$TeamId,
    
    [string]$Location = "westus2",
    
    [ValidateSet("B1", "B2", "S1")]
    [string]$SkuName = "B2",
    
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Fabrikam Workshop Team Deployment                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Verify logged in to correct tenant
Write-Host "Verifying Azure login..." -ForegroundColor Cyan
$currentAccount = az account show --query "{Tenant:tenantId, User:user.name, Subscription:name}" -o json | ConvertFrom-Json

if (-not $currentAccount) {
    Write-Host "  ✗ Not logged in to Azure" -ForegroundColor Red
    Write-Host "`n  Please login to the Fabrikam tenant:" -ForegroundColor Yellow
    Write-Host "  az login --tenant fabrikam1.csplevelup.com" -ForegroundColor Yellow
    Write-Host "  OR" -ForegroundColor Yellow
    Write-Host "  az login --tenant fd268415-22a5-4064-9b5e-d039761c5971" -ForegroundColor Yellow
    exit 1
}

$fabrikamTenantId = "fd268415-22a5-4064-9b5e-d039761c5971"

if ($currentAccount.Tenant -ne $fabrikamTenantId) {
    Write-Host "  ⚠️  Wrong tenant detected!" -ForegroundColor Yellow
    Write-Host "    Current:  $($currentAccount.Tenant)" -ForegroundColor Red
    Write-Host "    Expected: $fabrikamTenantId (fabrikam1.csplevelup.com)" -ForegroundColor Green
    Write-Host "`n  Please login to the correct tenant:" -ForegroundColor Yellow
    Write-Host "  az login --tenant fabrikam1.csplevelup.com" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ Logged in as: $($currentAccount.User)" -ForegroundColor Green
Write-Host "  ✓ Tenant: fabrikam1.csplevelup.com" -ForegroundColor Green
Write-Host "  ✓ Subscription: $($currentAccount.Subscription)" -ForegroundColor Green

# Generate unique 6-character suffix (lowercase letters only)
$suffix = -join ((97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})

# Resource names
$resourceGroupName = "rg-fabrikam-team-$TeamId"
$baseName = "fabrikam"
$environment = "workshop"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Team ID:            $TeamId $(if ($TeamId -eq '00') { '(Proctor)' })"
Write-Host "  Resource Group:     $resourceGroupName"
Write-Host "  Location:           $Location"
Write-Host "  Unique Suffix:      $suffix"
Write-Host "  SKU:                $SkuName (2 cores, 3.5GB RAM)"
Write-Host "  Authentication:     Disabled (workshop default)"
Write-Host "  Database:           InMemory (workshop default)"
Write-Host "  WhatIf Mode:        $WhatIf`n"

if ($WhatIf) {
    Write-Host "WhatIf mode - would create:" -ForegroundColor Gray
    Write-Host "  • Resource Group: $resourceGroupName"
    Write-Host "  • App Service Plan: asp-fabrikam-workshop-$suffix"
    Write-Host "  • API App: fabrikam-api-workshop-$suffix"
    Write-Host "  • MCP App: fabrikam-mcp-workshop-$suffix"
    Write-Host "  • SIM App: fabrikam-sim-workshop-$suffix"
    Write-Host "  • Key Vault: kv-workshop-$suffix (for JWT secrets)"
    Write-Host "`nNo resources created in WhatIf mode." -ForegroundColor Gray
    exit 0
}

# Confirmation
Write-Host "⚠️  This will create Azure resources with estimated cost:" -ForegroundColor Yellow
Write-Host "   - B2 App Service Plan: ~`$26/month" -ForegroundColor Yellow
Write-Host "   - Key Vault: ~`$0.03/month (minimal usage)" -ForegroundColor Yellow
Write-Host "   - Total: ~`$26/month for workshop duration`n" -ForegroundColor Yellow

$confirm = Read-Host "Continue with deployment? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n[1/3] Creating resource group..." -ForegroundColor Cyan
try {
    $rgResult = az group create `
        --name $resourceGroupName `
        --location $Location `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Resource group created: $resourceGroupName" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed to create resource group" -ForegroundColor Red
        Write-Host "`n  Error details:" -ForegroundColor Yellow
        Write-Host $rgResult -ForegroundColor Red
        
        Write-Host "`n  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Verify you have Contributor/Owner role on subscription" -ForegroundColor Yellow
        Write-Host "  - Check if resource group already exists: az group show --name $resourceGroupName" -ForegroundColor Yellow
        Write-Host "  - Try a different location: -Location eastus" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  ✗ Exception creating resource group" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/3] Getting deployer Object ID for Key Vault permissions..." -ForegroundColor Cyan
try {
    $userObjectId = az ad signed-in-user show --query id -o tsv
    if ($LASTEXITCODE -eq 0 -and $userObjectId) {
        Write-Host "  ✓ User Object ID: $userObjectId" -ForegroundColor Green
    } else {
        throw "Failed to get user Object ID"
    }
} catch {
    Write-Host "  ✗ Failed to get user Object ID" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  Tip: Make sure you're logged in with 'az login'" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[3/3] Deploying ARM template..." -ForegroundColor Cyan
Write-Host "  This may take 3-5 minutes..." -ForegroundColor Gray

# Build parameter object
$parameters = @{
    baseName = $baseName
    environment = "development"  # ARM template only allows development/production
    skuName = $SkuName
    databaseProvider = "InMemory"
    authenticationMode = "Disabled"
    userObjectId = $userObjectId
    _artifactsLocation = "https://raw.githubusercontent.com/davebirr/Fabrikam-Project/main/deployment/"
}

# Convert to JSON for parameter file
$paramJson = @{
    "`$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters = @{}
}

foreach ($key in $parameters.Keys) {
    $paramJson.parameters[$key] = @{ value = $parameters[$key] }
}

$tempParamFile = [System.IO.Path]::GetTempFileName()
$paramJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempParamFile -Encoding utf8

try {
    # Deploy using ARM template
    $deploymentName = "deploy-team-$TeamId-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    # Run deployment and capture output
    Write-Host "  Deployment name: $deploymentName" -ForegroundColor Gray
    
    $deployResult = az deployment group create `
        --name $deploymentName `
        --resource-group $resourceGroupName `
        --template-file "deployment/AzureDeploymentTemplate.modular.json" `
        --parameters "@$tempParamFile" `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Deployment completed successfully!" -ForegroundColor Green
        $outputs = $deployResult | ConvertFrom-Json
    } else {
        Write-Host "  ✗ Deployment failed" -ForegroundColor Red
        Write-Host "`n  Error details:" -ForegroundColor Yellow
        Write-Host $deployResult -ForegroundColor Red
        
        Write-Host "`n  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  - Check Azure Portal: https://portal.azure.com/#view/HubsExtension/DeploymentDetailsBlade/~/overview/id/%2Fsubscriptions%2F<sub-id>%2FresourceGroups%2F$resourceGroupName%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F$deploymentName" -ForegroundColor Yellow
        Write-Host "  - Verify you have Contributor role on subscription" -ForegroundColor Yellow
        Write-Host "  - Check if Key Vault name is already taken (must be globally unique)" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  ✗ Deployment exception: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item -Path $tempParamFile -Force -ErrorAction SilentlyContinue
}

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Deployment Complete                                         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Parse deployment outputs
if ($outputs -and $outputs.properties -and $outputs.properties.outputs) {
    $outputValues = $outputs.properties.outputs
    Write-Host "`n✅ Team $TeamId Deployment Summary:" -ForegroundColor Green
    Write-Host "  Resource Group: $resourceGroupName"
    Write-Host "  API URL:        $($outputValues.apiUrl.value)"
    Write-Host "  MCP URL:        $($outputValues.mcpUrl.value)"
    Write-Host "  SIM URL:        $($outputValues.simUrl.value)"
    
    Write-Host "`n🧪 Quick Test Commands:" -ForegroundColor Yellow
    Write-Host "  # API Health Check"
    Write-Host "  curl $($outputValues.apiUrl.value)/api/info"
    Write-Host "`n  # MCP Tools List"
    Write-Host "  Invoke-RestMethod -Uri '$($outputValues.mcpUrl.value)/mcp' -Method Post -ContentType 'application/json' -Body '{`"jsonrpc`":`"2.0`",`"method`":`"tools/list`",`"id`":1}' -SkipCertificateCheck"
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Test the endpoints above to verify deployment"
    Write-Host "  2. Configure Copilot Studio to use MCP URL"
    Write-Host "  3. Deploy code via GitHub Actions or manual publish"
    Write-Host "  4. Share API/MCP URLs with team $TeamId"
    
    Write-Host "`n🗑️  Cleanup (after workshop):" -ForegroundColor Gray
    Write-Host "  az group delete --name $resourceGroupName --yes --no-wait"
} else {
    Write-Host "`n⚠️  Deployment succeeded but could not retrieve outputs" -ForegroundColor Yellow
    Write-Host "  Check Azure Portal for resource details: https://portal.azure.com" -ForegroundColor Yellow
}
