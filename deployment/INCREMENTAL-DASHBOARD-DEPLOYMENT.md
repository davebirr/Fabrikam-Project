# Incremental Dashboard Deployment Guide

This guide explains how to deploy **only** the FabrikamDashboard to an existing Azure environment without affecting other services.

## 🎯 Purpose

Add the new Blazor Dashboard to existing deployments (main branch / workshop environments) without redeploying API, MCP, or Simulator services.

## 📋 Prerequisites

- Azure CLI installed and authenticated (`az login`)
- .NET 9.0 SDK installed
- PowerShell 7+ (for automated script)
- Existing resource group with FabrikamApi and FabrikamSimulator deployed

## 🚀 Deployment Methods

### Method 1: Automated PowerShell Script (Recommended)

The easiest way to deploy the dashboard:

```powershell
# Deploy to main branch environment (rg-agentathon-proctor)
.\deployment\Deploy-Dashboard-Incremental.ps1

# Deploy to specific team environment
.\deployment\Deploy-Dashboard-Incremental.ps1 `
  -ResourceGroup "rg-fabrikam-team-01" `
  -DashboardAppName "fabrikam-dash-team-01" `
  -ApiAppName "fabrikam-api-team-01" `
  -SimAppName "fabrikam-sim-team-01"

# Deploy infrastructure only (skip code deployment)
.\deployment\Deploy-Dashboard-Incremental.ps1 -SkipDeploy

# Skip build (use existing publish folder)
.\deployment\Deploy-Dashboard-Incremental.ps1 -SkipBuild
```

**What the script does:**
1. ✅ Validates Azure CLI authentication
2. ✅ Verifies resource group and existing apps exist
3. ✅ Deploys ARM template (creates App Service Plan + Dashboard App)
4. ✅ Builds FabrikamDashboard (.NET 9.0)
5. ✅ Creates deployment package (zip)
6. ✅ Deploys code to Azure App Service
7. ✅ Tests dashboard health endpoint
8. ✅ Displays summary with URLs

### Method 2: Manual ARM Template Deployment

Deploy just the infrastructure, then deploy code separately:

```bash
# 1. Deploy ARM template
az deployment group create \
  --name dashboard-deployment-$(date +%Y%m%d-%H%M%S) \
  --resource-group rg-agentathon-proctor \
  --template-file deployment/deploy-dashboard-incremental.json \
  --parameters \
    dashboardAppName=fabrikam-dash-development-tzjeje \
    apiAppName=fabrikam-api-development-tzjeje \
    simAppName=fabrikam-sim-development-tzjeje

# 2. Build and publish
dotnet publish FabrikamDashboard/FabrikamDashboard.csproj \
  --configuration Release \
  --output ./publish/dashboard

# 3. Create zip package
cd ./publish/dashboard
zip -r ../dashboard.zip .
cd ../..

# 4. Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-agentathon-proctor \
  --name fabrikam-dash-development-tzjeje \
  --src ./publish/dashboard.zip \
  --timeout 600
```

### Method 3: GitHub Actions (After Initial Deployment)

After deploying once manually, set up CI/CD for future updates:

1. **Configure deployment credentials** in the Azure Portal:
   - Go to: Dashboard App → Deployment Center → Settings
   - Copy the Publish Profile or configure Federated Credentials
   
2. **Add GitHub Secrets**:
   ```
   AZUREAPPSERVICE_CLIENTID_DASHBOARD_TZJEJE
   AZUREAPPSERVICE_TENANTID_DASHBOARD_TZJEJE
   AZUREAPPSERVICE_SUBSCRIPTIONID_DASHBOARD_TZJEJE
   ```

3. **Enable workflow**: `.github/workflows/main_fabrikam-dash-development-tzjeje.yml`

4. **Trigger**: Push to `main` branch or run manually

## 🏗️ Infrastructure Created

The incremental deployment creates:

### App Service Plan
- **Name**: `plan-dash-development-tzjeje` (or custom)
- **SKU**: B1 (Basic tier)
- **OS**: Linux
- **Runtime**: .NET 9.0

### Dashboard Web App
- **Name**: `fabrikam-dash-development-tzjeje` (or custom)
- **Runtime**: .NET 9.0 on Linux
- **Identity**: System-assigned managed identity
- **HTTPS Only**: Yes
- **TLS Version**: 1.2+

### App Settings (Auto-configured)
```json
{
  "ASPNETCORE_ENVIRONMENT": "Production",
  "FabrikamApi__BaseUrl": "https://fabrikam-api-development-tzjeje.azurewebsites.net",
  "FabrikamSimulator__BaseUrl": "https://fabrikam-sim-development-tzjeje.azurewebsites.net",
  "WEBSITE_RUN_FROM_PACKAGE": "1"
}
```

