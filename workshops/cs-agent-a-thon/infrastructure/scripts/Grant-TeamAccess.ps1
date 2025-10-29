<#
.SYNOPSIS
    Assigns RBAC permissions to team members for their resource groups.

.DESCRIPTION
    Grants Contributor role to each team member on their team's resource group.
    Uses attendee data to map users to teams and assign appropriate permissions.

.PARAMETER SubscriptionName
    Name of the Azure subscription containing resource groups.

.PARAMETER AttendeeCsvPath
    Path to CSV file containing attendee data with team assignments.

.PARAMETER ResourceGroupPrefix
    Prefix for resource group names.
    Default: rg-agentathon-team

.EXAMPLE
    .\Grant-TeamAccess.ps1 `
        -SubscriptionName "Workshop-AgentAThon-Nov2025" `
        -AttendeeCsvPath "..\..\docs\MICROSOFT-ATTENDEES.md"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter()]
    [string]$AttendeeCsvPath = "..\..\docs\MICROSOFT-ATTENDEES.md",
    
    [Parameter()]
    [string]$ResourceGroupPrefix = "rg-agentathon-team",
    
    [Parameter()]
    [string]$DomainName = "levelupcspfy26cs01.onmicrosoft.com"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Granting Team Resource Group Access                     ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Resolve CSV path
$csvFullPath = Join-Path $PSScriptRoot $AttendeeCsvPath
if (-not (Test-Path $csvFullPath)) {
    Write-Error "Attendee CSV file not found: $csvFullPath"
    exit 1
}

# Extract CSV data from markdown
Write-Host "Loading attendee data from: $csvFullPath" -ForegroundColor Cyan
$csvContent = Get-Content $csvFullPath | Where-Object { $_ -match '^[^|]*,[^,]*,[^,]*,' }
$attendees = $csvContent | ConvertFrom-Csv

Write-Host "  Loaded $($attendees.Count) attendees" -ForegroundColor Green
Write-Host ""

# Set subscription context
try {
    $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
    
    if (-not $subscription) {
        Write-Host "Subscription '$SubscriptionName' not found. Available subscriptions:" -ForegroundColor Yellow
        Get-AzSubscription | Format-Table Name, Id, State
        throw "Subscription not found"
    }
    
    Set-AzContext -SubscriptionId $subscription.Id | Out-Null
    Write-Host "✓ Using subscription: $($subscription.Name)" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "Failed to set subscription context: $_"
    exit 1
}

# Group attendees by team (exclude proctors)
$participantsByTeam = $attendees | 
    Where-Object { $_.Team -ne "Proctor" } | 
    Group-Object -Property Team

Write-Host "Teams to configure: $($participantsByTeam.Count)" -ForegroundColor Cyan
Write-Host ""

$assignmentCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($teamGroup in $participantsByTeam) {
    $teamNumber = [int]$teamGroup.Name
    $rgName = "$ResourceGroupPrefix-$($teamNumber.ToString('00'))"
    
    Write-Host "Processing Team $teamNumber ($($teamGroup.Count) members)" -ForegroundColor Yellow
    
    # Verify resource group exists
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "  ✗ Resource group not found: $rgName" -ForegroundColor Red
        Write-Host "    Run New-TeamResourceGroups.ps1 first" -ForegroundColor Yellow
        $errorCount++
        Write-Host ""
        continue
    }
    
    foreach ($member in $teamGroup.Group) {
        $upn = "$($member.Alias)@$DomainName"
        
        try {
            # Check if assignment already exists
            $existingAssignment = Get-AzRoleAssignment `
                -ObjectId (Get-AzADUser -UserPrincipalName $upn).Id `
                -RoleDefinitionName "Contributor" `
                -Scope $rg.ResourceId `
                -ErrorAction SilentlyContinue
            
            if ($existingAssignment) {
                Write-Host "  ✓ $($member.Alias) - Already has Contributor role" -ForegroundColor Gray
                $skippedCount++
            }
            else {
                # Grant Contributor role
                New-AzRoleAssignment `
                    -SignInName $upn `
                    -RoleDefinitionName "Contributor" `
                    -ResourceGroupName $rgName | Out-Null
                
                Write-Host "  ✓ $($member.Alias) - Granted Contributor role" -ForegroundColor Green
                $assignmentCount++
            }
        }
        catch {
            Write-Host "  ✗ $($member.Alias) - Error: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   RBAC Assignment Summary                                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total teams: $($participantsByTeam.Count)" -ForegroundColor Cyan
Write-Host "New role assignments: $assignmentCount" -ForegroundColor Green
Write-Host "Already assigned: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($assignmentCount -gt 0 -or $skippedCount -gt 0) {
    Write-Host "RBAC Configuration Complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Each team member now has Contributor access to their team resource group." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next step: Run Deploy-TeamInfrastructure.ps1 to provision Azure resources" -ForegroundColor Cyan
    Write-Host ""
}
