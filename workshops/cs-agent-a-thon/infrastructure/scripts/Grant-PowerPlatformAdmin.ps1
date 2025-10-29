<#
.SYNOPSIS
    Grant Power Platform Administrator role to workshop organizers
    
.DESCRIPTION
    Assigns Power Platform Administrator role so users can:
    - Create custom connectors
    - Assign environment roles (Environment Maker, etc.)
    - Manage Power Platform environments
    
.PARAMETER UserPrincipalName
    The UPN of the user to grant admin rights (e.g., oscarw@microsoft.com)
    
.EXAMPLE
    .\Grant-PowerPlatformAdmin.ps1 -UserPrincipalName "oscarw@microsoft.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

$ErrorActionPreference = "Stop"

Write-Host "🔐 Granting Power Platform Administrator role" -ForegroundColor Cyan
Write-Host ""

# Power Platform Administrator role template ID (fixed GUID)
$powerPlatformAdminRoleId = "11648597-926c-4cf3-9c36-bcebb0ba8dcc"

Write-Host "Step 1: Getting user object ID..." -ForegroundColor Yellow
$user = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$UserPrincipalName" | ConvertFrom-Json

if (-not $user) {
    Write-Host "❌ User not found: $UserPrincipalName" -ForegroundColor Red
    exit 1
}

$userId = $user.id
Write-Host "✅ Found user: $($user.displayName) ($userId)" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Checking if user already has Power Platform Administrator role..." -ForegroundColor Yellow
$existingRoles = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$userId/memberOf" | ConvertFrom-Json

$hasPowerPlatformAdmin = $existingRoles.value | Where-Object { 
    $_.'@odata.type' -eq '#microsoft.graph.directoryRole' -and 
    $_.roleTemplateId -eq $powerPlatformAdminRoleId 
}

if ($hasPowerPlatformAdmin) {
    Write-Host "✅ User already has Power Platform Administrator role" -ForegroundColor Green
    Write-Host ""
    Write-Host "Current admin roles for $($user.displayName):" -ForegroundColor Cyan
    $existingRoles.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.directoryRole' } | 
        Select-Object -ExpandProperty displayName | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    exit 0
}

Write-Host "User does not have Power Platform Administrator role. Granting..." -ForegroundColor Gray
Write-Host ""

Write-Host "Step 3: Activating Power Platform Administrator role in tenant..." -ForegroundColor Yellow
# First ensure the role is activated in the tenant
try {
    $role = az rest --method GET --uri "https://graph.microsoft.com/v1.0/directoryRoles?`$filter=roleTemplateId eq '$powerPlatformAdminRoleId'" | ConvertFrom-Json
    
    if ($role.value.Count -eq 0) {
        Write-Host "Activating role in tenant..." -ForegroundColor Gray
        $activateBody = @{
            roleTemplateId = $powerPlatformAdminRoleId
        } | ConvertTo-Json
        
        $role = az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles" --body $activateBody | ConvertFrom-Json
    } else {
        $role = $role.value[0]
    }
    
    $roleObjectId = $role.id
    Write-Host "✅ Role activated (Object ID: $roleObjectId)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to activate Power Platform Administrator role" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Step 4: Assigning role to user..." -ForegroundColor Yellow
try {
    $assignBody = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userId"
    } | ConvertTo-Json
    
    az rest --method POST --uri "https://graph.microsoft.com/v1.0/directoryRoles/$roleObjectId/members/`$ref" --body $assignBody | Out-Null
    
    Write-Host "✅ Power Platform Administrator role assigned to $($user.displayName)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to assign role" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "Step 5: Verifying assignment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$verifyRoles = az rest --method GET --uri "https://graph.microsoft.com/v1.0/users/$userId/memberOf" | ConvertFrom-Json
$verifyPowerPlatform = $verifyRoles.value | Where-Object { 
    $_.'@odata.type' -eq '#microsoft.graph.directoryRole' -and 
    $_.roleTemplateId -eq $powerPlatformAdminRoleId 
}

if ($verifyPowerPlatform) {
    Write-Host "✅ VERIFIED: Role assignment successful" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: Role may still be propagating (wait 5-10 minutes)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Power Platform Administrator Role Granted" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "User: $($user.displayName) ($UserPrincipalName)" -ForegroundColor White
Write-Host "Role: Power Platform Administrator" -ForegroundColor White
Write-Host ""
Write-Host "What $($user.displayName) can now do:" -ForegroundColor Yellow
Write-Host "  ✅ Create custom connectors in Power Platform" -ForegroundColor Green
Write-Host "  ✅ Assign Environment Maker role to users/groups" -ForegroundColor Green
Write-Host "  ✅ Manage Power Platform environments" -ForegroundColor Green
Write-Host "  ✅ Share connections with security groups" -ForegroundColor Green
Write-Host "  ✅ Create and manage Dataverse teams" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait 5-10 minutes for permissions to propagate" -ForegroundColor White
Write-Host "  2. Sign out and sign back in to Power Platform" -ForegroundColor White
Write-Host "  3. Navigate to: https://admin.powerplatform.microsoft.com" -ForegroundColor White
Write-Host "  4. Verify access to environment settings" -ForegroundColor White
Write-Host "  5. Assign Environment Maker role to Workshop-Team-Proctors" -ForegroundColor White
Write-Host ""