### Logging Configuration
- Application logs: Information level
- HTTP logs: 35 MB, 7 days retention
- Detailed error messages: Enabled
- Failed request tracing: Enabled

## 🔍 Verification

After deployment, verify the dashboard is working:

```powershell
# Check app status
az webapp show \
  --name fabrikam-dash-development-tzjeje \
  --resource-group rg-agentathon-proctor \
  --query "{Name:name, State:state, URL:defaultHostName}" \
  --output table

# Test the endpoint
curl https://fabrikam-dash-development-tzjeje.azurewebsites.net

# View logs
az webapp log tail \
  --name fabrikam-dash-development-tzjeje \
  --resource-group rg-agentathon-proctor
```

**Manual testing:**
1. Visit: `https://fabrikam-dash-development-tzjeje.azurewebsites.net`
2. Verify metrics cards populate with data
3. Check charts render (Orders by Status, Orders by Region)
4. Test simulator controls (start/stop workers)
5. Confirm real-time updates (every 5 seconds)

## 🛠️ Troubleshooting

### Dashboard shows "Connection lost"
- **Cause**: API or Simulator not running
- **Fix**: Verify API and Simulator apps are running in Azure Portal

### Metrics not updating
- **Cause**: Incorrect API/Simulator URLs
- **Fix**: Check app settings in Azure Portal, update if needed:
  ```bash
  az webapp config appsettings set \
    --name fabrikam-dash-development-tzjeje \
    --resource-group rg-agentathon-proctor \
    --settings \
      FabrikamApi__BaseUrl="https://fabrikam-api-development-tzjeje.azurewebsites.net" \
      FabrikamSimulator__BaseUrl="https://fabrikam-sim-development-tzjeje.azurewebsites.net"
  ```

### Deployment fails with "App Service Plan quota exceeded"
- **Cause**: Subscription limit reached
- **Fix**: Use existing App Service Plan or delete unused apps

### Build fails locally
- **Cause**: Missing .NET 9.0 SDK
- **Fix**: Install .NET 9.0 SDK from https://dot.net

### 502 Bad Gateway after deployment
- **Cause**: App still starting up
- **Fix**: Wait 30-60 seconds, then refresh. Check logs for errors.

## 📊 Resource Costs

**Estimated Monthly Costs (B1 SKU):**
- App Service Plan (B1): ~$13/month
- Dashboard App: Included in plan
- **Total**: ~$13/month additional

**To reduce costs:**
- Use same App Service Plan as existing apps (modify ARM template)
- Use Free tier for testing (F1 - limitations apply)
- Stop app when not in use (`az webapp stop`)

## 🔄 Updating the Dashboard

After initial deployment, update code:

```powershell
# Build and deploy
dotnet publish FabrikamDashboard/FabrikamDashboard.csproj -c Release -o ./publish/dashboard
Compress-Archive -Path ./publish/dashboard/* -DestinationPath ./publish/dashboard.zip -Force
az webapp deployment source config-zip \
  --resource-group rg-agentathon-proctor \
  --name fabrikam-dash-development-tzjeje \
  --src ./publish/dashboard.zip
```

Or commit to `main` branch to trigger GitHub Actions (if configured).

## 🎯 Deployment Targets

### Main Branch Environment
- **Resource Group**: `rg-agentathon-proctor`
- **Dashboard App**: `fabrikam-dash-development-tzjeje`
- **API**: `fabrikam-api-development-tzjeje`
- **Simulator**: `fabrikam-sim-development-tzjeje`

### Workshop Environments (team-01 through team-20)
Use the full-stack deployment workflow for workshop instances:
```bash
# Use the deploy-full-stack.yml workflow
# Select team environment
# Check "Deploy FabrikamDashboard"
```

## ⚠️ Safety Notes

- ✅ **Safe**: Incremental deployment only adds new resources
- ✅ **Safe**: Does NOT modify existing API, MCP, or Simulator apps
- ✅ **Safe**: Uses separate App Service Plan (no resource contention)
- ⚠️ **Warning**: Creates new billable resources (App Service Plan)
- ⚠️ **Warning**: If using same plan name, will fail if already exists

## 📚 Related Documentation

- [Dashboard Implementation Guide](../docs/development/DASHBOARD-IMPLEMENTATION-GUIDE.md)
- [Full Stack Deployment](../docs/deployment/DEPLOYMENT-GUIDE.md)
- [FabrikamDashboard README](../FabrikamDashboard/README.md)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)

## 🆘 Support

If you encounter issues:
1. Check Azure Portal logs
2. Verify app settings are correct
3. Ensure API and Simulator are running
4. Check GitHub Issues for similar problems
5. Review Application Insights for telemetry

---

**Last Updated**: November 5, 2025  
**Workshop Date**: November 6, 2025
