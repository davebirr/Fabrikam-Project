<#
.SYNOPSIS
    Master provisioning script for CS Agent-A-Thon workshop tenant and Azure resources.

.DESCRIPTION
    Orchestrates the complete provisioning of the workshop environment including:
    - Entra ID user accounts (proctors and participants)
    - Global Admin role assignments for proctors
    - Azure subscription and resource groups (one per team)
    - RBAC role assignments for team access
    - Infrastructure deployment validation

.PARAMETER TenantId
    The Entra ID tenant ID for the workshop environment.
    Default: fd268415-22a5-4064-9b5e-d039761c5971

.PARAMETER TenantDomain
    The primary tenant domain.
    Default: levelupcspfy26cs01.onmicrosoft.com

.PARAMETER SubscriptionName
    Name for the Azure subscription.
    Default: Workshop-AgentAThon-Nov2025

.PARAMETER Location
    Azure region for resource deployment.
    Default: eastus

.PARAMETER DryRun
    If specified, shows what would be done without making changes.

.EXAMPLE
    .\Provision-WorkshopTenant.ps1
    
.EXAMPLE
    .\Provision-WorkshopTenant.ps1 -DryRun
    
.EXAMPLE
    .\Provision-WorkshopTenant.ps1 -Location "westus2"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
    Requires: Az PowerShell module, Microsoft.Graph PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TenantId = "fd268415-22a5-4064-9b5e-d039761c5971",
    
    [Parameter()]
    [string]$TenantDomain = "levelupcspfy26cs01.onmicrosoft.com",
    
    [Parameter()]
    [string]$SubscriptionName = "Workshop-AgentAThon-Nov2025",
    
    [Parameter()]
    [string]$Location = "eastus",
    
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

#region Helper Functions

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $colors = @{
        "Info"    = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error"   = "Red"
    }
    
    $prefix = @{
        "Info"    = "[INFO]"
        "Success" = "[✓]"
        "Warning" = "[!]"
        "Error"   = "[✗]"
    }
    
    Write-Host "$($prefix[$Level]) $Message" -ForegroundColor $colors[$Level]
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..." "Info"
    
    # Check for required PowerShell modules
    $requiredModules = @("Az.Accounts", "Az.Resources", "Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Groups")
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Status "Missing required module: $module" "Error"
            Write-Status "Install with: Install-Module $module -Scope CurrentUser" "Info"
            return $false
        }
    }
    
    Write-Status "All prerequisites satisfied" "Success"
    return $true
}

function Connect-WorkshopTenant {
    param([string]$TenantId)
    
    Write-Status "Connecting to tenant $TenantId..." "Info"
    
    try {
        # Connect to Microsoft Graph
        Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -NoWelcome
        
        # Connect to Azure
        Connect-AzAccount -TenantId $TenantId
        
        Write-Status "Successfully connected to tenant" "Success"
        return $true
    }
    catch {
        Write-Status "Failed to connect: $_" "Error"
        return $false
    }
}

#endregion

#region Main Script

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CS Agent-A-Thon Workshop - Tenant Provisioning          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Status "DRY RUN MODE - No changes will be made" "Warning"
    Write-Host ""
}

# Step 1: Prerequisites
if (-not (Test-Prerequisites)) {
    Write-Status "Prerequisites check failed. Please install required modules." "Error"
    exit 1
}

# Step 2: Connect to tenant
if (-not (Connect-WorkshopTenant -TenantId $TenantId)) {
    Write-Status "Failed to connect to tenant. Exiting." "Error"
    exit 1
}

Write-Host ""
Write-Status "=== Provisioning Overview ===" "Info"
Write-Host "Tenant ID: $TenantId"
Write-Host "Tenant Domain: $TenantDomain"
Write-Host "Subscription: $SubscriptionName"
Write-Host "Location: $Location"
Write-Host ""

# Step 3: Load attendee data
Write-Status "Loading attendee data..." "Info"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$attendeesPath = Join-Path (Split-Path -Parent $scriptPath) "docs\microsoft-attendees.csv"

if (-not (Test-Path $attendeesPath)) {
    Write-Status "Attendees CSV not found at: $attendeesPath" "Error"
    exit 1
}

$attendees = Import-Csv $attendeesPath
$proctorAliases = @(
    "DAVIDB", "MERTUNAN", "KIRKDA", "APRILDELSING", "CDEPAEPE", "ESALVAREZ",
    "FRANVANH", "JIMBANACH", "JOWRIG", "MADERIDD", "MARIUSZO", "MABOAM",
    "MADAVI", "MIKEPALITTO", "OGORDON", "RAGNARPITLA", "RUNAUWEL", "SARAHBURG",
    "STSCHULZ", "ZASAEED"
)

$proctors = $attendees | Where-Object { $proctorAliases -contains $_.Alias }
$participants = $attendees | Where-Object { $proctorAliases -notcontains $_.Alias }

Write-Status "Found $($proctors.Count) proctors and $($participants.Count) participants" "Success"

# Step 4: Provision proctor accounts
Write-Host ""
Write-Status "=== Step 1: Provisioning Proctor Accounts ===" "Info"

if (-not $DryRun) {
    & "$scriptPath\Add-WorkshopProctors.ps1" -TenantId $TenantId -TenantDomain $TenantDomain
} else {
    Write-Status "Would provision $($proctors.Count) proctor accounts with Global Admin role" "Info"
}

# Step 5: Provision participant accounts
Write-Host ""
Write-Status "=== Step 2: Provisioning Participant Accounts ===" "Info"

if (-not $DryRun) {
    & "$scriptPath\Add-WorkshopParticipants.ps1" -TenantId $TenantId -TenantDomain $TenantDomain
} else {
    Write-Status "Would provision $($participants.Count) participant accounts" "Info"
}

# Step 6: Create Azure subscription and resource groups
Write-Host ""
Write-Status "=== Step 3: Creating Azure Resource Groups ===" "Info"

if (-not $DryRun) {
    & "$scriptPath\New-TeamResourceGroups.ps1" -SubscriptionName $SubscriptionName -Location $Location
} else {
    Write-Status "Would create subscription '$SubscriptionName' with 21 team resource groups" "Info"
}

# Step 7: Assign RBAC permissions
Write-Host ""
Write-Status "=== Step 4: Assigning Team Access Permissions ===" "Info"

if (-not $DryRun) {
    & "$scriptPath\Grant-TeamAccess.ps1" -TenantDomain $TenantDomain
} else {
    Write-Status "Would assign Contributor role to team members for their resource groups" "Info"
}

# Step 8: Validation
Write-Host ""
Write-Status "=== Step 5: Validating Provisioning ===" "Info"

if (-not $DryRun) {
    & "$scriptPath\Test-WorkshopReadiness.ps1" -TenantId $TenantId
} else {
    Write-Status "Would validate all user accounts and resource groups" "Info"
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Provisioning Complete!                                   ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Status "This was a dry run. No changes were made." "Warning"
    Write-Status "Run without -DryRun to execute provisioning." "Info"
} else {
    Write-Status "Workshop tenant is ready for November 6, 2025!" "Success"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Deploy team infrastructure: .\Deploy-TeamInfrastructure.ps1"
    Write-Host "  2. Test participant access: .\Test-WorkshopReadiness.ps1"
    Write-Host "  3. Review access documentation in docs/TENANT-CONFIG.md"
}

Write-Host ""

#endregion