# 🚀 Workshop Deployment Guide - CI/CD Setup

**Goal**: Deploy Fabrikam instances for CS Agent-A-Thon workshop using GitHub Actions CI/CD

---

## 📋 **Overview**

This guide covers:
1. ✅ **Deploy Proctor Instance** - For 19 proctors to test before Friday
2. ✅ **Set up CI/CD** - GitHub Actions for automated deployment
3. ✅ **Deploy 20 Team Instances** - After testing is complete

---

## 🎯 **Phase 1: Deploy Proctor Instance (Do This First)**

### **Step 1: Create Service Principal for Deployment**

```powershell
# Login to Azure with correct tenant
az login --tenant fd268415-22a5-4064-9b5e-d039761c5971

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify you're in the correct context
az account show --query "{subscription:name, tenant:tenantId}" -o table

# Create service principal with Contributor role on subscription
$sp = az ad sp create-for-rbac `
    --name "sp-fabrikam-workshop-deploy" `
    --role "Contributor" `
    --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" `
    --output json

# Save this output - you'll need it for GitHub secrets
$sp | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

**Output will look like**:
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "YOUR_SECRET_HERE",
  "subscriptionId": "YOUR_SUBSCRIPTION_ID",
  "tenantId": "fd268415-22a5-4064-9b5e-d039761c5971",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  ...
}
```

**⚠️ IMPORTANT**: Save this entire JSON output - you cannot retrieve the `clientSecret` again!

---

### **Step 2: Deploy Proctor Infrastructure**

```powershell
# Navigate to workshop scripts directory
cd workshops\cs-agent-a-thon\infrastructure\scripts

# Deploy proctor instance
.\Deploy-WorkshopInfrastructure.ps1 `
    -InstanceName "proctor" `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "YOUR_SUBSCRIPTION_ID" `
    -Location "eastus"
```

