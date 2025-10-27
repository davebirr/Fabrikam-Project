# 🚀 Workshop Infrastructure Deployment Scripts
**Automated provisioning for cs-agent-a-thon workshop**

---

## 📋 **Script Overview**

This folder contains PowerShell scripts for automated deployment and management of the workshop infrastructure across 2 BAMI tenants and 20 Fabrikam instances.

---

## 🏗️ **Core Deployment Scripts**

### **1. provision-tenants.ps1**
**Purpose**: Set up BAMI tenants with M365 licensing and Azure subscriptions

```powershell
<#
.SYNOPSIS
    Provisions BAMI tenants for cs-agent-a-thon workshop
.DESCRIPTION
    Sets up 2 BAMI tenants with M365 E5 licensing, Azure subscriptions,
    and basic security groups for workshop participants
.PARAMETER TenantCount
    Number of tenants to provision (default: 2)
.PARAMETER ParticipantsPerTenant
    Number of participants per tenant (default: 50)
.EXAMPLE
    .\provision-tenants.ps1 -TenantCount 2 -ParticipantsPerTenant 50
#>

param(
    [int]$TenantCount = 2,
    [int]$ParticipantsPerTenant = 50,
    [string]$WorkshopName = "cs-agent-a-thon",
    [switch]$WhatIf
)

# Tenant configuration
$TenantConfigs = @(
    @{
        Name = "$WorkshopName-tenant-a"
        Domain = "workshopa.onmicrosoft.com"
        Participants = 1..50
        Teams = "A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08", "A09", "A10"
    },
    @{
        Name = "$WorkshopName-tenant-b"
        Domain = "workshopb.onmicrosoft.com"
        Participants = 51..100
        Teams = "B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B09", "B10"
    }
)

ForEach ($Config in $TenantConfigs) {
    Write-Host "Provisioning tenant: $($Config.Name)" -ForegroundColor Yellow
    
    if (-not $WhatIf) {
        # Request BAMI tenant (manual process - output instructions)
        Write-Host "📝 Manual Action Required:" -ForegroundColor Red
        Write-Host "  1. Request BAMI tenant: $($Config.Name)" -ForegroundColor White
        Write-Host "  2. Configure M365 E5 licensing for $ParticipantsPerTenant users" -ForegroundColor White
        Write-Host "  3. Link Azure subscription to tenant" -ForegroundColor White
        Write-Host "  4. Update this script with actual tenant details" -ForegroundColor White
        
        Read-Host "Press Enter when tenant $($Config.Name) is ready"
    }
    
    # Create security groups for teams
    ForEach ($Team in $Config.Teams) {
        $GroupName = "Workshop-Team-$Team"
        
        if ($WhatIf) {
            Write-Host "Would create security group: $GroupName" -ForegroundColor Cyan
        } else {
            try {
                $Group = New-AzureADGroup `
                    -DisplayName $GroupName `
                    -Description "Workshop team $Team participants" `
                    -MailEnabled $false `
                    -SecurityEnabled $true `
                    -MailNickName "workshop-team-$($Team.ToLower())"
                
                Write-Host "✅ Created security group: $GroupName" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to create group $GroupName : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "✅ Tenant provisioning complete!" -ForegroundColor Green
```

---

### **2. deploy-instances.ps1**
**Purpose**: Deploy 20 Fabrikam instances across both Azure subscriptions

```powershell
<#
.SYNOPSIS
    Deploys Fabrikam instances for workshop
.DESCRIPTION
    Deploys 20 Fabrikam instances (10 per tenant) with all required Azure resources
.PARAMETER SubscriptionA
    Azure subscription ID for tenant A
.PARAMETER SubscriptionB
    Azure subscription ID for tenant B
.PARAMETER Location
    Azure region for deployment (default: East US 2)
.EXAMPLE
    .\deploy-instances.ps1 -SubscriptionA "xxx-xxx" -SubscriptionB "yyy-yyy"
#>

param(
    [Parameter(Mandatory)]
    [string]$SubscriptionA,
    [Parameter(Mandatory)]
    [string]$SubscriptionB,
    [string]$Location = "East US 2",
    [string]$ResourceGroupPrefix = "rg-fabrikam",
    [switch]$WhatIf
)

