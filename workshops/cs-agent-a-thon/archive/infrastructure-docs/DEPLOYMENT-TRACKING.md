# CS Agent-A-Thon Deployment Tracking

**Event Date**: October 31, 2025  
**Total Instances**: 21 (1 proctor + 20 teams)  
**Subscription**: cs-agent-a-thon (d3c2f651-1a5a-4781-94f3-460c4c4bffce)  
**Tenant**: fd268415-22a5-4064-9b5e-d039761c5971  
**Region**: West US 2

## Deployment Overview

All deployments use:
- **ARM Template**: `deployment/AzureDeploymentTemplate.modular.json`
- **Authentication Mode**: Disabled (workshop requirement)
- **Database Provider**: InMemory (workshop requirement)
- **SKU**: S1 (Standard tier)

## Proctor Instance (Master/Reference)

**Purpose**: Testing and reference instance for all 20 proctors

| Property | Value |
|----------|-------|
| **Resource Group** | `rg-agentathon-proctor` |
| **Base Name** | `fabrikam` |
| **Environment** | `proctor` |
| **Unique Suffix** | `tzjeje` |
| **API Endpoint** | https://fabrikam-api-development-tzjeje.azurewebsites.net |
| **MCP Endpoint** | https://fabrikam-mcp-development-tzjeje.azurewebsites.net |
| **Key Vault** | `kv-development-tzjeje` |
| **API Workflow** | `.github/workflows/main_fabrikam-api-development-tzjeje.yml` |
| **MCP Workflow** | `.github/workflows/main_fabrikam-mcp-development-tzjeje.yml` |
| **Deployment Date** | 2025-10-28 |
| **Status** | ✅ Active |

### Resources Created (9 total)
1. Log Analytics Workspace: `log-development-tzjeje`
2. Application Insights (API): `appi-api-development-tzjeje`
3. Application Insights (MCP): `appi-mcp-development-tzjeje`
4. App Service Plan (API): `plan-api-development-tzjeje`
5. App Service Plan (MCP): `plan-mcp-development-tzjeje`
6. App Service (API): `fabrikam-api-development-tzjeje`
7. App Service (MCP): `fabrikam-mcp-development-tzjeje`
8. Key Vault: `kv-development-tzjeje`
9. Action Group: `Application Insights Smart Detection`

### Proctor Access (20 Contributors)
- DAVIDB
- MERTUNAN
- KIRKDA
- APRILDELSING
- CDEPAEPE
- ESALVAREZ
- FRANVANH
- JIMBANACH
- JOWRIG
- MADERIDD
- MARIUSZO
- MABOAM
- MADAVI
- MIKEPALITTO
- OGORDON
- RAGNARPITLA
- RUNAUWEL
- SARAHBURG
- STSCHULZ
- ZASAEED

---

## Team Instances (20 total)

**Status**: 🔜 Pending deployment after proctor instance testing

| Team # | Resource Group | Unique Suffix | API Endpoint | MCP Endpoint | API Workflow | MCP Workflow | Status |
|--------|----------------|---------------|--------------|--------------|--------------|--------------|--------|
| 1 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 2 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 3 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 4 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 5 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 6 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 7 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 8 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 9 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 10 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 11 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 12 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 13 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 14 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 15 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 16 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 17 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 18 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 19 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |
| 20 | TBD | TBD | TBD | TBD | TBD | TBD | ⏳ Pending |

---

## Deployment Process Notes

### Proctor Instance Deployment
1. ✅ Created resource group: `rg-agentathon-proctor` in West US 2
2. ✅ Deployed ARM template via Azure CLI
3. ✅ Fixed Key Vault RBAC permissions for user (6b0e39f7-5639-4bba-8b8f-c3a0c9695f68)
4. ✅ Configured CI/CD via Azure Portal Deployment Center
5. ✅ Fixed generated workflows for monorepo structure
6. ⏳ Pending: Add 20 proctors as Contributors to resource group
7. ⏳ Pending: Test API and MCP endpoints after code deployment
8. ⏳ Pending: Validate AI agent integration

### Team Instance Deployment (Future)
1. Will deploy after proctor instance is validated
2. Plan to use GitHub Actions workflow with instance parameter
3. Each team gets dedicated resource group: `rg-agentathon-team-{number}`
4. Team members get Contributor access to their specific resource group only

---

## Key Learnings

### Issues Encountered
- ❌ Azure CLI local file deployment failed ("content already consumed" error)
- ❌ User Object ID from wrong tenant caused Key Vault role assignment failure
- ✅ Solution: Azure Portal Deployment Center for initial setup + manual Key Vault role fix

### Best Practices
- ✅ Always verify subscription and tenant before deployment
- ✅ Use User Object ID from correct tenant for Key Vault RBAC
- ✅ Portal-generated workflows need monorepo fixes (add project paths)
- ✅ Keep all 20 workshop instances in same subscription for easier management

---

## Next Steps

1. **Immediate** (Proctor Instance):
   - [ ] Commit and push workflow fixes
   - [ ] Wait for GitHub Actions deployment to complete
   - [ ] Test API endpoint: `/api/info`
   - [ ] Test MCP tools in GitHub Copilot
   - [ ] Add 20 proctors as Contributors

2. **This Week** (Before Friday):
   - [ ] Make API/MCP improvements
   - [ ] Test AI agent scenarios
   - [ ] Validate workshop exercises work
   - [ ] Collect proctor feedback

3. **After Testing** (Deploy 20 team instances):
   - [ ] Create deployment automation for team instances
   - [ ] Deploy all 20 team resource groups
   - [ ] Assign team members to their resource groups
   - [ ] Provide team-specific URLs to participants
