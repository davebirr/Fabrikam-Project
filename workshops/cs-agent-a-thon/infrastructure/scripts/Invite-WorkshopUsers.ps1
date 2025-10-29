<#
.SYNOPSIS
    Invites Microsoft employees as B2B guests to workshop tenant.

.DESCRIPTION
    Invites all 126 Microsoft attendees as B2B guests to the workshop tenant.
    - Proctors (19): Assigned Global Administrator role
    - Participants (107): Assigned Contributor role on their team resource group
    
    Since all attendees are Microsoft employees with existing M365 licenses,
    B2B guest approach is optimal (no licensing costs, no password management).

.PARAMETER TenantId
    The Microsoft Entra ID tenant ID.

.PARAMETER AttendeeCsvPath
    Path to CSV file containing attendee data.

.PARAMETER SubscriptionName
    Azure subscription name (for RBAC assignments).

.PARAMETER ResourceGroupPrefix
    Prefix for resource group names.

.EXAMPLE
    .\Invite-WorkshopUsers.ps1 `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionName "Workshop-AgentAThon-Nov2025"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
    
    B2B Guest Benefits:
    - Zero licensing costs (use Microsoft licenses)
    - No password management needed
    - Familiar login experience (@microsoft.com)
    - Simple cleanup post-workshop
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
    [string]$ResourceGroupPrefix = "rg-agentathon-team",
    
    [Parameter()]
    [string]$InviteRedirectUrl = "https://portal.azure.com"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Inviting Workshop Participants as B2B Guests            ║" -ForegroundColor Magenta
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

$proctors = $attendees | Where-Object { $_.Team -eq "Proctor" }
$participants = $attendees | Where-Object { $_.Team -ne "Proctor" }

Write-Host "  Proctors: $($proctors.Count)" -ForegroundColor Green
Write-Host "  Participants: $($participants.Count)" -ForegroundColor Green
Write-Host "  Total: $($attendees.Count)" -ForegroundColor Green
Write-Host ""

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    Connect-MgGraph -TenantId $TenantId -Scopes "User.Invite.All", "RoleManagement.ReadWrite.Directory" -NoWelcome
    Write-Host "  ✓ Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}
Write-Host ""

# Invite Proctors as B2B Guests with Global Admin Role
Write-Host "Inviting Proctors as B2B Guests (Global Administrator)..." -ForegroundColor Cyan
$proctorInviteCount = 0
$proctorSkipCount = 0
$proctorErrorCount = 0

foreach ($proctor in $proctors) {
    $email = "$($proctor.Alias)@microsoft.com"
    
    Write-Host "  Processing: $($proctor.Name) ($email)" -ForegroundColor Yellow
    
    try {
        # Check if user already exists as B2B guest
        $existingUser = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
        
        if ($existingUser -and $existingUser.UserType -eq "Guest") {
            Write-Host "    ✓ Already exists as B2B guest" -ForegroundColor Gray
            $userId = $existingUser.Id
            $proctorSkipCount++
        }
        else {
            # Send B2B invitation
            $invitationParams = @{
                InvitedUserEmailAddress = $email
                InviteRedirectUrl = $InviteRedirectUrl
                SendInvitationMessage = $true
                InvitedUserDisplayName = "$($proctor.Name) - Workshop Proctor"
            }
            
            $invitation = New-MgInvitation -BodyParameter $invitationParams
            $userId = $invitation.InvitedUser.Id
            
            Write-Host "    ✓ B2B invitation sent" -ForegroundColor Green
            $proctorInviteCount++
            
            # Wait for invitation to process
            Start-Sleep -Seconds 2
        }
        
        # Assign Global Administrator role
        $globalAdminRoleId = "62e90394-69f5-4237-9190-012177145e10" # Well-known Global Admin role ID
        
        # Check if already assigned
        $existingRoleAssignment = Get-MgDirectoryRoleMemberAsUser -DirectoryRoleId $globalAdminRoleId -ErrorAction SilentlyContinue |
            Where-Object { $_.Id -eq $userId }
        
        if (-not $existingRoleAssignment) {
            # Ensure role is activated
            $role = Get-MgDirectoryRole -Filter "roleTemplateId eq '$globalAdminRoleId'" -ErrorAction SilentlyContinue
            if (-not $role) {
                $role = New-MgDirectoryRole -RoleTemplateId $globalAdminRoleId
            }
            
            # Assign role
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userId"
            }
            
            Write-Host "    ✓ Assigned Global Administrator role" -ForegroundColor Green
        }
        else {
            Write-Host "    ✓ Already has Global Administrator role" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        $proctorErrorCount++
    }
    
    Write-Host ""
}

# Invite Participants as B2B Guests
Write-Host "Inviting Participants as B2B Guests..." -ForegroundColor Cyan
$participantInviteCount = 0
$participantSkipCount = 0
$participantErrorCount = 0

$progress = 0
foreach ($participant in $participants) {
    $progress++
    $email = "$($participant.Alias)@microsoft.com"
    
    Write-Progress -Activity "Inviting Participants" `
        -Status "$progress of $($participants.Count) - $($participant.Name)" `
        -PercentComplete (($progress / $participants.Count) * 100)
    
    try {
        # Check if user already exists as B2B guest
        $existingUser = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
        
        if ($existingUser -and $existingUser.UserType -eq "Guest") {
            $participantSkipCount++
        }
        else {
            # Send B2B invitation
            $invitationParams = @{
                InvitedUserEmailAddress = $email
                InviteRedirectUrl = $InviteRedirectUrl
                SendInvitationMessage = $true
                InvitedUserDisplayName = "$($participant.Name) - Team $($participant.Team)"
            }
            
            $invitation = New-MgInvitation -BodyParameter $invitationParams
            $participantInviteCount++
            
            # Small delay to avoid throttling
            Start-Sleep -Milliseconds 500
        }
    }
    catch {
        $participantErrorCount++
    }
}

Write-Progress -Activity "Inviting Participants" -Completed

Write-Host "  ✓ Invited: $participantInviteCount" -ForegroundColor Green
Write-Host "  ✓ Already existed: $participantSkipCount" -ForegroundColor Gray
if ($participantErrorCount -gt 0) {
    Write-Host "  ✗ Errors: $participantErrorCount" -ForegroundColor Red
}
Write-Host ""

# Now assign Azure RBAC to participants
Write-Host "Assigning Azure RBAC to Participants..." -ForegroundColor Cyan
Write-Host "  (This requires resource groups to exist - run New-TeamResourceGroups.ps1 first)" -ForegroundColor Yellow
Write-Host ""

# Connect to Azure
try {
    $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
    
    if (-not $subscription) {
        Write-Host "Subscription '$SubscriptionName' not found. Skipping RBAC assignment." -ForegroundColor Yellow
        Write-Host "Run Grant-TeamAccess.ps1 after resource groups are created." -ForegroundColor Yellow
    }
    else {
        Set-AzContext -SubscriptionId $subscription.Id | Out-Null
        Write-Host "✓ Connected to subscription: $($subscription.Name)" -ForegroundColor Green
        Write-Host ""
        
        # Group participants by team
        $participantsByTeam = $participants | Group-Object -Property Team
        
        $rbacAssignCount = 0
        $rbacSkipCount = 0
        $rbacErrorCount = 0
        
        foreach ($teamGroup in $participantsByTeam) {
            $teamNumber = [int]$teamGroup.Name
            $rgName = "$ResourceGroupPrefix-$($teamNumber.ToString('00'))"
            
            # Check if resource group exists
            $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
            if (-not $rg) {
                Write-Host "  ⚠ Resource group not found: $rgName (skipping RBAC)" -ForegroundColor Yellow
                continue
            }
            
            Write-Host "  Processing Team $teamNumber RBAC assignments..." -ForegroundColor Yellow
            
            foreach ($member in $teamGroup.Group) {
                $email = "$($member.Alias)@microsoft.com"
                
                try {
                    # Get B2B guest user
                    $user = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
                    
                    if (-not $user) {
                        Write-Host "    ⚠ User not found: $email (invitation may be pending)" -ForegroundColor Yellow
                        continue
                    }
                    
                    # Check if assignment already exists
                    $existingAssignment = Get-AzRoleAssignment `
                        -ObjectId $user.Id `
                        -RoleDefinitionName "Contributor" `
                        -Scope $rg.ResourceId `
                        -ErrorAction SilentlyContinue
                    
                    if ($existingAssignment) {
                        $rbacSkipCount++
                    }
                    else {
                        # Grant Contributor role
                        New-AzRoleAssignment `
                            -ObjectId $user.Id `
                            -RoleDefinitionName "Contributor" `
                            -ResourceGroupName $rgName | Out-Null
                        
                        $rbacAssignCount++
                    }
                }
                catch {
                    $rbacErrorCount++
                }
            }
        }
        
        Write-Host ""
        Write-Host "RBAC Assignments:" -ForegroundColor Cyan
        Write-Host "  ✓ Newly assigned: $rbacAssignCount" -ForegroundColor Green
        Write-Host "  ✓ Already assigned: $rbacSkipCount" -ForegroundColor Gray
        if ($rbacErrorCount -gt 0) {
            Write-Host "  ✗ Errors: $rbacErrorCount" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Azure connection failed. Run Grant-TeamAccess.ps1 manually after resource groups are created." -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   B2B Guest Invitation Summary                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Proctors (Global Administrator):" -ForegroundColor Cyan
Write-Host "  Invited: $proctorInviteCount" -ForegroundColor Green
Write-Host "  Already existed: $proctorSkipCount" -ForegroundColor Gray
Write-Host "  Errors: $proctorErrorCount" -ForegroundColor $(if ($proctorErrorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

Write-Host "Participants (Contributor on team RG):" -ForegroundColor Cyan
Write-Host "  Invited: $participantInviteCount" -ForegroundColor Green
Write-Host "  Already existed: $participantSkipCount" -ForegroundColor Gray
Write-Host "  Errors: $participantErrorCount" -ForegroundColor $(if ($participantErrorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

Write-Host "Total B2B Guests: $($proctorInviteCount + $proctorSkipCount + $participantInviteCount + $participantSkipCount)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Participants will receive email invitations" -ForegroundColor White
Write-Host "  2. They must accept invitation before workshop" -ForegroundColor White
Write-Host "  3. Run New-TeamResourceGroups.ps1 to create Azure resource groups" -ForegroundColor White
Write-Host "  4. RBAC permissions will be assigned automatically (or run Grant-TeamAccess.ps1)" -ForegroundColor White
Write-Host "  5. Run Test-WorkshopReadiness.ps1 to validate environment" -ForegroundColor White
Write-Host ""

Write-Host "B2B Benefits:" -ForegroundColor Green
Write-Host "  ✓ Zero licensing costs (using Microsoft licenses)" -ForegroundColor Green
Write-Host "  ✓ No password management needed" -ForegroundColor Green
Write-Host "  ✓ Familiar @microsoft.com login" -ForegroundColor Green
Write-Host "  ✓ Simple cleanup post-workshop" -ForegroundColor Green
Write-Host ""
