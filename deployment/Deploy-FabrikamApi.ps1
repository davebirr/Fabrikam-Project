# Deploy-FabrikamApi.ps1
# PowerShell script to deploy Fabrikam API with authentication mode selection

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disabled', 'BearerToken', 'EntraExternalId')]
    [string]$AuthenticationMode,
    
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    # EntraExternalId specific parameters
    [Parameter(Mandatory = $false)]
    [string]$EntraExternalIdTenant,
    
    [Parameter(Mandatory = $false)]
    [string]$EntraExternalIdClientId,
    
    [Parameter(Mandatory = $false)]
    [SecureString]$EntraExternalIdClientSecret,
    
    [Parameter(Mandatory = $false)]
    [string]$AppServiceSku = "F1",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "🚀 Fabrikam API Deployment Script" -ForegroundColor Cyan
Write-Host "Authentication Mode: $AuthenticationMode" -ForegroundColor Yellow
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow

# Validate Azure CLI is installed
try {
    $azVersion = az --version 2>$null
    if (-not $azVersion) {
        throw "Azure CLI not found"
    }
    Write-Host "✅ Azure CLI found" -ForegroundColor Green
} catch {
    Write-Error "❌ Azure CLI is required. Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if logged in to Azure
try {
    $currentUser = az account show --query user.name -o tsv 2>$null
    if (-not $currentUser) {
        throw "Not logged in"
    }
    Write-Host "✅ Logged in as: $currentUser" -ForegroundColor Green
} catch {
    Write-Error "❌ Please log in to Azure CLI: az login"
    exit 1
}

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "🔄 Setting subscription to: $SubscriptionId" -ForegroundColor Blue
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to set subscription"
        exit 1
    }
}

# Get current subscription info
$subscription = az account show --query "{id:id, name:name}" -o json | ConvertFrom-Json
Write-Host "📋 Using subscription: $($subscription.name) ($($subscription.id))" -ForegroundColor Green

# ============================================================================
# App Service SKU Quota Validation
# ============================================================================
# F1 (Free) and D1 (Shared) tiers use shared compute and don't require
# dedicated worker quotas. B1+ tiers require dedicated App Service worker
# quotas (separate from Compute VM quotas). New subscriptions often have
# zero dedicated worker quota, causing SubscriptionIsOverQuotaForSku errors.
# ============================================================================

$skuRequiresDedicatedWorkers = $AppServiceSku -notin @("F1", "D1")

if ($skuRequiresDedicatedWorkers) {
    Write-Host "🔍 Checking App Service worker quota for SKU '$AppServiceSku' in '$Location'..." -ForegroundColor Blue
    
    # Map SKU to worker tier for quota check
    $workerTier = switch -Wildcard ($AppServiceSku) {
        "B*"  { "Basic" }
        "S*"  { "Standard" }
        "P*"  { "Premium" }
        default { "Standard" }
    }
    
    try {
        # Check App Service worker availability by attempting to list available SKUs
        $availableSkus = az appservice list-locations --sku $AppServiceSku --query "[?name=='$Location']" -o json 2>$null | ConvertFrom-Json
        
        # Also check via resource provider quotas
        $webQuota = az rest --method GET `
            --url "https://management.azure.com/subscriptions/$($subscription.id)/providers/Microsoft.Web/listSitesAssignedToHostName?api-version=2023-12-01" `
            2>$null

        Write-Host "⚠️  SKU '$AppServiceSku' requires $workerTier tier App Service workers." -ForegroundColor Yellow
        Write-Host "   If deployment fails with 'SubscriptionIsOverQuotaForSku', your subscription" -ForegroundColor Yellow
        Write-Host "   has zero dedicated worker quota for this region." -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        Write-Host "   To fix:" -ForegroundColor Yellow
        Write-Host "   1. Use -AppServiceSku F1 (Free tier, no quota needed)" -ForegroundColor White
        Write-Host "   2. Request quota increase: Azure Portal > Quotas > Microsoft.Web" -ForegroundColor White
        Write-Host "      or file a support request for '$workerTier VMs' worker quota" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Host "⚠️  Could not verify App Service worker quota. Proceeding anyway." -ForegroundColor Yellow
        Write-Host "   If deployment fails with 'SubscriptionIsOverQuotaForSku', use -AppServiceSku F1" -ForegroundColor Yellow
    }
}

# Set default resource group name if not provided
if (-not $ResourceGroupName) {
    $ResourceGroupName = "rg-fabrikam-$EnvironmentName"
}

# Validate EntraExternalId parameters
if ($AuthenticationMode -eq "EntraExternalId") {
    if (-not $EntraExternalIdTenant) {
        $EntraExternalIdTenant = Read-Host "Enter Entra External ID tenant domain (e.g., contoso.onmicrosoft.com)"
        if (-not $EntraExternalIdTenant) {
            Write-Error "❌ Entra External ID tenant is required for EntraExternalId authentication mode"
            exit 1
        }
    }
    
    if (-not $EntraExternalIdClientId) {
        $EntraExternalIdClientId = Read-Host "Enter Entra External ID application client ID"
        if (-not $EntraExternalIdClientId) {
            Write-Error "❌ Entra External ID client ID is required for EntraExternalId authentication mode"
            exit 1
        }
    }
    
    if (-not $EntraExternalIdClientSecret) {
        $EntraExternalIdClientSecret = Read-Host "Enter Entra External ID client secret" -AsSecureString
        if (-not $EntraExternalIdClientSecret) {
            Write-Error "❌ Entra External ID client secret is required for EntraExternalId authentication mode"
            exit 1
        }
    }
    
    Write-Host "✅ EntraExternalId parameters validated" -ForegroundColor Green
}