# Instance configurations
$InstanceConfigs = @()

# Tenant A instances (A01-A10)
For ($i = 1; $i -le 10; $i++) {
    $InstanceId = "A" + $i.ToString("D2")
    $InstanceConfigs += @{
        InstanceId = $InstanceId
        Subscription = $SubscriptionA
        ResourceGroup = "$ResourceGroupPrefix-$($InstanceId.ToLower())-workshop"
        ApiAppName = "fabrikam-api-$($InstanceId.ToLower())"
        McpAppName = "fabrikam-mcp-$($InstanceId.ToLower())"
        SqlServerName = "sql-fabrikam-$($InstanceId.ToLower())"
        KeyVaultName = "kv-fabrikam-$($InstanceId.ToLower())"
    }
}

# Tenant B instances (B01-B10)
For ($i = 1; $i -le 10; $i++) {
    $InstanceId = "B" + $i.ToString("D2")
    $InstanceConfigs += @{
        InstanceId = $InstanceId
        Subscription = $SubscriptionB
        ResourceGroup = "$ResourceGroupPrefix-$($InstanceId.ToLower())-workshop"
        ApiAppName = "fabrikam-api-$($InstanceId.ToLower())"
        McpAppName = "fabrikam-mcp-$($InstanceId.ToLower())"
        SqlServerName = "sql-fabrikam-$($InstanceId.ToLower())"
        KeyVaultName = "kv-fabrikam-$($InstanceId.ToLower())"
    }
}

