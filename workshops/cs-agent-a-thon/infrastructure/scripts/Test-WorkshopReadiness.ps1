<#
.SYNOPSIS
    Validates workshop tenant and Azure environment readiness.

.DESCRIPTION
    Comprehensive validation of:
    - Entra ID user accounts (proctors and participants)
    - Azure resource groups
    - RBAC role assignments
    - Resource group tags and metadata

.PARAMETER TenantId
    The Microsoft Entra ID tenant ID.

.PARAMETER SubscriptionName
    Name of the Azure subscription.

.PARAMETER AttendeeCsvPath
    Path to CSV file containing attendee data.

.EXAMPLE
    .\Test-WorkshopReadiness.ps1 `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionName "Workshop-AgentAThon-Nov2025"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding()]
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
    [string]$ResourceGroupPrefix = "rg-agentathon-team"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Workshop Readiness Validation                            ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Validation results
$validationResults = @{
    EntraUsers = @{ Expected = 0; Found = 0; Missing = 0; Issues = @() }
    Proctors = @{ Expected = 0; Found = 0; Missing = 0; Issues = @() }
    Participants = @{ Expected = 0; Found = 0; Missing = 0; Issues = @() }
    ResourceGroups = @{ Expected = 21; Found = 0; Missing = 0; Issues = @() }
    RoleAssignments = @{ Expected = 0; Found = 0; Missing = 0; Issues = @() }
}

# Load attendee data
Write-Host "Loading attendee data..." -ForegroundColor Cyan
$csvFullPath = Join-Path $PSScriptRoot $AttendeeCsvPath
if (-not (Test-Path $csvFullPath)) {
    Write-Error "Attendee CSV file not found: $csvFullPath"
    exit 1
}

$csvContent = Get-Content $csvFullPath | Where-Object { $_ -match '^[^|]*,[^,]*,[^,]*,' }
$attendees = $csvContent | ConvertFrom-Csv

$proctors = $attendees | Where-Object { $_.Team -eq "Proctor" }
$participants = $attendees | Where-Object { $_.Team -ne "Proctor" }

$validationResults.EntraUsers.Expected = $attendees.Count
$validationResults.Proctors.Expected = $proctors.Count
$validationResults.Participants.Expected = $participants.Count

Write-Host "  Expected: $($attendees.Count) total users ($($proctors.Count) proctors, $($participants.Count) participants)" -ForegroundColor Green
Write-Host ""

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -TenantId $TenantId -Scopes "User.Read.All", "Directory.Read.All" -NoWelcome
    Write-Host "  ✓ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}
Write-Host ""

# Validate Proctor Accounts
Write-Host "Validating Proctor Accounts..." -ForegroundColor Cyan
foreach ($proctor in $proctors) {
    $upn = "$($proctor.Alias)@$DomainName"
    
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue
        
        if ($user) {
            $validationResults.Proctors.Found++
            Write-Host "  ✓ $($proctor.Alias)" -ForegroundColor Green
        }
        else {
            $validationResults.Proctors.Missing++
            $validationResults.Proctors.Issues += "Missing proctor: $($proctor.Alias)"
            Write-Host "  ✗ $($proctor.Alias) - NOT FOUND" -ForegroundColor Red
        }
    }
    catch {
        $validationResults.Proctors.Issues += "Error checking $($proctor.Alias): $_"
        Write-Host "  ✗ $($proctor.Alias) - ERROR: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Validate Participant Accounts
Write-Host "Validating Participant Accounts..." -ForegroundColor Cyan
$participantProgress = 0
foreach ($participant in $participants) {
    $participantProgress++
    $upn = "$($participant.Alias)@$DomainName"
    
    Write-Progress -Activity "Validating Participants" `
        -Status "$participantProgress of $($participants.Count)" `
        -PercentComplete (($participantProgress / $participants.Count) * 100)
    
    try {
        $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue
        
        if ($user) {
            $validationResults.Participants.Found++
        }
        else {
            $validationResults.Participants.Missing++
            $validationResults.Participants.Issues += "Missing participant: $($participant.Alias) (Team $($participant.Team))"
        }
    }
    catch {
        $validationResults.Participants.Issues += "Error checking $($participant.Alias): $_"
    }
}
Write-Progress -Activity "Validating Participants" -Completed

Write-Host "  ✓ Found: $($validationResults.Participants.Found) / $($validationResults.Participants.Expected)" -ForegroundColor $(if ($validationResults.Participants.Missing -eq 0) { "Green" } else { "Yellow" })
if ($validationResults.Participants.Missing -gt 0) {
    Write-Host "  ✗ Missing: $($validationResults.Participants.Missing)" -ForegroundColor Red
}
Write-Host ""

# Set Azure context
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

# Validate Resource Groups
Write-Host "Validating Resource Groups..." -ForegroundColor Cyan
for ($teamNum = 1; $teamNum -le 21; $teamNum++) {
    $rgName = "$ResourceGroupPrefix-$($teamNum.ToString('00'))"
    
    try {
        $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        
        if ($rg) {
            $validationResults.ResourceGroups.Found++
            Write-Host "  ✓ $rgName" -ForegroundColor Green
            
            # Validate tags
            if (-not $rg.Tags -or -not $rg.Tags.ContainsKey("Workshop")) {
                $validationResults.ResourceGroups.Issues += "$rgName missing required tags"
            }
        }
        else {
            $validationResults.ResourceGroups.Missing++
            $validationResults.ResourceGroups.Issues += "Missing resource group: $rgName"
            Write-Host "  ✗ $rgName - NOT FOUND" -ForegroundColor Red
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        $validationResults.ResourceGroups.Issues += "Error checking ${rgName}: $errorMsg"
        Write-Host "  ✗ $rgName - ERROR: $errorMsg" -ForegroundColor Red
    }
}
Write-Host ""

# Validate RBAC Assignments (sample teams only to save time)
Write-Host "Validating RBAC Assignments (sampling Teams 1, 10, 21)..." -ForegroundColor Cyan
$sampleTeams = @(1, 10, 21)

foreach ($teamNum in $sampleTeams) {
    $rgName = "$ResourceGroupPrefix-$($teamNum.ToString('00'))"
    $teamMembers = $participants | Where-Object { [int]$_.Team -eq $teamNum }
    
    $validationResults.RoleAssignments.Expected += $teamMembers.Count
    
    Write-Host "  Team $teamNum ($($teamMembers.Count) members):" -ForegroundColor Yellow
    
    foreach ($member in $teamMembers) {
        $upn = "$($member.Alias)@$DomainName"
        
        try {
            $user = Get-AzADUser -UserPrincipalName $upn -ErrorAction SilentlyContinue
            
            if ($user) {
                $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
                
                if ($rg) {
                    $assignment = Get-AzRoleAssignment `
                        -ObjectId $user.Id `
                        -RoleDefinitionName "Contributor" `
                        -Scope $rg.ResourceId `
                        -ErrorAction SilentlyContinue
                    
                    if ($assignment) {
                        $validationResults.RoleAssignments.Found++
                        Write-Host "    ✓ $($member.Alias) - Contributor access" -ForegroundColor Green
                    }
                    else {
                        $validationResults.RoleAssignments.Missing++
                        $validationResults.RoleAssignments.Issues += "$($member.Alias) missing Contributor role on $rgName"
                        Write-Host "    ✗ $($member.Alias) - NO ACCESS" -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            $validationResults.RoleAssignments.Issues += "Error checking $($member.Alias) access: $_"
            Write-Host "    ✗ $($member.Alias) - ERROR: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Final Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $(if ($validationResults.Proctors.Missing -eq 0 -and $validationResults.Participants.Missing -eq 0 -and $validationResults.ResourceGroups.Missing -eq 0) { "Green" } else { "Yellow" })
Write-Host "║   Validation Summary                                       ║" -ForegroundColor $(if ($validationResults.Proctors.Missing -eq 0 -and $validationResults.Participants.Missing -eq 0 -and $validationResults.ResourceGroups.Missing -eq 0) { "Green" } else { "Yellow" })
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $(if ($validationResults.Proctors.Missing -eq 0 -and $validationResults.Participants.Missing -eq 0 -and $validationResults.ResourceGroups.Missing -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

Write-Host "Proctor Accounts:" -ForegroundColor Cyan
Write-Host "  Expected: $($validationResults.Proctors.Expected)" -ForegroundColor White
Write-Host "  Found: $($validationResults.Proctors.Found)" -ForegroundColor $(if ($validationResults.Proctors.Found -eq $validationResults.Proctors.Expected) { "Green" } else { "Red" })
Write-Host "  Missing: $($validationResults.Proctors.Missing)" -ForegroundColor $(if ($validationResults.Proctors.Missing -eq 0) { "Green" } else { "Red" })
Write-Host ""

Write-Host "Participant Accounts:" -ForegroundColor Cyan
Write-Host "  Expected: $($validationResults.Participants.Expected)" -ForegroundColor White
Write-Host "  Found: $($validationResults.Participants.Found)" -ForegroundColor $(if ($validationResults.Participants.Found -eq $validationResults.Participants.Expected) { "Green" } else { "Red" })
Write-Host "  Missing: $($validationResults.Participants.Missing)" -ForegroundColor $(if ($validationResults.Participants.Missing -eq 0) { "Green" } else { "Red" })
Write-Host ""

Write-Host "Resource Groups:" -ForegroundColor Cyan
Write-Host "  Expected: $($validationResults.ResourceGroups.Expected)" -ForegroundColor White
Write-Host "  Found: $($validationResults.ResourceGroups.Found)" -ForegroundColor $(if ($validationResults.ResourceGroups.Found -eq $validationResults.ResourceGroups.Expected) { "Green" } else { "Red" })
Write-Host "  Missing: $($validationResults.ResourceGroups.Missing)" -ForegroundColor $(if ($validationResults.ResourceGroups.Missing -eq 0) { "Green" } else { "Red" })
Write-Host ""

Write-Host "RBAC Assignments (sampled):" -ForegroundColor Cyan
Write-Host "  Expected: $($validationResults.RoleAssignments.Expected)" -ForegroundColor White
Write-Host "  Found: $($validationResults.RoleAssignments.Found)" -ForegroundColor $(if ($validationResults.RoleAssignments.Found -eq $validationResults.RoleAssignments.Expected) { "Green" } else { "Red" })
Write-Host "  Missing: $($validationResults.RoleAssignments.Missing)" -ForegroundColor $(if ($validationResults.RoleAssignments.Missing -eq 0) { "Green" } else { "Red" })
Write-Host ""

# Show issues if any
$totalIssues = $validationResults.Proctors.Issues.Count + 
               $validationResults.Participants.Issues.Count + 
               $validationResults.ResourceGroups.Issues.Count + 
               $validationResults.RoleAssignments.Issues.Count

if ($totalIssues -gt 0) {
    Write-Host "Issues Found ($totalIssues):" -ForegroundColor Red
    Write-Host ""
    
    if ($validationResults.Proctors.Issues.Count -gt 0) {
        Write-Host "  Proctor Issues:" -ForegroundColor Yellow
        $validationResults.Proctors.Issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        Write-Host ""
    }
    
    if ($validationResults.Participants.Issues.Count -gt 0) {
        Write-Host "  Participant Issues:" -ForegroundColor Yellow
        $validationResults.Participants.Issues | Select-Object -First 10 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        if ($validationResults.Participants.Issues.Count -gt 10) {
            Write-Host "    ... and $($validationResults.Participants.Issues.Count - 10) more" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($validationResults.ResourceGroups.Issues.Count -gt 0) {
        Write-Host "  Resource Group Issues:" -ForegroundColor Yellow
        $validationResults.ResourceGroups.Issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        Write-Host ""
    }
    
    if ($validationResults.RoleAssignments.Issues.Count -gt 0) {
        Write-Host "  RBAC Assignment Issues:" -ForegroundColor Yellow
        $validationResults.RoleAssignments.Issues | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
        Write-Host ""
    }
}
else {
    Write-Host "✓ All validations passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Workshop environment is ready for November 6, 2025!" -ForegroundColor Green
    Write-Host ""
}
