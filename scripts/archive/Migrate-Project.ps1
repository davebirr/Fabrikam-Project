# 🔄 Migrate Project to Different Azure Subscription
# Helper script to migrate Fabrikam Project to a subscription with full Entra permissions

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetSubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$TargetResourceGroup,
    
    [string]$TargetInstanceName = "fabrikam-main",
    [string]$TargetLocation = "eastus2",
    [switch]$DryRun,
    [switch]$CheckPermissions
)

Write-Host "🔄 Project Migration Assistant" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

if ($CheckPermissions) {
    Write-Host "`n🔍 Checking Target Subscription Permissions..." -ForegroundColor Yellow
    
    # Switch to target subscription
    try {
        az account set --subscription $TargetSubscriptionId
        $targetContext = az account show --output json | ConvertFrom-Json
        
        Write-Host "✅ Target Subscription: $($targetContext.name)" -ForegroundColor Green
        Write-Host "✅ Target Tenant: $($targetContext.tenantId)" -ForegroundColor Green
        
        # Check Entra permissions in target tenant
        Write-Host "`n🔑 Assessing Entra Permissions in Target Tenant..." -ForegroundColor Yellow
        
        $userRoles = az rest --method GET --url "https://graph.microsoft.com/v1.0/me/memberOf" --output json | ConvertFrom-Json
        $hasGlobalAdmin = $false
        $hasApplicationAdmin = $false
        
        foreach ($role in $userRoles.value) {
            if ($role.'@odata.type' -eq '#microsoft.graph.directoryRole') {
                Write-Host "   - Directory Role: $($role.displayName)" -ForegroundColor White
                
                if ($role.displayName -eq "Global Administrator") {
                    $hasGlobalAdmin = $true
                    Write-Host "   ✅ Global Administrator detected!" -ForegroundColor Green
                }
                if ($role.displayName -eq "Application Administrator") {
                    $hasApplicationAdmin = $true
                }
            }
        }
        
        if ($hasGlobalAdmin) {
            Write-Host "`n🎯 RECOMMENDATION: Migrate to this subscription" -ForegroundColor Green
            Write-Host "   Full Entra External ID capabilities available" -ForegroundColor White
            Write-Host "   Can implement Strategy 1 (preferred approach)" -ForegroundColor White
        }
        elseif ($hasApplicationAdmin) {
            Write-Host "`n⚠️  PARTIAL: Some Entra capabilities available" -ForegroundColor Yellow
            Write-Host "   May be able to create External ID tenant" -ForegroundColor White
            Write-Host "   Recommend testing External ID creation first" -ForegroundColor White
        }
        else {
            Write-Host "`n❌ LIMITED: Similar permissions to current subscription" -ForegroundColor Red
            Write-Host "   Migration would not provide additional capabilities" -ForegroundColor White
            Write-Host "   Recommend staying with current ASP.NET Identity approach" -ForegroundColor White
        }
        
    }
    catch {
        Write-Host "❌ Cannot access target subscription: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    return
}

Write-Host "`n📋 Migration Overview:" -ForegroundColor Yellow
Write-Host "Source: Current MCAPS subscription (ASP.NET Identity ready)" -ForegroundColor White
Write-Host "Target: $TargetSubscriptionId" -ForegroundColor White
Write-Host "New Resource Group: $TargetResourceGroup" -ForegroundColor White
Write-Host "New Instance: $TargetInstanceName" -ForegroundColor White

if ($DryRun) {
    Write-Host "`n🧪 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Step 1: Update workspace configuration
Write-Host "`n⚙️ Step 1: Update Workspace Configuration..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "🧪 Would update .vscode/settings.json with new subscription details" -ForegroundColor Cyan
    Write-Host "🧪 Would update copilot-instructions.md with new environment" -ForegroundColor Cyan
}
else {
    # Update VS Code settings
    $settingsPath = ".vscode/settings.json"
    if (Test-Path $settingsPath) {
        Write-Host "   Updating VS Code settings..." -ForegroundColor White
        
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $settings.'azure.subscriptionId' = $TargetSubscriptionId
        $settings.'azure.resourceGroup' = $TargetResourceGroup
        $settings.'azure.instanceName' = $TargetInstanceName
        
        # Update API URLs for new instance
        $settings.'rest-client.environmentVariables'.azure.apiUrl = "https://$TargetInstanceName-api.levelupcsp.com"
        $settings.'rest-client.environmentVariables'.azure.mcpUrl = "https://$TargetInstanceName-mcp.levelupcsp.com"
        
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-Host "   ✅ VS Code settings updated" -ForegroundColor Green
    }
}

# Step 2: Create target resource group
Write-Host "`n🏗️ Step 2: Create Target Resource Group..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "🧪 Would create resource group: $TargetResourceGroup" -ForegroundColor Cyan
}
else {
    try {
        # Switch to target subscription
        az account set --subscription $TargetSubscriptionId
        
        # Create resource group
        az group create --name $TargetResourceGroup --location $TargetLocation --output none
        Write-Host "   ✅ Resource group created: $TargetResourceGroup" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Choose authentication strategy
Write-Host "`n🔐 Step 3: Authentication Strategy Selection..." -ForegroundColor Yellow

Write-Host "   Available strategies in target subscription:" -ForegroundColor White
Write-Host "   1. Entra External ID (if Global Admin permissions)" -ForegroundColor Green
Write-Host "   2. ASP.NET Core Identity (universal fallback)" -ForegroundColor Yellow
Write-Host "   3. Dual implementation (both strategies)" -ForegroundColor Cyan

Write-Host "`n   Recommended next steps:" -ForegroundColor White
Write-Host "   1. Run permission check: -CheckPermissions" -ForegroundColor White
Write-Host "   2. If Global Admin: Implement Entra External ID" -ForegroundColor White
Write-Host "   3. If limited permissions: Use ASP.NET Identity" -ForegroundColor White

# Step 4: Generate migration summary
$migrationSummary = @{
    Timestamp           = Get-Date
    SourceSubscription  = "1ae622b1-c33c-457f-a2bb-351fed78922f"
    TargetSubscription  = $TargetSubscriptionId
    TargetResourceGroup = $TargetResourceGroup
    TargetInstance      = $TargetInstanceName
    RecommendedStrategy = "Check permissions first"
    NextSteps           = @(
        "Run migration script with -CheckPermissions",
        "Assess Entra capabilities in target tenant",
        "Choose appropriate authentication strategy",
        "Run Setup-Authentication-Strategy.ps1 for chosen approach",
        "Update GitHub repository variables if needed"
    )
}

$summaryPath = "docs/deployment/migration-summary-$TargetInstanceName.json"
$migrationSummary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "`n📄 Migration summary saved to: $summaryPath" -ForegroundColor Cyan

Write-Host "`n🎯 Next Actions:" -ForegroundColor Yellow
Write-Host "1. Check permissions: .\scripts\Migrate-Project.ps1 -TargetSubscriptionId '$TargetSubscriptionId' -TargetResourceGroup '$TargetResourceGroup' -CheckPermissions" -ForegroundColor White
Write-Host "2. Based on results, choose authentication strategy" -ForegroundColor White
Write-Host "3. Run appropriate setup script for chosen strategy" -ForegroundColor White

Write-Host "`n✅ Migration planning complete!" -ForegroundColor Green
