#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Incrementally deploy FabrikamDashboard to existing Azure environment
.DESCRIPTION
    This script deploys only the dashboard app service to an existing resource group.
    It creates a new App Service Plan and configures the dashboard to connect to existing API and Simulator apps.
.PARAMETER ResourceGroup
    The name of the existing resource group (default: rg-agentathon-proctor)
.PARAMETER DashboardAppName
    The name for the dashboard app (default: fabrikam-dash-development-tzjeje)
.PARAMETER ApiAppName
    The name of the existing API app (default: fabrikam-api-development-tzjeje)
.PARAMETER SimAppName
    The name of the existing Simulator app (default: fabrikam-sim-development-tzjeje)
.PARAMETER SkipBuild
    Skip building the dashboard project (use if already built)
.PARAMETER SkipDeploy
    Skip deploying the code (only create infrastructure)
.EXAMPLE
    .\Deploy-Dashboard-Incremental.ps1
.EXAMPLE
    .\Deploy-Dashboard-Incremental.ps1 -ResourceGroup "rg-fabrikam-team-00" -DashboardAppName "fabrikam-dash-team-00"
#>

param(
    [string]$ResourceGroup = "rg-agentathon-proctor",
    [string]$DashboardAppName = "fabrikam-dash-development-tzjeje",
    [string]$ApiAppName = "fabrikam-api-development-tzjeje",
    [string]$SimAppName = "fabrikam-sim-development-tzjeje",
    [switch]$SkipBuild,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "`n🚀 Fabrikam Dashboard Incremental Deployment"
Write-Info "=" * 70

# Verify Azure CLI is logged in
Write-Info "`n📋 Checking Azure CLI authentication..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "❌ Not logged into Azure CLI. Please run 'az login' first."
    exit 1
}
Write-Success "✅ Logged in as: $($account.user.name)"
Write-Success "✅ Subscription: $($account.name)"

# Verify resource group exists
Write-Info "`n📋 Verifying resource group: $ResourceGroup"
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Error "❌ Resource group '$ResourceGroup' does not exist"
    exit 1
}
Write-Success "✅ Resource group exists"

# Verify API and Simulator apps exist
Write-Info "`n📋 Verifying existing apps..."
$apiApp = az webapp show --name $ApiAppName --resource-group $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $apiApp) {
    Write-Error "❌ API app '$ApiAppName' not found in resource group '$ResourceGroup'"
    exit 1
}
Write-Success "✅ API app found: $ApiAppName"

$simApp = az webapp show --name $SimAppName --resource-group $ResourceGroup 2>$null | ConvertFrom-Json
if (-not $simApp) {
    Write-Error "❌ Simulator app '$SimAppName' not found in resource group '$ResourceGroup'"
    exit 1
}
Write-Success "✅ Simulator app found: $SimAppName"

# Deploy ARM template
Write-Info "`n🏗️  Deploying dashboard infrastructure..."
$templateFile = Join-Path $PSScriptRoot "deploy-dashboard-incremental.json"

if (-not (Test-Path $templateFile)) {
    Write-Error "❌ Template file not found: $templateFile"
    exit 1
}

$deploymentName = "dashboard-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Info "Deployment name: $deploymentName"
Write-Info "Template file: $templateFile"

try {
    $deployment = az deployment group create `
        --name $deploymentName `
        --resource-group $ResourceGroup `
        --template-file $templateFile `
        --parameters `
            dashboardAppName=$DashboardAppName `
            apiAppName=$ApiAppName `
            simAppName=$SimAppName `
        --query "properties.outputs" `
        --output json | ConvertFrom-Json

    Write-Success "`n✅ Infrastructure deployment completed!"
    Write-Success "Dashboard App Name: $($deployment.dashboardAppName.value)"
    Write-Success "Dashboard URL: $($deployment.dashboardUrl.value)"
    Write-Success "Principal ID: $($deployment.dashboardPrincipalId.value)"
}
catch {
    Write-Error "`n❌ Infrastructure deployment failed: $_"
    exit 1
}

