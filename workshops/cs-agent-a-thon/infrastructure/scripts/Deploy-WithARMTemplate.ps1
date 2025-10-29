<#
.SYNOPSIS
    Deploy workshop instances using the proven ARM template

.DESCRIPTION
    Uses the same ARM template that has been working for months
    Just wraps it for multi-instance workshop deployment
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(proctor|team-\d{2})$')]
    [string]$InstanceName,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$Location = "westus2"
)

$ErrorActionPreference = "Stop"

# Set Azure context
Write-Host "Setting Azure context..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId

# Get deployer User Object ID
Write-Host "Getting your User Object ID..." -ForegroundColor Cyan
$userObjectId = az ad signed-in-user show --query "id" -o tsv

if (-not $userObjectId) {
    Write-Error "Could not get User Object ID. Make sure you're logged in with: az login --tenant $TenantId"
    exit 1
}

Write-Host "User Object ID: $userObjectId" -ForegroundColor Green

# Create resource group with instance-specific name
$resourceGroupName = "rg-agentathon-$InstanceName"

Write-Host "`nCreating resource group: $resourceGroupName" -ForegroundColor Cyan
az group create `
    --name $resourceGroupName `
    --location $Location `
    --tags `
        "instance=$InstanceName" `
        "workshop=cs-agent-a-thon" `
        "workshop-date=2025-11-06"

# Path to the ARM template (the one that works!)
$templatePath = Join-Path $PSScriptRoot "..\..\..\..\deployment\AzureDeploymentTemplate.modular.json"

if (-not (Test-Path $templatePath)) {
    Write-Error "ARM template not found at: $templatePath"
    exit 1
}

Write-Host "`nDeploying with ARM template..." -ForegroundColor Cyan
Write-Host "Template: $templatePath" -ForegroundColor Gray
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Gray
Write-Host "Authentication: Disabled" -ForegroundColor Gray
Write-Host "Database: InMemory" -ForegroundColor Gray

# Deploy using the ARM template
az deployment group create `
    --resource-group $resourceGroupName `
    --template-file $templatePath `
    --parameters `
        baseName="fabrikam" `
        environment="$InstanceName" `
        authenticationMode="Disabled" `
        databaseProvider="InMemory" `
        userObjectId="$userObjectId" `
        location="$Location" `
        skuName="S1"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
    
    # Get outputs
    $outputs = az deployment group show `
        --resource-group $resourceGroupName `
        --name "AzureDeploymentTemplate.modular" `
        --query "properties.outputs" -o json | ConvertFrom-Json
    
    Write-Host "`n📊 Deployment Details:" -ForegroundColor Cyan
    Write-Host "Resource Group: $resourceGroupName" -ForegroundColor White
    
    if ($outputs.apiUrl) {
        Write-Host "API URL: $($outputs.apiUrl.value)" -ForegroundColor White
    }
    
    if ($outputs.mcpUrl) {
        Write-Host "MCP URL: $($outputs.mcpUrl.value)" -ForegroundColor White
    }
} else {
    Write-Error "Deployment failed!"
    exit 1
}