**This creates**:
- **Resource Group**: `rg-agentathon-proctor`
- **API App Service**: `fabrikam-api-proctor` (https://fabrikam-api-proctor.azurewebsites.net)
- **MCP App Service**: `fabrikam-mcp-proctor` (https://fabrikam-mcp-proctor.azurewebsites.net)
- **App Service Plan**: Shared Standard S1
- **Application Insights**: Monitoring & telemetry
- **Key Vault**: Secrets management

**Deployment time**: ~5-7 minutes

---

## 🔧 **Phase 2: Configure GitHub Actions CI/CD**

### **Step 1: Add GitHub Repository Secret**

1. **Navigate to your GitHub repository**:
   - Go to: `https://github.com/davebirr/Fabrikam-Project`

2. **Open Settings**:
   - Click **Settings** tab
   - In left sidebar: **Secrets and variables** → **Actions**

3. **Create New Repository Secret**:
   - Click **New repository secret**
   - **Name**: `AZURE_CREDENTIALS`
   - **Value**: Paste the entire JSON from Step 1 (service principal output)
   - Click **Add secret**

**Your `AZURE_CREDENTIALS` secret should contain**:
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "YOUR_SECRET_HERE",
  "subscriptionId": "YOUR_SUBSCRIPTION_ID",
  "tenantId": "fd268415-22a5-4064-9b5e-d039761c5971",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

---

### **Step 2: Test CI/CD with Proctor Deployment**

1. **Navigate to GitHub Actions**:
   - Go to: `https://github.com/davebirr/Fabrikam-Project/actions`

2. **Find "Deploy Full Stack to Azure" workflow**:
   - Click on **Deploy Full Stack to Azure** in the workflows list

3. **Run Workflow**:
   - Click **Run workflow** dropdown
   - **Environment**: Select `proctor`
   - **Deploy FabrikamApi**: ✅ Check
   - **Deploy FabrikamMcp**: ✅ Check
   - Click **Run workflow**

4. **Monitor Deployment**:
   - Watch the workflow execution
   - Should complete in ~5-10 minutes
   - Check for green checkmarks on all jobs

---

### **Step 3: Verify Proctor Deployment**

```powershell
# Test API health
$apiUrl = "https://fabrikam-api-proctor.azurewebsites.net"
Invoke-RestMethod -Uri "$apiUrl/api/info" | ConvertTo-Json

# Test MCP health  
$mcpUrl = "https://fabrikam-mcp-proctor.azurewebsites.net"
Invoke-RestMethod -Uri "$mcpUrl/mcp/v1/info" | ConvertTo-Json

# Test API endpoints
Invoke-RestMethod -Uri "$apiUrl/api/orders" | ConvertTo-Json -Depth 3
Invoke-RestMethod -Uri "$apiUrl/api/customers" | ConvertTo-Json -Depth 3
Invoke-RestMethod -Uri "$apiUrl/api/products" | ConvertTo-Json -Depth 3
```

**Expected Results**:
- ✅ All endpoints return 200 OK
- ✅ API `/api/info` shows version and configuration
- ✅ MCP `/mcp/v1/info` shows available tools
- ✅ Sample data is loaded (orders, customers, products)

---

## 👥 **Phase 3: Share with Proctors for Testing**

### **Proctor Access Information**

Send this to all 19 proctors:

```markdown
🎉 **Proctor Testing Environment Ready!**

The Fabrikam workshop environment is deployed and ready for testing.

**API URL**: https://fabrikam-api-proctor.azurewebsites.net
**MCP URL**: https://fabrikam-mcp-proctor.azurewebsites.net

**Quick Tests**:

1. **Test API Health**:
   ```
   https://fabrikam-api-proctor.azurewebsites.net/api/info
   ```

2. **View Sample Orders**:
   ```
   https://fabrikam-api-proctor.azurewebsites.net/api/orders
   ```

3. **View Sample Customers**:
   ```
   https://fabrikam-api-proctor.azurewebsites.net/api/customers
   ```

4. **Test MCP Server** (use in GitHub Copilot):
   - Add MCP server URL in Copilot settings
   - Try asking: "Show me recent orders from Fabrikam"

**Please test and report any issues by Friday!**

Access Azure Portal to view resources:
- Resource Group: `rg-agentathon-proctor`
- Login: https://portal.azure.com (switch to workshop tenant)
```

---

## 🚀 **Phase 4: Deploy Team Instances (After Friday Testing)**

Once proctors confirm everything works, deploy the 20 team instances:

### **Option A: Deploy All Teams at Once (Recommended)**

```powershell
# Deploy all 20 team instances in sequence
cd workshops\cs-agent-a-thon\infrastructure\scripts

.\Deploy-WorkshopInfrastructure.ps1 `
    -DeployTeams `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "YOUR_SUBSCRIPTION_ID" `
    -Location "eastus"
```

**Deployment time**: ~100-140 minutes (5-7 minutes per team × 20)

**Creates**:
- `rg-agentathon-team-01` → `fabrikam-api-team-01`, `fabrikam-mcp-team-01`
- `rg-agentathon-team-02` → `fabrikam-api-team-02`, `fabrikam-mcp-team-02`
- ... through ...
- `rg-agentathon-team-20` → `fabrikam-api-team-20`, `fabrikam-mcp-team-20`

---

### **Option B: Deploy Specific Teams Individually**

```powershell
# Deploy single team
.\Deploy-WorkshopInfrastructure.ps1 `
    -InstanceName "team-05" `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "YOUR_SUBSCRIPTION_ID"
```

---

### **Option C: Use GitHub Actions for Team Deployments**

1. **Navigate to Actions** → **Deploy Full Stack to Azure**
2. **Run workflow** for each team:
   - Environment: `team-01`
   - Deploy FabrikamApi: ✅
   - Deploy FabrikamMcp: ✅
3. **Repeat** for `team-02` through `team-20`

**Benefit**: Can run multiple deployments in parallel using GitHub Actions

---

## 📊 **Deployment Summary**

After all deployments complete, you'll have:

### **Proctor Instance** (for 19 proctors):
- `rg-agentathon-proctor`
- `fabrikam-api-proctor.azurewebsites.net`
- `fabrikam-mcp-proctor.azurewebsites.net`

### **Team Instances** (20 teams, 5-6 participants each):
- `rg-agentathon-team-01` → URLs ending in `-team-01`
- `rg-agentathon-team-02` → URLs ending in `-team-02`
- ... through ...
- `rg-agentathon-team-20` → URLs ending in `-team-20`

### **Total Resources**:
- **21 Resource Groups** (1 proctor + 20 teams)
- **42 App Services** (API + MCP for each instance)
- **21 App Service Plans** (Standard S1)
- **21 Application Insights**
- **21 Key Vaults**

---

## 🔄 **Updating Deployments**

### **Deploy Code Changes via GitHub Actions**

1. **Commit and push code changes** to `main` branch
2. **Navigate to Actions** → **Deploy Full Stack to Azure**
3. **Run workflow**:
   - Choose instance to update (e.g., `proctor` or `team-05`)
   - Select which services to deploy (API, MCP, or both)
   - Click **Run workflow**

### **Deploy Code Changes via PowerShell**

```powershell
# Build and publish locally
cd c:\Users\davidb\1Repositories\Fabrikam-Project

dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ./api-publish
dotnet publish FabrikamMcp/src/FabrikamMcp.csproj -c Release -o ./mcp-publish

# Deploy to Azure
az webapp deployment source config-zip `
    --resource-group "rg-agentathon-proctor" `
    --name "fabrikam-api-proctor" `
    --src "./api-publish.zip"

az webapp deployment source config-zip `
    --resource-group "rg-agentathon-proctor" `
    --name "fabrikam-mcp-proctor" `
    --src "./mcp-publish.zip"
```

---

## 🧹 **Post-Workshop Cleanup**

After workshop concludes (November 7+):

```powershell
# Delete all workshop resource groups
az group list --query "[?contains(name, 'rg-agentathon')].name" -o tsv | 
    ForEach-Object { 
        Write-Host "Deleting: $_" -ForegroundColor Yellow
        az group delete --name $_ --yes --no-wait 
    }

# Verify deletion
az group list --query "[?contains(name, 'rg-agentathon')]" -o table
```

---

## ✅ **Quick Checklist**

### **Before Friday (Proctor Testing)**
- [ ] Create Azure service principal
- [ ] Add `AZURE_CREDENTIALS` to GitHub secrets
- [ ] Deploy proctor infrastructure (PowerShell script)
- [ ] Test proctor deployment via GitHub Actions
- [ ] Verify API and MCP endpoints work
- [ ] Share proctor URLs with 19 proctors
- [ ] Collect proctor feedback

### **After Friday (Team Deployment)**
- [ ] Incorporate proctor feedback
- [ ] Deploy any code changes to proctor instance
- [ ] Deploy all 20 team instances (PowerShell or GitHub Actions)
- [ ] Verify team deployments
- [ ] Update workshop documentation with URLs
- [ ] Prepare participant quick-start guide with team-specific URLs

### **Workshop Day (November 6)**
- [ ] Monitor all instances via Application Insights
- [ ] Have deployment scripts ready for emergency fixes
- [ ] GitHub Actions available for quick redeployments
- [ ] Azure Portal access for troubleshooting

---

## 📖 **Additional Resources**

- **Deployment Script**: `workshops/cs-agent-a-thon/infrastructure/scripts/Deploy-WorkshopInfrastructure.ps1`
- **GitHub Workflow**: `.github/workflows/deploy-full-stack.yml`
- **DR Procedures**: `workshops/cs-agent-a-thon/infrastructure/PROCTOR-DR-RUNBOOK.md`
- **Tenant Config**: `workshops/cs-agent-a-thon/infrastructure/TENANT-CONFIG.md`

---

**Next Step**: Run Step 1 to create your Azure service principal! 🚀
