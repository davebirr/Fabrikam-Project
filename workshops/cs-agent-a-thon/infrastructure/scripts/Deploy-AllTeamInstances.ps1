<#
.SYNOPSIS
    Deploy all workshop team instances and configure Entra ID groups with permissions

.DESCRIPTION
    Comprehensive deployment script that:
    1. Deploys MCP instances for all teams (00-24)
    2. Creates Entra ID groups for each team
    3. Adds team members to their respective groups
    4. Grants Contributor access to resource groups
    5. Tracks deployment status

.PARAMETER TeamsCSV
    Path to participant tracking CSV file

.PARAMETER Location
    Azure region (default: westus2)

.PARAMETER SkuName
    App Service Plan SKU (default: B2)

.PARAMETER WhatIf
    Preview what would be created without actually deploying

.PARAMETER TeamNumber
    Deploy only a specific team number (01-24, 00 for proctor)

.EXAMPLE
    .\Deploy-AllTeamInstances.ps1 -TeamsCSV "participant-credentials-TRACKING.csv"
    Deploy all teams and configure permissions

.EXAMPLE
    .\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf
    Preview deployment for team-05 only
#>

param(
    [string]$TeamsCSV = "../participant-credentials-TRACKING.csv",
    [string]$Location = "westus2",
    [ValidateSet("B1", "B2", "S1")]
    [string]$SkuName = "B2",
    [switch]$WhatIf,
    [ValidatePattern('^\d{2}$')]
    [string]$TeamNumber
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Workshop Team Deployment & Configuration                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Verify logged in to correct tenant
Write-Host "[Step 1/6] Verifying Azure login..." -ForegroundColor Cyan
$currentAccount = az account show --query "{Tenant:tenantId, User:user.name, Subscription:name}" -o json | ConvertFrom-Json

if (-not $currentAccount) {
    Write-Host "  ✗ Not logged in to Azure" -ForegroundColor Red
    Write-Host "`n  Please login: az login --tenant fabrikam1.csplevelup.com" -ForegroundColor Yellow
    exit 1
}

$fabrikamTenantId = "fd268415-22a5-4064-9b5e-d039761c5971"
if ($currentAccount.Tenant -ne $fabrikamTenantId) {
    Write-Host "  ⚠️  Wrong tenant: $($currentAccount.Tenant)" -ForegroundColor Red
    Write-Host "  Expected: $fabrikamTenantId (fabrikam1.csplevelup.com)" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ Logged in as: $($currentAccount.User)" -ForegroundColor Green
Write-Host "  ✓ Tenant: fabrikam1.csplevelup.com" -ForegroundColor Green
Write-Host "  ✓ Subscription: $($currentAccount.Subscription)" -ForegroundColor Green

# Read participant data
Write-Host "`n[Step 2/6] Reading participant data..." -ForegroundColor Cyan
$csvPath = Join-Path $PSScriptRoot $TeamsCSV
if (-not (Test-Path $csvPath)) {
    Write-Host "  ✗ CSV file not found: $csvPath" -ForegroundColor Red
    exit 1
}

$participants = Import-Csv $csvPath
Write-Host "  ✓ Loaded $($participants.Count) participants" -ForegroundColor Green

# Group by team
$teams = $participants | Where-Object { $_.Team -match '^Team-\d+$' } | 
    Group-Object -Property Team | 
    Sort-Object Name

Write-Host "  ✓ Found $($teams.Count) teams" -ForegroundColor Green

# If specific team requested, filter to just that team
if ($TeamNumber) {
    $teamName = "Team-$TeamNumber"
    $teams = $teams | Where-Object { $_.Name -eq $teamName }
    if (-not $teams) {
        Write-Host "  ✗ Team $TeamNumber not found in CSV" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ℹ️  Deploying only: $teamName" -ForegroundColor Yellow
}

# Deployment summary
$deploymentLog = @()
$successCount = 0
$failureCount = 0

foreach ($team in $teams) {
    $teamId = $team.Name -replace 'Team-', ''
    $teamMembers = $team.Group
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   Processing $($team.Name) - $($teamMembers.Count) members" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $resourceGroupName = "rg-fabrikam-team-$teamId"
    $groupName = "Fabrikam-Team-$teamId"
    
    $deploymentStatus = [PSCustomObject]@{
        TeamId = $teamId
        TeamName = $team.Name
        MemberCount = $teamMembers.Count
        ResourceGroup = $resourceGroupName
        EntraGroup = $groupName
        DeploymentStatus = ""
        GroupStatus = ""
        PermissionStatus = ""
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # ========================================
    # Step 3: Deploy MCP Instance
    # ========================================
    Write-Host "`n[Step 3/6] Deploying MCP instance for Team-$teamId..." -ForegroundColor Cyan
    
    if ($WhatIf) {
        Write-Host "  [WhatIf] Would deploy:" -ForegroundColor Gray
        Write-Host "    • Resource Group: $resourceGroupName"
        Write-Host "    • Location: $Location"
        Write-Host "    • SKU: $SkuName"
        $deploymentStatus.DeploymentStatus = "WhatIf - Not Deployed"
    } else {
        try {
            # Check if resources already exist (not just resource group)
            $rgExists = az group exists --name $resourceGroupName
            $resourceCount = 0
            
            if ($rgExists -eq "true") {
                # Count actual resources in the group
                $resourcesJson = az resource list -g $resourceGroupName --query "[]" -o json 2>$null
                if ($resourcesJson) {
                    try {
                        $resourceArray = $resourcesJson | ConvertFrom-Json
                        $resourceCount = $resourceArray.Count
                    } catch {
                        $resourceCount = 0
                    }
                }
            }
            
            if ($rgExists -eq "true" -and $resourceCount -gt 0) {
                Write-Host "  ℹ️  Resources already deployed: $resourceGroupName ($resourceCount resources)" -ForegroundColor Yellow
                $deploymentStatus.DeploymentStatus = "Already Exists"
            } else {
                if ($rgExists -eq "true") {
                    Write-Host "  ⚠️  Resource group exists but is empty - deploying resources..." -ForegroundColor Yellow
                }
                Write-Host "  📦 Deploying resources (this takes 3-5 minutes)..." -ForegroundColor Gray
                
                # Call Deploy-Workshop-Team.ps1 script
                # Get the repository root (4 levels up from this script's location)
                $repoRoot = Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) -Parent
                $deployScript = Join-Path $repoRoot "scripts\Deploy-Workshop-Team.ps1"
                
                # Run deployment (suppress interactive prompts)
                $env:CONFIRM_DEPLOY = "yes"
                & $deployScript -TeamId $teamId -Location $Location -SkuName $SkuName
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Deployment succeeded" -ForegroundColor Green
                    $deploymentStatus.DeploymentStatus = "Success"
                    $successCount++
                } else {
                    throw "Deployment script failed with exit code $LASTEXITCODE"
                }
            }
        } catch {
            Write-Host "  ✗ Deployment failed: $_" -ForegroundColor Red
            $deploymentStatus.DeploymentStatus = "Failed: $_"
            $failureCount++
        }
    }
    
    # ========================================
    # Step 4: Create Entra ID Group
    # ========================================
    Write-Host "`n[Step 4/6] Creating Entra ID group..." -ForegroundColor Cyan
    
    if ($WhatIf) {
        Write-Host "  [WhatIf] Would create group: $groupName" -ForegroundColor Gray
        Write-Host "  [WhatIf] Would add $($teamMembers.Count) members" -ForegroundColor Gray
        $deploymentStatus.GroupStatus = "WhatIf - Not Created"
    } else {
        try {
            # Check if group already exists
            $existingGroup = az ad group list --filter "displayName eq '$groupName'" --query "[0].id" -o tsv 2>$null
            
            if ($existingGroup) {
                Write-Host "  ℹ️  Group already exists: $groupName (ID: $existingGroup)" -ForegroundColor Yellow
                $groupId = $existingGroup
                $deploymentStatus.GroupStatus = "Already Exists"
            } else {
                # Create new group
                $groupJson = az ad group create `
                    --display-name $groupName `
                    --mail-nickname "fabrikam-team-$teamId" `
                    --description "Workshop Team $teamId - Fabrikam AI Agent Challenge" `
                    --output json
                
                if ($LASTEXITCODE -eq 0) {
                    $group = $groupJson | ConvertFrom-Json
                    $groupId = $group.id
                    Write-Host "  ✓ Created group: $groupName (ID: $groupId)" -ForegroundColor Green
                    $deploymentStatus.GroupStatus = "Created"
                } else {
                    throw "Failed to create group"
                }
            }
            
            # Add members to group
            Write-Host "  Adding members to group..." -ForegroundColor Gray
            $addedCount = 0
            $skippedCount = 0
            
            foreach ($member in $teamMembers) {
                $upn = $member.WorkshopUsername
                
                # Get user object ID
                $userId = az ad user show --id $upn --query id -o tsv 2>$null
                
                if ($userId) {
                    # Check if already a member
                    $isMember = az ad group member check --group $groupId --member-id $userId --query value -o tsv 2>$null
                    
                    if ($isMember -eq "true") {
                        Write-Host "    - $upn (already member)" -ForegroundColor Gray
                        $skippedCount++
                    } else {
                        # Add to group
                        az ad group member add --group $groupId --member-id $userId 2>$null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "    ✓ Added: $upn" -ForegroundColor Green
                            $addedCount++
                        } else {
                            Write-Host "    ✗ Failed to add: $upn" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "    ⚠️  User not found: $upn" -ForegroundColor Yellow
                }
            }
            
            Write-Host "  ✓ Members: $addedCount added, $skippedCount already in group" -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Group creation failed: $_" -ForegroundColor Red
            $deploymentStatus.GroupStatus = "Failed: $_"
        }
    }
    
    # ========================================
    # Step 5: Grant Contributor Access
    # ========================================
    Write-Host "`n[Step 5/6] Granting Contributor access to resource group..." -ForegroundColor Cyan
    
    if ($WhatIf) {
        Write-Host "  [WhatIf] Would grant Contributor role to group on $resourceGroupName" -ForegroundColor Gray
        $deploymentStatus.PermissionStatus = "WhatIf - Not Granted"
    } else {
        try {
            if (-not $groupId) {
                throw "Group ID not available - skipping permission grant"
            }
            
            # Check if resource group exists
            $rgExists = az group exists --name $resourceGroupName
            
            if ($rgExists -ne "true") {
                Write-Host "  ⚠️  Resource group doesn't exist yet: $resourceGroupName" -ForegroundColor Yellow
                $deploymentStatus.PermissionStatus = "Skipped - RG Not Found"
            } else {
                # Check if role assignment already exists
                $existingAssignment = az role assignment list `
                    --assignee $groupId `
                    --resource-group $resourceGroupName `
                    --role "Contributor" `
                    --query "[0].id" -o tsv 2>$null
                
                if ($existingAssignment) {
                    Write-Host "  ℹ️  Role assignment already exists" -ForegroundColor Yellow
                    $deploymentStatus.PermissionStatus = "Already Granted"
                } else {
                    # Get resource group scope
                    $subscriptionId = az account show --query id -o tsv
                    $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
                    
                    # Grant Contributor role
                    az role assignment create `
                        --assignee $groupId `
                        --role "Contributor" `
                        --scope $scope `
                        --output none 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✓ Granted Contributor role to $groupName" -ForegroundColor Green
                        $deploymentStatus.PermissionStatus = "Granted"
                    } else {
                        throw "Failed to grant role"
                    }
                }
            }
        } catch {
            Write-Host "  ✗ Permission grant failed: $_" -ForegroundColor Red
            $deploymentStatus.PermissionStatus = "Failed: $_"
        }
    }
    
    # Add to log
    $deploymentLog += $deploymentStatus
    
    Write-Host "`n  Summary for Team-$teamId" -ForegroundColor Cyan
    Write-Host "    Deployment: $($deploymentStatus.DeploymentStatus)"
    Write-Host "    Group:      $($deploymentStatus.GroupStatus)"
    Write-Host "    Permission: $($deploymentStatus.PermissionStatus)"
}

# ========================================
# Step 6: Final Summary
# ========================================
Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Deployment Complete                                         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "[Step 6/6] Deployment Summary" -ForegroundColor Cyan
Write-Host "  Total Teams: $($deploymentLog.Count)"
Write-Host "  Successful:  $successCount" -ForegroundColor Green
Write-Host "  Failed:      $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })

# Export log to CSV
$logFile = "deployment-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$logPath = Join-Path $PSScriptRoot $logFile
$deploymentLog | Export-Csv -Path $logPath -NoTypeInformation

Write-Host "`n📋 Detailed log saved to: $logPath" -ForegroundColor Green

# Show failures if any
if ($failureCount -gt 0) {
    Write-Host "`n⚠️  Failed Deployments:" -ForegroundColor Yellow
    $deploymentLog | Where-Object { $_.DeploymentStatus -like "Failed*" } | 
        Format-Table TeamId, TeamName, DeploymentStatus, GroupStatus, PermissionStatus -AutoSize
}

Write-Host "`n✅ Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review deployment log: $logPath"
Write-Host "  2. Test MCP endpoints for each team"
Write-Host "  3. Deploy code to instances via GitHub Actions"
Write-Host "  4. Share URLs with participants"

if ($WhatIf) {
    Write-Host "`n  ℹ️  WhatIf mode - no resources were created" -ForegroundColor Gray
    Write-Host "  Run without -WhatIf to perform actual deployment" -ForegroundColor Gray
}
