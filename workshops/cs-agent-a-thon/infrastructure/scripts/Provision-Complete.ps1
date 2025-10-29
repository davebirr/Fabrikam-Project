<#
.SYNOPSIS
    Complete workshop provisioning: B2B guests, admin roles, teams, and Azure resources

.DESCRIPTION
    This script handles the complete workshop setup:
    1. Invites all @microsoft.com participants as B2B guests (NO licenses)
    2. Assigns Global Admin to 8 key proctors
    3. Assigns Privileged Role Administrator to 11 other proctors
    4. Creates security groups for 20 teams
    5. Adds participants to their team groups
    6. Creates Azure resource groups for each team
    7. Assigns Contributor role to team groups on their resource groups

.PARAMETER TenantId
    The workshop tenant ID (default: fd268415-22a5-4064-9b5e-d039761c5971)

.PARAMETER SubscriptionId
    The Azure subscription ID (default: d3c2f651-1a5a-4781-94f3-460c4c4bffce)

.PARAMETER WhatIf
    Run in simulation mode without making changes

.EXAMPLE
    .\Provision-Complete.ps1
    
.EXAMPLE
    .\Provision-Complete.ps1 -WhatIf

.NOTES
    Requirements:
    - Microsoft.Graph PowerShell module
    - Azure CLI authenticated
    - Global Administrator permissions in target tenant
    - Owner/Contributor on Azure subscription
    
    Author: David Bjurman-Birr
    Date: October 28, 2025
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TenantId = "fd268415-22a5-4064-9b5e-d039761c5971",
    [string]$SubscriptionId = "d3c2f651-1a5a-4781-94f3-460c4c4bffce",
    [string]$Location = "westus2",
    [switch]$SkipInvitations
)

