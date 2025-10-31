# 🔄 Multi-Environment CI/CD Strategy for Workshop

## 📋 Problem Statement

**Current Situation:**
- Repository forked from `oscarw-fab1/Fabrikam-Project`
- Active development in `davebirr/Fabrikam-Project`
- Need to manage multiple deployments:
  - Your development instance
  - Workshop proctor instance
  - Multiple team instances (potentially)
- Want to sync stable changes back to `oscarw-fab1` fork
- Don't want workflow files to break oscarw-fab1's setup

## ✅ Recommended Solution: Branch-Based GitHub Environments

### **Repository Structure**

```
oscarw-fab1/Fabrikam-Project (upstream)
    ↓ (you periodically sync from workshop-stable)
    |
davebirr/Fabrikam-Project (your fork)
    ├── main (your active development)
    │   └── Deploys to: fabrikam-*-development-tzjeje
    │
    ├── workshop-stable (stable releases for workshop)
    │   └── Deploys to: fabrikam-*-proctor-[suffix]
    │
    └── team-* (optional: separate team branches)
        └── Deploys to: fabrikam-*-team1-[suffix]
```

### **GitHub Environments Configuration**

Create these environments in your repository settings:

#### **Environment: `development`**
- **Purpose**: Your daily development work
- **Branch**: `main`
- **Secrets**:
  - `AZURE_API_PUBLISH_PROFILE` → fabrikam-api-development-tzjeje
  - `AZURE_MCP_PUBLISH_PROFILE` → fabrikam-mcp-development-tzjeje
  - `AZURE_SIM_PUBLISH_PROFILE` → fabrikam-sim-development-tzjeje
- **Variables**:
  - `AZURE_API_WEBAPP_NAME` = `fabrikam-api-development-tzjeje`
  - `AZURE_MCP_WEBAPP_NAME` = `fabrikam-mcp-development-tzjeje`
  - `AZURE_SIM_WEBAPP_NAME` = `fabrikam-sim-development-tzjeje`
  - `RESOURCE_GROUP` = `rg-fabrikam-dev`

#### **Environment: `workshop-proctor`**
- **Purpose**: Stable proctor instance for workshop
- **Branch**: `workshop-stable`
- **Secrets**:
  - `AZURE_API_PUBLISH_PROFILE` → fabrikam-api-proctor-[suffix]
  - `AZURE_MCP_PUBLISH_PROFILE` → fabrikam-mcp-proctor-[suffix]
  - `AZURE_SIM_PUBLISH_PROFILE` → fabrikam-sim-proctor-[suffix]
- **Variables**:
  - `AZURE_API_WEBAPP_NAME` = `fabrikam-api-proctor-[suffix]`
  - `AZURE_MCP_WEBAPP_NAME` = `fabrikam-mcp-proctor-[suffix]`
  - `AZURE_SIM_WEBAPP_NAME` = `fabrikam-sim-proctor-[suffix]`
  - `RESOURCE_GROUP` = `rg-agentathon-proctor`

## 🔧 Workflow File Strategy

### **Option A: Generic Workflows (Recommended)**

Replace environment-specific workflow files with generic ones that use GitHub Environments:

**Benefits**:
- ✅ Clean: One workflow per service (API, MCP, Simulator)
- ✅ Scalable: Add new environments without new workflow files
- ✅ Safe for upstream: oscarw-fab1 can sync without breaking his setup
- ✅ Flexible: Manual deployments to any environment

**Files to create**:
```
.github/workflows/
├── deploy-api.yml          # Generic API deployment
├── deploy-mcp.yml          # Generic MCP deployment  
├── deploy-simulator.yml    # Generic Simulator deployment
└── testing.yml            # Existing - runs on all branches
```

**Files to archive** (move to `.github/workflows/archive/`):
```
main_fabrikam-api-development-tzjeje.yml
main_fabrikam-mcp-development-tzjeje.yml
main_fabrikam-sim-development-tzjeje.yml
```

### **Option B: Separate Workshop Workflows (Alternative)**

Keep your existing dev workflows, add workshop-specific ones:

**Benefits**:
- ✅ Familiar: Your dev workflow stays unchanged
- ✅ Isolated: Workshop changes don't affect dev deployments
- ❌ More files: oscarw-fab1 inherits unused workflows
- ❌ Duplication: Similar logic in multiple files

**Files structure**:
```
.github/workflows/
├── main_fabrikam-api-development-tzjeje.yml  # Your dev (existing)
├── main_fabrikam-mcp-development-tzjeje.yml  # Your dev (existing)
├── main_fabrikam-sim-development-tzjeje.yml  # Your dev (existing)
├── workshop-api-proctor.yml                  # Workshop proctor (new)
├── workshop-mcp-proctor.yml                  # Workshop proctor (new)
├── workshop-sim-proctor.yml                  # Workshop proctor (new)
└── testing.yml                               # Runs on all branches
```

## 📝 Handling oscarw-fab1 Sync

### **Scenario: You sync workshop-stable to oscarw-fab1**

**What happens with workflows:**

