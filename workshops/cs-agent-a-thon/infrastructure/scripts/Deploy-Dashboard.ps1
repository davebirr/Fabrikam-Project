#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy FabrikamDashboard to an existing resource group
.DESCRIPTION
    Builds and deploys the FabrikamDashboard to a specified team's resource group
.PARAMETER TeamNumber
    Team number (e.g., 00, 24)
.PARAMETER ResourceGroup
    Resource group name (default: rg-fabrikam-team-{TeamNumber})
.EXAMPLE
    .\Deploy-Dashboard.ps1 -TeamNumber 00
    Deploy dashboard to team-00
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TeamNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

# Header
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 Deploy FabrikamDashboard" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Set resource group name
if (-not $ResourceGroup) {
    $ResourceGroup = "rg-fabrikam-team-$TeamNumber"
}

Write-Info "Target: $ResourceGroup"
Write-Host ""

# Check Azure login
Write-Info "Checking Azure authentication..."
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Success "Authenticated as: $($account.user.name)"
    Write-Info "Subscription: $($account.name)"
} catch {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

Write-Host ""

# Check if resource group exists
Write-Info "Checking resource group..."
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Error "Resource group '$ResourceGroup' does not exist"
    exit 1
}
Write-Success "Resource group found"
Write-Host ""

# Get or create web app
Write-Info "Checking for existing dashboard web app..."
$dashboardApps = az webapp list -g $ResourceGroup --query "[?contains(name, 'dash')].[name]" -o tsv

if ($dashboardApps) {
    $appName = $dashboardApps
    Write-Success "Found existing dashboard: $appName"
} else {
    Write-Info "No dashboard found. Creating new web app..."
    
    # Get the existing App Service Plan
    $aspName = az appservice plan list -g $ResourceGroup --query "[0].name" -o tsv
    
    if (-not $aspName) {
        Write-Error "No App Service Plan found in $ResourceGroup"
        exit 1
    }
    
    Write-Info "Using App Service Plan: $aspName"
    
    # Extract suffix from existing app (API, MCP, or Sim) to maintain consistency
    $existingApp = az webapp list -g $ResourceGroup --query "[?contains(name, 'api') || contains(name, 'mcp') || contains(name, 'sim')].name" -o tsv | Select-Object -First 1
    
    if ($existingApp -match '-([a-z0-9]{6})$') {
        $uniqueSuffix = $matches[1]
        Write-Info "Using existing suffix from $existingApp : $uniqueSuffix"
    } else {
        # Fallback: generate new suffix if pattern not found
        $uniqueSuffix = -join ((97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
        Write-Warning "Could not extract suffix from existing apps, generating new: $uniqueSuffix"
    }
    
    $appName = "fabrikam-dash-dev-$uniqueSuffix"
    
    Write-Info "Creating web app: $appName"
    
    az webapp create `
        --name $appName `
        --resource-group $ResourceGroup `
        --plan $aspName `
        --runtime "DOTNETCORE:9.0" `
        2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create web app"
        exit 1
    }
    
    Write-Success "Web app created: $appName"
}

Write-Host ""

# Build and publish
Write-Info "Building FabrikamDashboard..."
$projectPath = Join-Path $PSScriptRoot "..\..\..\..\FabrikamDashboard\FabrikamDashboard.csproj"

if (-not (Test-Path $projectPath)) {
    Write-Error "Project not found: $projectPath"
    exit 1
}

try {
    dotnet restore $projectPath 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Restore failed" }
    
    dotnet build $projectPath --configuration Release --no-restore 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
    
    Write-Success "Build completed"
} catch {
    Write-Error "Build failed: $_"
    exit 1
}

Write-Host ""

# Publish
Write-Info "Publishing to temp directory..."
$publishDir = Join-Path $env:TEMP "fabrikam-dashboard-publish"
if (Test-Path $publishDir) {
    Remove-Item $publishDir -Recurse -Force
}

try {
    dotnet publish $projectPath -c Release -o $publishDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Publish failed" }
    Write-Success "Published to: $publishDir"
} catch {
    Write-Error "Publish failed: $_"
    exit 1
}

Write-Host ""

# Create deployment package
Write-Info "Creating deployment package..."
$zipPath = Join-Path $env:TEMP "dashboard.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

try {
    Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force
    Write-Success "Package created: $zipPath"
} catch {
    Write-Error "Failed to create deployment package: $_"
    exit 1
}

Write-Host ""

# Configure app settings
Write-Info "Configuring app settings..."

# Get API and Simulator URLs from the same resource group
$apiApp = az webapp list -g $ResourceGroup --query "[?contains(name, 'api')].defaultHostName" -o tsv | Select-Object -First 1
$simApp = az webapp list -g $ResourceGroup --query "[?contains(name, 'sim')].defaultHostName" -o tsv | Select-Object -First 1

$settings = @()

if ($apiApp) {
    $apiUrl = "https://$apiApp"
    Write-Info "API URL: $apiUrl"
    $settings += "FabrikamApi__BaseUrl=$apiUrl"
}

if ($simApp) {
    $simUrl = "https://$simApp"
    Write-Info "Simulator URL: $simUrl"
    $settings += "FabrikamSimulator__BaseUrl=$simUrl"
}

# Add critical authentication settings
$settings += "Authentication__Mode=Disabled"
$settings += "Dashboard__ServiceGuid=00000000-0000-0000-0000-000000000001"
Write-Info "Authentication Mode: Disabled"
Write-Info "Service GUID: 00000000-0000-0000-0000-000000000001"

if ($settings.Count -gt 0) {
    az webapp config appsettings set `
        --name $appName `
        --resource-group $ResourceGroup `
        --settings $settings `
        2>&1 | Out-Null
    
    Write-Success "App settings configured"
} else {
    Write-Warning "No app settings to configure"
}
Write-Host ""

# Deploy
Write-Info "Deploying to Azure..."
try {
    az webapp deployment source config-zip `
        --resource-group $ResourceGroup `
        --name $appName `
        --src $zipPath `
        2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) { throw "Deployment failed" }
    Write-Success "Deployment completed"
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host ""

# Get app URL
$appUrl = az webapp show -g $ResourceGroup -n $appName --query defaultHostName -o tsv
Write-Info "Waiting for app to warm up (30 seconds)..."
Start-Sleep -Seconds 30

# Health check
Write-Info "Running health check..."
try {
    $response = Invoke-WebRequest -Uri "https://$appUrl/" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Success "Dashboard is running!"
    } else {
        Write-Warning "Dashboard returned HTTP $($response.StatusCode)"
    }
} catch {
    Write-Warning "Health check failed (app may still be starting): $_"
}

Write-Host ""

# Summary
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ Deployment Complete" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  App Name: $appName" -ForegroundColor White
Write-Host "  Dashboard URL: https://$appUrl" -ForegroundColor Green
Write-Host ""

# Cleanup
Write-Info "Cleaning up temporary files..."
if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Write-Success "Cleanup complete"

Write-Host ""
Write-Success "🎉 Dashboard deployed successfully!"
Write-Host ""
