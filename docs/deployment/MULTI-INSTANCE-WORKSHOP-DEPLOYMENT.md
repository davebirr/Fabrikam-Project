# 🚀 Multi-Instance Workshop Deployment Strategy

## **Overview**

Deploy 20 isolated Fabrikam instances for the Agent-a-thon workshop using GitHub Actions matrix strategy. Each team gets their own complete environment (API + MCP + SIM).

---

## **Architecture**

### **Instance Naming Convention**

```
Team Instance: team-{01-20}
API:  fabrikam-api-team-{01-20}
MCP:  fabrikam-mcp-team-{01-20}  
SIM:  fabrikam-sim-team-{01-20}

Example Team 01:
- API: fabrikam-api-team-01.azurewebsites.net
- MCP: fabrikam-mcp-team-01.azurewebsites.net
- SIM: fabrikam-sim-team-01.azurewebsites.net
```

### **Resource Groups**

**Option 1: Single Resource Group (Simpler)**
```
Resource Group: rg-fabrikam-workshop
Contains: All 60 App Services (20 teams × 3 services)
Pros: Single deployment scope, easier cleanup
Cons: All teams share same RG permissions
```

**Option 2: Per-Team Resource Groups (Isolated)**
```
Resource Groups: rg-fabrikam-team-01 through rg-fabrikam-team-20
Contains: 3 App Services per team
Pros: Complete isolation, granular permissions
Cons: More complex deployment, 20 RGs to manage
```

**Recommendation**: Option 1 for workshop (simpler), Option 2 for production

---

## **GitHub Actions Matrix Deployment**

### **Strategy: Single Workflow, Parallel Deployment**

Create one workflow file that deploys to all instances using matrix strategy:

**`.github/workflows/deploy-workshop-instances.yml`**

```yaml
name: Deploy Workshop Instances

on:
  push:
    branches: [ workshop-stable ]
  workflow_dispatch:
    inputs:
      teams:
        description: 'Teams to deploy (comma-separated: 01,02,03 or "all")'
        required: true
        default: 'all'

env:
  DOTNET_VERSION: '9.0.x'
  RESOURCE_GROUP: 'rg-fabrikam-workshop'

jobs:
  # Build once, deploy many
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        project: [api, mcp, sim]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
      
      - name: Build ${{ matrix.project }}
        run: |
          if [ "${{ matrix.project }}" == "api" ]; then
            dotnet build FabrikamApi/src/FabrikamApi.csproj --configuration Release
            dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ./api-publish
          elif [ "${{ matrix.project }}" == "mcp" ]; then
            dotnet build FabrikamMcp/src/FabrikamMcp.csproj --configuration Release
            dotnet publish FabrikamMcp/src/FabrikamMcp.csproj -c Release -o ./mcp-publish
          elif [ "${{ matrix.project }}" == "sim" ]; then
            dotnet build FabrikamSim/FabrikamSim.csproj --configuration Release
            dotnet publish FabrikamSim/FabrikamSim.csproj -c Release -o ./sim-publish
          fi
      
      - name: Upload artifact for ${{ matrix.project }}
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.project }}-artifact
          path: ./${{ matrix.project }}-publish
  
  # Deploy to all team instances in parallel
  deploy:
    runs-on: ubuntu-latest
    needs: build
    strategy:
      max-parallel: 10  # Deploy 10 teams at a time to avoid rate limits
      matrix:
        team: ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
               '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']
        project: [api, mcp, sim]
    
    steps:
      - name: Download ${{ matrix.project }} artifact
        uses: actions/download-artifact@v4
        with:
          name: ${{ matrix.project }}-artifact
          path: ./${{ matrix.project }}-publish
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy to fabrikam-${{ matrix.project }}-team-${{ matrix.team }}
        uses: azure/webapps-deploy@v2
        with:
          app-name: fabrikam-${{ matrix.project }}-team-${{ matrix.team }}
          package: ./${{ matrix.project }}-publish
      
      - name: Verify deployment
        run: |
          echo "Deployed fabrikam-${{ matrix.project }}-team-${{ matrix.team }}"
          echo "URL: https://fabrikam-${{ matrix.project }}-team-${{ matrix.team }}.azurewebsites.net"
```

