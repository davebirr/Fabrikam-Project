<#
.SYNOPSIS
    Deploy Azure infrastructure for workshop instances using Bicep templates.

.DESCRIPTION
    Deploys FabrikamApi and FabrikamMcp infrastructure for workshop teams.
    Supports deploying single instance (proctor) or multiple team instances (1-20).
    
    This script provisions:
    - Resource Group
    - App Service Plan (shared per instance)
    - App Service for FabrikamApi
    - App Service for FabrikamMcp
    - Application Insights
    - Log Analytics Workspace
    - Key Vault (for secrets)

.PARAMETER InstanceName
    Name of the instance to deploy (e.g., "proctor", "team-01", "team-02")

.PARAMETER TenantId
    Azure AD Tenant ID for the workshop

.PARAMETER SubscriptionId
    Azure Subscription ID

.PARAMETER Location
    Azure region for deployment (default: eastus)

.PARAMETER DeployAll
    Deploy all 21 instances (proctor + team-01 through team-20)

.PARAMETER DeployTeams
    Deploy only the 20 team instances (team-01 through team-20)

.PARAMETER WhatIf
    Show what would be deployed without making changes

.EXAMPLE
    # Deploy proctor instance for testing
    .\Deploy-WorkshopInfrastructure.ps1 `
        -InstanceName "proctor" `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionId "YOUR_SUBSCRIPTION_ID"

.EXAMPLE
    # Deploy specific team instance
    .\Deploy-WorkshopInfrastructure.ps1 `
        -InstanceName "team-05" `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionId "YOUR_SUBSCRIPTION_ID"

.EXAMPLE
    # Deploy all 20 team instances (after Friday testing)
    .\Deploy-WorkshopInfrastructure.ps1 `
        -DeployTeams `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionId "YOUR_SUBSCRIPTION_ID"

.EXAMPLE
    # Deploy all 21 instances (proctor + 20 teams)
    .\Deploy-WorkshopInfrastructure.ps1 `
        -DeployAll `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionId "YOUR_SUBSCRIPTION_ID"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
    
    Workshop: CS Agent-A-Thon (November 6, 2025)
    Participants: 126 Microsoft employees (19 proctors + 107 participants)
#>

