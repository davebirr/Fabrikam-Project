<#
.SYNOPSIS
    Provisions 137 workshop users (fictitious alter egos) in Entra ID

.DESCRIPTION
    Creates native users in the workshop tenant (fabrikam1.csplevelup.com) with:
    - Fictitious names (NO PII)
    - Temporary passwords
    - M365 E3 licenses
    - Security group assignments
    - RBAC on Azure subscription

.PARAMETER TenantId
    Workshop tenant ID (default: fd268415-22a5-4064-9b5e-d039761c5971)

.PARAMETER DryRun
    Preview what would be created without actually creating users

.PARAMETER BatchSize
    Number of users to create at a time (default: 10)

.NOTES
    Prerequisites:
    - Azure CLI authenticated to workshop tenant
    - Microsoft Graph PowerShell SDK installed
    - Global Administrator or User Administrator role
    
    Run time: ~15-20 minutes for 137 users
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups

[CmdletBinding()]
param(
    [string]$TenantId = "fd268415-22a5-4064-9b5e-d039761c5971",
    [switch]$DryRun,
    [int]$BatchSize = 10,
    [switch]$ProctorsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$infrastructurePath = Split-Path -Parent $PSScriptRoot

Write-Host "`n🚀 Workshop User Provisioning" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Load workshop user mapping
$mappingPath = Join-Path $infrastructurePath "workshop-user-mapping.csv"
if (-not (Test-Path $mappingPath)) {
    throw "Workshop user mapping not found at: $mappingPath"
}

Write-Host "`n📂 Loading user mapping..." -ForegroundColor Yellow
$allUsers = Import-Csv $mappingPath

if ($ProctorsOnly) {
    $users = $allUsers | Where-Object { $_.Role -eq "Proctor" }
    Write-Host "   🎯 Provisioning PROCTORS ONLY: $($users.Count) users" -ForegroundColor Cyan
} else {
    $users = $allUsers
    Write-Host "   Found $($users.Count) total users" -ForegroundColor White
}

Write-Host "`n📊 User Distribution:" -ForegroundColor Yellow
$proctors = @($users | Where-Object { $_.Role -eq "Proctor" })
$participants = @($users | Where-Object { $_.Role -eq "Participant" })
$proctorCount = $proctors.Count
$participantCount = $participants.Count
Write-Host "   Proctors: $proctorCount" -ForegroundColor Cyan
Write-Host "   Participants: $participantCount" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN MODE - No users will be created" -ForegroundColor Yellow
}

# Check authentication
Write-Host "`n🔐 Checking authentication..." -ForegroundColor Yellow
try {
    $context = Get-MgContext
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

# Generate secure temporary passwords
function New-TemporaryPassword {
    $length = 16
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    
    # Ensure complexity requirements
    if ($password -notmatch "[a-z]" -or $password -notmatch "[A-Z]" -or 
        $password -notmatch "[0-9]" -or $password -notmatch "[!@#$%^&*]") {
        return New-TemporaryPassword
    }
    
    return $password
}

# Create users in batches
$createdUsers = @()
$failedUsers = @()
$skippedUsers = @()
$credentialsExport = @()

Write-Host "`n👥 Creating users..." -ForegroundColor Cyan
$currentBatch = 0
$totalBatches = [Math]::Ceiling($users.Count / $BatchSize)

foreach ($batch in ($users | Group-Object -Property { [Math]::Floor([Array]::IndexOf($users, $_) / $BatchSize) })) {
    $currentBatch++
    Write-Host "`n📦 Batch $currentBatch of $totalBatches ($($batch.Group.Count) users)" -ForegroundColor Yellow
    
    foreach ($user in $batch.Group) {
        $upn = $user.NativeUserPrincipalName
        
        Write-Host "   Creating: $upn ($($user.FictitiousFullName))..." -ForegroundColor White -NoNewline
        
        if ($DryRun) {
            Write-Host " [DRY RUN]" -ForegroundColor Yellow
            continue
        }
        
        try {
            # Check if user already exists
            $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            
            if ($existingUser) {
                Write-Host " ⚠️  Already exists" -ForegroundColor Yellow
                $skippedUsers += $user
                continue
            }
            
            # Generate temporary password
            $tempPassword = New-TemporaryPassword
            
            # Create user
            $passwordProfile = @{
                Password = $tempPassword
                ForceChangePasswordNextSignIn = $true
            }
            
            $userParams = @{
                UserPrincipalName = $upn
                DisplayName = $user.DisplayName
                GivenName = $user.FictitiousFirstName
                Surname = $user.FictitiousLastName
                MailNickname = $user.Alias
                AccountEnabled = $true
                PasswordProfile = $passwordProfile
                UsageLocation = "US"
            }
            
            $newUser = New-MgUser @userParams -ErrorAction Stop
            
            Write-Host " ✅" -ForegroundColor Green
            $createdUsers += $user
            
            # Store credentials for export
            $credentialsExport += [PSCustomObject]@{
                UserNumber              = $user.UserNumber
                RealFullName            = $user.RealFullName
                RealEmail               = $user.RealEmail
                Role                    = $user.Role
                WorkshopUsername        = $upn
                FictitiousName          = $user.FictitiousFullName
                TemporaryPassword       = $tempPassword
                ChallengeLevel          = $user.ChallengeLevel
            }
            
        } catch {
            Write-Host " ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            $failedUsers += [PSCustomObject]@{
                User = $user
                Error = $_.Exception.Message
            }
        }
        
        # Rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "   Batch $currentBatch complete. Pausing 5 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

# Export credentials to secure file
if ($credentialsExport.Count -gt 0 -and -not $DryRun) {
    $credentialsPath = Join-Path $infrastructurePath "workshop-user-credentials.csv"
    $credentialsExport | Export-Csv -Path $credentialsPath -NoTypeInformation -Force
    
    Write-Host "`n🔐 Credentials exported to:" -ForegroundColor Green
    Write-Host "   $credentialsPath" -ForegroundColor White
    Write-Host "   ⚠️  KEEP THIS FILE SECURE - Contains temporary passwords!" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "📊 Provisioning Summary" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

Write-Host "`n✅ Created: $($createdUsers.Count) users" -ForegroundColor Green
Write-Host "⚠️  Skipped (already exist): $($skippedUsers.Count) users" -ForegroundColor Yellow
Write-Host "❌ Failed: $($failedUsers.Count) users" -ForegroundColor Red

if ($failedUsers.Count -gt 0) {
    Write-Host "`n❌ Failed Users:" -ForegroundColor Red
    $failedUsers | Format-Table @{Name='UPN';Expression={$_.User.NativeUserPrincipalName}}, Error -AutoSize
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
if (-not $DryRun -and $createdUsers.Count -gt 0) {
    Write-Host "1. ✅ Assign M365 E3 licenses (run: Assign-Licenses.ps1)" -ForegroundColor White
    Write-Host "2. ✅ Add users to security groups (run: Add-UsersToGroups.ps1)" -ForegroundColor White
    Write-Host "3. ✅ Assign Azure RBAC roles (run: Assign-AzureRoles.ps1)" -ForegroundColor White
    Write-Host "4. ✅ Distribute credentials via email (run: Send-CredentialEmails.ps1)" -ForegroundColor White
} else {
    Write-Host "   Re-run without -DryRun to create users" -ForegroundColor White
}

Write-Host ""