$ErrorActionPreference = "Continue"  # Changed from Stop to allow script to continue on auth warnings

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  CS Agent-A-Thon Complete Workshop Provisioning             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($WhatIfPreference) {
    Write-Host "🔍 WHATIF MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Import required modules
try {
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
    Write-Host "✅ PowerShell modules loaded" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to load required modules. Install with:" -ForegroundColor Red
    Write-Host "   Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# Connect to Microsoft Graph (or use existing connection)
Write-Host "📡 Checking Microsoft Graph connection..." -ForegroundColor Yellow
$mgContext = Get-MgContext
if (-not $mgContext -or $mgContext.TenantId -ne $TenantId) {
    Write-Host "   Connecting to Microsoft Graph (use device code for reliability)..." -ForegroundColor Yellow
    try {
        Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Group.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -UseDeviceCode -NoWelcome
        Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✅ Using existing Microsoft Graph connection" -ForegroundColor Green
}

# Set Azure subscription context
Write-Host "☁️  Setting Azure subscription context..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set Azure subscription. Ensure Azure CLI is authenticated." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure subscription context set" -ForegroundColor Green

# Load participant data
$attendeesPath = Join-Path $PSScriptRoot "..\attendees.csv"
if (-not (Test-Path $attendeesPath)) {
    Write-Host "❌ Attendees file not found: $attendeesPath" -ForegroundColor Red
    exit 1
}

$attendees = Import-Csv $attendeesPath
Write-Host "✅ Loaded $($attendees.Count) participants" -ForegroundColor Green
Write-Host ""

#region Step 1: Invite B2B Guests (NO licenses)
if (-not $SkipInvitations) {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 1: Invite B2B Guest Accounts (@microsoft.com)" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$invitedCount = 0
$skippedCount = 0

foreach ($attendee in $attendees) {
    $email = $attendee.Email
    $displayName = $attendee.FullName
    
    # Check if user already exists
    $existingUser = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
    
    if ($existingUser) {
        Write-Host "  ⏭️  $displayName ($email)" -ForegroundColor DarkGray
        $skippedCount++
        continue
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] Would invite: $displayName ($email)" -ForegroundColor Magenta
        $invitedCount++
        continue
    }
    
    try {
        # Use Invoke-MgGraphRequest to avoid re-authentication issues
        $inviteBody = @{
            invitedUserEmailAddress = $email
            invitedUserDisplayName = $displayName
            inviteRedirectUrl = "https://copilotstudio.microsoft.com/?tenant=$TenantId"
            sendInvitationMessage = $false
        } | ConvertTo-Json
        
        $null = Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/invitations" `
            -Body $inviteBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "  ✅ $displayName ($email)" -ForegroundColor Green
        $invitedCount++
        Start-Sleep -Milliseconds 300
    }
    catch {
        Write-Host "  ❌ Failed: $email - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 B2B Invitation Summary:" -ForegroundColor White
Write-Host "   Invited: $invitedCount | Skipped: $skippedCount" -ForegroundColor Gray
Write-Host ""
}
else {
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "STEP 1: SKIPPED - B2B invitations done manually in portal" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}
#endregion

#region Step 2: Assign Admin Roles to Proctors
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 2: Assign Admin Roles to Proctors" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Global Admins (8 key people)
$globalAdmins = @(
    "davidb@microsoft.com",
    "meunan@microsoft.com",      # Mert
    "kirklend@microsoft.com",    # Kirk
    "olgabu@microsoft.com",      # Olga
    "ragrose@microsoft.com",     # Ragnar
    "rubhuber@microsoft.com",    # Ruben
    "stsassen@microsoft.com",    # Stefan
    "mattben@microsoft.com"      # Matt
)

Write-Host "🔐 Assigning Global Administrator (8 key proctors)..." -ForegroundColor Yellow

# Get or activate Global Administrator role
$globalAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'" -ErrorAction SilentlyContinue
if (-not $globalAdminRole) {
    $globalAdminRoleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Global Administrator'"
    if (-not $WhatIf) {
        $globalAdminRole = New-MgDirectoryRole -RoleTemplateId $globalAdminRoleTemplate.Id
    }
}

$gaAssigned = 0
$gaSkipped = 0

foreach ($email in $globalAdmins) {
    $user = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
    
    if (-not $user) {
        Write-Host "  ⚠️  User not found: $email" -ForegroundColor Yellow
        continue
    }
    
    if ($globalAdminRole) {
        $existingAssignment = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $user.Id }
        
        if ($existingAssignment) {
            Write-Host "  ⏭️  $email" -ForegroundColor DarkGray
            $gaSkipped++
            continue
        }
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] Would assign Global Admin: $email" -ForegroundColor Magenta
        $gaAssigned++
        continue
    }
    
    try {
        New-MgDirectoryRoleMemberByRef -DirectoryRoleId $globalAdminRole.Id -BodyParameter @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)"
        }
        Write-Host "  ✅ $email" -ForegroundColor Green
        $gaAssigned++
    }
    catch {
        Write-Host "  ❌ Failed: $email - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🔐 Assigning Privileged Role Administrator (other proctors)..." -ForegroundColor Yellow

# Get other proctors (not in Global Admin list)
$proctors = $attendees | Where-Object { $_.Manager -eq "Yes" }
$otherProctors = $proctors | Where-Object { $_.Email -notin $globalAdmins } | Select-Object -ExpandProperty Email

# Get or activate Privileged Role Administrator role
$privRoleAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Privileged Role Administrator'" -ErrorAction SilentlyContinue
if (-not $privRoleAdminRole) {
    $privRoleAdminRoleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Privileged Role Administrator'"
    if (-not $WhatIf) {
        $privRoleAdminRole = New-MgDirectoryRole -RoleTemplateId $privRoleAdminRoleTemplate.Id
    }
}

$praAssigned = 0
$praSkipped = 0

foreach ($email in $otherProctors) {
    $user = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
    
    if (-not $user) {
        Write-Host "  ⚠️  User not found: $email" -ForegroundColor Yellow
        continue
    }
    
    if ($privRoleAdminRole) {
        $existingAssignment = Get-MgDirectoryRoleMember -DirectoryRoleId $privRoleAdminRole.Id -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $user.Id }
        
        if ($existingAssignment) {
            Write-Host "  ⏭️  $email" -ForegroundColor DarkGray
            $praSkipped++
            continue
        }
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] Would assign Privileged Role Admin: $email" -ForegroundColor Magenta
        $praAssigned++
        continue
    }
    
    try {
        New-MgDirectoryRoleMemberByRef -DirectoryRoleId $privRoleAdminRole.Id -BodyParameter @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)"
        }
        Write-Host "  ✅ $email" -ForegroundColor Green
        $praAssigned++
    }
    catch {
        Write-Host "  ❌ Failed: $email - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Admin Role Summary:" -ForegroundColor White
Write-Host "   Global Admin: $gaAssigned assigned, $gaSkipped skipped" -ForegroundColor Gray
Write-Host "   Privileged Role Admin: $praAssigned assigned, $praSkipped skipped" -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 3: Participant Roles
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 3: Participant Permissions" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$participants = $attendees | Where-Object { $_.Manager -ne "Yes" }

Write-Host "ℹ️  Participants ($($participants.Count) users) receive:" -ForegroundColor Cyan
Write-Host "   • Basic user permissions (automatic)" -ForegroundColor Gray
Write-Host "   • Agent creation via Copilot Studio licensing (assigned later)" -ForegroundColor Gray
Write-Host "   • Azure Contributor on team resource group (Step 7)" -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 4: Create Team Security Groups
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 4: Create Team Security Groups" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Load team names from team-roster.md
$teamRosterPath = Join-Path $PSScriptRoot "..\docs\team-roster.md"

# Define workshop teams with their creative names
$workshopTeams = @(
    @{ Number = 0; Name = "Proctors"; Track = "Support" }  # Proctor team
    @{ Number = 1; Name = "Copilot Commanders"; Track = "Beginner" }
    @{ Number = 2; Name = "Prompt Pioneers"; Track = "Beginner" }
    @{ Number = 3; Name = "Agent Architects"; Track = "Intermediate" }
    @{ Number = 4; Name = "Semantic Samurai"; Track = "Intermediate" }
    @{ Number = 5; Name = "MCP Mavericks"; Track = "Intermediate" }
    @{ Number = 6; Name = "Orchestration Ninjas"; Track = "Advanced" }
    @{ Number = 7; Name = "AutoGen Avengers"; Track = "Advanced" }
    @{ Number = 8; Name = "LangChain Legends"; Track = "Advanced" }
    @{ Number = 9; Name = "Agentic Alchemists"; Track = "Intermediate" }
    @{ Number = 10; Name = "RAG Raiders"; Track = "Intermediate" }
    @{ Number = 11; Name = "Workflow Wizards"; Track = "Beginner" }
    @{ Number = 12; Name = "Context Champions"; Track = "Beginner" }
    @{ Number = 13; Name = "Intelligent Integrators"; Track = "Intermediate" }
    @{ Number = 14; Name = "Prompt Perfectionists"; Track = "Intermediate" }
    @{ Number = 15; Name = "Cognitive Crafters"; Track = "Advanced" }
    @{ Number = 16; Name = "Reasoning Rebels"; Track = "Advanced" }
    @{ Number = 17; Name = "Function Fanatics"; Track = "Beginner" }
    @{ Number = 18; Name = "Schema Sherpas"; Track = "Beginner" }
    @{ Number = 19; Name = "Response Rockstars"; Track = "Intermediate" }
    @{ Number = 20; Name = "Action Architects"; Track = "Intermediate" }
    @{ Number = 21; Name = "Completion Crusaders"; Track = "Advanced" }
)

$teamGroups = @{}
$groupsCreated = 0
$groupsSkipped = 0

foreach ($team in $workshopTeams) {
    $teamNumber = if ($team.Number -eq 0) { "Proctors" } else { $team.Number.ToString("00") }
    $teamName = $team.Name
    $groupName = "Workshop-Team-$teamName"
    $groupDescription = "CS Agent-A-Thon - $teamName ($($team.Track) Track)"
    
    # Check if group already exists
    $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
    
    if ($existingGroup) {
        Write-Host "  ⏭️  $groupName" -ForegroundColor DarkGray
        $teamGroups[$teamNumber] = $existingGroup
        $groupsSkipped++
        continue
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] Would create: $groupName" -ForegroundColor Magenta
        $groupsCreated++
        continue
    }
    
    try {
        # Create mail nickname from team name (remove spaces and special chars)
        $mailNickname = ($teamName -replace '[^a-zA-Z0-9]', '').ToLower()
        
        $newGroup = New-MgGroup -DisplayName $groupName `
            -MailEnabled:$false `
            -MailNickname "workshop-$mailNickname" `
            -SecurityEnabled:$true `
            -Description $groupDescription
        
        Write-Host "  ✅ $groupName" -ForegroundColor Green
        $teamGroups[$teamNumber] = $newGroup
        $groupsCreated++
    }
    catch {
        Write-Host "  ❌ Failed: $groupName - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Team Groups Summary:" -ForegroundColor White
Write-Host "   Created: $groupsCreated | Skipped: $groupsSkipped" -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 5: Add Users to Team Groups
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 5: Add Proctors to Proctor Team" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Add all proctors to the Proctor team
$proctors = $attendees | Where-Object { $_.Manager -eq "Yes" }
$membersAdded = 0
$membersSkipped = 0

if ($teamGroups.ContainsKey("Proctors")) {
    $proctorGroup = $teamGroups["Proctors"]
    
    foreach ($proctor in $proctors) {
        $email = $proctor.Email
        $user = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" -ErrorAction SilentlyContinue
        
        if (-not $user) {
            Write-Host "  ⚠️  User not found: $email" -ForegroundColor Yellow
            continue
        }
        
        # Check if already a member
        $existingMember = Get-MgGroupMember -GroupId $proctorGroup.Id -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $user.Id }
        
        if ($existingMember) {
            $membersSkipped++
            continue
        }
        
        if ($WhatIfPreference) {
            Write-Host "  [WHATIF] $email → Workshop-Team-Proctors" -ForegroundColor Magenta
            $membersAdded++
            continue
        }
        
        try {
            New-MgGroupMember -GroupId $proctorGroup.Id -DirectoryObjectId $user.Id
            Write-Host "  ✅ $email → Workshop-Team-Proctors" -ForegroundColor Green
            $membersAdded++
            Start-Sleep -Milliseconds 200
        }
        catch {
            Write-Host "  ❌ Failed: $email - $_" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "  ⚠️  Proctor group not found - run without -WhatIf first" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 Proctor Team Membership:" -ForegroundColor White
Write-Host "   Added: $membersAdded | Skipped: $membersSkipped" -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  Participant team assignments from team-roster.md" -ForegroundColor Cyan
Write-Host "   Use separate script to assign participants to teams 1-21" -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 6: Create Azure Resource Groups
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 6: Create Azure Resource Groups (Teams 1-21)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "ℹ️  Proctor resource group (rg-agentathon-proctor) already exists" -ForegroundColor Cyan
Write-Host ""

$rgCreated = 0
$rgSkipped = 0

# Create resource groups for participant teams 1-21 (not proctors)
foreach ($teamNum in 1..21) {
    $teamNumber = $teamNum.ToString("00")
    $rgName = "rg-agentathon-team-$teamNumber"
    
    # Check if resource group exists
    $existingRg = az group exists --name $rgName --subscription $SubscriptionId 2>$null
    
    if ($existingRg -eq "true") {
        Write-Host "  ⏭️  $rgName" -ForegroundColor DarkGray
        $rgSkipped++
        continue
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] Would create: $rgName" -ForegroundColor Magenta
        $rgCreated++
        continue
    }
    
    try {
        az group create --name $rgName --location $Location --subscription $SubscriptionId --output none 2>$null
        Write-Host "  ✅ $rgName" -ForegroundColor Green
        $rgCreated++
    }
    catch {
        Write-Host "  ❌ Failed: $rgName - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Resource Groups Summary:" -ForegroundColor White
Write-Host "   Created: $rgCreated | Skipped: $rgSkipped" -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 7: Assign Contributor to Team Groups
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 7: Assign Contributor Role to Team Groups" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$rolesAssigned = 0
$rolesSkipped = 0

# Assign Contributor to teams 1-21 on their resource groups
foreach ($teamNum in 1..21) {
    $teamNumber = $teamNum.ToString("00")
    $rgName = "rg-agentathon-team-$teamNumber"
    
    if (-not $teamGroups.ContainsKey($teamNumber)) {
        Write-Host "  ⚠️  Group not found for team: $teamNumber" -ForegroundColor Yellow
        continue
    }
    
    $group = $teamGroups[$teamNumber]
    $groupObjectId = $group.Id
    
    # Get the team name for display
    $teamInfo = $workshopTeams | Where-Object { $_.Number -eq $teamNum }
    $teamName = if ($teamInfo) { $teamInfo.Name } else { "Team $teamNumber" }
    
    # Check if role assignment exists
    $existingAssignment = az role assignment list `
        --resource-group $rgName `
        --assignee $groupObjectId `
        --role "Contributor" `
        --subscription $SubscriptionId 2>$null | ConvertFrom-Json
    
    if ($existingAssignment -and $existingAssignment.Count -gt 0) {
        Write-Host "  ⏭️  $rgName → $teamName" -ForegroundColor DarkGray
        $rolesSkipped++
        continue
    }
    
    if ($WhatIfPreference) {
        Write-Host "  [WHATIF] $rgName → $teamName (Contributor)" -ForegroundColor Magenta
        $rolesAssigned++
        continue
    }
    
    try {
        az role assignment create `
            --assignee $groupObjectId `
            --role "Contributor" `
            --resource-group $rgName `
            --subscription $SubscriptionId `
            --output none 2>$null
        
        Write-Host "  ✅ $rgName → $teamName" -ForegroundColor Green
        $rolesAssigned++
        Start-Sleep -Milliseconds 300
    }
    catch {
        Write-Host "  ❌ Failed: $rgName - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 RBAC Assignments Summary:" -ForegroundColor White
Write-Host "   Assigned: $rolesAssigned | Skipped: $rolesSkipped" -ForegroundColor Gray
Write-Host ""
#endregion

#region Final Summary
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ PROVISIONING COMPLETE                                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Final Summary:" -ForegroundColor Cyan
Write-Host "   B2B Guests: $invitedCount invited, $skippedCount existing" -ForegroundColor White
Write-Host "   Global Admins: $gaAssigned assigned (8 key proctors)" -ForegroundColor White
Write-Host "   Privileged Role Admins: $praAssigned assigned (other proctors)" -ForegroundColor White
Write-Host "   Team Groups: $groupsCreated created, $groupsSkipped existing" -ForegroundColor White
Write-Host "   Team Members: $membersAdded added to groups" -ForegroundColor White
Write-Host "   Resource Groups: $rgCreated created, $rgSkipped existing" -ForegroundColor White
Write-Host "   RBAC Assignments: $rolesAssigned Contributor roles assigned" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IMPORTANT: Licenses NOT Assigned Yet" -ForegroundColor Yellow
Write-Host "   Reason: Insufficient licenses currently available" -ForegroundColor Gray
Write-Host "   Next: Purchase/assign M365 E3 + Copilot Studio licenses" -ForegroundColor Gray
Write-Host ""

Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Purchase 126 Microsoft 365 E3 licenses" -ForegroundColor White
Write-Host "   2. Assign M365 E3 + Copilot Studio to all users" -ForegroundColor White
Write-Host "   3. Deploy team Fabrikam instances (ARM template × 20)" -ForegroundColor White
Write-Host "   4. Create MCP connectors and share with team groups" -ForegroundColor White
Write-Host "   5. Test with sample participants" -ForegroundColor White
Write-Host ""

if ($WhatIfPreference) {
    Write-Host "🔍 This was a WHATIF run - no changes were made" -ForegroundColor Yellow
    Write-Host "   Run without -WhatIf to execute provisioning" -ForegroundColor Gray
}
else {
    Write-Host "🎉 Workshop tenant ready for licensing and deployment!" -ForegroundColor Green
}
Write-Host ""
#endregion