[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
    [ValidatePattern('^(proctor|team-\d{2})$')]
    [string]$InstanceName,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$UserObjectId,
    
    [Parameter()]
    [string]$Location = "westus2",
    
    [Parameter(ParameterSetName = 'All')]
    [switch]$DeployAll,
    
    [Parameter(ParameterSetName = 'Teams')]
    [switch]$DeployTeams,
    
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

#region Helper Functions

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Deploy-Instance {
    param(
        [string]$Name,
        [string]$Tenant,
        [string]$Subscription,
        [string]$Region,
        [string]$DeployerObjectId
    )
    
    Write-Header "Deploying Instance: $Name"
    
    # Resource naming (match ARM template pattern)
    $resourceGroupName = "rg-agentathon-$Name"
    $apiAppName = "fabrikam-api-$Name"
    $mcpAppName = "fabrikam-mcp-$Name"
    $apiPlanName = "plan-api-$Name"
    $mcpPlanName = "plan-mcp-$Name"
    $apiInsightsName = "appi-api-$Name"
    $mcpInsightsName = "appi-mcp-$Name"
    $logAnalyticsName = "law-fabrikam-$Name"
    $keyVaultName = "kv-fab-$Name-$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    Write-Info "Resource Group: $resourceGroupName"
    Write-Info "API App: $apiAppName"
    Write-Info "MCP App: $mcpAppName"
    Write-Info "Location: $Region"
    
    if ($DryRun) {
        Write-Warning "DryRun mode - no resources will be created"
        return @{
            ResourceGroup = $resourceGroupName
            ApiApp = $apiAppName
            McpApp = $mcpAppName
        }
    }
    
    try {
        # Create Resource Group
        Write-Info "Creating resource group..."
        az group create `
            --name $resourceGroupName `
            --location $Region `
            --tags `
                "workshop=agent-a-thon" `
                "instance=$Name" `
                "workshop-date=2025-11-06" `
                "environment=workshop" | Out-Null
        
        Write-Success "Resource group created: $resourceGroupName"
        
        # Create Log Analytics Workspace (shared by both apps)
        Write-Info "Creating Log Analytics workspace..."
        az monitor log-analytics workspace create `
            --workspace-name $logAnalyticsName `
            --resource-group $resourceGroupName `
            --location $Region | Out-Null
        
        $workspaceId = az monitor log-analytics workspace show `
            --workspace-name $logAnalyticsName `
            --resource-group $resourceGroupName `
            --query "id" -o tsv
        
        # Create API Application Insights
        Write-Info "Creating API Application Insights..."
        az monitor app-insights component create `
            --app $apiInsightsName `
            --resource-group $resourceGroupName `
            --location $Region `
            --workspace $workspaceId | Out-Null
        
        $apiConnectionString = az monitor app-insights component show `
            --app $apiInsightsName `
            --resource-group $resourceGroupName `
            --query "connectionString" -o tsv
        
        # Create MCP Application Insights
        Write-Info "Creating MCP Application Insights..."
        az monitor app-insights component create `
            --app $mcpInsightsName `
            --resource-group $resourceGroupName `
            --location $Region `
            --workspace $workspaceId | Out-Null
        
        $mcpConnectionString = az monitor app-insights component show `
            --app $mcpInsightsName `
            --resource-group $resourceGroupName `
            --query "connectionString" -o tsv
        
        Write-Success "Monitoring resources created"
        
        # Create API App Service Plan
        Write-Info "Creating API App Service Plan..."
        az appservice plan create `
            --name $apiPlanName `
            --resource-group $resourceGroupName `
            --location $Region `
            --is-linux `
            --sku S1 | Out-Null
        
        # Create MCP App Service Plan
        Write-Info "Creating MCP App Service Plan..."
        az appservice plan create `
            --name $mcpPlanName `
            --resource-group $resourceGroupName `
            --location $Region `
            --is-linux `
            --sku S1 | Out-Null
        
        Write-Success "App Service Plans created"
        
        # Create Key Vault
        Write-Info "Creating Key Vault..."
        az keyvault create `
            --name $keyVaultName `
            --resource-group $resourceGroupName `
            --location $Region `
            --enable-rbac-authorization true | Out-Null
        
        Write-Success "Key Vault created: $keyVaultName"
        
        # Create API App Service
        Write-Info "Creating FabrikamApi App Service..."
        az webapp create `
            --name $apiAppName `
            --resource-group $resourceGroupName `
            --plan $appServicePlanName `
            --runtime "DOTNETCORE:9.0" | Out-Null
        
        # Configure API App Settings
        az webapp config appsettings set `
            --resource-group $resourceGroupName `
            --name $apiAppName `
            --settings `
                "APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=$instrumentationKey" `
                "ApplicationInsightsAgent_EXTENSION_VERSION=~3" `
                "XDT_MicrosoftApplicationInsights_Mode=recommended" `
                "DatabaseProvider=InMemory" `
                "Authentication__Mode=Disabled" `
                "Authentication__EnableUserTracking=true" `
                "ASPNETCORE_ENVIRONMENT=Production" | Out-Null
        
        # Enable managed identity for API
        $apiPrincipalId = az webapp identity assign `
            --resource-group $resourceGroupName `
            --name $apiAppName `
            --query "principalId" -o tsv
        
        Write-Success "FabrikamApi created: https://$apiAppName.azurewebsites.net"
        
        # Create MCP App Service
        Write-Info "Creating FabrikamMcp App Service..."
        az webapp create `
            --name $mcpAppName `
            --resource-group $resourceGroupName `
            --plan $appServicePlanName `
            --runtime "DOTNETCORE:9.0" | Out-Null
        
        # Configure MCP App Settings
        az webapp config appsettings set `
            --resource-group $resourceGroupName `
            --name $mcpAppName `
            --settings `
                "APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=$instrumentationKey" `
                "ApplicationInsightsAgent_EXTENSION_VERSION=~3" `
                "XDT_MicrosoftApplicationInsights_Mode=recommended" `
                "FabrikamApi__BaseUrl=https://$apiAppName.azurewebsites.net" `
                "ASPNETCORE_ENVIRONMENT=Production" | Out-Null
        
        # Enable managed identity for MCP
        $mcpPrincipalId = az webapp identity assign `
            --resource-group $resourceGroupName `
            --name $mcpAppName `
            --query "principalId" -o tsv
        
        Write-Success "FabrikamMcp created: https://$mcpAppName.azurewebsites.net"
        
        # Configure Key Vault RBAC role assignments
        Write-Info "Configuring Key Vault permissions..."
        
        # Get Key Vault resource ID
        $keyVaultId = az keyvault show `
            --name $keyVaultName `
            --resource-group $resourceGroupName `
            --query "id" -o tsv
        
        # Key Vault Secrets User role ID (built-in Azure role)
        $secretsUserRoleId = "4633458b-17de-408a-b874-0445c86b69e6"
        
        # Key Vault Secrets Officer role ID (built-in Azure role)
        $secretsOfficerRoleId = "b86a8fe4-44ce-4948-aee5-eccb2c155cd7"
        
        # Assign Key Vault Secrets User role to API managed identity
        az role assignment create `
            --assignee $apiPrincipalId `
            --role $secretsUserRoleId `
            --scope $keyVaultId | Out-Null
        
        # Assign Key Vault Secrets User role to MCP managed identity
        az role assignment create `
            --assignee $mcpPrincipalId `
            --role $secretsUserRoleId `
            --scope $keyVaultId | Out-Null
        
        # Assign Key Vault Secrets Officer role to deploying user (if provided)
        if ($DeployerObjectId) {
            az role assignment create `
                --assignee $DeployerObjectId `
                --role $secretsOfficerRoleId `
                --scope $keyVaultId | Out-Null
        }
        
        Write-Success "Key Vault permissions configured"
        
        Write-Header "✅ Deployment Complete: $Name"
        Write-Host ""
        Write-Host "Resource Group:  $resourceGroupName" -ForegroundColor White
        Write-Host "API URL:         https://$apiAppName.azurewebsites.net" -ForegroundColor Green
        Write-Host "MCP URL:         https://$mcpAppName.azurewebsites.net" -ForegroundColor Green
        Write-Host "Key Vault:       $keyVaultName" -ForegroundColor White
        Write-Host ""
        
        return @{
            ResourceGroup = $resourceGroupName
            ApiApp = $apiAppName
            ApiUrl = "https://$apiAppName.azurewebsites.net"
            McpApp = $mcpAppName
            McpUrl = "https://$mcpAppName.azurewebsites.net"
            KeyVault = $keyVaultName
        }
    }
    catch {
        Write-Error "Deployment failed for $Name : $_"
        throw
    }
}

#endregion

#region Main Execution

Write-Header "Workshop Infrastructure Deployment"

# Validate Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI not found. Install from: https://aka.ms/installazurecli"
    exit 1
}

# Set Azure context
Write-Info "Setting Azure context..."
az account set --subscription $SubscriptionId

$currentTenant = az account show --query "tenantId" -o tsv
if ($currentTenant -ne $TenantId) {
    Write-Warning "Current tenant: $currentTenant"
    Write-Error "Not logged into correct tenant. Run: az login --tenant $TenantId"
    exit 1
}

Write-Success "Connected to subscription: $SubscriptionId"
Write-Success "Using tenant: $TenantId"

# Get deployer's User Object ID if not provided
if (-not $UserObjectId) {
    Write-Info "Getting your User Object ID for Key Vault permissions..."
    $UserObjectId = az ad signed-in-user show --query "id" -o tsv
    if ($LASTEXITCODE -ne 0 -or -not $UserObjectId) {
        Write-Warning "Could not auto-detect User Object ID. Key Vault permissions will not be set for deploying user."
        Write-Warning "You can manually get your Object ID with: az ad signed-in-user show --query id -o tsv"
        $UserObjectId = $null
    } else {
        Write-Success "Deployer Object ID: $UserObjectId"
    }
}

# Determine what to deploy
$instancesToDeploy = @()

if ($DeployAll) {
    $instancesToDeploy += "proctor"
    $instancesToDeploy += 1..20 | ForEach-Object { "team-{0:D2}" -f $_ }
}
elseif ($DeployTeams) {
    $instancesToDeploy = 1..20 | ForEach-Object { "team-{0:D2}" -f $_ }
}
else {
    $instancesToDeploy = @($InstanceName)
}

Write-Info "Instances to deploy: $($instancesToDeploy.Count)"
Write-Host ($instancesToDeploy -join ", ") -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    $confirm = Read-Host "Proceed with deployment? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Warning "Deployment cancelled"
        exit 0
    }
}

# Deploy instances
$results = @()
$startTime = Get-Date

foreach ($instance in $instancesToDeploy) {
    $result = Deploy-Instance -Name $instance -Tenant $TenantId -Subscription $SubscriptionId -Region $Location -DeployerObjectId $UserObjectId
    $results += $result
}

$duration = (Get-Date) - $startTime

# Summary
Write-Header "🎉 All Deployments Complete"

Write-Host "Total instances deployed: $($results.Count)" -ForegroundColor Green
Write-Host "Total time: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
Write-Host ""

# Output results to JSON for GitHub Actions
$outputPath = "deployment-results.json"
$results | ConvertTo-Json -Depth 10 | Out-File $outputPath
Write-Success "Deployment results saved to: $outputPath"

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure GitHub Actions secrets (AZURE_CREDENTIALS)" -ForegroundColor White
Write-Host "2. Test proctor deployment with GitHub Actions workflow" -ForegroundColor White
Write-Host "3. After testing, deploy remaining team instances" -ForegroundColor White
Write-Host "4. Update workshop documentation with URLs" -ForegroundColor White
Write-Host ""

#endregion
