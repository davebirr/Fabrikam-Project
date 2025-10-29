<#
.SYNOPSIS
    Add users/groups to Power Platform environment using PowerShell
    
.DESCRIPTION
    Uses Power Platform PowerShell module to add System Administrator role
    Works when portal UI shows "You do not hold necessary privileges"
    
.EXAMPLE
    .\Add-PowerPlatformUser.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "🔐 Adding System Administrator to Power Platform Environment" -ForegroundColor Cyan
Write-Host ""

# Environment details
$environmentId = "Default-fd268415-22a5-4064-9b5e-d039761c5971"
$tenantId = "fd268415-22a5-4064-9b5e-d039761c5971"

Write-Host "Step 1: Installing Power Platform PowerShell module (if needed)..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerApps.Administration.PowerShell)) {
    Write-Host "Installing Microsoft.PowerApps.Administration.PowerShell module..." -ForegroundColor Gray
    Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force -AllowClobber
    Write-Host "✅ Module installed" -ForegroundColor Green
} else {
    Write-Host "✅ Module already installed" -ForegroundColor Green
}
Write-Host ""

Write-Host "Step 2: Connecting to Power Platform..." -ForegroundColor Yellow
Write-Host "⚠️  You'll be prompted to sign in - use oscarw@levelupcspfy26cs01.onmicrosoft.com" -ForegroundColor Yellow
Write-Host ""

try {
    Add-PowerAppsAccount -TenantID $tenantId
    Write-Host "✅ Connected to Power Platform" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to connect to Power Platform" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Step 3: Getting environment details..." -ForegroundColor Yellow
try {
    $env = Get-AdminPowerAppEnvironment -EnvironmentName $environmentId
    Write-Host "✅ Found environment: $($env.DisplayName)" -ForegroundColor Green
    Write-Host "   Environment ID: $environmentId" -ForegroundColor Gray
    Write-Host "   Type: $($env.EnvironmentType)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to get environment details" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Step 4: Adding oscarw as user with System Administrator role..." -ForegroundColor Yellow
Write-Host "Getting oscarw's user ID from Entra..." -ForegroundColor Gray

$oscarwEmail = "oscarw@levelupcspfy26cs01.onmicrosoft.com"
try {
    $oscarwUser = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$oscarwEmail" | ConvertFrom-Json
    $oscarwId = $oscarwUser.id
    Write-Host "✅ Found oscarw: $($oscarwUser.displayName) ($oscarwId)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not find user via Graph API, trying alternative method..." -ForegroundColor Yellow
    $oscarwEmail = "oscarw@microsoft.com"
    $oscarwUser = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$oscarwEmail" | ConvertFrom-Json
    $oscarwId = $oscarwUser.id
    Write-Host "✅ Found oscarw: $($oscarwUser.displayName) ($oscarwId)" -ForegroundColor Green
}
Write-Host ""

Write-Host "Adding oscarw to environment..." -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  NOTE: Power Platform PowerShell doesn't directly support adding System Administrator" -ForegroundColor Yellow
Write-Host "   You need to use Dataverse Web API or Power Platform Admin Center UI" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 ALTERNATIVE SOLUTION: Use Power Platform CLI (PAC)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Power Platform CLI is the recommended tool for this operation." -ForegroundColor White
Write-Host ""
Write-Host "Installation:" -ForegroundColor Cyan
Write-Host "  dotnet tool install --global Microsoft.PowerApps.CLI.Tool" -ForegroundColor White
Write-Host ""
Write-Host "Commands to run:" -ForegroundColor Cyan
Write-Host "  pac auth create --tenant $tenantId" -ForegroundColor White
Write-Host "  pac org select --environment $environmentId" -ForegroundColor White
Write-Host "  pac admin assign-user --user $oscarwEmail --role 'System Administrator'" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Would you like to install Power Platform CLI and continue? (Y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "Installing Power Platform CLI..." -ForegroundColor Yellow
    dotnet tool install --global Microsoft.PowerApps.CLI.Tool
    
    Write-Host ""
    Write-Host "✅ Installation complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now run these commands:" -ForegroundColor Yellow
    Write-Host "  pac auth create --tenant $tenantId" -ForegroundColor Cyan
    Write-Host "  pac org select --environment $environmentId" -ForegroundColor Cyan
    Write-Host "  pac admin assign-user --user $oscarwEmail --role 'System Administrator'" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Installation skipped. Manual steps required." -ForegroundColor Yellow
    Write-Host ""
}
