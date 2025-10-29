h# 🚀 Quick Start: Deploy Proctor Instance NOW

**Time to complete: ~15 minutes**

---

## Step 1: Create Service Principal (5 minutes)

```powershell
# Login to workshop tenant
az login --tenant fd268415-22a5-4064-9b5e-d039761c5971

# Set your subscription
az account set --subscription "d3c2f651-1a5a-4781-94f3-460c4c4bffce"

# Create service principal
$sp = az ad sp create-for-rbac `
    --name "sp-fabrikam-workshop-deploy" `
    --role "Contributor" `
    --scopes "/subscriptions/d3c2f651-1a5a-4781-94f3-460c4c4bffce" `
    --output json

# Display result (SAVE THIS!)
$sp
```

**⚠️ COPY THE ENTIRE OUTPUT** - you need it for GitHub!

---

## Step 2: Deploy Proctor Infrastructure (7 minutes)

```powershell
# Navigate to workshop directory
cd c:\Users\davidb\1Repositories\Fabrikam-Project\workshops\cs-agent-a-thon\infrastructure\scripts

# Deploy proctor instance
.\Deploy-WorkshopInfrastructure.ps1 `
    -InstanceName "proctor" `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "d3c2f651-1a5a-4781-94f3-460c4c4bffce"
```

**Wait for deployment** (5-7 minutes). You'll get:
- Resource Group: `rg-agentathon-proctor`
- API URL: `https://fabrikam-api-proctor.azurewebsites.net`
- MCP URL: `https://fabrikam-mcp-proctor.azurewebsites.net`

---

## Step 3: Add GitHub Secret (2 minutes)

1. **Go to**: https://github.com/davebirr/Fabrikam-Project/settings/secrets/actions

2. **Click**: "New repository secret"

3. **Enter**:
   - Name: `AZURE_CREDENTIALS`
   - Value: (paste service principal JSON from Step 1)

4. **Click**: "Add secret"

---

## Step 4: Deploy Code via GitHub Actions (5 minutes)

1. **Go to**: https://github.com/davebirr/Fabrikam-Project/actions

2. **Click**: "Deploy Full Stack to Azure"

3. **Click**: "Run workflow"

4. **Select**:
   - Environment: `proctor`
   - Deploy FabrikamApi: ✅ Checked
   - Deploy FabrikamMcp: ✅ Checked

5. **Click**: "Run workflow"

**Monitor the workflow** - should be green in 5-10 minutes!

---

## Step 5: Test Deployment (1 minute)

```powershell
# Test API
Invoke-RestMethod https://fabrikam-api-proctor.azurewebsites.net/api/info

# Test sample data
Invoke-RestMethod https://fabrikam-api-proctor.azurewebsites.net/api/orders
```

**✅ If you see JSON data, you're done!**

---

## 🎉 Success! What You Have Now:

- ✅ **Working proctor instance** for 19 proctors to test
- ✅ **GitHub Actions CI/CD** configured for future deployments
- ✅ **Automated deployment pipeline** ready for 20 team instances

---

## 📧 Share with Proctors:

```
🎉 Proctor Testing Ready!

API: https://fabrikam-api-proctor.azurewebsites.net
MCP: https://fabrikam-mcp-proctor.azurewebsites.net

Test the API:
https://fabrikam-api-proctor.azurewebsites.net/api/orders

Please test and report issues by Friday!
```

---

## 🚀 After Friday: Deploy Team Instances

```powershell
# Deploy all 20 teams at once (100-140 minutes)
.\Deploy-WorkshopInfrastructure.ps1 `
    -DeployTeams `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "d3c2f651-1a5a-4781-94f3-460c4c4bffce"
```

---

**📖 Full Guide**: See `WORKSHOP-DEPLOYMENT-GUIDE.md` for complete details.

**❓ Questions?** Check:
- GitHub Actions logs for errors
- Azure Portal → Resource Group `rg-agentathon-proctor` for resources
- Application Insights for runtime issues
