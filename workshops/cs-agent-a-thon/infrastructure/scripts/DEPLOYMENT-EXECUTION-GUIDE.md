# Workshop Deployment - Ready to Execute

## ✅ What's Ready

1. **Deployment Script**: `Deploy-AllTeamInstances.ps1`
   - Deploys MCP instances for all teams
   - Creates Entra ID groups
   - Adds team members to groups
   - Grants Contributor access
   - Generates deployment logs

2. **Individual Team Script**: `Deploy-Workshop-Team.ps1`
   - Supports batch mode (no interactive prompts)
   - Called by main deployment script

3. **Documentation**: `README-DEPLOYMENT.md`
   - Complete deployment guide
   - Troubleshooting steps
   - Cleanup procedures

## 🚀 Execution Commands

### **Test First (Recommended)**

```powershell
# Navigate to scripts directory
cd workshops/cs-agent-a-thon/infrastructure/scripts

# Test single team deployment
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf

# Test all teams deployment (preview only)
.\Deploy-AllTeamInstances.ps1 -WhatIf
```

### **Deploy Single Team (For Testing)**

```powershell
# Deploy Team-05 as a test
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05

# Deploy Proctor instance (Team-00)
.\Deploy-AllTeamInstances.ps1 -TeamNumber 00
```

### **Deploy All Teams**

```powershell
# Full deployment - all 25 teams (00-24)
.\Deploy-AllTeamInstances.ps1
```

**Expected Duration**: 2-3 hours (each team takes 3-5 minutes)

## 📊 What Gets Created

### **Per Team (×25 teams)**

- **Resource Group**: `rg-fabrikam-team-XX`
- **App Services**: API, MCP, Simulator (B2 SKU)
- **Key Vault**: For JWT secrets
- **Entra ID Group**: `Fabrikam-Team-XX`
- **Role Assignment**: Contributor on resource group

### **Total Resources**

- 25 Resource Groups
- 75 App Services (3 per team)
- 25 App Service Plans
- 25 Key Vaults
- 25 Entra ID Groups
- 25 Role Assignments

**Cost**: ~$650/month for workshop duration

## 📋 Team Assignments (From CSV)

Based on `participant-credentials-TRACKING.csv`:

- **Team-00**: Proctor instance (no participants assigned)
- **Team-01 through Team-24**: 4-5 participants each
- **Total**: 122 participants across 24 teams

## ✅ Pre-Execution Checklist

Before running deployment:

- [x] **Azure CLI installed** and up-to-date
- [x] **Logged in** to fabrikam1.csplevelup.com tenant
- [x] **Verified permissions** (Contributor/Owner on subscription)
- [x] **Entra ID permissions** (User Administrator for group creation)
- [x] **CSV file** verified and up-to-date
- [x] **WhatIf mode** tested successfully
- [x] **Scripts ready** and executable

## 🎯 Recommended Deployment Strategy

### **Phase 1: Test Deployment (15-30 minutes)**

```powershell
# 1. Test with WhatIf
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf

# 2. Deploy single test team
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05

# 3. Verify test deployment
az resource list -g rg-fabrikam-team-05 -o table
az ad group show --group "Fabrikam-Team-05"
az role assignment list -g rg-fabrikam-team-05 -o table

# 4. Test MCP endpoint
$mcpUrl = az webapp show -g rg-fabrikam-team-05 -n $(az webapp list -g rg-fabrikam-team-05 --query "[?contains(name, 'mcp')].name" -o tsv) --query defaultHostName -o tsv
Invoke-RestMethod "https://$mcpUrl/status"
```

### **Phase 2: Proctor Deployment (5-10 minutes)**

```powershell
# Deploy proctor instance (Team-00)
.\Deploy-AllTeamInstances.ps1 -TeamNumber 00

# Verify
az resource list -g rg-fabrikam-team-00 -o table
```

### **Phase 3: Full Deployment (2-3 hours)**

```powershell
# Deploy all remaining teams
.\Deploy-AllTeamInstances.ps1

# Monitor progress
# - Script shows real-time progress for each team
# - Deployment log saved automatically
# - Can cancel and resume if needed
```

### **Phase 4: Verification (30 minutes)**

```powershell
# Check all resource groups created
az group list --query "[?starts_with(name, 'rg-fabrikam-team-')].{Name:name, Location:location, Status:properties.provisioningState}" -o table

# Count: should be 25 (Team-00 through Team-24)
az group list --query "[?starts_with(name, 'rg-fabrikam-team-')] | length(@)"

# Check all Entra groups
az ad group list --filter "startswith(displayName, 'Fabrikam-Team-')" --query "[].{Name:displayName, Members:length(members)}" -o table

# Count: should be 25
az ad group list --filter "startswith(displayName, 'Fabrikam-Team-')" --query "length(@)"

# Verify permissions on random samples
az role assignment list -g rg-fabrikam-team-12 --query "[?roleDefinitionName=='Contributor'].{Principal:principalName, Role:roleDefinitionName}" -o table
```

## 📝 Deployment Log

Each deployment creates: `deployment-log-YYYYMMDD-HHMMSS.csv`

**Columns**:
- TeamId, TeamName, MemberCount
- ResourceGroup, EntraGroup
- DeploymentStatus, GroupStatus, PermissionStatus
- Timestamp

**Review after deployment** to identify any failures.

## 🆘 If Something Fails

### **Deployment Failed for a Team**

```powershell
# Check deployment log CSV for error
Import-Csv deployment-log-*.csv | Where-Object { $_.DeploymentStatus -like "Failed*" }

# Re-run just that team
.\Deploy-AllTeamInstances.ps1 -TeamNumber XX

# Or check Azure Portal deployment history
az deployment group list -g rg-fabrikam-team-XX --query "[0].{Name:name, Status:properties.provisioningState}" -o json
```

### **Group Creation Failed**

```powershell
# Verify Entra permissions
az ad signed-in-user show --query "id" -o tsv | ForEach-Object {
    az role assignment list --assignee $_ --query "[?roleDefinitionName=='User Administrator' || roleDefinitionName=='Global Administrator']"
}

# Manually create group if needed
az ad group create --display-name "Fabrikam-Team-XX" --mail-nickname "fabrikam-team-XX"
```

### **Permission Grant Failed**

```powershell
# Get group ID
$groupId = az ad group list --filter "displayName eq 'Fabrikam-Team-XX'" --query "[0].id" -o tsv

# Manually grant Contributor
az role assignment create --assignee $groupId --role "Contributor" --resource-group rg-fabrikam-team-XX
```

## 🎯 Post-Deployment Tasks

After all teams deployed:

1. **Deploy Code** to all instances:
   ```powershell
   # Option 1: GitHub Actions (automated)
   # Trigger workflow for workshop-stable branch
   
   # Option 2: Manual publish to each team
   # Use Deploy-FabrikamApi.ps1 for each resource group
   ```

2. **Configure Copilot Studio** connectors for each team

3. **Test MCP endpoints** for all teams

4. **Update participant documentation** with their team's URLs

5. **Send credentials** to participants (if not already sent)

## 📊 Success Criteria

✅ Deployment successful if:
- 25/25 resource groups created
- 25/25 Entra ID groups created
- 25/25 role assignments granted
- All MCP `/status` endpoints return 200 OK
- Deployment log shows no failures

---

**Ready to deploy?** Start with Phase 1 (test deployment) and proceed through the phases!
