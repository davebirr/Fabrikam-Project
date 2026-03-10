# 🚀 Deploy to Azure - Three Authentication Modes

## 🔧 Prerequisites: Create Resource Group First

**⚠️ Important**: You must create a resource group before deploying. This ensures proper resource naming and isolation.

### Step 1: Open Azure Cloud Shell

1. Go to [Azure Portal](https://portal.azure.com)
2. Click the Cloud Shell icon (`>_`) in the top toolbar

### Step 2: Run the Setup Script

Copy and paste this complete script to create your resource group and get your User Object ID:

```powershell
# Generate 6-character lowercase suffix (improved collision avoidance)
$suffix = -join ((97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})

# Create resource group
$resourceGroupName = "rg-fabrikam-development-$suffix"
az group create --name $resourceGroupName --location "East US 2"

# Get your user object ID (needed for Key Vault RBAC permissions)
$userObjectId = az ad signed-in-user show --query id -o tsv

# Display the values you need for deployment
$message = @"

===============================================
✅ SETUP COMPLETE - Copy these values:
===============================================

Use these values in the ARM template deployment below:

$resourceGroupName
$userObjectId

===============================================
"@

Write-Host $message -ForegroundColor Green
```

## 🚀 Deploy to Azure

**After running the setup script above**, click the button below to deploy:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdavebirr%2FFabrikam-Project%2Fmain%2Fdeployment%2FAzureDeploymentTemplate.modular.json)

> 💡 **Tip**: Right-click the button and select "Open link in new tab" to keep this page open for reference during deployment.

## 🎯 Choose Your Authentication Mode During Deployment

The ARM template will prompt you to select one of three authentication modes:

### 🔓 **Disabled Mode** - Quick Demos

- **Best for**: POCs, demos, rapid testing
- **Security**: GUID-based user tracking only
- **Setup Time**: ⚡ Instant

### 🔐 **BearerToken Mode** - JWT Authentication

- **Best for**: Production APIs, secure demos
- **Security**: JWT tokens with Key Vault secrets
- **Setup Time**: 🔧 5 minutes

### 🏢 **EntraExternalId Mode** - Enterprise OAuth

- **Best for**: Enterprise integration, SSO scenarios
- **Security**: OAuth 2.0 with Microsoft Entra External ID
- **Setup Time**: 🏢 15-30 minutes

## 📋 Authentication Mode Comparison

| Feature | Disabled | BearerToken | EntraExternalId |
|---------|----------|-------------|-----------------|
| **Setup Time** | ⚡ Instant | 🔧 5 minutes | 🏢 15-30 minutes |
| **Security Level** | 🔓 Basic tracking | 🔐 JWT tokens | 🏢 Enterprise OAuth |
| **User Management** | 📝 GUID only | 👤 Registration required | 🏢 Azure AD integration |
| **Best For** | Demos, POCs | Production APIs | Enterprise SSO |
| **Prerequisites** | None | None | Entra External ID tenant |

## 🔐 Key Features

### Enhanced Security:
- ✅ **Azure Key Vault** deployed with **RBAC authorization** (not legacy access policies)
- ✅ **JWT secrets** secured in Key Vault (never in app configuration)
- ✅ **SQL connection strings** secured for SQL Server deployments
- ✅ **Managed Identity** authentication to Key Vault
- ✅ **Auto-assigned permissions**: App Services get Key Vault Secrets User role
- ✅ **Deployment user permissions**: Deployer gets Key Vault Secrets Officer role

### Flexible Database Options:
- 🚀 **InMemory**: Quick demos, no persistence, instant startup
- 🗃️ **SQL Server**: Production-like, persistent data, full features

### Smart Resource Naming:
- 📋 **Pattern**: `rg-fabrikam-{environment}-{suffix}`
- 🔀 **Example**: `rg-fabrikam-development-abc123` (6-character lowercase suffix)
- ✅ **Benefits**: Unique isolation, easy identification, improved collision avoidance

