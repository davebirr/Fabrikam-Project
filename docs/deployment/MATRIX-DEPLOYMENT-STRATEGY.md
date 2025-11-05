# 🚀 Workshop Deployment Strategy - Matrix-Based CI/CD

## 📋 The Problem with Auto-Generated Workflows

**Current Approach** (Azure Portal Auto-Generated):
```
20 teams × 3 services = 60 workflow files
❌ main_fabrikam-api-team1-xyz.yml
❌ main_fabrikam-api-team2-xyz.yml
... (60 files total)
```

**Issues:**
- 60+ workflow files to maintain
- Each file needs manual monorepo path fixes
- Secrets management nightmare (60+ publish profiles)
- Hard to update deployment logic across all teams
- GitHub Actions quota concerns with parallel jobs

## ✅ Solution: Matrix Strategy + JSON Configuration

**New Approach**:
```
1 workflow file × 3 services = 3 workflow files total
✅ deploy-api.yml
✅ deploy-mcp.yml  
✅ deploy-simulator.yml
+ 1 config file (deployments.json)
```

### **How It Works**

1. **Configuration File** defines all deployments
2. **Matrix Strategy** deploys to multiple teams in parallel
3. **Reusable Workflows** share common deployment logic
4. **Secrets** stored once per service type (not per team)

---

## 📁 Configuration Structure

### **deployments.json** (Repository Root)

```json
{
  "environments": {
    "development": {
      "enabled": true,
      "branches": ["main"],
      "api": {
        "appName": "fabrikam-api-development-tzjeje",
        "resourceGroup": "rg-fabrikam-dev"
      },
      "mcp": {
        "appName": "fabrikam-mcp-development-tzjeje",
        "resourceGroup": "rg-fabrikam-dev"
      },
      "simulator": {
        "appName": "fabrikam-sim-development-tzjeje",
        "resourceGroup": "rg-fabrikam-dev"
      }
    },
    "proctor": {
      "enabled": true,
      "branches": ["workshop-stable"],
      "api": {
        "appName": "fabrikam-api-proctor-tzjeje",
        "resourceGroup": "rg-agentathon-proctor"
      },
      "mcp": {
        "appName": "fabrikam-mcp-proctor-tzjeje",
        "resourceGroup": "rg-agentathon-proctor"
      },
      "simulator": {
        "appName": "fabrikam-sim-proctor-tzjeje",
        "resourceGroup": "rg-agentathon-proctor"
      }
    },
    "teams": {
      "enabled": true,
      "branches": ["workshop-stable"],
      "instances": [
        {
          "name": "team1",
          "api": "fabrikam-api-team1-abc123",
          "mcp": "fabrikam-mcp-team1-abc123",
          "simulator": "fabrikam-sim-team1-abc123",
          "resourceGroup": "rg-agentathon-team1"
        },
        {
          "name": "team2",
          "api": "fabrikam-api-team2-def456",
          "mcp": "fabrikam-mcp-team2-def456",
          "simulator": "fabrikam-sim-team2-def456",
          "resourceGroup": "rg-agentathon-team2"
        }
        // ... repeat for all 20 teams
      ]
    }
  }
}
```

---

## 🔧 Workflow Implementation

### **deploy-api.yml** (Single File for All API Deployments)