### **Deployment Metrics**

With `max-parallel: 10`:
- **Total Jobs**: 60 (20 teams × 3 services)
- **Parallel Batches**: 6 batches of 10
- **Build Time**: ~5 minutes (parallel for 3 projects)
- **Deploy Time per Batch**: ~3 minutes
- **Total Time**: ~25 minutes (build + 6 batches)

With `max-parallel: 20` (faster but higher Azure API load):
- **Total Time**: ~15 minutes (build + 3 batches)

---

## **Infrastructure Provisioning**

### **Option A: Azure CLI Script (Recommended for Workshop)**

**`scripts/provision-workshop-instances.ps1`**

```powershell
<#
.SYNOPSIS
    Provision 20 workshop team instances in Azure
.PARAMETER TeamCount
    Number of teams (default: 20)
.PARAMETER ResourceGroup
    Resource group name (default: rg-fabrikam-workshop)
.PARAMETER Location
    Azure region (default: westus2)
#>

param(
    [int]$TeamCount = 20,
    [string]$ResourceGroup = "rg-fabrikam-workshop",
    [string]$Location = "westus2",
    [string]$AppServicePlan = "asp-fabrikam-workshop",
    [string]$Sku = "B2"  # Basic tier with 2 cores
)

# Create resource group
Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

# Create App Service Plan (shared by all instances for cost efficiency)
Write-Host "Creating App Service Plan: $AppServicePlan" -ForegroundColor Cyan
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku $Sku `
    --is-linux

# Provision instances for each team
for ($team = 1; $team -le $TeamCount; $team++) {
    $teamId = $team.ToString("00")
    Write-Host "`n=== Provisioning Team $teamId ===" -ForegroundColor Green
    
    # API App Service
    $apiName = "fabrikam-api-team-$teamId"
    Write-Host "Creating $apiName..." -ForegroundColor Yellow
    az webapp create `
        --name $apiName `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --runtime "DOTNETCORE:9.0"
    
    az webapp config appsettings set `
        --name $apiName `
        --resource-group $ResourceGroup `
        --settings `
            ASPNETCORE_ENVIRONMENT=Workshop `
            TeamId=$teamId
    
    # MCP App Service
    $mcpName = "fabrikam-mcp-team-$teamId"
    Write-Host "Creating $mcpName..." -ForegroundColor Yellow
    az webapp create `
        --name $mcpName `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --runtime "DOTNETCORE:9.0"
    
    az webapp config appsettings set `
        --name $mcpName `
        --resource-group $ResourceGroup `
        --settings `
            ASPNETCORE_ENVIRONMENT=Workshop `
            FabrikamApi__BaseUrl="https://$apiName.azurewebsites.net" `
            TeamId=$teamId
    
    # SIM App Service
    $simName = "fabrikam-sim-team-$teamId"
    Write-Host "Creating $simName..." -ForegroundColor Yellow
    az webapp create `
        --name $simName `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --runtime "DOTNETCORE:9.0"
    
    az webapp config appsettings set `
        --name $simName `
        --resource-group $ResourceGroup `
        --settings `
            ASPNETCORE_ENVIRONMENT=Workshop `
            FabrikamApi__BaseUrl="https://$apiName.azurewebsites.net" `
            TeamId=$teamId
    
    Write-Host "Team $teamId provisioned successfully!" -ForegroundColor Green
}

Write-Host "`n=== Provisioning Complete ===" -ForegroundColor Cyan
Write-Host "Total Teams: $TeamCount"
Write-Host "Total App Services: $($TeamCount * 3)"
Write-Host "Resource Group: $ResourceGroup"
Write-Host "`nNext steps:"
Write-Host "1. Configure GitHub Actions secrets"
Write-Host "2. Push to workshop-stable branch to deploy"
Write-Host "3. Verify deployments at: https://portal.azure.com"
```

### **Option B: Bicep/ARM Template (Infrastructure as Code)**

**`deployment/workshop-instances.bicep`**

```bicep
param location string = resourceGroup().location
param teamCount int = 20
param appServicePlanSku string = 'B2'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-fabrikam-workshop'
  location: location
  sku: {
    name: appServicePlanSku
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource apiApps 'Microsoft.Web/sites@2022-03-01' = [for i in range(1, teamCount): {
  name: 'fabrikam-api-team-${padLeft(i, 2, '0')}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: 'Workshop' }
        { name: 'TeamId', value: padLeft(i, 2, '0') }
      ]
    }
  }
}]

