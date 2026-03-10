#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Remove Azure resource groups for specified team instances
.DESCRIPTION
    Deletes resource groups for teams 01-23, preserving team-00, team-24, and proctor instances
.PARAMETER StartTeam
    First team number to delete (default: 1)
.PARAMETER EndTeam
    Last team number to delete (default: 23)
.PARAMETER WhatIf
    Show what would be deleted without actually deleting
.PARAMETER Force
    Skip confirmation prompts
.EXAMPLE
    .\Remove-TeamInstances.ps1 -WhatIf
    Show what would be deleted
.EXAMPLE
    .\Remove-TeamInstances.ps1 -StartTeam 1 -EndTeam 23
    Delete teams 1-23 with confirmation
.EXAMPLE
    .\Remove-TeamInstances.ps1 -StartTeam 1 -EndTeam 23 -Force
    Delete teams 1-23 without confirmation
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$StartTeam = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$EndTeam = 23,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

# Header
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🗑️  Remove Fabrikam Team Resource Groups" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Validate parameters
if ($StartTeam -lt 0 -or $EndTeam -gt 24) {
    Write-Error "Team numbers must be between 0 and 24"
    exit 1
}

if ($StartTeam -gt $EndTeam) {
    Write-Error "StartTeam cannot be greater than EndTeam"
    exit 1
}

# Check for protected teams
$protectedTeams = @(0, 24)
$teamsToDelete = $StartTeam..$EndTeam | Where-Object { $_ -notin $protectedTeams }

if ($teamsToDelete.Count -eq 0) {
    Write-Warning "No teams to delete (all specified teams are protected)"
    exit 0
}

# Build list of resource groups to delete
$resourceGroups = @()
foreach ($teamNum in $teamsToDelete) {
    $teamNumPadded = "{0:D2}" -f $teamNum
    $rgName = "rg-fabrikam-team-$teamNumPadded"
    $resourceGroups += $rgName
}

# Show summary
Write-Info "Deletion Plan:"
Write-Host ""
Write-Host "  Teams to delete: $($teamsToDelete -join ', ')" -ForegroundColor White
Write-Host "  Protected teams: 00 (workshop), 24 (testing), proctor" -ForegroundColor Yellow
Write-Host "  Resource groups to delete: $($resourceGroups.Count)" -ForegroundColor White
Write-Host ""

# List resource groups
Write-Host "  Resource Groups:" -ForegroundColor White
foreach ($rg in $resourceGroups) {
    if ($WhatIf) {
        Write-Host "    - $rg (WOULD DELETE)" -ForegroundColor Yellow
    } else {
        Write-Host "    - $rg" -ForegroundColor White
    }
}
Write-Host ""

# WhatIf mode - just show what would happen
if ($WhatIf) {
    Write-Warning "WhatIf mode - no resources will be deleted"
    Write-Info "Run without -WhatIf to perform actual deletion"
    exit 0
}

# Confirmation prompt
if (-not $Force) {
    Write-Warning "This will PERMANENTLY DELETE all resources in these resource groups!"
    Write-Host ""
    $confirmation = Read-Host "Type 'DELETE' to confirm (or anything else to cancel)"
    
    if ($confirmation -ne "DELETE") {
        Write-Warning "Deletion cancelled by user"
        exit 0
    }
}

Write-Host ""
Write-Info "Starting deletion process..."
Write-Host ""

# Check Azure login
Write-Info "Checking Azure authentication..."
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Success "Authenticated as: $($account.user.name)"
    Write-Info "Subscription: $($account.name)"
} catch {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

Write-Host ""

# Delete resource groups
$successCount = 0
$failCount = 0
$skippedCount = 0
$results = @()

foreach ($rg in $resourceGroups) {
    Write-Info "Processing: $rg"
    
    # Check if resource group exists
    $exists = az group exists --name $rg 2>&1
    if ($exists -eq "false") {
        Write-Warning "  Resource group does not exist - skipping"
        $skippedCount++
        $results += [PSCustomObject]@{
            ResourceGroup = $rg
            Status = "Skipped"
            Reason = "Does not exist"
        }
        Write-Host ""
        continue
    }
    
    # Get resource count
    try {
        $resources = az resource list --resource-group $rg 2>&1 | ConvertFrom-Json
        $resourceCount = $resources.Count
        Write-Info "  Found $resourceCount resource(s) in $rg"
    } catch {
        $resourceCount = "unknown"
    }
    
    # Delete resource group (no-wait for async deletion)
    Write-Info "  Initiating deletion..."
    try {
        az group delete --name $rg --yes --no-wait 2>&1 | Out-Null
        Write-Success "  Deletion initiated for $rg"
        $successCount++
        $results += [PSCustomObject]@{
            ResourceGroup = $rg
            Status = "Deleting"
            ResourceCount = $resourceCount
        }
    } catch {
        Write-Error "  Failed to delete $rg"
        Write-Error "  Error: $_"
        $failCount++
        $results += [PSCustomObject]@{
            ResourceGroup = $rg
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📊 Deletion Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Total resource groups processed: $($resourceGroups.Count)" -ForegroundColor White
Write-Success "  Deletion initiated: $successCount"
Write-Warning "  Skipped (not found): $skippedCount"
if ($failCount -gt 0) {
    Write-Error "  Failed: $failCount"
}

Write-Host ""
Write-Host "  Detailed Results:" -ForegroundColor White
$results | Format-Table -AutoSize

Write-Host ""
Write-Info "Note: Deletions are running asynchronously in the background."
Write-Info "Use 'az group list' to check deletion progress."
Write-Host ""

# Check remaining resource groups
Write-Info "Checking remaining Fabrikam resource groups..."
$remainingRgs = az group list --query "[?starts_with(name, 'rg-fabrikam')].name" -o tsv 2>&1

if ($remainingRgs) {
    Write-Host ""
    Write-Host "  Remaining resource groups:" -ForegroundColor White
    $remainingRgs | ForEach-Object {
        if ($_ -match "team-(00|24)|proctor") {
            Write-Host "    - $_ (protected ✅)" -ForegroundColor Green
        } else {
            Write-Host "    - $_ (deleting...)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Success "Deletion process complete!"
Write-Info "Resource groups are being deleted in the background."
Write-Info "This may take several minutes to complete."
Write-Host ""