```yaml
name: Deploy FabrikamApi to All Environments

on:
  push:
    branches:
      - main                # Deploys to development
      - workshop-stable     # Deploys to proctor + all teams
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment (development/proctor/team1/team2/etc.)'
        required: false
        type: string
      force_deploy:
        description: 'Force deploy even if branch doesnt match'
        required: false
        type: boolean
        default: false

jobs:
  # Load configuration and determine which environments to deploy
  prepare:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Load deployment configuration
        id: set-matrix
        run: |
          # Read deployments.json
          CONFIG=$(cat deployments.json)
          
          # Determine which environments to deploy based on branch
          BRANCH="${{ github.ref_name }}"
          MANUAL_ENV="${{ github.event.inputs.environment }}"
          
          if [ -n "$MANUAL_ENV" ]; then
            # Manual deployment to specific environment
            echo "Deploying to manually selected environment: $MANUAL_ENV"
            MATRIX=$(echo $CONFIG | jq -c "{include: [.environments.$MANUAL_ENV.api // .environments.teams.instances[] | select(.name == \"$MANUAL_ENV\") | {name: .name, appName: .api, resourceGroup: .resourceGroup}]}")
          elif [ "$BRANCH" == "main" ]; then
            # Deploy to development only
            echo "Deploying to development environment"
            MATRIX=$(echo $CONFIG | jq -c '{include: [{name: "development", appName: .environments.development.api.appName, resourceGroup: .environments.development.api.resourceGroup}]}')
          elif [ "$BRANCH" == "workshop-stable" ]; then
            # Deploy to proctor + all teams
            echo "Deploying to proctor and all team environments"
            PROCTOR=$(echo $CONFIG | jq -c '{name: "proctor", appName: .environments.proctor.api.appName, resourceGroup: .environments.proctor.api.resourceGroup}')
            TEAMS=$(echo $CONFIG | jq -c '[.environments.teams.instances[] | {name: .name, appName: .api, resourceGroup: .resourceGroup}]')
            MATRIX=$(echo "{\"include\":[$PROCTOR,$TEAMS]}" | jq -c '.include |= flatten')
          else
            echo "No deployment configured for branch: $BRANCH"
            MATRIX='{"include":[]}'
          fi
          
          echo "matrix=$MATRIX" >> $GITHUB_OUTPUT
          echo "Deployment matrix: $MATRIX"

  # Build once, deploy to multiple environments
  build:
    runs-on: ubuntu-latest
    needs: prepare
    if: ${{ needs.prepare.outputs.matrix != '{"include":[]}' }}
    
    steps:
      - uses: actions/checkout@v4

      - name: Set up .NET Core
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.x'

      - name: Build API
        run: dotnet build FabrikamApi/src/FabrikamApi.csproj --configuration Release

      - name: Publish API
        run: dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ./publish/api

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: fabrikam-api
          path: ./publish/api
          retention-days: 1

  # Deploy to all environments in parallel using matrix
  deploy:
    runs-on: ubuntu-latest
    needs: [prepare, build]
    if: ${{ needs.prepare.outputs.matrix != '{"include":[]}' }}
    
    strategy:
      matrix: ${{ fromJson(needs.prepare.outputs.matrix) }}
      max-parallel: 5  # Limit concurrent deployments to avoid rate limits
      fail-fast: false  # Continue deploying to other teams if one fails
    
    steps:
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: fabrikam-api

      - name: Deploy to ${{ matrix.name }}
        uses: azure/webapps-deploy@v3
        with:
          app-name: ${{ matrix.appName }}
          publish-profile: ${{ secrets[format('AZURE_API_PUBLISH_PROFILE_{0}', matrix.name)] }}
          package: .

      - name: Verify deployment
        run: |
          echo "✅ Deployed FabrikamApi to ${{ matrix.name }}"
          echo "🌐 App: ${{ matrix.appName }}"
          echo "📦 Resource Group: ${{ matrix.resourceGroup }}"
          
          # Health check (wait 30s then curl)
          sleep 30
          HEALTH_URL="https://${{ matrix.appName }}.azurewebsites.net/api/info"
          echo "🔍 Health check: $HEALTH_URL"
          
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL || echo "000")
          if [ "$STATUS" == "200" ]; then
            echo "✅ Health check passed"
          else
            echo "⚠️  Health check returned $STATUS (may still be warming up)"
          fi

  # Summary job
  summary:
    runs-on: ubuntu-latest
    needs: [prepare, deploy]
    if: always()
    
    steps:
      - name: Deployment Summary
        run: |
          echo "## 🚀 Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Branch:** ${{ github.ref_name }}" >> $GITHUB_STEP_SUMMARY
          echo "**Trigger:** ${{ github.event_name }}" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          
          if [ "${{ needs.deploy.result }}" == "success" ]; then
            echo "✅ All deployments completed successfully" >> $GITHUB_STEP_SUMMARY
          elif [ "${{ needs.deploy.result }}" == "failure" ]; then
            echo "❌ Some deployments failed - check job details" >> $GITHUB_STEP_SUMMARY
          else
            echo "⚠️  Deployment status: ${{ needs.deploy.result }}" >> $GITHUB_STEP_SUMMARY
          fi
```

---

## 🔐 Secrets Management Strategy

### **Problem: 20 Teams = 60 Publish Profiles?**

**No!** Use **Azure Service Principal** authentication instead:

