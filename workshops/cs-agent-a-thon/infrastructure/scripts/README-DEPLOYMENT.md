# Workshop Team Instance Deployment Guide

Complete guide for deploying MCP instances and configuring permissions for workshop teams.

---

## 📋 Prerequisites

### **Required Tools**
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version)
- PowerShell 7+ (cross-platform)
- Contributor or Owner role on Azure subscription

### **Required Access**
- **Fabrikam Tenant**: `fabrikam1.csplevelup.com`
- **Tenant ID**: `fd268415-22a5-4064-9b5e-d039761c5971`
- **Subscription**: Access to target subscription for resource deployment
- **Entra ID Permissions**: User Administrator or Global Administrator (for group creation)

---

## 🚀 Quick Start

### **Option 1: Deploy All Teams**

Deploy all 24 team instances + proctor instance in one operation:

```powershell
# Navigate to scripts directory
cd workshops/cs-agent-a-thon/infrastructure/scripts

# Login to Fabrikam tenant
az login --tenant fabrikam1.csplevelup.com

# Run deployment (WhatIf mode first to preview)
.\Deploy-AllTeamInstances.ps1 -WhatIf

# Actual deployment
.\Deploy-AllTeamInstances.ps1
```

**What this does:**
1. ✅ Deploys MCP instances for Teams 00-24 (25 total)
2. ✅ Creates Entra ID groups for each team
3. ✅ Adds team members to groups
4. ✅ Grants Contributor access to resource groups
5. ✅ Generates deployment log CSV

**Duration**: ~2-3 hours for all 25 teams (deployment runs sequentially)

---

### **Option 2: Deploy Single Team**

Deploy just one team for testing or individual setup:

```powershell
# Deploy Team-05 only
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05

# Deploy proctor instance (Team-00)
.\Deploy-AllTeamInstances.ps1 -TeamNumber 00
```

---

## 🛠️ Detailed Deployment Steps

### **Step 1: Verify Prerequisites**

```powershell
# Check Azure CLI version (should be 2.50+)
az --version

# Login to correct tenant
az login --tenant fabrikam1.csplevelup.com

# Verify correct subscription is selected
az account show

# Check permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --scope /subscriptions/$(az account show --query id -o tsv)
```

You should see **Contributor** or **Owner** role.

---

### **Step 2: Prepare Participant Data**

Ensure `participant-credentials-TRACKING.csv` is up-to-date:

```powershell
# Check CSV location
ls ../participant-credentials-TRACKING.csv

# Verify team assignments
Import-Csv ../participant-credentials-TRACKING.csv | 
    Group-Object Team | 
    Sort-Object Name | 
    Select-Object Name, Count
```

Expected output: ~24 teams with 4-5 members each

---

### **Step 3: Test Deployment (WhatIf Mode)**

Always test with `-WhatIf` first:

```powershell
# Preview what will be created
.\Deploy-AllTeamInstances.ps1 -WhatIf

# Preview single team
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf
```

Review output to ensure:
- ✅ Correct team numbers (01-24, plus 00 for proctor)
- ✅ Proper resource group names (`rg-fabrikam-team-XX`)
- ✅ Correct Entra ID group names (`Fabrikam-Team-XX`)

---

### **Step 4: Execute Deployment**

#### **All Teams (Full Deployment)**

```powershell
# Start deployment
.\Deploy-AllTeamInstances.ps1

# Monitor progress
# - Each team takes 3-5 minutes
# - Total: ~2-3 hours for 25 teams
# - Script shows progress for each team
```

#### **Single Team (Testing or Individual)**

```powershell
# Deploy specific team
.\Deploy-AllTeamInstances.ps1 -TeamNumber 12

# Useful for:
# - Testing deployment process
# - Adding new teams after initial deployment
# - Redeploying failed instances
```

---

### **Step 5: Verify Deployment**

After deployment completes, verify resources:

```powershell
# List all resource groups
az group list --query "[?starts_with(name, 'rg-fabrikam-team-')].{Name:name, Location:location}" -o table

# Check specific team
az resource list -g rg-fabrikam-team-05 --query "[].{Name:name, Type:type}" -o table

# Test MCP endpoint
$mcpUrl = az webapp show -g rg-fabrikam-team-05 -n fabrikam-mcp-team-05 --query defaultHostName -o tsv
Invoke-RestMethod "https://$mcpUrl/status" | ConvertTo-Json
```

---

### **Step 6: Verify Entra ID Groups**

```powershell
# List all team groups
az ad group list --filter "startswith(displayName, 'Fabrikam-Team-')" --query "[].{Name:displayName, Id:id}" -o table

# Check specific group members
az ad group member list --group "Fabrikam-Team-05" --query "[].{Name:displayName, UPN:userPrincipalName}" -o table

# Verify permissions
az role assignment list --resource-group rg-fabrikam-team-05 --query "[].{Principal:principalName, Role:roleDefinitionName}" -o table
```

Expected: Each group should have **Contributor** role on its resource group.

---

## 📊 Deployment Architecture

### **Resources Created Per Team**

Each team gets:
- ✅ **Resource Group**: `rg-fabrikam-team-XX`
- ✅ **App Service Plan**: `asp-fabrikam-workshop-XXXXXX` (B2 - 2 cores, 3.5GB RAM)
- ✅ **API App Service**: `fabrikam-api-workshop-XXXXXX`
- ✅ **MCP App Service**: `fabrikam-mcp-workshop-XXXXXX`
- ✅ **Simulator App Service**: `fabrikam-sim-workshop-XXXXXX`
- ✅ **Key Vault**: `kv-workshop-XXXXXX`
- ✅ **Entra ID Group**: `Fabrikam-Team-XX`
- ✅ **Role Assignment**: Contributor access to resource group

### **Naming Conventions**

- **Resource Groups**: `rg-fabrikam-team-XX` (XX = 00-24)
- **Entra Groups**: `Fabrikam-Team-XX`
- **App Services**: Randomly generated 6-character suffix for uniqueness

### **Cost Estimate**

Per team instance:
- App Service Plan (B2): ~$26/month
- Key Vault: ~$0.03/month
- **Total per team**: ~$26/month
- **25 teams**: ~$650/month for workshop duration

---

## 🔧 Customization Options

### **Change Location**

```powershell
# Deploy to East US instead of West US 2
.\Deploy-AllTeamInstances.ps1 -Location eastus
```

### **Change SKU**

```powershell
# Use smaller SKU for cost savings (not recommended for workshop)
.\Deploy-AllTeamInstances.ps1 -SkuName B1

# Use production SKU (S1)
.\Deploy-AllTeamInstances.ps1 -SkuName S1
```

### **Custom CSV Path**

```powershell
# Use different participant file
.\Deploy-AllTeamInstances.ps1 -TeamsCSV "path/to/custom-participants.csv"
```

---

## 🆘 Troubleshooting

### **Common Issues**

#### **Problem: "Not logged in to Azure"**

```powershell
# Solution: Login to correct tenant
az login --tenant fabrikam1.csplevelup.com

# Verify
az account show
```

#### **Problem: "Wrong tenant detected"**

```powershell
# Solution: Explicitly specify tenant
az login --tenant fd268415-22a5-4064-9b5e-d039761c5971
```

#### **Problem: "CSV file not found"**

```powershell
# Check script is in correct directory
pwd  # Should be: .../infrastructure/scripts

# Verify CSV exists
ls ../participant-credentials-TRACKING.csv
```

#### **Problem: "Deployment failed for Team-XX"**

1. Check deployment log CSV for error details
2. Check Azure Portal deployment history:
   ```powershell
   az deployment group list -g rg-fabrikam-team-XX --query "[0].{Name:name, Status:properties.provisioningState, Error:properties.error}" -o json
   ```
