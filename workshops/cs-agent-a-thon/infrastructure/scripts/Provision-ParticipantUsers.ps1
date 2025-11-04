<#
.SYNOPSIS
    Provisions workshop participant alter ego accounts and team security groups.

.DESCRIPTION
    Creates native user accounts for all 118 workshop participants using their
    fictitious alter ego identities. Also creates team security groups and assigns
    users to their respective teams.
    
    - Creates Entra ID users with fictitious names from workshop-user-mapping.csv
    - Generates and records secure temporary passwords
    - Creates security groups for each team (Team-01 through Team-24)
    - Assigns users to their team security groups
    - Exports credentials to secure CSV file
    
    EXCLUDES proctors (already provisioned) and auditors (Yara Chia)

.PARAMETER TenantId
    The Entra ID tenant ID for the workshop tenant.

.PARAMETER TenantDomain
    The tenant domain for UPN construction (e.g., fabrikam1.csplevelup.com).

.PARAMETER DryRun
    Preview what would be created without actually creating users.

.PARAMETER SkipUsers
    Skip user creation (only create groups and assignments).

.PARAMETER SkipGroups
    Skip group creation (only create users).

.EXAMPLE
    .\Provision-ParticipantUsers.ps1 -TenantId "fd268415-..." -TenantDomain "fabrikam1.csplevelup.com"

.EXAMPLE
    .\Provision-ParticipantUsers.ps1 -TenantId "fd268415-..." -TenantDomain "fabrikam1.csplevelup.com" -DryRun

.NOTES
    Author: David Bjurman-Birr
    Date: November 2, 2025
    
    Prerequisites:
    - Microsoft Graph PowerShell SDK installed (Install-Module Microsoft.Graph)
    - Connected to Microsoft Graph with appropriate permissions:
      - User.ReadWrite.All
      - Group.ReadWrite.All
      - Directory.ReadWrite.All
    
    Run time: ~20-30 minutes for 118 users + 24 groups
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantDomain,
    
    [Parameter()]
    [switch]$DryRun,
    
    [Parameter()]
    [switch]$SkipUsers,
    
    [Parameter()]
    [switch]$SkipGroups
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$infrastructurePath = Split-Path -Parent $scriptPath

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Workshop Participant Provisioning                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tenant: $TenantDomain" -ForegroundColor Yellow
Write-Host "Tenant ID: $TenantId" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no changes will be made)" -ForegroundColor Magenta
}
Write-Host ""

# Load workshop user mapping
$mappingPath = Join-Path $infrastructurePath "workshop-user-mapping.csv"
if (-not (Test-Path $mappingPath)) {
    Write-Error "Workshop user mapping not found at: $mappingPath"
    exit 1
}

Write-Host "📂 Loading workshop user mapping..." -ForegroundColor Yellow
$allUsers = Import-Csv $mappingPath

# Filter to participants only (exclude proctors and auditors)
$participants = $allUsers | Where-Object { 
    $_.Role -eq "Participant" -and $_.Team -ne "Auditor" 
}

Write-Host "   Total users in mapping: $($allUsers.Count)" -ForegroundColor White
Write-Host "   Participants to provision: $($participants.Count)" -ForegroundColor Cyan
Write-Host "   Teams: $(($participants | Select-Object -Unique Team).Count)" -ForegroundColor Cyan
Write-Host ""

# Check authentication
Write-Host "🔐 Checking Microsoft Graph authentication..." -ForegroundColor Yellow
try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph"
    }
    if ($context.TenantId -ne $TenantId) {
        Write-Host "   ⚠️  Connected to wrong tenant. Reconnecting..." -ForegroundColor Yellow
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"
    } else {
        Write-Host "   ✅ Connected to workshop tenant" -ForegroundColor Green
    }
} catch {
    Write-Host "   Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"
}

$context = Get-MgContext
Write-Host "   Account: $($context.Account)" -ForegroundColor Gray
Write-Host "   Scopes: $($context.Scopes -join ', ')" -ForegroundColor Gray
Write-Host ""

