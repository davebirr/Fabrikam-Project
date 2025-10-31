# 🔐 GitHub Actions CI/CD Setup

## Overview

This guide sets up GitHub Actions to deploy your Fabrikam application code to Azure App Services created by the `Deploy-Workshop-Team.ps1` script.

## 📋 Prerequisites

- ✅ Azure resources deployed via ARM template (e.g., `rg-fabrikam-team-00`)
- ✅ Azure CLI logged in to the correct tenant
- ✅ GitHub repository access

## 🔑 Step 1: Create Azure Service Principal

Create a Service Principal with Contributor access to your subscription:

```powershell
# Set your subscription (use the correct subscription ID)
$subscriptionId = "1ae622b1-c33c-457f-a2bb-351fed78922f"
$subscriptionName = "cs-agent-a-thon"

# Create Service Principal with Contributor role
$sp = az ad sp create-for-rbac `
  --name "github-actions-fabrikam-workshop" `
  --role contributor `
  --scopes /subscriptions/$subscriptionId `
  --sdk-auth
```

**Important**: Save the entire JSON output! You'll need it for GitHub.

Expected output:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "1ae622b1-c33c-457f-a2bb-351fed78922f",
  "tenantId": "fd268415-22a5-4064-9b5e-d039761c5971",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## 🔐 Step 2: Add GitHub Repository Secret

### Option A: Using GitHub CLI (Recommended)

```powershell
# Copy the JSON output from Step 1 to clipboard
# Then run:
gh secret set AZURE_CREDENTIALS --repo davebirr/Fabrikam-Project

# Paste the JSON when prompted and press Enter, then Ctrl+Z, then Enter
```

### Option B: Using GitHub Web UI

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the entire JSON output from Step 1
6. Click **Add secret**

## 🚀 Step 3: Run the Deployment Workflow

### Via GitHub Web UI

1. Go to **Actions** tab in your repository
2. Select **Deploy Full Stack to Azure** workflow
3. Click **Run workflow**
4. Fill in the parameters:
   - **Environment**: Select `proctor` (for team-00) or `team-01` through `team-20`
   - **Deploy FabrikamApi**: ✅ (checked)
   - **Deploy FabrikamMcp**: ✅ (checked)
   - **Deploy FabrikamSim**: ☐ (unchecked - optional)
5. Click **Run workflow**

### Via GitHub CLI

```powershell
# Deploy to team-00 (proctor)
gh workflow run deploy-full-stack.yml `
  --repo davebirr/Fabrikam-Project `
  --ref main `
  -f environment=proctor `
  -f deploy_api=true `
  -f deploy_mcp=true `
  -f deploy_sim=false

# Deploy to team-01
gh workflow run deploy-full-stack.yml `
  --repo davebirr/Fabrikam-Project `
  --ref main `
  -f environment=team-01 `
  -f deploy_api=true `
  -f deploy_mcp=true `
  -f deploy_sim=false
```

## 🔄 How the Workflow Works

The updated workflow:

1. **Setup Job**: 
   - Maps environment name to team ID (proctor → 00, team-01 → 01, etc.)
   - Queries Azure to find actual resource names with unique suffixes
   - Example: `rg-fabrikam-team-00` contains `fabrikam-api-dev-66nqp3`

2. **Build Jobs**:
   - Builds FabrikamApi, FabrikamMcp, and optionally FabrikamSimulator
   - Creates deployment artifacts
   - Uploads to GitHub Actions

3. **Deploy Jobs**:
   - Downloads artifacts
   - Logs into Azure using Service Principal
   - Configures app settings (API URL for MCP/SIM)
   - Deploys to Azure App Services
   - Tests health endpoints

4. **Summary**:
   - Reports deployment status
   - Shows URLs for all deployed apps

## 📊 Monitoring Deployments

### Check Workflow Status

```powershell
# List recent workflow runs
gh run list --repo davebirr/Fabrikam-Project --workflow=deploy-full-stack.yml

# Watch a specific run
gh run watch <run-id> --repo davebirr/Fabrikam-Project
```

