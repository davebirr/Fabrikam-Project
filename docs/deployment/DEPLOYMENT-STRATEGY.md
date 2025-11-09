# 🚀 Fabrikam Deployment Strategy

**Last Updated**: November 9, 2025  
**Single Source of Truth**: ARM Template (`deployment/AzureDeploymentTemplate.modular.json`)

---

## 🎯 Primary Deployment Method: ARM Template

**The ARM template is the single source of truth** for all infrastructure deployments. All deployment scripts should use this template to ensure consistency.

### ✅ What the ARM Template Deploys

The modular ARM template (`deployment/AzureDeploymentTemplate.modular.json`) deploys:

1. **App Service Plan** - Shared hosting for all services
2. **Key Vault** - Secure storage for JWT secrets
3. **API App** (`fabrikam-api-*`) - Main business API
4. **MCP App** (`fabrikam-mcp-*`) - Model Context Protocol server
5. **SIM App** (`fabrikam-sim-*`) - Event simulator
6. **Dashboard App** (`fabrikam-dash-*`) - Real-time business dashboard

### ✅ Dashboard Configuration (Fixed November 9, 2025)

The ARM template now correctly configures **all 4 required dashboard app settings**:

```json
"appSettings": [
  {
    "name": "FabrikamApi__BaseUrl",
    "value": "[parameters('apiUrl')]"
  },
  {
    "name": "FabrikamSimulator__BaseUrl",
    "value": "[parameters('simUrl')]"
  },
  {
    "name": "Authentication__Mode",
    "value": "[parameters('authenticationMode')]"  // ✅ ADDED
  },
  {
    "name": "Dashboard__ServiceGuid",
    "value": "00000000-0000-0000-0000-000000000001"  // ✅ FIXED (removed "dashboard-" prefix)
  }
]
```

**Critical**: The `Authentication__Mode` setting was missing, causing dashboards to fail silently. This has been fixed in the ARM template.

---

## 📋 Recommended Deployment Scripts

### For Workshop Deployment (Teams 00-24)

**Primary Script**: `workshops/cs-agent-a-thon/infrastructure/scripts/Deploy-AllTeamInstances.ps1`

**What it does**:
- Deploys all 25 team instances (00-24) using ARM template
- Creates Entra ID groups for each team
- Configures permissions (Contributor access to resource groups)
- Tracks deployment status

**Usage**:
```powershell
# Deploy all teams
.\Deploy-AllTeamInstances.ps1 -TeamsCSV "participant-credentials-TRACKING.csv"

# Deploy single team (preview)
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf

# Deploy single team (actual)
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05
```

**This script uses**: `scripts/Deploy-Workshop-Team.ps1` (which calls ARM template)

### For Production/Demo Deployment

**Primary Script**: `scripts/Deploy-Azure-Resources.ps1`

**Usage**:
```powershell
# Interactive deployment
.\Deploy-Azure-Resources.ps1

# Specify parameters
.\Deploy-Azure-Resources.ps1 -BaseName "fabrikam" -Location "eastus2" -Environment "production"
```

### For CI/CD Deployment

**GitHub Actions Workflows**:

1. **Team-24 (Main Branch)**: `.github/workflows/deploy-team-24-main.yml`
   - Deploys from `main` branch
   - Uses ARM template
   - ✅ Automatically configures dashboard app settings after deployment

2. **Teams 00-23 (Workshop Branch)**: `.github/workflows/deploy-workshop-instances.yml`
   - Deploys from `workshop-stable` branch
   - Uses ARM template
   - ⚠️ May need dashboard configuration step added (similar to Team-24)

---

## ⚠️ Scripts to Archive

These scripts are outdated or redundant:

### Should Move to Archive:

1. **`workshops/.../Deploy-Dashboard.ps1`** - Standalone dashboard deployment
   - **Why**: Dashboard should be deployed with full stack via ARM template
   - **Keep for**: Emergency dashboard-only redeployment
   - **Status**: Updated with fix but not primary method

2. **`deployment/Deploy-Dashboard-Incremental.ps1`** - Incremental dashboard deployment
   - **Why**: Redundant with ARM template
   - **Action**: Archive

3. **`deployment/Deploy-FabrikamApi.ps1`** - Standalone API deployment
   - **Why**: API should be deployed with full stack
   - **Action**: Archive