## 📋 Key Deployment Parameters

When you click "Deploy to Azure", you'll configure these key parameters using the values from your setup script:

- **Authentication Mode**: Choose `Disabled`, `BearerToken`, or `EntraExternalId`
- **Resource Group**: Use the **Resource Group Name** from your setup script output
- **Deployer Object ID**: Use the **User Object ID** from your setup script output
- **Database Provider**: Choose `InMemory` (demos) or `SqlServer` (persistent)

For **EntraExternalId mode**, you'll also need:

- **Entra Tenant**: Your Entra External ID tenant domain
- **Client ID**: Application ID from your Entra app registration

## 🏢 EntraExternalId Setup Prerequisites

If you plan to use **EntraExternalId mode**, complete these steps first:

### 1. Create Entra External ID Tenant
```bash
# Option 1: Use existing Azure AD B2C tenant
# Option 2: Create new Entra External ID tenant in Azure Portal
# Go to: Azure Portal > Microsoft Entra ID > External Identities > Overview
```

### 2. Register Your Application
1. In your Entra tenant: **App registrations** > **New registration**
2. **Name**: `Fabrikam-API-Demo`
3. **Supported account types**: Accounts in any organizational directory and personal Microsoft accounts
4. **Redirect URI**: Leave empty (will be set after deployment)
5. **Register** and note the **Application (client) ID**