# Get deployment user ID for Key Vault access
Write-Host "🔍 Getting current user object ID for Key Vault permissions..." -ForegroundColor Blue
$deploymentUserId = az ad signed-in-user show --query id -o tsv
if ($LASTEXITCODE -ne 0) {
    Write-Warning "⚠️ Could not get user object ID. Key Vault permissions may need to be set manually."
    $deploymentUserId = ""
}

# Prepare deployment parameters
$deploymentParams = @{
    environmentName = $EnvironmentName
    location = $Location  
    authenticationMode = $AuthenticationMode
    enableUserTracking = $true
    appServiceSku = $AppServiceSku
    deploymentUserId = $deploymentUserId
}

# Add EntraExternalId parameters if using that mode
if ($AuthenticationMode -eq "EntraExternalId") {
    $deploymentParams.entraExternalIdTenant = $EntraExternalIdTenant
    $deploymentParams.entraExternalIdClientId = $EntraExternalIdClientId
    # Convert SecureString to plain text for Azure deployment
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($EntraExternalIdClientSecret)
    $deploymentParams.entraExternalIdClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
}

# Create parameters file
$parameterFilePath = "deployment/parameters.temp.json"
$parametersJson = @{
    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters = @{}
}

foreach ($key in $deploymentParams.Keys) {
    $parametersJson.parameters[$key] = @{ value = $deploymentParams[$key] }
}

$parametersJson | ConvertTo-Json -Depth 4 | Out-File -FilePath $parameterFilePath -Encoding UTF8

try {
    Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "  Authentication Mode: $AuthenticationMode" -ForegroundColor White
    Write-Host "  App Service SKU: $AppServiceSku" -ForegroundColor White
    if ($AuthenticationMode -eq "EntraExternalId") {
        Write-Host "  Entra Tenant: $EntraExternalIdTenant" -ForegroundColor White
        Write-Host "  Entra Client ID: $EntraExternalIdClientId" -ForegroundColor White
    }
    
    if ($WhatIf) {
        Write-Host "🔍 WhatIf mode - no actual deployment will occur" -ForegroundColor Yellow
        Write-Host "Would deploy with parameters:" -ForegroundColor Yellow
        Get-Content $parameterFilePath | Write-Host
        return
    }
    
    # Confirm deployment
    $confirm = Read-Host "Do you want to proceed with deployment? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "❌ Deployment cancelled by user" -ForegroundColor Red
        return
    }
    
    Write-Host "🚀 Starting deployment..." -ForegroundColor Green
    
    # Deploy using Azure CLI
    $deploymentName = "fabrikam-api-$EnvironmentName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    $deployCommand = @(
        "az", "deployment", "sub", "create",
        "--name", $deploymentName,
        "--location", $Location,
        "--template-file", "deployment/bicep/main.bicep", 
        "--parameters", "@$parameterFilePath"
    )
    
    if ($Verbose) {
        $deployCommand += "--verbose"
    }
    
    Write-Host "Executing: $($deployCommand -join ' ')" -ForegroundColor Blue
    
    & $deployCommand[0] $deployCommand[1..($deployCommand.Length-1)]
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
        
        # Get deployment outputs
        Write-Host "📋 Deployment Outputs:" -ForegroundColor Cyan
        $outputs = az deployment sub show --name $deploymentName --query properties.outputs -o json | ConvertFrom-Json
        
        if ($outputs) {
            Write-Host "  API URI: $($outputs.API_URI.value)" -ForegroundColor White
            Write-Host "  Resource Group: $($outputs.AZURE_RESOURCE_GROUP.value)" -ForegroundColor White
            Write-Host "  Authentication Mode: $($outputs.AUTHENTICATION_MODE.value)" -ForegroundColor White
            
            if ($AuthenticationMode -eq "EntraExternalId") {
                Write-Host "  Entra Authority: $($outputs.ENTRA_AUTHORITY_URL.value)" -ForegroundColor White
                Write-Host "  Entra Well-Known: $($outputs.ENTRA_WELL_KNOWN_ENDPOINT.value)" -ForegroundColor White
                
                Write-Host "🔗 Next Steps for EntraExternalId:" -ForegroundColor Yellow
                Write-Host "  1. Configure redirect URIs in your Entra External ID app registration" -ForegroundColor White
                Write-Host "  2. Add API permissions and scopes as needed" -ForegroundColor White
                Write-Host "  3. Test OAuth flow using the API endpoints" -ForegroundColor White
            }
        }
        
        Write-Host "🎉 Fabrikam API deployed successfully with $AuthenticationMode authentication!" -ForegroundColor Green
    } else {
        Write-Error "❌ Deployment failed with exit code: $LASTEXITCODE"
        exit 1
    }
    
} finally {
    # Clean up temporary parameter file
    if (Test-Path $parameterFilePath) {
        Remove-Item $parameterFilePath -Force
    }
}