4. **`scripts/Deploy-Workshop-Team.ps1`** - Individual team deployment
   - **Status**: Currently used by Deploy-AllTeamInstances.ps1
   - **Note**: Uses ARM template correctly, keep for now
   - **Future**: Could be merged into Deploy-AllTeamInstances.ps1

---

## 🔧 Deployment Best Practices

### 1. Always Use ARM Template

✅ **DO**: Deploy infrastructure using ARM template  
❌ **DON'T**: Manually create resources via portal or individual `az` commands

### 2. Verify Dashboard Configuration

After any deployment, verify dashboard has all 4 settings:
```powershell
az webapp config appsettings list \
  -n <dashboard-app-name> \
  -g <resource-group> \
  --query "[?contains(name, 'FabrikamApi') || contains(name, 'FabrikamSimulator') || contains(name, 'Authentication__Mode') || contains(name, 'Dashboard__ServiceGuid')]"
```

Expected output:
```json
[
  {"Name": "FabrikamApi__BaseUrl", "Value": "https://..."},
  {"Name": "FabrikamSimulator__BaseUrl", "Value": "https://..."},
  {"Name": "Authentication__Mode", "Value": "Disabled"},
  {"Name": "Dashboard__ServiceGuid", "Value": "00000000-0000-0000-0000-000000000001"}
]
```

### 3. Test Deployment

After deploying, test all components:

```powershell
# Test API
curl https://<api-url>/health

# Test MCP
curl https://<mcp-url>/health

# Test Simulator
curl https://<sim-url>/health

# Test Dashboard (should load data, not show perpetual loading)
# Open https://<dashboard-url>/ in browser
```

### 4. Use WhatIf for Preview

Always preview changes before deployment:
```powershell
.\Deploy-AllTeamInstances.ps1 -TeamNumber 05 -WhatIf
```

---

## 🐛 Troubleshooting

### Dashboard Shows Perpetual Loading

**Symptom**: Dashboard displays "Loading data... (0 seconds)" indefinitely  
**Cause**: Missing `Authentication__Mode` app setting  
**Fix**: 
```powershell
az webapp config appsettings set \
  -n <dashboard-app-name> \
  -g <resource-group> \
  --settings "Authentication__Mode=Disabled"

az webapp restart -n <dashboard-app-name> -g <resource-group>
```

### Deployment Fails with Key Vault Error

**Cause**: Key Vault name must be globally unique  
**Fix**: ARM template generates unique suffix automatically, but if conflict occurs, try different region or redeploy

### Missing App Settings After Deployment

**Cause**: ARM template may not have been updated  
**Fix**: Pull latest changes from `main` branch, ensure using `deployment/AzureDeploymentTemplate.modular.json`

---

## 📊 Deployment Status Check

To verify all teams deployed correctly:

```powershell
# List all Fabrikam resource groups
az group list --query "[?contains(name, 'fabrikam')].name" -o table

# Check specific team
az webapp list -g rg-fabrikam-team-05 --query "[].{Name:name, State:state, URL:defaultHostName}" -o table
```

---

## 🎯 Migration Plan

### Short-term (Completed)
- ✅ Fix ARM template dashboard configuration
- ✅ Update Deploy-AllTeamInstances.ps1 to use ARM template
- ✅ Update Team-24 CI/CD workflow

### Medium-term (Next Steps)
- [ ] Update Teams 00-23 CI/CD workflow with dashboard config
- [ ] Test full workshop deployment end-to-end
- [ ] Document ARM template parameters
- [ ] Create deployment troubleshooting guide

### Long-term (Future)
- [ ] Archive redundant deployment scripts
- [ ] Consolidate Deploy-Workshop-Team.ps1 into Deploy-AllTeamInstances.ps1
- [ ] Add automated deployment validation tests
- [ ] Create deployment monitoring dashboard

---

## 📚 Related Documentation

- [ARM Template](../../deployment/AzureDeploymentTemplate.modular.json) - Single source of truth
- [Workshop Infrastructure](../../workshops/cs-agent-a-thon/infrastructure/README.md) - Workshop-specific deployment
- [GitHub Actions](.github/workflows/) - CI/CD pipelines
- [Development Workflow](../development/DEVELOPMENT-WORKFLOW.md) - Day-to-day development process