#### **Option A (Generic Workflows)**:
1. oscarw-fab1 receives `deploy-api.yml`, `deploy-mcp.yml`, `deploy-simulator.yml`
2. Workflows won't run automatically (no environments configured in his repo)
3. He can:
   - Ignore them (they're harmless)
   - Delete them (clean up)
   - Configure his own environments if he wants to use them

**Add this to `.github/workflows/README.md`:**
```markdown
# Workshop Deployment Workflows

If you've synced from davebirr/Fabrikam-Project:

**For oscarw-fab1 (or other forks):**
- `deploy-*.yml` files are for workshop multi-environment deployments
- They require GitHub Environments configured (Settings → Environments)
- Safe to delete if you don't need multi-environment deployment
- Your existing deployment setup is unaffected

**For workshop facilitators:**
- See [WORKSHOP-DEPLOYMENT.md](../../docs/deployment/WORKSHOP-DEPLOYMENT.md)
```

#### **Option B (Separate Workflows)**:
1. oscarw-fab1 receives `workshop-*-proctor.yml` files
2. Workflows reference non-existent Azure resources in his subscription
3. He should delete `workshop-*.yml` files after sync
4. His existing workflows continue to work

**Add this to workflow files:**
```yaml
# NOTE: This workflow is specific to davebirr's workshop deployments
# If you've synced this from davebirr/Fabrikam-Project, you can safely delete it
# unless you're running your own workshop with similar infrastructure
```

## 🚀 Implementation Steps

### **Step 1: Create workshop-stable Branch**

```powershell
# From main branch
git checkout main
git pull origin main

# Create workshop-stable branch
git checkout -b workshop-stable
git push origin workshop-stable
```

### **Step 2: Configure GitHub Environments**

1. Go to your repository → Settings → Environments
2. Create `development` environment
   - Add secrets (publish profiles)
   - Add variables (webapp names, resource groups)
3. Create `workshop-proctor` environment
   - Add secrets for proctor Azure resources
   - Add variables for proctor webapp names

### **Step 3: Implement Chosen Workflow Strategy**

#### **For Option A (Generic Workflows)**:

1. Create `deploy-api.yml` using environment-based deployment
2. Create `deploy-mcp.yml` using environment-based deployment
3. Create `deploy-simulator.yml` using environment-based deployment
4. Archive old workflow files
5. Test deployments from both branches
6. Add `.github/workflows/README.md` explaining the setup

#### **For Option B (Separate Workflows)**:

1. Copy existing workflows to `workshop-*-proctor.yml`
2. Update app names and resource groups
3. Change trigger from `main` to `workshop-stable`
4. Add explanatory comments about workshop-specific nature
5. Test deployments

### **Step 4: Establish Sync Process**

```powershell
# When ready to sync stable changes to oscarw-fab1

# 1. Merge tested features from main to workshop-stable
git checkout workshop-stable
git merge main

# 2. Test workshop deployment
# Wait for GitHub Actions to deploy

# 3. Create PR to oscarw-fab1 (via GitHub UI)
# From: davebirr/Fabrikam-Project:workshop-stable
# To: oscarw-fab1/Fabrikam-Project:main
```

### **Step 5: Document for oscarw-fab1**

Create `.github/FORK-SYNC-NOTES.md`:
```markdown
# Notes for Fork Maintainers

This repository includes workshop-specific CI/CD workflows.

**If you've synced from davebirr/Fabrikam-Project:**

1. **Workflow Files**: Check `.github/workflows/README.md`
   - Some workflows may be workshop-specific
   - Safe to delete if you don't need them
   
2. **GitHub Environments**: Not required unless you want multi-environment deployment
   
3. **Azure Resources**: Workflows reference workshop-specific Azure resources
   - Won't affect your deployments (different environment)
   - Will fail gracefully if triggered without configuration

**Questions?** Contact davebirr or see docs/deployment/WORKSHOP-DEPLOYMENT.md
```

## 🎯 Recommendation

**Go with Option A (Generic Workflows)**

**Reasons:**
1. **Cleaner**: One workflow per service, not environment-specific files
2. **Scalable**: Easy to add team1, team2, etc. environments later
3. **Safer for upstream**: oscarw-fab1 gets generic files that won't conflict
4. **Professional**: Uses GitHub's intended multi-environment pattern
5. **Flexible**: Manual deployments to any environment via workflow_dispatch

**Trade-offs:**
- Requires one-time setup of GitHub Environments
- Slight learning curve for environment-based deployment
- More upfront work, but pays off long-term

## 📚 Additional Resources

**GitHub Documentation:**
- [Using environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Deployment branches and tags](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-branches-and-tags)

**Workshop-Specific Docs** (create these):
- `docs/deployment/WORKSHOP-DEPLOYMENT.md` - Complete deployment guide
- `docs/deployment/ENVIRONMENT-SETUP.md` - GitHub Environments configuration
- `.github/workflows/README.md` - Workflow file explanation

---

**Summary**: Use branch-based GitHub Environments (Option A) for clean, scalable multi-environment deployment that won't break oscarw-fab1's fork when you sync.
