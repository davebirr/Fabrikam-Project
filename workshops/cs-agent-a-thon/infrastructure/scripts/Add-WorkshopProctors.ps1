<#
.SYNOPSIS
    Provisions proctor accounts with Global Administrator role.

.DESCRIPTION
    Creates user accounts for all workshop proctors and assigns them
    Global Administrator role in the tenant. Proctors need elevated
    permissions to support participants and troubleshoot issues.

.PARAMETER TenantId
    The Entra ID tenant ID.

.PARAMETER TenantDomain
    The tenant domain for UPN construction.

.PARAMETER ProctorsOnly
    If specified, only processes users in the proctors list.

.EXAMPLE
    .\Add-WorkshopProctors.ps1 -TenantId "fd268415-..." -TenantDomain "levelupcspfy26cs01.onmicrosoft.com"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$TenantDomain,
    
    [Parameter()]
    [switch]$ProctorsOnly
)

$ErrorActionPreference = "Stop"

# Load team roster to get proctor list
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$attendeesPath = Join-Path (Split-Path -Parent $scriptPath) "docs\microsoft-attendees.csv"

if (-not (Test-Path $attendeesPath)) {
    Write-Error "Attendees CSV not found at: $attendeesPath"
    exit 1
}

# Define proctor aliases (Field & Partner team + Mert Unan + Kirk Daues)
$proctorAliases = @(
    "DAVIDB",        # David Bjurman-Birr - Workshop Lead
    "MERTUNAN",      # Mert Unan - Regional Expert
    "KIRKDA",        # Kirk Daues - Solutions Architect
    "APRILDELSING",  # April Delsing
    "CDEPAEPE",      # Cedric Depaepe
    "ESALVAREZ",     # Estefanie Alvarez
    "FRANVANH",      # Francois van Hemert
    "JIMBANACH",     # Jim Banach
    "JOWRIG",        # Jojo Wright
    "MADERIDD",      # Mario De Ridder
    "MARIUSZO",      # Mariusz Ostrowski
    "MABOAM",        # Martin Boam
    "MADAVI",        # Matthew Davis
    "MIKEPALITTO",   # Mike Palitto
    "OGORDON",       # Olga Gordon
    "RAGNARPITLA",   # Ragnar Pitla
    "RUNAUWEL",      # Ruben Nauwelaers
    "SARAHBURG",     # Sarah Burg
    "STSCHULZ",      # Stefan Schulz
    "ZASAEED"        # Zahid Saeed
)

$attendees = Import-Csv $attendeesPath
$proctors = $attendees | Where-Object { $proctorAliases -contains $_.Alias }

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Provisioning Proctor Accounts                            ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Tenant: $TenantDomain" -ForegroundColor Cyan
Write-Host "Proctors to provision: $($proctors.Count)" -ForegroundColor Cyan
Write-Host ""

# Get Global Administrator role
$globalAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"

if (-not $globalAdminRole) {
    # Role template needs to be activated
    $roleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Global Administrator'"
    $globalAdminRole = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id
}

$provisionedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($proctor in $proctors) {
    $upn = "$($proctor.Alias)@$TenantDomain"
    $displayName = $proctor.FullName
    
    Write-Host "Processing: $displayName ($upn)" -ForegroundColor Yellow
    
    try {
        # Check if user already exists
        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-Host "  ✓ User already exists: $($existingUser.Id)" -ForegroundColor Gray
            $userId = $existingUser.Id
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
                MailNickname      = $proctor.Alias
                PasswordProfile   = $passwordProfile
                UsageLocation     = "US"  # Required for license assignment
                JobTitle          = "Workshop Proctor"
                Department        = "CS Agent-A-Thon"
            }
            
            $newUser = New-MgUser @userParams
            $userId = $newUser.Id
            
            Write-Host "  ✓ Created user: $userId" -ForegroundColor Green
            $provisionedCount++
        }
        
        # Assign Global Administrator role
        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id
        $isMember = $roleMembers | Where-Object { $_.Id -eq $userId }
        
        if (-not $isMember) {
            $directoryObject = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
            }
            
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $globalAdminRole.Id -BodyParameter $directoryObject
            Write-Host "  ✓ Assigned Global Administrator role" -ForegroundColor Green
        }
        else {
            Write-Host "  ✓ Already has Global Administrator role" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        Write-Host ""
        $errorCount++
    }
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Proctor Provisioning Summary                             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total proctors: $($proctors.Count)" -ForegroundColor Cyan
Write-Host "Newly provisioned: $provisionedCount" -ForegroundColor Green
Write-Host "Already existed: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Default password: WorkshopTemp2025!" -ForegroundColor Yellow
Write-Host "Users must change password on first sign-in" -ForegroundColor Yellow
Write-Host ""