### Verify Deployed Apps

After deployment completes, test the endpoints:

```powershell
# Get app URLs from Azure (example for team-00)
$apiUrl = az webapp show --resource-group rg-fabrikam-team-00 --name fabrikam-api-dev-66nqp3 --query defaultHostName -o tsv
$mcpUrl = az webapp show --resource-group rg-fabrikam-team-00 --name fabrikam-mcp-dev-66nqp3 --query defaultHostName -o tsv

# Test API
curl "https://$apiUrl/api/info"

# Test MCP
curl "https://$mcpUrl/mcp/v1/info"
```

## 🎯 Workshop Deployment Strategy

### For Proctor Instance (Team 00)

1. Deploy infrastructure:
   ```powershell
   .\scripts\Deploy-Workshop-Team.ps1 -TeamId 00
   ```

2. Deploy application code:
   ```powershell
   gh workflow run deploy-full-stack.yml `
     --ref main `
     -f environment=proctor `
     -f deploy_api=true `
     -f deploy_mcp=true
   ```

### For All Team Instances (01-20)

Option A: Deploy one at a time manually
Option B: Script the deployments (see below)

```powershell
# Deploy all teams via GitHub Actions
1..20 | ForEach-Object {
    $teamId = "{0:D2}" -f $_
    
    Write-Host "🚀 Deploying team-$teamId..." -ForegroundColor Cyan
    
    gh workflow run deploy-full-stack.yml `
      --ref main `
      -f environment="team-$teamId" `
      -f deploy_api=true `
      -f deploy_mcp=true
    
    Start-Sleep -Seconds 5  # Rate limit between triggers
}
```

## 🔧 Troubleshooting

### Issue: "Resource group not found"

**Cause**: Infrastructure not deployed yet or wrong naming convention

**Solution**: 
1. Verify resource group exists:
   ```powershell
   az group list --query "[?contains(name, 'fabrikam-team')]" -o table
   ```
2. Deploy infrastructure first using `Deploy-Workshop-Team.ps1`

### Issue: "App name not found in Azure query"

**Cause**: Workflow trying to query apps before they're created

**Solution**: This should only happen during setup job. Verify the RG has App Services:
```powershell
az webapp list --resource-group rg-fabrikam-team-00 -o table
```

### Issue: Deployment succeeds but app shows errors

**Cause**: App Settings not configured or database connection issues

**Solution**: 
1. Check App Settings in Azure Portal
2. Verify `FabrikamApi__BaseUrl` is set for MCP/SIM apps
3. Check Application Insights for errors (if enabled)

### Issue: Service Principal permission denied

**Cause**: Service Principal doesn't have Contributor role on subscription

**Solution**:
```powershell
# Get Service Principal Object ID
$spObjectId = az ad sp list --display-name "github-actions-fabrikam-workshop" --query "[0].id" -o tsv

# Grant Contributor role
az role assignment create `
  --assignee $spObjectId `
  --role Contributor `
  --scope /subscriptions/1ae622b1-c33c-457f-a2bb-351fed78922f
```

## 🎓 Next Steps

After successful deployment:

1. **Test the API**: 
   - Visit `https://fabrikam-api-dev-{suffix}.azurewebsites.net/api/info`
   - Verify health endpoint responds

2. **Test MCP Server**:
   - Configure Copilot Studio with MCP URL
   - Test MCP tools in Copilot

3. **Generate Team URLs**:
   - Create documentation with all team URLs
   - Distribute to workshop participants

4. **Monitor Usage**:
   - Check Azure Portal for resource utilization
   - Monitor costs during workshop

## 📚 Related Documentation

- [Deploy-Workshop-Team.ps1 Script](../scripts/Deploy-Workshop-Team.ps1)
- [ARM Template Documentation](../../deployment/README.md)
- [Workshop Planning](../workshops/README.md)