### 3. Create Client Secret  
1. In your app registration: **Certificates & secrets** > **New client secret**
2. **Description**: `Fabrikam-Demo-Secret`
3. **Expires**: 6 months (for demos)
4. **Add** and **copy the secret value immediately** (you can't see it again)

### 4. Configure After Deployment
After deploying, you'll need to update your app registration:
1. **Redirect URIs**: Add these to your app registration:
   - `https://your-api-app-name.azurewebsites.net/signin-oidc`
   - `https://your-api-app-name.azurewebsites.net/.auth/login/aad/callback`
2. **API permissions**: Configure as needed for your tenant
3. **Token configuration**: Add optional claims if required

## 🏗️ What Gets Deployed

### Improved Resource Naming (2025 Update)

The deployment now uses a **more reliable naming pattern**:

- **6-character lowercase suffix** (vs. old 4-character mixed-case)
- **Reduced collision probability**: From 1 in 1.6M to 1 in 308M
- **Pattern**: `{baseName}-{environment}-{6-char-suffix}`
- **Example**: `fabrikam-development-abc123`

This improves deployment reliability, especially when multiple users fork and deploy simultaneously.

### InMemory + Authentication (Recommended for testing)

- 🌐 **API App Service** (with authentication)
- 🤖 **MCP App Service** (Model Context Protocol)
- � **Dashboard App Service** (Blazor real-time dashboard)
- 🎲 **Simulator App Service** (business activity simulator)
- 🔐 **Key Vault** (with JWT secret)
- 📊 **Application Insights** (monitoring)
- 📱 **App Service Plan**

### SQL Server + Authentication (Production-like)

- 🌐 **API App Service** (with authentication)
- 🤖 **MCP App Service** (Model Context Protocol)
- 📊 **Dashboard App Service** (Blazor real-time dashboard)
- 🎲 **Simulator App Service** (business activity simulator)
- 🔐 **Key Vault** (with JWT + SQL secrets)
- 🗃️ **SQL Server & Database**
- 📊 **Application Insights** (monitoring)
- 📱 **App Service Plan**

## 🔄 Setting Up CI/CD (Fork Users)

The ARM template creates **4 empty App Services**. You need to set up CI/CD to deploy code to them.

### Step 1: Delete Instance-Specific Workflow Files

Your fork includes workflow files tied to the original repo's Azure instance. Delete these — they won't work for your deployment:

```bash
rm .github/workflows/main_fabrikam-api-development-tzjeje.yml
rm .github/workflows/main_fabrikam-mcp-development-tzjeje.yml
rm .github/workflows/main_fabrikam-dash-development-tzjeje.yml
rm .github/workflows/main_fabrikam-sim-development-tzjeje.yml
rm .github/workflows/deploy-team-24-main.yml
rm .github/workflows/deploy-workshop-instances.yml
rm .github/workflows/deploy-full-stack.yml
rm .github/workflows/deploy-api.yml
```

> 💡 Keep `testing.yml` — it runs tests on PRs and has no Azure dependencies.

### Step 2: Set Up CI/CD via Azure Portal

For **each** of the 4 App Services, use the Azure Portal's Deployment Center:

1. Go to your App Service in the [Azure Portal](https://portal.azure.com)
2. Navigate to **Deployment Center** (left sidebar)
3. Select **GitHub** as the source
4. Authorize and select your **forked repo**, branch `main`
5. Azure will auto-generate a GitHub Actions workflow file

Repeat for all 4 App Services: API, MCP, Dashboard, and Simulator.

### Step 3: Fix Project Paths for Monorepo

**⚠️ Critical**: Azure Portal generates workflows assuming a single-project repo. Since this is a **monorepo**, you must update the `dotnet build` and `dotnet publish` lines in each generated workflow to use the correct project path.

Update the `build` and `publish` steps in each workflow file:

| App Service | Project Path |
|---|---|
| **API** | `FabrikamApi/src/FabrikamApi.csproj` |
| **MCP** | `FabrikamMcp/src/FabrikamMcp.csproj` |
| **Dashboard** | `FabrikamDashboard/FabrikamDashboard.csproj` |
| **Simulator** | `FabrikamSimulator/src/FabrikamSimulator.csproj` |

For example, in your API workflow, change:

```yaml
# ❌ Azure Portal generates (wrong for monorepo):
- name: Build with dotnet
  run: dotnet build --configuration Release
- name: dotnet publish
  run: dotnet publish -c Release -o ${{env.DOTNET_ROOT}}/myapp

# ✅ Correct — specify the project path:
- name: Build with dotnet
  run: dotnet build FabrikamApi/src/FabrikamApi.csproj --configuration Release
- name: dotnet publish
  run: dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ${{env.DOTNET_ROOT}}/myapp
```

### Step 4: Configure Dashboard App Settings

The Dashboard needs to know where the API and Simulator are. In the Azure Portal, go to your Dashboard App Service > **Configuration** > **Application settings** and add:

| Setting | Value |
|---|---|
| `FabrikamApi__BaseUrl` | `https://your-api-app-name.azurewebsites.net` |
| `FabrikamSimulator__BaseUrl` | `https://your-sim-app-name.azurewebsites.net` |

The MCP and Simulator also need the API URL:

| App Service | Setting | Value |
|---|---|---|
| **MCP** | `FabrikamApi__BaseUrl` | `https://your-api-app-name.azurewebsites.net` |
| **Simulator** | `FabrikamApi__BaseUrl` | `https://your-api-app-name.azurewebsites.net` |

## 🔍 Testing Your Deployment

### Quick Health Check

```bash
# API Health Check
curl https://your-api-app-name.azurewebsites.net/api/orders

# MCP Health Check  
curl https://your-mcp-app-name.azurewebsites.net/mcp/v1/info
```

### Authentication Testing

```bash
# Register a test user
curl -X POST https://your-api-app-name.azurewebsites.net/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","firstName":"Test","lastName":"User"}'

# Login to get JWT token
curl -X POST https://your-api-app-name.azurewebsites.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!"}'
```

## 🎯 Next Steps

1. ✅ **Deploy** using the button above
2. 🔧 **Configure** repository variables for CI/CD
3. 🧪 **Test** the auto-fix workflow functionality
4. 📊 **Monitor** via Application Insights
5. 🔄 **Iterate** with the enhanced CI/CD pipeline

---

## Summary

Ready to deploy with enhanced security and Key Vault integration! 🚀
