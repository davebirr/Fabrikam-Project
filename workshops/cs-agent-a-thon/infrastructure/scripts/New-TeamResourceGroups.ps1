<#
.SYNOPSIS
    Creates Azure resource groups for each workshop team.

.DESCRIPTION
    Creates one resource group per team (20 teams total) with consistent
    naming convention and tags for workshop identification and cost tracking.

.PARAMETER SubscriptionName
    Name of the Azure subscription to use.

.PARAMETER Location
    Azure region for all resource groups.

.PARAMETER ResourceGroupPrefix
    Prefix for resource group names.
    Default: rg-agentathon-team

.EXAMPLE
    .\New-TeamResourceGroups.ps1 -SubscriptionName "Workshop-AgentAThon-Nov2025" -Location "eastus"

.NOTES
    Author: David Bjurman-Birr
    Date: October 27, 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionName,
    
    [Parameter()]
    [string]$Location = "eastus",
    
    [Parameter()]
    [string]$ResourceGroupPrefix = "rg-agentathon-team"
)

$ErrorActionPreference = "Stop"

# Team information (from team-roster.md)
$teams = @(
    @{ Number = 1; Name = "Copilot Commanders"; Track = "Beginner"; Members = 6 }
    @{ Number = 2; Name = "Prompt Pioneers"; Track = "Beginner"; Members = 6 }
    @{ Number = 3; Name = "Agent Architects"; Track = "Intermediate"; Members = 5 }
    @{ Number = 4; Name = "Semantic Samurai"; Track = "Intermediate"; Members = 5 }
    @{ Number = 5; Name = "MCP Mavericks"; Track = "Intermediate"; Members = 6 }
    @{ Number = 6; Name = "Orchestration Ninjas"; Track = "Advanced"; Members = 5 }
    @{ Number = 7; Name = "AutoGen Avengers"; Track = "Advanced"; Members = 6 }
    @{ Number = 8; Name = "LangChain Legends"; Track = "Advanced"; Members = 5 }
    @{ Number = 9; Name = "Agentic Alchemists"; Track = "Intermediate"; Members = 6 }
    @{ Number = 10; Name = "RAG Raiders"; Track = "Intermediate"; Members = 5 }
    @{ Number = 11; Name = "Workflow Wizards"; Track = "Beginner"; Members = 6 }
    @{ Number = 12; Name = "Context Champions"; Track = "Beginner"; Members = 5 }
    @{ Number = 13; Name = "Intelligent Integrators"; Track = "Intermediate"; Members = 6 }
    @{ Number = 14; Name = "Prompt Perfectionists"; Track = "Intermediate"; Members = 5 }
    @{ Number = 15; Name = "Cognitive Crafters"; Track = "Advanced"; Members = 6 }
    @{ Number = 16; Name = "Reasoning Rebels"; Track = "Advanced"; Members = 5 }
    @{ Number = 17; Name = "Function Fanatics"; Track = "Beginner"; Members = 6 }
    @{ Number = 18; Name = "Schema Sherpas"; Track = "Beginner"; Members = 5 }
    @{ Number = 19; Name = "Response Rockstars"; Track = "Intermediate"; Members = 6 }
    @{ Number = 20; Name = "Action Architects"; Track = "Intermediate"; Members = 5 }
    @{ Number = 21; Name = "Completion Crusaders"; Track = "Advanced"; Members = 6 }
)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Creating Team Resource Groups                           ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Subscription: $SubscriptionName" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan
Write-Host "Teams: $($teams.Count)" -ForegroundColor Cyan
Write-Host ""

# Set subscription context
try {
    $subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue
    
    if (-not $subscription) {
        Write-Host "Subscription '$SubscriptionName' not found. Available subscriptions:" -ForegroundColor Yellow
        Get-AzSubscription | Format-Table Name, Id, State
        throw "Subscription not found"
    }
    
    Set-AzContext -SubscriptionId $subscription.Id | Out-Null
    Write-Host "✓ Using subscription: $($subscription.Name)" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Error "Failed to set subscription context: $_"
    exit 1
}

$createdCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($team in $teams) {
    $rgName = "$ResourceGroupPrefix-$($team.Number.ToString('00'))"
    
    Write-Host "Processing Team $($team.Number): $($team.Name)" -ForegroundColor Yellow
    
    try {
        # Check if resource group exists
        $existingRg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
        
        if ($existingRg) {
            Write-Host "  ✓ Resource group already exists" -ForegroundColor Gray
            $skippedCount++
        }
        else {
            # Create resource group
            $tags = @{
                "Workshop"      = "CS-Agent-A-Thon"
                "Date"          = "2025-11-06"
                "TeamNumber"    = $team.Number
                "TeamName"      = $team.Name
                "ChallengeTrack" = $team.Track
                "TeamSize"      = $team.Members
                "Environment"   = "Workshop"
                "ManagedBy"     = "David Bjurman-Birr"
                "CostCenter"    = "CSU-Workshop"
            }
            
            $rg = New-AzResourceGroup -Name $rgName -Location $Location -Tag $tags
            
            Write-Host "  ✓ Created resource group: $rgName" -ForegroundColor Green
            $createdCount++
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Resource Group Creation Summary                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total teams: $($teams.Count)" -ForegroundColor Cyan
Write-Host "Newly created: $createdCount" -ForegroundColor Green
Write-Host "Already existed: $skippedCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($createdCount -gt 0 -or $skippedCount -gt 0) {
    Write-Host "Resource groups created in: $Location" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next step: Run Grant-TeamAccess.ps1 to assign RBAC permissions" -ForegroundColor Cyan
    Write-Host ""
}