resource mcpApps 'Microsoft.Web/sites@2022-03-01' = [for i in range(1, teamCount): {
  name: 'fabrikam-mcp-team-${padLeft(i, 2, '0')}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: 'Workshop' }
        { name: 'TeamId', value: padLeft(i, 2, '0') }
        { name: 'FabrikamApi__BaseUrl', value: 'https://fabrikam-api-team-${padLeft(i, 2, '0')}.azurewebsites.net' }
      ]
    }
  }
}]

resource simApps 'Microsoft.Web/sites@2022-03-01' = [for i in range(1, teamCount): {
  name: 'fabrikam-sim-team-${padLeft(i, 2, '0')}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: 'Workshop' }
        { name: 'TeamId', value: padLeft(i, 2, '0') }
        { name: 'FabrikamApi__BaseUrl', value: 'https://fabrikam-api-team-${padLeft(i, 2, '0')}.azurewebsites.net' }
      ]
    }
  }
}]

output apiUrls array = [for i in range(1, teamCount): 'https://fabrikam-api-team-${padLeft(i, 2, '0')}.azurewebsites.net']
output mcpUrls array = [for i in range(1, teamCount): 'https://fabrikam-mcp-team-${padLeft(i, 2, '0')}.azurewebsites.net']
```

Deploy with:
```bash
az deployment group create \
  --resource-group rg-fabrikam-workshop \
  --template-file deployment/workshop-instances.bicep \
  --parameters teamCount=20
```

---

## **GitHub Secrets Configuration**

### **Required Secrets**

```bash
# Azure credentials for deployment
AZURE_CREDENTIALS='<service-principal-json>'

# Optional: Per-team secrets (if needed)
# TEAM_01_API_KEY='<key>'
# TEAM_02_API_KEY='<key>'
```

### **Generate Azure Credentials**

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-workshop-deployer" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/rg-fabrikam-workshop \
  --sdk-auth

# Output (add to GitHub secrets as AZURE_CREDENTIALS):
{
  "clientId": "<guid>",
  "clientSecret": "<secret>",
  "subscriptionId": "<guid>",
  "tenantId": "<guid>",
  ...
}
```

---

## **Cost Optimization**

### **Shared App Service Plan**

All 60 instances share one App Service Plan:
- **Plan**: Basic B2 (2 cores, 3.5 GB RAM)
- **Cost**: ~$73/month
- **Capacity**: Suitable for workshop (light load, 2-day duration)

### **Per-Instance Isolation**

Each team gets:
- Separate App Service (isolated processes)
- Separate database (in-memory, no shared state)
- Separate MCP URL (for Copilot Studio)

### **Workshop-Specific Savings**

- Use Basic tier (vs Standard/Premium)
- Single App Service Plan (shared infrastructure)
- Delete after workshop (temporary deployment)
- No Azure SQL (in-memory database)
- No Application Insights per-instance (use shared)

**Total Workshop Cost**: ~$73 for 2 days (can delete immediately after)

---

## **Deployment Workflow**

### **Initial Setup (One-Time)**

```bash
# 1. Provision infrastructure
./scripts/provision-workshop-instances.ps1 -TeamCount 20

# 2. Configure GitHub secrets
gh secret set AZURE_CREDENTIALS < azure-creds.json

# 3. Create workshop-stable branch
git checkout -b workshop-stable
git push -u origin workshop-stable

# 4. Tag baseline
git tag -a v1.0.0-workshop -m "Workshop baseline"
git push origin v1.0.0-workshop
```

### **Regular Deployment**

```bash
# Push to workshop-stable triggers deployment to all 20 teams
git checkout workshop-stable
git merge main --no-ff
git push origin workshop-stable

# Monitor deployment
gh run watch
```

### **Selective Deployment (Manual Trigger)**