if ($SkipDeploy) {
    Write-Warning "`n⚠️  Skipping code deployment (--SkipDeploy flag set)"
    Write-Info "`nNext steps:"
    Write-Info "1. Build the dashboard: dotnet publish FabrikamDashboard/FabrikamDashboard.csproj -c Release -o ./publish"
    Write-Info "2. Deploy manually: az webapp deployment source config-zip --resource-group $ResourceGroup --name $DashboardAppName --src ./publish.zip"
    exit 0
}

# Build the dashboard
if (-not $SkipBuild) {
    Write-Info "`n🔨 Building FabrikamDashboard..."
    $publishDir = Join-Path $PSScriptRoot ".." "publish" "dashboard"
    
    # Clean previous build
    if (Test-Path $publishDir) {
        Remove-Item -Path $publishDir -Recurse -Force
    }
    
    # Build and publish
    dotnet publish (Join-Path $PSScriptRoot ".." "FabrikamDashboard" "FabrikamDashboard.csproj") `
        --configuration Release `
        --output $publishDir `
        --nologo
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Build failed"
        exit 1
    }
    
    Write-Success "✅ Build completed: $publishDir"
}
else {
    Write-Warning "⚠️  Skipping build (--SkipBuild flag set)"
    $publishDir = Join-Path $PSScriptRoot ".." "publish" "dashboard"
    
    if (-not (Test-Path $publishDir)) {
        Write-Error "❌ Publish directory not found: $publishDir"
        Write-Error "Run without --SkipBuild or build manually first"
        exit 1
    }
}

# Create deployment package
Write-Info "`n📦 Creating deployment package..."
$zipFile = Join-Path $PSScriptRoot ".." "publish" "dashboard.zip"

if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path "$publishDir\*" -DestinationPath $zipFile -Force
Write-Success "✅ Package created: $zipFile"

# Deploy to Azure
Write-Info "`n☁️  Deploying to Azure App Service..."
Write-Info "App Name: $DashboardAppName"
Write-Info "Resource Group: $ResourceGroup"

try {
    az webapp deployment source config-zip `
        --resource-group $ResourceGroup `
        --name $DashboardAppName `
        --src $zipFile `
        --timeout 600 | Out-Null
    
    Write-Success "`n✅ Code deployment completed!"
}
catch {
    Write-Error "`n❌ Code deployment failed: $_"
    exit 1
}

# Wait for app to start
Write-Info "`n⏳ Waiting for dashboard to start..."
Start-Sleep -Seconds 15

# Test the deployment
Write-Info "`n🧪 Testing dashboard endpoint..."
$dashboardUrl = "https://$DashboardAppName.azurewebsites.net"

try {
    $response = Invoke-WebRequest -Uri $dashboardUrl -Method Get -TimeoutSec 30 -ErrorAction SilentlyContinue
    
    if ($response.StatusCode -eq 200) {
        Write-Success "`n✅ Dashboard is responding!"
    }
    else {
        Write-Warning "`n⚠️  Dashboard returned status: $($response.StatusCode)"
        Write-Warning "The app may need more time to fully start."
    }
}
catch {
    Write-Warning "`n⚠️  Could not verify dashboard health: $_"
    Write-Warning "The app may need more time to fully start."
    Write-Warning "Check the Azure Portal for deployment logs."
}

# Summary
Write-Info "`n" + ("=" * 70)
Write-Success "🎉 DEPLOYMENT COMPLETE!"
Write-Info "`nDashboard Details:"
Write-Info "  • Name: $DashboardAppName"
Write-Info "  • URL: $dashboardUrl"
Write-Info "  • Resource Group: $ResourceGroup"
Write-Info "`nConfiguration:"
Write-Info "  • API: https://$ApiAppName.azurewebsites.net"
Write-Info "  • Simulator: https://$SimAppName.azurewebsites.net"
Write-Info "`nNext Steps:"
Write-Info "  1. Visit: $dashboardUrl"
Write-Info "  2. Verify real-time metrics are updating"
Write-Info "  3. Test simulator controls"
Write-Info "  4. Check Azure Portal for logs if needed"
Write-Info ("=" * 70)
Write-Info ""