```yaml
# Instead of publish-profile per team:
❌ AZURE_API_PUBLISH_PROFILE_TEAM1
❌ AZURE_API_PUBLISH_PROFILE_TEAM2
... (60 secrets)

# Use ONE service principal with RBAC:
✅ AZURE_CREDENTIALS (one JSON with subscription/tenant/client)
✅ Service principal has "Contributor" on workshop resource groups
```

### **Updated Deployment Step (Using Service Principal)**

```yaml
deploy:
  strategy:
    matrix: ${{ fromJson(needs.prepare.outputs.matrix) }}
  
  steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy to ${{ matrix.name }}
      uses: azure/webapps-deploy@v3
      with:
        app-name: ${{ matrix.appName }}
        package: .
```

### **Create Service Principal**

```powershell
# One-time setup
az ad sp create-for-rbac `
  --name "github-actions-fabrikam-workshop" `
  --role contributor `
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-agentathon-proctor `
           /subscriptions/{subscription-id}/resourceGroups/rg-agentathon-team1 `
           /subscriptions/{subscription-id}/resourceGroups/rg-agentathon-team2 `
  --sdk-auth

# Output JSON goes into GitHub secret: AZURE_CREDENTIALS
```

---

## 📝 Managing Team Deployments

### **Adding a New Team**

1. **Add to deployments.json**:
```json
{
  "name": "team21",
  "api": "fabrikam-api-team21-xyz",
  "mcp": "fabrikam-mcp-team21-xyz",
  "simulator": "fabrikam-sim-team21-xyz",
  "resourceGroup": "rg-agentathon-team21"
}
```

2. **Grant Service Principal access**:
```powershell
az role assignment create `
  --assignee {service-principal-id} `
  --role Contributor `
  --scope /subscriptions/{sub-id}/resourceGroups/rg-agentathon-team21
```

3. **Commit and push** - automatic deployment!

### **Deploying to Specific Team**

```bash
# Via GitHub UI: Actions → Deploy FabrikamApi → Run workflow
# environment: team5

# Or via gh CLI:
gh workflow run deploy-api.yml -f environment=team5
```

---

## 🎯 Benefits of This Approach

| Aspect | Old Way (60 files) | New Way (Matrix) |
|--------|-------------------|------------------|
| **Workflow Files** | 60 (3 per team) | 3 (1 per service) |
| **Secrets** | 60 publish profiles | 1 service principal |
| **Add New Team** | Create 3 files, 3 secrets | Edit 1 JSON, 1 RBAC command |
| **Update Logic** | Edit 60 files | Edit 3 files |
| **Maintenance** | Nightmare | Easy |
| **Parallel Deploys** | 60 jobs | 1 job with matrix |
| **Sync to oscarw** | 60 files he doesn't need | 3 generic files + config |

---

## 🚀 Migration Plan

### **Phase 1: Create Infrastructure** (Today)

1. Create `deployments.json` with development + proctor
2. Create service principal with RBAC
3. Add `AZURE_CREDENTIALS` secret to GitHub
4. Create new matrix-based workflows

### **Phase 2: Test with Development** (Test Run)

1. Push to `main` branch
2. Verify deployment to development only
3. Validate build artifacts
4. Check health endpoints

### **Phase 3: Create workshop-stable Branch** (Pre-Workshop)

1. Create `workshop-stable` from `main`
2. Add proctor to `deployments.json`
3. Push and verify proctor deployment

### **Phase 4: Add Teams** (Week Before Workshop)

1. Deploy 20 team instances via ARM template
2. Collect App Service names
3. Add all teams to `deployments.json`
4. Grant service principal RBAC
5. Push `workshop-stable` → deploys to all 21 environments

### **Phase 5: Archive Old Workflows** (Cleanup)

1. Move `main_fabrikam-*-development-*.yml` to archive folder
2. Update `.github/workflows/README.md`
3. Document new deployment process

---

## 📋 Quick Start Implementation

Want me to create the actual workflow files and deployments.json for you now? I can:

1. Create matrix-based `deploy-api.yml`, `deploy-mcp.yml`, `deploy-simulator.yml`
2. Create `deployments.json` with your current dev environment
3. Create migration guide for switching from old workflows
4. Create service principal setup script

This will give you a production-ready matrix deployment system that scales from 1 to 100+ teams without adding workflow files!

---

**Bottom Line**: Replace 60 workflow files + 60 secrets with 3 workflow files + 1 service principal + 1 JSON config file. Much easier to maintain and safe to sync to oscarw-fab1.