```yaml
# In GitHub UI or via CLI:
gh workflow run deploy-workshop-instances.yml \
  -f teams="01,05,12"  # Deploy only specific teams
```

---

## **Monitoring & Health Checks**

### **Post-Deployment Validation Script**

**`scripts/verify-workshop-deployment.ps1`**

```powershell
param([int]$TeamCount = 20)

$failedInstances = @()

for ($team = 1; $team -le $TeamCount; $team++) {
    $teamId = $team.ToString("00")
    Write-Host "Testing Team $teamId..." -ForegroundColor Cyan
    
    # Test API
    $apiUrl = "https://fabrikam-api-team-$teamId.azurewebsites.net/api/info"
    try {
        $apiResponse = Invoke-RestMethod -Uri $apiUrl -SkipCertificateCheck -TimeoutSec 10
        Write-Host "  ✓ API: $($apiResponse.version)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ API failed" -ForegroundColor Red
        $failedInstances += "API-$teamId"
    }
    
    # Test MCP
    $mcpUrl = "https://fabrikam-mcp-team-$teamId.azurewebsites.net/mcp"
    try {
        $mcpResponse = Invoke-RestMethod -Uri $mcpUrl -Method Post -Body '{"method":"tools/list"}' -ContentType "application/json" -SkipCertificateCheck -TimeoutSec 10
        Write-Host "  ✓ MCP: $($mcpResponse.tools.Count) tools" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ MCP failed" -ForegroundColor Red
        $failedInstances += "MCP-$teamId"
    }
}

if ($failedInstances.Count -eq 0) {
    Write-Host "`n✓ All instances healthy!" -ForegroundColor Green
} else {
    Write-Host "`n✗ Failed instances: $($failedInstances -join ', ')" -ForegroundColor Red
    exit 1
}
```

---

## **Team Assignment**

### **Generate Team URLs Document**

**`scripts/generate-team-urls.ps1`**

```powershell
param([int]$TeamCount = 20, [string]$OutputFile = "workshop-team-urls.md")

$content = @"
# Workshop Team Instance URLs

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm")

| Team | API URL | MCP URL | SIM URL |
|------|---------|---------|---------|
"@

for ($team = 1; $team -le $TeamCount; $team++) {
    $teamId = $team.ToString("00")
    $content += "`n| Team $teamId | https://fabrikam-api-team-$teamId.azurewebsites.net | https://fabrikam-mcp-team-$teamId.azurewebsites.net/mcp | https://fabrikam-sim-team-$teamId.azurewebsites.net |"
}

$content | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "Team URLs generated: $OutputFile" -ForegroundColor Green
```

---

## **Cleanup After Workshop**

```bash
# Delete entire resource group (removes all 60 instances)
az group delete --name rg-fabrikam-workshop --yes --no-wait

# Or keep infrastructure but stop instances to save costs
for i in {01..20}; do
  az webapp stop --name fabrikam-api-team-$i --resource-group rg-fabrikam-workshop
  az webapp stop --name fabrikam-mcp-team-$i --resource-group rg-fabrikam-workshop
  az webapp stop --name fabrikam-sim-team-$i --resource-group rg-fabrikam-workshop
done
```

---

## **Recommended Timeline**

**3 Days Before Workshop** (Nov 1):
- Provision all 20 team instances
- Deploy workshop-stable baseline
- Run health checks on all instances
- Generate team URL document

**2 Days Before Workshop** (Nov 2):
- Final merge from main to workshop-stable
- Redeploy to all instances
- Full validation testing (5+ MCP calls per instance)
- Freeze workshop-stable branch

**1 Day Before Workshop** (Nov 3):
- Final health checks
- Distribute team URLs to facilitators
- Emergency hotfix window (if needed)

**Workshop Day** (Nov 4-5):
- Monitor instance health
- No deployments unless critical
- Log any issues for post-workshop review

**Post-Workshop** (Nov 6+):
- Merge any hotfixes back to main
- Cleanup/delete workshop instances
- Document lessons learned

---

**Last Updated**: October 31, 2025  
**Status**: Ready for implementation  
**Next Step**: Provision infrastructure and configure GitHub Actions
