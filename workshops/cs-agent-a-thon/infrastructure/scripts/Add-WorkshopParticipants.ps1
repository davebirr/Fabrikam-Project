<#
.SYNOPSIS
    Provisions participant accounts with standard user permissions.

.DESCRIPTION
    Creates user accounts for all workshop participants.
    Participants get standard user role and will receive
    Contributor access to their team resource group.

.PARAMETER TenantId
    The Entra ID tenant ID.

.PARAMETER TenantDomain
    The tenant domain for UPN construction.

.EXAMPLE
    .\Add-WorkshopParticipants.ps1 -TenantId "fd268415-..." -TenantDomain "levelupcspfy26cs01.onmicrosoft.com"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantDomain
)

$ErrorActionPreference = "Stop"

# Load attendee data
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$attendeesPath = Join-Path (Split-Path -Parent $scriptPath) "docs\microsoft-attendees.csv"

if (-not (Test-Path $attendeesPath)) {
    Write-Error "Attendees CSV not found at: $attendeesPath"
    exit 1
}

# Proctor aliases (to exclude from participants)
$proctorAliases = @(
    "DAVIDB", "MERTUNAN", "KIRKDA", "APRILDELSING", "CDEPAEPE", "ESALVAREZ",
    "FRANVANH", "JIMBANACH", "JOWRIG", "MADERIDD", "MARIUSZO", "MABOAM",
    "MADAVI", "MIKEPALITTO", "OGORDON", "RAGNARPITLA", "RUNAUWEL", "SARAHBURG",
    "STSCHULZ", "ZASAEED"
)

$attendees = Import-Csv $attendeesPath
$participants = $attendees | Where-Object { $proctorAliases -notcontains $_.Alias }

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Provisioning Participant Accounts                        ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tenant: $TenantDomain" -ForegroundColor Cyan
Write-Host "Participants to provision: $($participants.Count)" -ForegroundColor Cyan
Write-Host ""

$provisionedCount = 0
$skippedCount = 0
$errorCount = 0
$currentProgress = 0

foreach ($participant in $participants) {
    $currentProgress++
    $upn = "$($participant.Alias)@$TenantDomain"
    $displayName = $participant.FullName
    
    Write-Progress -Activity "Provisioning Participants" -Status "Processing $displayName" -PercentComplete (($currentProgress / $participants.Count) * 100)
    
    try {
        # Check if user already exists
        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-Host "  ✓ User exists: $displayName" -ForegroundColor Gray
            $skippedCount++
        }
        else {
            # Create user account
            $passwordProfile = @{
                Password                      = "WorkshopTemp2025!"
                ForceChangePasswordNextSignIn = $true
            }
            
            $userParams = @{
                AccountEnabled    = $true
                DisplayName       = $displayName
                UserPrincipalName = $upn
                MailNickname      = $participant.Alias
                PasswordProfile   = $passwordProfile
                UsageLocation     = "US"
                JobTitle          = "Workshop Participant"
                Department        = $participant.Team
                CompanyName       = "CS Agent-A-Thon Workshop"
                Country           = $participant.Country
            }
            
            $newUser = New-MgUser @userParams
            
            Write-Host "  ✓ Created: $displayName ($upn)" -ForegroundColor Green
            $provisionedCount++
        }
    }
    catch {
        Write-Host "  ✗ Error creating $displayName : $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Progress -Activity "Provisioning Participants" -Completed

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Participant Provisioning Summary                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total participants: $($participants.Count)" -ForegroundColor Cyan
Write-Host "Newly provisioned: $provisionedCount" -ForegroundColor Green
Write-Host "Already existed: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Default password: WorkshopTemp2025!" -ForegroundColor Yellow
Write-Host "Users must change password on first sign-in" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run New-TeamResourceGroups.ps1 to create Azure resources" -ForegroundColor Cyan
Write-Host ""