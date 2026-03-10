<#
.SYNOPSIS
    Disables workshop participant accounts marked for paused access.

.DESCRIPTION
    Reads workshop-participants-consolidated.csv and disables Entra ID accounts
    for all participants with Status="paused". Users with Status="continuous" 
    will remain active.

.PARAMETER TenantId
    The Entra ID tenant ID.

.PARAMETER TenantDomain
    The tenant domain for UPN construction.

.PARAMETER WhatIf
    Shows what would be disabled without actually disabling accounts.

.EXAMPLE
    .\Disable-PausedAccounts.ps1 -TenantId "fd268415-..." -TenantDomain "levelupcspfy26cs01.onmicrosoft.com" -WhatIf

.EXAMPLE
    .\Disable-PausedAccounts.ps1 -TenantId "fd268415-..." -TenantDomain "levelupcspfy26cs01.onmicrosoft.com"

.NOTES
    Author: David Bjurman-Birr
    Date: November 13, 2025
    
    This script uses the workshop-participants-consolidated.csv file which contains
    the Status column indicating "continuous" (keep active) or "paused" (disable).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantDomain,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Load participant data
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvPath = Join-Path (Split-Path -Parent $scriptPath) "workshop-participants-consolidated.csv"

if (-not (Test-Path $csvPath)) {
    Write-Error "Participants CSV not found at: $csvPath"
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Disable Paused Workshop Accounts                         ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tenant: $TenantDomain" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "Mode: WHAT-IF (no changes will be made)" -ForegroundColor Yellow
} else {
    Write-Host "Mode: LIVE (accounts will be disabled)" -ForegroundColor Red
}
Write-Host ""

# Load and filter participants
$allParticipants = Import-Csv $csvPath
$pausedUsers = $allParticipants | Where-Object { $_.Status -eq "paused" }
$continuousUsers = $allParticipants | Where-Object { $_.Status -eq "continuous" }

Write-Host "Total participants: $($allParticipants.Count)" -ForegroundColor Cyan
Write-Host "  Continuous (keep active): $($continuousUsers.Count)" -ForegroundColor Green
Write-Host "  Paused (will disable): $($pausedUsers.Count)" -ForegroundColor Yellow
Write-Host ""

if ($pausedUsers.Count -eq 0) {
    Write-Host "No accounts to disable. Exiting." -ForegroundColor Green
    exit 0
}

# Confirm action
if (-not $WhatIf) {
    Write-Host "⚠️  WARNING: This will disable $($pausedUsers.Count) user accounts!" -ForegroundColor Red
    Write-Host ""
    $confirmation = Read-Host "Type 'DISABLE' to confirm"
    
    if ($confirmation -ne "DISABLE") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Show continuous users (who will NOT be disabled)
Write-Host "Users keeping active access:" -ForegroundColor Green
foreach ($user in $continuousUsers) {
    Write-Host "  ✓ $($user.RealFullName) ($($user.RealAlias))" -ForegroundColor Gray
}
Write-Host ""

# Process paused users
$disabledCount = 0
$notFoundCount = 0
$errorCount = 0
$currentProgress = 0

Write-Host "Disabling paused accounts:" -ForegroundColor Yellow
Write-Host ""

# Get all users from tenant once (more efficient than individual lookups)
Write-Host "Fetching all users from tenant..." -ForegroundColor Gray
$allTenantUsers = Get-MgUser -All -Property UserPrincipalName,DisplayName,AccountEnabled,Id
Write-Host "Found $($allTenantUsers.Count) total users in tenant" -ForegroundColor Gray
Write-Host ""

foreach ($participant in $pausedUsers) {
    $currentProgress++
    $upn = "$($participant.NativeUserPrincipalName)"
    $displayName = $participant.RealFullName
    $alias = $participant.RealAlias
    
    Write-Progress -Activity "Disabling Paused Accounts" -Status "Processing $displayName" -PercentComplete (($currentProgress / $pausedUsers.Count) * 100)
    
    try {
        # Find user by UPN from pre-fetched list
        $user = $allTenantUsers | Where-Object { $_.UserPrincipalName -eq $upn } | Select-Object -First 1
        
        if (-not $user) {
            Write-Host "  ⚠️  User not found: $displayName ($upn)" -ForegroundColor Yellow
            $notFoundCount++
            continue
        }
        
        # Check if already disabled
        if (-not $user.AccountEnabled) {
            Write-Host "  ⏸️  Already disabled: $displayName" -ForegroundColor Gray
            $disabledCount++
            continue
        }
        
        if ($WhatIf) {
            Write-Host "  [WHAT-IF] Would disable: $displayName ($upn)" -ForegroundColor Magenta
            $disabledCount++
        }
        else {
            # Disable the account
            Update-MgUser -UserId $user.Id -AccountEnabled:$false
            Write-Host "  ✓ Disabled: $displayName ($upn)" -ForegroundColor Yellow
            $disabledCount++
        }
    }
    catch {
        Write-Host "  ✗ Error disabling $displayName : $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Progress -Activity "Disabling Paused Accounts" -Completed

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Account Disable Summary                                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total paused accounts: $($pausedUsers.Count)" -ForegroundColor Cyan
Write-Host "Successfully disabled: $disabledCount" -ForegroundColor Yellow
Write-Host "Not found: $notFoundCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Active accounts remaining: $($continuousUsers.Count)" -ForegroundColor Green
Write-Host ""

if ($WhatIf) {
    Write-Host "This was a WHAT-IF run. No accounts were actually disabled." -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to disable accounts." -ForegroundColor Yellow
} else {
    Write-Host "Disabled accounts can be re-enabled using Update-MgUser -AccountEnabled `$true" -ForegroundColor Cyan
}
Write-Host ""
