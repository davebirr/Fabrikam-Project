<#
.SYNOPSIS
    Removes all workshop resources from Azure and Entra ID.

.DESCRIPTION
    Post-workshop cleanup script that removes:
    - All participant user accounts
    - All proctor user accounts
    - All team resource groups and contained resources
    
    WARNING: This is a destructive operation. Use with caution!

.PARAMETER TenantId
    The Microsoft Entra ID tenant ID.

.PARAMETER SubscriptionName
    Name of the Azure subscription.

.PARAMETER AttendeeCsvPath
    Path to CSV file containing attendee data.

.PARAMETER WhatIf
    Show what would be deleted without actually deleting.

.EXAMPLE
    .\Remove-WorkshopResources.ps1 `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionName "Workshop-AgentAThon-Nov2025" `
        -WhatIf

.EXAMPLE
    .\Remove-WorkshopResources.ps1 `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionName "Workshop-AgentAThon-Nov2025"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter()]
    [string]$AttendeeCsvPath = "..\..\docs\MICROSOFT-ATTENDEES.md",
    
    [Parameter()]
    [string]$DomainName = "levelupcspfy26cs01.onmicrosoft.com",
    
    [Parameter()]
    [string]$ResourceGroupPrefix = "rg-agentathon-team",
    
    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║   Workshop Resource Cleanup                                ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

if ($WhatIf) {
    Write-Host "RUNNING IN WHATIF MODE - No resources will be deleted" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "WARNING: This will delete ALL workshop resources!" -ForegroundColor Red
    Write-Host ""
    Write-Host "This includes:" -ForegroundColor Yellow
    Write-Host "  - 126 Entra ID user accounts" -ForegroundColor Yellow
    Write-Host "  - 21 Azure resource groups" -ForegroundColor Yellow
    Write-Host "  - All resources within those resource groups" -ForegroundColor Yellow
    Write-Host ""
    
    $confirmation = Read-Host "Type 'DELETE' to confirm deletion"
    
    if ($confirmation -ne "DELETE") {
        Write-Host ""
        Write-Host "Cleanup cancelled." -ForegroundColor Green
        exit 0
    }
}

Write-Host ""

# Load attendee data
$csvFullPath = Join-Path $PSScriptRoot $AttendeeCsvPath
if (-not (Test-Path $csvFullPath)) {
    Write-Error "Attendee CSV file not found: $csvFullPath"
    exit 1
}

$csvContent = Get-Content $csvFullPath | Where-Object { $_ -match '^[^|]*,[^,]*,[^,]*,' }
$attendees = $csvContent | ConvertFrom-Csv

Write-Host "Loaded $($attendees.Count) attendees from CSV" -ForegroundColor Cyan
Write-Host ""

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
try {
    $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
    
    if (-not $subscription) {
        Write-Error "Subscription '$SubscriptionName' not found"
        exit 1
    }
    
    Set-AzContext -SubscriptionId $subscription.Id | Out-Null
    Write-Host "  ✓ Connected to subscription: $($subscription.Name)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Azure: $_"
    exit 1
}
Write-Host ""

# Delete Resource Groups
Write-Host "Deleting Resource Groups..." -ForegroundColor Cyan
$deletedRgCount = 0
$skippedRgCount = 0

for ($teamNum = 1; $teamNum -le 21; $teamNum++) {
    $rgName = "$ResourceGroupPrefix-$($teamNum.ToString('00'))"
    
    try {
        $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        
        if ($rg) {
            if ($WhatIf) {
                Write-Host "  [WHATIF] Would delete: $rgName" -ForegroundColor Yellow
                $deletedRgCount++
            }
            else {
                Write-Host "  Deleting: $rgName..." -ForegroundColor Yellow -NoNewline
                Remove-AzResourceGroup -Name $rgName -Force | Out-Null
                Write-Host " ✓ Deleted" -ForegroundColor Green
                $deletedRgCount++
            }
        }
        else {
            Write-Host "  ✓ $rgName - Already deleted" -ForegroundColor Gray
            $skippedRgCount++
        }
    }
    catch {
        Write-Host "  ✗ Error deleting $rgName" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Resource Groups:" -ForegroundColor Cyan
Write-Host "  Deleted: $deletedRgCount" -ForegroundColor $(if ($WhatIf) { "Yellow" } else { "Green" })
Write-Host "  Skipped: $skippedRgCount" -ForegroundColor Gray
Write-Host ""

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
    Write-Host "  ✓ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}
Write-Host ""

# Delete User Accounts
Write-Host "Deleting User Accounts..." -ForegroundColor Cyan
$deletedUserCount = 0
$skippedUserCount = 0
$errorUserCount = 0

$progress = 0
foreach ($attendee in $attendees) {
    $progress++
    $upn = "$($attendee.Alias)@$DomainName"
    
    Write-Progress -Activity "Deleting Users" `
        -Status "$progress of $($attendees.Count)" `
        -PercentComplete (($progress / $attendees.Count) * 100)
    
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue
        
        if ($user) {
            if ($WhatIf) {
                $deletedUserCount++
            }
            else {
                Remove-MgUser -UserId $user.Id -Confirm:$false
                $deletedUserCount++
            }
        }
        else {
            $skippedUserCount++
        }
    }
    catch {
        $errorUserCount++
    }
}

Write-Progress -Activity "Deleting Users" -Completed

if ($WhatIf) {
    Write-Host "  [WHATIF] Would delete: $deletedUserCount users" -ForegroundColor Yellow
}
else {
    Write-Host "  ✓ Deleted: $deletedUserCount users" -ForegroundColor Green
}
Write-Host "  ✓ Already deleted: $skippedUserCount" -ForegroundColor Gray
if ($errorUserCount -gt 0) {
    Write-Host "  ✗ Errors: $errorUserCount" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Cleanup Summary                                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($WhatIf) {
    Write-Host "WHATIF MODE - No resources were deleted" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would have deleted:" -ForegroundColor Cyan
    Write-Host "  - $deletedRgCount resource groups" -ForegroundColor Yellow
    Write-Host "  - $deletedUserCount user accounts" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run without -WhatIf to actually delete resources" -ForegroundColor Cyan
}
else {
    Write-Host "Successfully deleted:" -ForegroundColor Green
    Write-Host "  - $deletedRgCount resource groups" -ForegroundColor Green
    Write-Host "  - $deletedUserCount user accounts" -ForegroundColor Green
    Write-Host ""
    
    if ($skippedRgCount -gt 0 -or $skippedUserCount -gt 0) {
        Write-Host "Resources already deleted:" -ForegroundColor Gray
        if ($skippedRgCount -gt 0) {
            Write-Host "  - $skippedRgCount resource groups" -ForegroundColor Gray
        }
        if ($skippedUserCount -gt 0) {
            Write-Host "  - $skippedUserCount user accounts" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($errorUserCount -gt 0) {
        Write-Host "Errors encountered:" -ForegroundColor Red
        Write-Host "  - $errorUserCount user account deletions failed" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "Workshop cleanup complete!" -ForegroundColor Green
}

Write-Host ""
