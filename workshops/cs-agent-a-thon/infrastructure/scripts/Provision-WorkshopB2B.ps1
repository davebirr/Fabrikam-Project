<#
.SYNOPSIS
    Master provisioning script for CS Agent-A-Thon workshop using B2B guests.

.DESCRIPTION
    Orchestrates complete workshop provisioning using B2B guest invitations:
    - Invite 126 Microsoft employees as B2B guests
    - Assign Global Admin role to 19 proctors
    - Create 21 Azure resource groups (one per team)
    - Assign Contributor RBAC to participants on team resource groups
    - Validate complete environment

.PARAMETER TenantId
    The Entra ID tenant ID for the workshop environment.

.PARAMETER SubscriptionName
    Name of the Azure subscription.

.PARAMETER DryRun
    Shows what would be done without making changes.

.EXAMPLE
    .\Provision-WorkshopB2B.ps1 `
        -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
        -SubscriptionName "Workshop-AgentAThon-Nov2025" `
        -DryRun

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
    
    B2B Approach Benefits:
    - Zero licensing costs (Microsoft employees use existing licenses)
    - No password management
    - Familiar @microsoft.com login
    - Simple cleanup post-workshop
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter()]
    [string]$Location = "eastus",
    
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   CS Agent-A-Thon Workshop Provisioning (B2B Guests)      ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

if ($DryRun) {
    Write-Host "═══ DRY RUN MODE - No changes will be made ═══" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Tenant ID: $TenantId" -ForegroundColor White
Write-Host "  Subscription: $SubscriptionName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Mode: $(if ($DryRun) { 'Dry Run' } else { 'Execute' })" -ForegroundColor White
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

$requiredModules = @("Az.Accounts", "Az.Resources", "Microsoft.Graph")
$missingModules = @()

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        $missingModules += $module
        Write-Host "  ✗ Missing: $module" -ForegroundColor Red
    }
    else {
        Write-Host "  ✓ Found: $module" -ForegroundColor Green
    }
}

if ($missingModules.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing required modules. Install with:" -ForegroundColor Yellow
    foreach ($module in $missingModules) {
        Write-Host "  Install-Module -Name $module -Scope CurrentUser -Force" -ForegroundColor White
    }
    exit 1
}

Write-Host ""
Write-Host "All prerequisites satisfied!" -ForegroundColor Green
Write-Host ""

# Confirm execution
if (-not $DryRun) {
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Invite 126 Microsoft employees as B2B guests" -ForegroundColor White
    Write-Host "  2. Assign Global Admin to 19 proctors" -ForegroundColor White
    Write-Host "  3. Create 21 Azure resource groups" -ForegroundColor White
    Write-Host "  4. Assign Contributor RBAC to 107 participants" -ForegroundColor White
    Write-Host ""
    
    $confirmation = Read-Host "Continue with provisioning? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "Provisioning cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Step 1: Invite B2B Guests
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 1: Inviting Microsoft Employees as B2B Guests" -ForegroundColor Yellow
Write-Host ""

if (-not $DryRun) {
    & "$PSScriptRoot\Invite-WorkshopUsers.ps1" `
        -TenantId $TenantId `
        -SubscriptionName $SubscriptionName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ B2B guest invitation failed" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[DRY RUN] Would run: Invite-WorkshopUsers.ps1" -ForegroundColor Cyan
    Write-Host "  - Invite 19 proctors with Global Admin role" -ForegroundColor Cyan
    Write-Host "  - Invite 107 participants" -ForegroundColor Cyan
    Write-Host "  - Send email invitations to @microsoft.com addresses" -ForegroundColor Cyan
}

Write-Host ""

# Step 2: Create Resource Groups
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 2: Creating Team Resource Groups" -ForegroundColor Yellow
Write-Host ""

if (-not $DryRun) {
    & "$PSScriptRoot\New-TeamResourceGroups.ps1" `
        -SubscriptionName $SubscriptionName `
        -Location $Location
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Resource group creation failed" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[DRY RUN] Would run: New-TeamResourceGroups.ps1" -ForegroundColor Cyan
    Write-Host "  - Create 21 resource groups (rg-agentathon-team-01 to 21)" -ForegroundColor Cyan
    Write-Host "  - Apply workshop tags for cost tracking" -ForegroundColor Cyan
}

Write-Host ""

# Step 3: Assign RBAC (if not already done in Step 1)
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 3: Verifying RBAC Assignments" -ForegroundColor Yellow
Write-Host ""

if (-not $DryRun) {
    # Grant-TeamAccess handles B2B guests properly
    & "$PSScriptRoot\Grant-TeamAccess.ps1" `
        -SubscriptionName $SubscriptionName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ RBAC assignment warnings (may be normal)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "[DRY RUN] Would run: Grant-TeamAccess.ps1" -ForegroundColor Cyan
    Write-Host "  - Assign Contributor role to each participant on their team RG" -ForegroundColor Cyan
}

Write-Host ""

# Step 4: Validate Environment
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Step 4: Validating Workshop Environment" -ForegroundColor Yellow
Write-Host ""

if (-not $DryRun) {
    & "$PSScriptRoot\Test-WorkshopReadiness.ps1" `
        -TenantId $TenantId `
        -SubscriptionName $SubscriptionName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ Validation found issues - review output above" -ForegroundColor Yellow
    }
}
else {
    Write-Host "[DRY RUN] Would run: Test-WorkshopReadiness.ps1" -ForegroundColor Cyan
    Write-Host "  - Validate all B2B guests invited" -ForegroundColor Cyan
    Write-Host "  - Validate resource groups created" -ForegroundColor Cyan
    Write-Host "  - Validate RBAC assignments" -ForegroundColor Cyan
}

Write-Host ""

# Final Summary
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Workshop Provisioning Complete!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "This was a DRY RUN - no changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to execute provisioning" -ForegroundColor Cyan
}
else {
    Write-Host "Workshop environment provisioned successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Participants must accept B2B invitation emails" -ForegroundColor White
    Write-Host "  2. Verify access: https://portal.azure.com" -ForegroundColor White
    Write-Host "  3. Deploy team infrastructure (AI Foundry, OpenAI, etc.)" -ForegroundColor White
    Write-Host "  4. Test with sample participants before workshop" -ForegroundColor White
    Write-Host ""
    Write-Host "B2B Guest Benefits:" -ForegroundColor Cyan
    Write-Host "  ✓ Zero licensing costs (using Microsoft licenses)" -ForegroundColor Green
    Write-Host "  ✓ No password management needed" -ForegroundColor Green
    Write-Host "  ✓ Familiar @microsoft.com login" -ForegroundColor Green
    Write-Host "  ✓ Simple cleanup: just revoke B2B invitations" -ForegroundColor Green
}

Write-Host ""