# Generate secure temporary password
function New-SecureTemporaryPassword {
    $length = 16
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    
    do {
        $password = -join ((1..$length) | ForEach-Object { 
            $chars[(Get-Random -Maximum $chars.Length)] 
        })
    } while (
        $password -notmatch "[a-z]" -or 
        $password -notmatch "[A-Z]" -or 
        $password -notmatch "[0-9]" -or 
        $password -notmatch "[!@#$%^&*]"
    )
    
    return $password
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Create Team Security Groups
# ═══════════════════════════════════════════════════════════════════

if (-not $SkipGroups) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   Phase 1: Creating Team Security Groups                  ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    $teamNumbers = $participants | Select-Object -ExpandProperty Team -Unique | Sort-Object { [int]$_ }
    $createdGroups = @()
    $existingGroups = @()

    foreach ($teamNum in $teamNumbers) {
        $teamId = "Team-{0:D2}" -f [int]$teamNum
        $groupName = "Workshop-$teamId"
        $description = "CS Agent-A-Thon Workshop - Team $teamNum"
        
        Write-Host "Creating security group: $groupName..." -ForegroundColor Yellow -NoNewline
        
        if ($DryRun) {
            Write-Host " [DRY RUN]" -ForegroundColor Magenta
            continue
        }
        
        try {
            # Check if group already exists
            $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            
            if ($existingGroup) {
                Write-Host " ✓ Already exists" -ForegroundColor Gray
                $existingGroups += $groupName
            } else {
                # Create security group
                $groupParams = @{
                    DisplayName = $groupName
                    Description = $description
                    MailEnabled = $false
                    MailNickname = "workshop-team-$teamNum"
                    SecurityEnabled = $true
                    GroupTypes = @()
                }
                
                $newGroup = New-MgGroup @groupParams
                Write-Host " ✅ Created ($($newGroup.Id))" -ForegroundColor Green
                $createdGroups += $groupName
            }
        } catch {
            Write-Host " ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Team Groups Summary:" -ForegroundColor Cyan
    Write-Host "   Created: $($createdGroups.Count)" -ForegroundColor Green
    Write-Host "   Already existed: $($existingGroups.Count)" -ForegroundColor Yellow
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Create Participant User Accounts
# ═══════════════════════════════════════════════════════════════════

$credentialsExport = @()
$createdUsers = @()
$skippedUsers = @()
$errorUsers = @()

if (-not $SkipUsers) {
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   Phase 2: Creating Participant User Accounts             ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    $totalUsers = $participants.Count
    $currentUser = 0

    foreach ($participant in $participants) {
        $currentUser++
        $percentComplete = [math]::Round(($currentUser / $totalUsers) * 100)
        
        $upn = $participant.NativeUserPrincipalName
        $displayName = $participant.DisplayName
        $teamNum = $participant.Team
        
        Write-Host "[$currentUser/$totalUsers - $percentComplete%] Creating: $displayName ($upn)..." -ForegroundColor Yellow -NoNewline
        
        if ($DryRun) {
            Write-Host " [DRY RUN]" -ForegroundColor Magenta
            continue
        }
        
        try {
            # Check if user already exists
            $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            
            if ($existingUser) {
                Write-Host " ⚠️  Already exists" -ForegroundColor Yellow
                $skippedUsers += $participant
                $userId = $existingUser.Id
            } else {
                # Generate temporary password
                $tempPassword = New-SecureTemporaryPassword
                
                # Create user account
                $passwordProfile = @{
                    Password = $tempPassword
                    ForceChangePasswordNextSignIn = $true
                }
                
                $userParams = @{
                    AccountEnabled = $true
                    DisplayName = $displayName
                    UserPrincipalName = $upn
                    MailNickname = $participant.Alias
                    GivenName = $participant.FictitiousFirstName
                    Surname = $participant.FictitiousLastName
                    PasswordProfile = $passwordProfile
                    UsageLocation = "US"
                    JobTitle = "Workshop Participant"
                    Department = "CS Agent-A-Thon - Team $teamNum"
                    CompanyName = "Fabrikam Modular Homes"
                }
                
                $newUser = New-MgUser @userParams
                $userId = $newUser.Id
                
                Write-Host " ✅" -ForegroundColor Green
                $createdUsers += $participant
                
                # Store credentials for export
                $credentialsExport += [PSCustomObject]@{
                    UserNumber = $participant.UserNumber
                    RealFullName = $participant.RealFullName
                    RealEmail = $participant.RealEmail
                    Role = $participant.Role
                    WorkshopUsername = $upn
                    FictitiousName = $participant.FictitiousFullName
                    TemporaryPassword = $tempPassword
                    ChallengeLevel = $participant.ChallengeLevel
                    Team = "Team-{0:D2}" -f [int]$teamNum
                }
            }
            
            # Add user to team security group
            $teamId = "Team-{0:D2}" -f [int]$teamNum
            $groupName = "Workshop-$teamId"
            $teamGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
            
            if ($teamGroup) {
                # Check if already a member
                $members = Get-MgGroupMember -GroupId $teamGroup.Id
                $isMember = $members | Where-Object { $_.Id -eq $userId }
                
                if (-not $isMember) {
                    $directoryObject = @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
                    }
                    New-MgGroupMember -GroupId $teamGroup.Id -BodyParameter $directoryObject -ErrorAction SilentlyContinue
                }
            }
            
        } catch {
            Write-Host " ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            $errorUsers += [PSCustomObject]@{
                Participant = $participant
                Error = $_.Exception.Message
            }
        }
        
        # Rate limiting - avoid throttling
        Start-Sleep -Milliseconds 500
        
        # Pause every 20 users to avoid throttling
        if ($currentUser % 20 -eq 0 -and $currentUser -lt $totalUsers) {
            Write-Host ""
            Write-Host "   Pausing 10 seconds to avoid throttling..." -ForegroundColor Gray
            Start-Sleep -Seconds 10
            Write-Host ""
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: Export Credentials
# ═══════════════════════════════════════════════════════════════════

if ($credentialsExport.Count -gt 0 -and -not $DryRun) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   Phase 3: Exporting Credentials                          ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $credentialsPath = Join-Path $infrastructurePath "participant-credentials-$timestamp.csv"
    
    $credentialsExport | Sort-Object { [int]$_.UserNumber } | Export-Csv -Path $credentialsPath -NoTypeInformation -Force
    
    Write-Host "🔐 Credentials exported to:" -ForegroundColor Green
    Write-Host "   $credentialsPath" -ForegroundColor White
    Write-Host ""
    Write-Host "   ⚠️  KEEP THIS FILE SECURE - Contains temporary passwords!" -ForegroundColor Yellow
    Write-Host "   ⚠️  Add to .gitignore to prevent accidental commit!" -ForegroundColor Yellow
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════
# Summary Report
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Provisioning Summary                                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (-not $SkipGroups) {
    Write-Host "Team Security Groups:" -ForegroundColor Yellow
    Write-Host "   Created: $($createdGroups.Count)" -ForegroundColor Green
    Write-Host "   Already existed: $($existingGroups.Count)" -ForegroundColor Gray
    Write-Host ""
}

if (-not $SkipUsers) {
    Write-Host "User Accounts:" -ForegroundColor Yellow
    Write-Host "   Created: $($createdUsers.Count)" -ForegroundColor Green
    Write-Host "   Skipped (already exist): $($skippedUsers.Count)" -ForegroundColor Gray
    Write-Host "   Errors: $($errorUsers.Count)" -ForegroundColor $(if ($errorUsers.Count -gt 0) { "Red" } else { "Green" })
    Write-Host ""
}

if ($errorUsers.Count -gt 0) {
    Write-Host "❌ Failed Users:" -ForegroundColor Red
    $errorUsers | ForEach-Object {
        Write-Host "   $($_.Participant.NativeUserPrincipalName): $($_.Error)" -ForegroundColor Red
    }
    Write-Host ""
}

if ($DryRun) {
    Write-Host "💡 This was a DRY RUN - no actual changes were made" -ForegroundColor Magenta
    Write-Host "   Remove -DryRun parameter to provision users" -ForegroundColor White
} else {
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. ✅ Assign M365 licenses to users" -ForegroundColor White
    Write-Host "2. ✅ Configure team-specific Azure resources" -ForegroundColor White
    Write-Host "3. ✅ Send credential emails to participants" -ForegroundColor White
    Write-Host "4. ✅ Verify user access to Copilot Studio and Azure portal" -ForegroundColor White
}

Write-Host ""