# Deploy each instance
ForEach ($Config in $InstanceConfigs) {
    Write-Host "Deploying Fabrikam instance: $($Config.InstanceId)" -ForegroundColor Yellow
    
    if (-not $WhatIf) {
        # Set subscription context
        Set-AzContext -SubscriptionId $Config.Subscription
        
        # Create resource group
        $ResourceGroup = New-AzResourceGroup `
            -Name $Config.ResourceGroup `
            -Location $Location `
            -Force
        
        Write-Host "✅ Created resource group: $($Config.ResourceGroup)" -ForegroundColor Green
        
        # Deploy via Bicep template
        $DeploymentParams = @{
            instanceId = $Config.InstanceId.ToLower()
            location = $Location
            apiAppName = $Config.ApiAppName
            mcpAppName = $Config.McpAppName
            sqlServerName = $Config.SqlServerName
            keyVaultName = $Config.KeyVaultName
        }
        
        try {
            $Deployment = New-AzResourceGroupDeployment `
                -ResourceGroupName $Config.ResourceGroup `
                -TemplateFile "..\deployment\bicep\fabrikam-instance.bicep" `
                -TemplateParameterObject $DeploymentParams `
                -Name "fabrikam-$($Config.InstanceId.ToLower())-deployment"
            
            Write-Host "✅ Deployed instance $($Config.InstanceId): $($Deployment.ProvisioningState)" -ForegroundColor Green
            
            # Store instance details for team assignment
            $InstanceDetails = @{
                InstanceId = $Config.InstanceId
                ResourceGroup = $Config.ResourceGroup
                ApiUrl = "https://$($Config.ApiAppName).azurewebsites.net"
                McpUrl = "https://$($Config.McpAppName).eastus2.azurecontainerapps.io"
                SqlServer = $Config.SqlServerName
                Subscription = $Config.Subscription
            }
            
            # Export for team assignment
            $InstanceDetails | Export-Csv -Path "deployed-instances.csv" -Append -NoTypeInformation
        }
        catch {
            Write-Host "❌ Failed to deploy instance $($Config.InstanceId): $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Would deploy instance: $($Config.InstanceId) to $($Config.ResourceGroup)" -ForegroundColor Cyan
    }
}

Write-Host "✅ Instance deployment complete!" -ForegroundColor Green
Write-Host "📄 Instance details exported to: deployed-instances.csv" -ForegroundColor Cyan
```

---

### **3. manage-users.ps1**
**Purpose**: Manage workshop participant accounts (B2B or native users)

```powershell
<#
.SYNOPSIS
    Manages workshop participant user accounts
.DESCRIPTION
    Creates B2B guest invitations or native users for workshop participants
.PARAMETER UserType
    Type of user creation: "B2B" or "Native"
.PARAMETER ParticipantList
    CSV file with participant email addresses
.PARAMETER TenantDomain
    Target tenant domain
.EXAMPLE
    .\manage-users.ps1 -UserType "B2B" -ParticipantList "participants.csv" -TenantDomain "workshopa.onmicrosoft.com"
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet("B2B", "Native")]
    [string]$UserType,
    [Parameter(Mandatory)]
    [string]$ParticipantList,
    [Parameter(Mandatory)]
    [string]$TenantDomain,
    [string]$DefaultPassword = "Workshop2025!@#",
    [switch]$WhatIf
)

# Import participant list
$Participants = Import-Csv -Path $ParticipantList

# Team assignment logic (5 participants per team)
$TeamsPerTenant = if ($TenantDomain -like "*workshopa*") { 
    @("A01","A02","A03","A04","A05","A06","A07","A08","A09","A10") 
} else { 
    @("B01","B02","B03","B04","B05","B06","B07","B08","B09","B10") 
}

$ParticipantIndex = 0
$Results = @()

ForEach ($Participant in $Participants) {
    $TeamIndex = [Math]::Floor($ParticipantIndex / 5)
    $TeamId = $TeamsPerTenant[$TeamIndex]
    
    if ($UserType -eq "B2B") {
        # B2B Guest Invitation
        if ($WhatIf) {
            Write-Host "Would invite B2B guest: $($Participant.Email) to team $TeamId" -ForegroundColor Cyan
        } else {
            try {
                $Invitation = New-AzureADMSInvitation `
                    -InvitedUserEmailAddress $Participant.Email `
                    -InviteRedirectUrl "https://fabrikam-api-$($TeamId.ToLower()).azurewebsites.net" `
                    -InvitedUserDisplayName "$($Participant.Name) - Team $TeamId" `
                    -SendInvitationMessage $true
                
                # Add to team security group
                Start-Sleep -Seconds 2
                $TeamGroup = Get-AzureADGroup -Filter "DisplayName eq 'Workshop-Team-$TeamId'"
                if ($TeamGroup) {
                    Add-AzureADGroupMember -ObjectId $TeamGroup.ObjectId -RefObjectId $Invitation.InvitedUser.Id
                }
                
                $Results += [PSCustomObject]@{
                    Email = $Participant.Email
                    Name = $Participant.Name
                    TeamId = $TeamId
                    UserType = "B2B Guest"
                    Status = "Invited"
                    LoginUrl = "https://portal.azure.com"
                    FabrikamInstance = "https://fabrikam-api-$($TeamId.ToLower()).azurewebsites.net"
                }
                
                Write-Host "✅ Invited B2B guest: $($Participant.Email) (Team $TeamId)" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to invite $($Participant.Email): $($_.Exception.Message)" -ForegroundColor Red
                
                $Results += [PSCustomObject]@{
                    Email = $Participant.Email
                    Name = $Participant.Name
                    TeamId = $TeamId
                    UserType = "B2B Guest"
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
            }
        }
    }
    elseif ($UserType -eq "Native") {
        # Native User Creation
        $UserPrincipalName = "$($Participant.Email.Split('@')[0])@$TenantDomain"
        
        if ($WhatIf) {
            Write-Host "Would create native user: $UserPrincipalName for team $TeamId" -ForegroundColor Cyan
        } else {
            try {
                $SecurePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force
                
                $NewUser = New-AzureADUser `
                    -UserPrincipalName $UserPrincipalName `
                    -Password $SecurePassword `
                    -DisplayName "$($Participant.Name) - Team $TeamId" `
                    -MailNickName $Participant.Email.Split('@')[0] `
                    -UsageLocation "US" `
                    -AccountEnabled $true `
                    -ForceChangePasswordNextLogin $false
                
                # Assign M365 E5 license
                Start-Sleep -Seconds 3
                Set-AzureADUserLicense `
                    -ObjectId $NewUser.ObjectId `
                    -AssignedLicenses @{
                        AddLicenses = @("SPE_E5")
                        RemoveLicenses = @()
                    }
                
                # Add to team security group
                $TeamGroup = Get-AzureADGroup -Filter "DisplayName eq 'Workshop-Team-$TeamId'"
                if ($TeamGroup) {
                    Add-AzureADGroupMember -ObjectId $TeamGroup.ObjectId -RefObjectId $NewUser.ObjectId
                }
                
                $Results += [PSCustomObject]@{
                    Email = $Participant.Email
                    Name = $Participant.Name
                    TeamId = $TeamId
                    UserType = "Native User"
                    Username = $UserPrincipalName
                    Password = $DefaultPassword
                    Status = "Created"
                    LoginUrl = "https://portal.azure.com"
                    FabrikamInstance = "https://fabrikam-api-$($TeamId.ToLower()).azurewebsites.net"
                }
                
                Write-Host "✅ Created native user: $UserPrincipalName (Team $TeamId)" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to create user for $($Participant.Email): $($_.Exception.Message)" -ForegroundColor Red
                
                $Results += [PSCustomObject]@{
                    Email = $Participant.Email
                    Name = $Participant.Name
                    TeamId = $TeamId
                    UserType = "Native User"
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
            }
        }
    }
    
    $ParticipantIndex++
}

