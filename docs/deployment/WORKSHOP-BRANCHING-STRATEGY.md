# 🎯 Workshop Branching & CI/CD Strategy

## Overview

Strategy for managing **20+ team deployments** without creating 60+ workflow files.

## 🌿 Branch Strategy

```
main (development)
  ↓
workshop-stable (production-ready for workshop)
  ↓ (deploys to all team environments)
20+ team instances
```

### **Branches**

#### **`main`** (Development Branch)
- **Purpose**: Your active development work
- **Deploys to**: Your personal dev environment (`fabrikam-*-development-tzjeje`)
- **Workflow**: Auto-deploys on push to `main`
- **Who uses it**: You (davebirr)

#### **`workshop-stable`** (Workshop Production Branch)
- **Purpose**: Stable, tested releases for workshop week
- **Deploys to**: All 20 team environments + proctor environment
- **Workflow**: Auto-deploys to all teams on push to `workshop-stable`
- **Who uses it**: Workshop teams + facilitators
- **Merge strategy**: Only merge from `main` after thorough testing

### **Workflow**

```bash
# 1. Develop on main
git checkout main
# ... make changes ...
git commit -m "feat: add new feature"
git push origin main
# → Deploys to fabrikam-*-development-tzjeje

# 2. Test thoroughly in dev

# 3. When ready for workshop, merge to workshop-stable
git checkout workshop-stable
git merge main
git push origin workshop-stable
# → Deploys to all 20 team environments + proctor
```

## 🚀 CI/CD Architecture

### **Problem**: Avoiding 60 Workflow Files

Instead of:
```
❌ main_fabrikam-api-team1.yml
❌ main_fabrikam-api-team2.yml
❌ main_fabrikam-api-team3.yml
... (60+ files!)
```

We use:
```
✅ deploy-workshop.yml (ONE file, matrix strategy)
✅ deploy-dev.yml (ONE file, for your dev environment)
```

### **Solution: Matrix Deployment**

**Single workflow deploys to ALL environments using GitHub Environments + Matrix**

## 📋 Implementation Plan

### **Step 1: Create GitHub Environments**

Create these in your repository **Settings → Environments**:

#### **Environment: `development`**
- **Purpose**: Your personal dev instance
- **Protection**: None (auto-deploy from `main`)
- **Secrets**:
  - `AZURE_CREDENTIALS` (Service Principal for tzjeje resource group)
- **Variables**:
  - `RESOURCE_GROUP` = `rg-fabrikam-dev`
  - `API_APP_NAME` = `fabrikam-api-development-tzjeje`
  - `MCP_APP_NAME` = `fabrikam-mcp-development-tzjeje`
  - `SIM_APP_NAME` = `fabrikam-sim-development-tzjeje`

#### **Environment: `workshop-proctor`**
- **Purpose**: Proctor/facilitator instance
- **Protection**: Required reviewers (optional)
- **Secrets**:
  - `AZURE_CREDENTIALS` (Service Principal for proctor resource group)
- **Variables**:
  - `RESOURCE_GROUP` = `rg-agentathon-proctor`
  - `API_APP_NAME` = `fabrikam-api-proctor-[suffix]`
  - `MCP_APP_NAME` = `fabrikam-mcp-proctor-[suffix]`
  - `SIM_APP_NAME` = `fabrikam-sim-proctor-[suffix]`

#### **Environments: `workshop-team1` through `workshop-team20`**
- **Purpose**: Individual team instances
- **Protection**: None (auto-deploy from `workshop-stable`)
- **Secrets**:
  - `AZURE_CREDENTIALS` (Service Principal for team resource group)
- **Variables**:
  - `RESOURCE_GROUP` = `rg-agentathon-team1` (team-specific)
  - `API_APP_NAME` = `fabrikam-api-team1-[suffix]`
  - `MCP_APP_NAME` = `fabrikam-mcp-team1-[suffix]`
  - `SIM_APP_NAME` = `fabrikam-sim-team1-[suffix]`

### **Step 2: Simplified Environment Creation Script**

**PowerShell script to create all 20+ environments programmatically:**

```powershell
# Create-Workshop-Environments.ps1
# Run this to create all GitHub Environments via gh CLI

$environments = @(
    "development",
    "workshop-proctor",
    "workshop-team1",
    "workshop-team2",
    # ... team3-team20
)

foreach ($env in $environments) {
    gh api repos/davebirr/Fabrikam-Project/environments/$env `
        -X PUT `
        -f wait_timer=0
    
    Write-Host "✅ Created environment: $env"
}
```

### **Step 3: Create Matrix Deployment Workflows**

#### **File: `.github/workflows/deploy-workshop.yml`**

This ONE file deploys to ALL team environments:

```yaml
name: Deploy to Workshop Environments

on:
  push:
    branches:
      - workshop-stable
  workflow_dispatch:
    inputs:
      target_environment:
        description: 'Specific environment to deploy to (optional)'
        required: false
        type: choice
        options:
          - all
          - workshop-proctor
          - workshop-team1
          - workshop-team2
          # Add all teams here

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [api, mcp, simulator]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up .NET Core
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.x'
      
      - name: Build ${{ matrix.service }}
        run: |
          case "${{ matrix.service }}" in
            api)
              dotnet build FabrikamApi/src/FabrikamApi.csproj --configuration Release
              dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ./publish/api
              ;;
            mcp)
              dotnet build FabrikamMcp/src/FabrikamMcp.csproj --configuration Release
              dotnet publish FabrikamMcp/src/FabrikamMcp.csproj -c Release -o ./publish/mcp
              ;;
            simulator)
              dotnet build FabrikamSimulator/src/FabrikamSimulator.csproj --configuration Release
              dotnet publish FabrikamSimulator/src/FabrikamSimulator.csproj -c Release -o ./publish/simulator
              ;;
          esac
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.service }}
          path: ./publish/${{ matrix.service }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    strategy:
      max-parallel: 5  # Deploy to 5 teams at a time to avoid rate limits
      matrix:
        environment:
          - workshop-proctor
          - workshop-team1
          - workshop-team2
          - workshop-team3
          # Add all 20 teams here
        service:
          - api
          - mcp
          - simulator
    
    environment: ${{ matrix.environment }}
    
    steps:
      - name: Download ${{ matrix.service }} artifact
        uses: actions/download-artifact@v4
        with:
          name: ${{ matrix.service }}
          path: ./publish
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy ${{ matrix.service }} to ${{ matrix.environment }}
        uses: azure/webapps-deploy@v3
        with:
          app-name: ${{ vars[format('{0}_APP_NAME', matrix.service == 'api' && 'API' || matrix.service == 'mcp' && 'MCP' || 'SIM')] }}
          package: ./publish
      
      - name: Deployment Summary
        run: |
          echo "✅ Deployed ${{ matrix.service }} to ${{ matrix.environment }}"
          echo "🌐 App: ${{ vars[format('{0}_APP_NAME', matrix.service == 'api' && 'API' || matrix.service == 'mcp' && 'MCP' || 'SIM')] }}"
          echo "📦 Resource Group: ${{ vars.RESOURCE_GROUP }}"
```

#### **File: `.github/workflows/deploy-dev.yml`**

Your personal development deployments:

```yaml
name: Deploy to Development

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [api, mcp, simulator]
    
    environment: development
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up .NET Core
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.x'
      
      - name: Build and deploy ${{ matrix.service }}
        run: |
          # Build logic (same as workshop workflow)
          # Deploy logic using development environment variables
```

### **Step 4: Azure Resource Deployment**

**Create all team resources using Bicep/ARM with parameters:**

```bash
# Deploy 20 team instances
for i in {1..20}; do
  az deployment group create \
    --resource-group "rg-agentathon-team$i" \
    --template-file deployment/AzureDeploymentTemplate.modular.json \
    --parameters environment=workshop-team$i
done
```

### **Step 5: Configure GitHub Environment Variables**

**Script to set environment variables for all teams:**

```powershell
# Set-Environment-Variables.ps1
param(
    [int]$TeamCount = 20
)

for ($i = 1; $i -le $TeamCount; $i++) {
    $env = "workshop-team$i"
    $suffix = "xyz123"  # Get from Azure deployment
    
    # Set variables via GitHub API
    gh api repos/davebirr/Fabrikam-Project/environments/$env/variables/RESOURCE_GROUP `
        -X PUT -f name="RESOURCE_GROUP" -f value="rg-agentathon-team$i"
    
    gh api repos/davebirr/Fabrikam-Project/environments/$env/variables/API_APP_NAME `
        -X PUT -f name="API_APP_NAME" -f value="fabrikam-api-team$i-$suffix"
    
    # ... repeat for MCP and SIM
    
    Write-Host "✅ Configured environment: $env"
}
```

## 🎯 Benefits

### **Scalability**
- ✅ Add team21-team50 without creating new workflow files
- ✅ Just add to matrix in ONE place

### **Maintainability**
- ✅ Fix deployment logic once, applies to all teams
- ✅ No copy-paste errors across 60 files

### **Flexibility**
- ✅ Deploy to specific environment via workflow_dispatch
- ✅ Deploy to all teams with one push
- ✅ Parallel deployment (5 at a time) for speed

### **Safety**
- ✅ Development branch (`main`) never touches workshop environments
- ✅ Workshop branch (`workshop-stable`) protected from accidental changes
- ✅ Environment-specific secrets (no cross-contamination)

## 📅 Workshop Week Workflow

### **Monday (Prep)**
```bash
# Merge latest stable code to workshop-stable
git checkout workshop-stable
git merge main
git push origin workshop-stable
# → Deploys to all 20 teams (takes ~10-15 minutes)
```

### **Tuesday-Thursday (Workshop)**
```bash
# If urgent fix needed:
git checkout main
# ... make fix ...
git commit -m "fix: urgent workshop issue"
git push origin main  # Deploy to dev first
# Test in dev
git checkout workshop-stable
git cherry-pick <commit-hash>
git push origin workshop-stable  # Deploy to all teams
```

### **Friday (Cleanup)**
```bash
# Merge any workshop fixes back to main
git checkout main
git merge workshop-stable
```

## 🚨 Troubleshooting

### **Problem: Deployment to team5 fails**
```bash
# Re-deploy just team5
gh workflow run deploy-workshop.yml -f target_environment=workshop-team5
```

### **Problem: Need to update all team configurations**
```powershell
# Run Set-Environment-Variables.ps1 again
.\scripts\Set-Environment-Variables.ps1
```

### **Problem: Secret expired for team10**
```bash
# Update secret via GitHub UI or API
gh secret set AZURE_CREDENTIALS --env workshop-team10 < credentials.json
```

## 📚 Next Steps

1. ✅ Create `workshop-stable` branch
2. ✅ Create GitHub Environments (proctor + 20 teams)
3. ✅ Deploy Azure resources for all teams
4. ✅ Create deploy-workshop.yml workflow
5. ✅ Test deployment to one team environment
6. ✅ Roll out to all teams
7. ✅ Document team-specific URLs for workshop

---

**Total Workflow Files Needed**: 2 (instead of 60+)
**Total GitHub Environments**: 22 (dev + proctor + 20 teams)
**Deployment Time**: ~10-15 minutes for all teams in parallel