3. Common causes:
   - Resource name conflict (Key Vault name already taken)
   - Insufficient permissions
   - Quota limits reached

#### **Problem: "Failed to create Entra ID group"**

```powershell
# Check permissions
az ad signed-in-user show --query "id" -o tsv
az role assignment list --assignee <user-id> --query "[?roleDefinitionName=='User Administrator' || roleDefinitionName=='Global Administrator']"
```

Required roles:
- **User Administrator** (for group creation)
- **Groups Administrator** (alternative)

#### **Problem: "User not found: XXX@fabrikam1.csplevelup.com"**

1. Verify user exists:
   ```powershell
   az ad user show --id "XXX@fabrikam1.csplevelup.com"
   ```
2. If missing, run user provisioning script first:
   ```powershell
   .\Provision-ParticipantUsers.ps1
   ```

---

## 📝 Deployment Log

Each deployment creates a log file: `deployment-log-YYYYMMDD-HHMMSS.csv`

**Columns:**
- `TeamId`: Team number (00-24)
- `TeamName`: Team-XX
- `MemberCount`: Number of team members
- `ResourceGroup`: Resource group name
- `EntraGroup`: Entra ID group name
- `DeploymentStatus`: Success/Failed/Already Exists
- `GroupStatus`: Created/Failed/Already Exists
- `PermissionStatus`: Granted/Failed/Skipped
- `Timestamp`: Deployment time

**Example:**
```csv
TeamId,TeamName,MemberCount,ResourceGroup,EntraGroup,DeploymentStatus,GroupStatus,PermissionStatus,Timestamp
05,Team-05,5,rg-fabrikam-team-05,Fabrikam-Team-05,Success,Created,Granted,2025-11-05 22:15:30
12,Team-12,5,rg-fabrikam-team-12,Fabrikam-Team-12,Success,Already Exists,Granted,2025-11-05 22:22:45
```

---

## 🧹 Cleanup (After Workshop)

### **Delete All Team Resources**

```powershell
# Delete all team resource groups
for ($i=0; $i -le 24; $i++) {
    $teamId = "{0:D2}" -f $i
    $rgName = "rg-fabrikam-team-$teamId"
    
    Write-Host "Deleting $rgName..." -ForegroundColor Yellow
    az group delete --name $rgName --yes --no-wait
}

# Monitor deletion progress
az group list --query "[?starts_with(name, 'rg-fabrikam-team-')]" -o table
```

### **Delete Entra ID Groups**

```powershell
# Delete all team groups
for ($i=0; $i -le 24; $i++) {
    $teamId = "{0:D2}" -f $i
    $groupName = "Fabrikam-Team-$teamId"
    
    $groupId = az ad group list --filter "displayName eq '$groupName'" --query "[0].id" -o tsv
    
    if ($groupId) {
        Write-Host "Deleting $groupName..." -ForegroundColor Yellow
        az ad group delete --group $groupId
    }
}
```

---

## 📚 Related Documentation

- **User Provisioning**: `Provision-ParticipantUsers.ps1`
- **Individual Team Deployment**: `Deploy-Workshop-Team.ps1` (in `/scripts`)
- **ARM Template**: `deployment/AzureDeploymentTemplate.modular.json`
- **Workshop Guide**: `workshops/cs-agent-a-thon/README.md`

---

## ✅ Pre-Workshop Checklist

Before workshop day:
- [ ] All 25 team instances deployed successfully
- [ ] All Entra ID groups created with correct members
- [ ] Contributor permissions granted to all groups
- [ ] MCP endpoints tested and responding
- [ ] Code deployed to all instances (via GitHub Actions or manual publish)
- [ ] Connection settings configured in Copilot Studio
- [ ] Participant credentials sent
- [ ] Backup/DR instance ready (proctor instance can serve as backup)

---

**Questions?** Contact the workshop infrastructure team or check the deployment log CSV for detailed status.