# Export results
$OutputFile = "workshop-users-$UserType-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$Results | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "✅ User management complete!" -ForegroundColor Green
Write-Host "📄 Results exported to: $OutputFile" -ForegroundColor Cyan

if ($UserType -eq "Native") {
    Write-Host "🔑 IMPORTANT: Distribute credentials securely to participants" -ForegroundColor Yellow
}
```

---

### **4. cleanup-workshop.ps1**
**Purpose**: Clean up all workshop resources post-event

```powershell
<#
.SYNOPSIS
    Cleans up workshop resources after event
.DESCRIPTION
    Removes user accounts, deletes Azure resources, and generates cleanup report
.PARAMETER SubscriptionA
    Azure subscription ID for tenant A
.PARAMETER SubscriptionB
    Azure subscription ID for tenant B
.PARAMETER UserType
    Type of users to clean up: "B2B" or "Native" or "Both"
.EXAMPLE
    .\cleanup-workshop.ps1 -SubscriptionA "xxx" -SubscriptionB "yyy" -UserType "Both"
#>

param(
    [Parameter(Mandatory)]
    [string]$SubscriptionA,
    [Parameter(Mandatory)]
    [string]$SubscriptionB,
    [ValidateSet("B2B", "Native", "Both")]
    [string]$UserType = "Both",
    [switch]$WhatIf,
    [switch]$Force
)

Write-Host "🧹 Starting workshop cleanup..." -ForegroundColor Yellow

# Cleanup user accounts
if ($UserType -in @("B2B", "Both")) {
    Write-Host "Removing B2B guest users..." -ForegroundColor Yellow
    
    $GuestUsers = Get-AzureADUser -Filter "UserType eq 'Guest'" | Where-Object {
        $_.DisplayName -like "*Workshop*" -or $_.DisplayName -like "*Team*"
    }
    
    ForEach ($Guest in $GuestUsers) {
        if ($WhatIf) {
            Write-Host "Would remove B2B guest: $($Guest.DisplayName)" -ForegroundColor Cyan
        } else {
            try {
                Remove-AzureADUser -ObjectId $Guest.ObjectId
                Write-Host "✅ Removed B2B guest: $($Guest.DisplayName)" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to remove guest $($Guest.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

if ($UserType -in @("Native", "Both")) {
    Write-Host "Removing native workshop users..." -ForegroundColor Yellow
    
    $WorkshopUsers = Get-AzureADUser -All $true | Where-Object {
        $_.UserPrincipalName -like "*workshop*" -or $_.DisplayName -like "*Workshop*"
    }
    
    ForEach ($User in $WorkshopUsers) {
        if ($WhatIf) {
            Write-Host "Would remove native user: $($User.DisplayName)" -ForegroundColor Cyan
        } else {
            try {
                Remove-AzureADUser -ObjectId $User.ObjectId
                Write-Host "✅ Removed native user: $($User.DisplayName)" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to remove user $($User.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Cleanup Azure resources
$Subscriptions = @($SubscriptionA, $SubscriptionB)
$TotalCost = 0

ForEach ($Subscription in $Subscriptions) {
    Write-Host "Cleaning up resources in subscription: $Subscription" -ForegroundColor Yellow
    
    Set-AzContext -SubscriptionId $Subscription
    
    # Get workshop resource groups
    $WorkshopResourceGroups = Get-AzResourceGroup | Where-Object {
        $_.ResourceGroupName -like "*fabrikam*workshop*"
    }
    
    ForEach ($ResourceGroup in $WorkshopResourceGroups) {
        if ($WhatIf) {
            Write-Host "Would remove resource group: $($ResourceGroup.ResourceGroupName)" -ForegroundColor Cyan
        } else {
            try {
                # Get cost estimate before deletion
                $ResourceCosts = Get-AzConsumptionUsageDetail -ResourceGroup $ResourceGroup.ResourceGroupName -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -ErrorAction SilentlyContinue
                $GroupCost = ($ResourceCosts | Measure-Object -Property PretaxCost -Sum).Sum
                $TotalCost += $GroupCost
                
                # Remove resource group
                Remove-AzResourceGroup -Name $ResourceGroup.ResourceGroupName -Force:$Force
                Write-Host "✅ Removed resource group: $($ResourceGroup.ResourceGroupName) (Cost: $($GroupCost:C))" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to remove resource group $($ResourceGroup.ResourceGroupName): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Cleanup security groups
Write-Host "Removing workshop security groups..." -ForegroundColor Yellow

$WorkshopGroups = Get-AzureADGroup -All $true | Where-Object {
    $_.DisplayName -like "*Workshop-Team*"
}

ForEach ($Group in $WorkshopGroups) {
    if ($WhatIf) {
        Write-Host "Would remove security group: $($Group.DisplayName)" -ForegroundColor Cyan
    } else {
        try {
            Remove-AzureADGroup -ObjectId $Group.ObjectId
            Write-Host "✅ Removed security group: $($Group.DisplayName)" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Failed to remove group $($Group.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Generate cleanup report
$CleanupReport = @{
    CleanupDate = Get-Date
    SubscriptionsProcessed = $Subscriptions
    UserTypesProcessed = $UserType
    EstimatedCostSavings = $TotalCost
    ResourceGroupsRemoved = $WorkshopResourceGroups.Count
    UsersRemoved = ($GuestUsers.Count + $WorkshopUsers.Count)
    SecurityGroupsRemoved = $WorkshopGroups.Count
}

$CleanupReport | ConvertTo-Json | Out-File -FilePath "workshop-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmm').json"

Write-Host "✅ Workshop cleanup complete!" -ForegroundColor Green
Write-Host "💰 Estimated cost savings: $($TotalCost:C)" -ForegroundColor Cyan
Write-Host "📄 Cleanup report saved" -ForegroundColor Cyan
```

---

## 📋 **Usage Instructions**

### **Pre-Workshop Setup**
```powershell
# 1. Provision BAMI tenants (manual + automated setup)
.\provision-tenants.ps1 -WhatIf  # Preview first
.\provision-tenants.ps1          # Execute

# 2. Deploy Fabrikam instances
.\deploy-instances.ps1 -SubscriptionA "your-sub-a" -SubscriptionB "your-sub-b" -WhatIf
.\deploy-instances.ps1 -SubscriptionA "your-sub-a" -SubscriptionB "your-sub-b"

# 3. Create participant accounts
.\manage-users.ps1 -UserType "B2B" -ParticipantList "participants.csv" -TenantDomain "workshopa.onmicrosoft.com"
```

### **Post-Workshop Cleanup**
```powershell
# Clean up everything
.\cleanup-workshop.ps1 -SubscriptionA "your-sub-a" -SubscriptionB "your-sub-b" -UserType "Both" -Force
```

---

**These scripts provide complete automation for the workshop infrastructure lifecycle from provisioning through cleanup! 🚀**