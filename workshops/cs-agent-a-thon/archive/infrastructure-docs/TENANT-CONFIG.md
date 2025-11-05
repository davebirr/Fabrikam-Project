# 🔐 Workshop Tenant Configuration
**Primary + Backup Tenant Details for Disaster Recovery**

## Primary Tenant (Active)

| Property | Value |
|----------|-------|
| **Tenant ID** | `fd268415-22a5-4064-9b5e-d039761c5971` |
| **Tenant Domain** | `levelupcspfy26cs01.onmicrosoft.com` |
| **Primary Domain** | `fabrikam1.csplevelup.com` |
| **Workshop Date** | November 6, 2025 |
| **Purpose** | CS Agent-A-Thon Workshop Environment (Primary) |
| **Status** | ✅ **ACTIVE** |

## Backup Tenant (Disaster Recovery)

| Property | Value |
|----------|-------|
| **Tenant ID** | `26764e2b-92cb-448e-a938-16ea018ddc4c` |
| **Tenant Domain** | TBD (will match primary pattern) |
| **Primary Domain** | TBD |
| **Workshop Date** | November 6, 2025 |
| **Purpose** | CS Agent-A-Thon Workshop Environment (Backup/DR) |
| **Status** | ⚠️ **STANDBY** - Use only if primary tenant fails |

> **Disaster Recovery Strategy**: Backup tenant will be provisioned identically to primary tenant. In case of catastrophic failure, participants can be redirected to backup tenant URLs.

## 🚨 **CRITICAL: Workshop Access URLs**

### **Primary Tenant** (Use by Default)

| Service | Access URL | Notes |
|---------|------------|-------|
| **Copilot Studio** | `https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971` | ⚠️ **MUST use tenant parameter** |
| **Azure Portal** | `https://portal.azure.com` | Switch to `levelupcspfy26cs01` tenant |
| **AI Foundry** | `https://ai.azure.com` | Switch to workshop subscription |

### **Backup Tenant** (Emergency Only)

| Service | Access URL | Notes |
|---------|------------|-------|
| **Copilot Studio** | `https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c` | ⚠️ **Use only if directed by proctors** |
| **Azure Portal** | `https://portal.azure.com` | Switch to backup tenant (TBD domain) |
| **AI Foundry** | `https://ai.azure.com` | Switch to backup subscription |

> **Important**: Participants MUST use the tenant-specific Copilot Studio URL above. Without the `?tenant=` parameter, they will access their home tenant instead of the workshop tenant.
>
> **Failover Procedure**: In case of primary tenant issues, proctors will announce backup tenant URLs to all participants.

## User Provisioning Strategy

### Proctors (19 users)
- **Role**: Global Administrator
- **Purpose**: Full tenant management, troubleshooting, participant support
- **Access**: All Azure subscriptions, all resource groups
- **Licenses**: Microsoft 365 E5 Developer

### Participants (107 users)
- **Role**: User + Custom RBAC roles
- **Purpose**: Workshop challenge completion
- **Access**: Team-specific resource group (Contributor)
- **Licenses**: Microsoft 365 E5 Developer

## Azure Resource Structure

### Subscription Organization
- **Primary Subscription**: Workshop-AgentAThon-Nov2025
- **Resource Groups**: One per team (20 total)
- **Naming Convention**: `rg-agentathon-team-{number}`

### Team Resource Groups

| Team # | Team Name | Resource Group | Members (Contributor) |
|--------|-----------|----------------|----------------------|
| 1 | Copilot Commanders | rg-agentathon-team-01 | 6 members |
| 2 | Prompt Pioneers | rg-agentathon-team-02 | 6 members |
| 3 | Agent Architects | rg-agentathon-team-03 | 5 members |
| 4 | Semantic Samurai | rg-agentathon-team-04 | 5 members |
| 5 | MCP Mavericks | rg-agentathon-team-05 | 6 members |
| 6 | Orchestration Ninjas | rg-agentathon-team-06 | 5 members |
| 7 | AutoGen Avengers | rg-agentathon-team-07 | 6 members |
| 8 | LangChain Legends | rg-agentathon-team-08 | 5 members |
| 9 | Agentic Alchemists | rg-agentathon-team-09 | 6 members |
| 10 | RAG Raiders | rg-agentathon-team-10 | 5 members |
| 11 | Workflow Wizards | rg-agentathon-team-11 | 6 members |
| 12 | Context Champions | rg-agentathon-team-12 | 5 members |
| 13 | Intelligent Integrators | rg-agentathon-team-13 | 6 members |
| 14 | Prompt Perfectionists | rg-agentathon-team-14 | 5 members |
| 15 | Cognitive Crafters | rg-agentathon-team-15 | 6 members |
| 16 | Reasoning Rebels | rg-agentathon-team-16 | 5 members |
| 17 | Function Fanatics | rg-agentathon-team-17 | 6 members |
| 18 | Schema Sherpas | rg-agentathon-team-18 | 5 members |
| 19 | Response Rockstars | rg-agentathon-team-19 | 6 members |
| 20 | Action Architects | rg-agentathon-team-20 | 5 members |
| 21 | Completion Crusaders | rg-agentathon-team-21 | 6 members |

## Required Azure Resources per Team

Each team resource group will contain:
- **Azure AI Foundry Workspace**
- **Azure OpenAI Service** (GPT-4, GPT-4o)
- **Azure App Service Plan** (for Fabrikam API deployment)
- **Azure Container Apps** (for MCP server)
- **Azure SQL Database** (Fabrikam business data)
- **Azure Key Vault** (secrets management)
- **Azure Application Insights** (monitoring)
- **Azure Storage Account** (data and logs)

## Security & Access Model

### Entra ID Roles

**Proctors**:
- Global Administrator (tenant-wide)
- Azure Subscription Owner (all resource groups)

**Participants**:
- User (basic tenant access)
- Contributor (team resource group only)
- Cognitive Services OpenAI User (Azure OpenAI access)
- App Configuration Data Owner (workshop configuration)

### Network Security
- **Public Access**: Enabled for workshop duration
- **IP Restrictions**: None (global Microsoft network)
- **Authentication**: Entra ID required for all services
- **MFA**: Optional (Microsoft employee accounts)

## Automation Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `Provision-WorkshopTenant.ps1` | Master provisioning orchestrator | `infrastructure/scripts/` |
| `Add-WorkshopProctors.ps1` | Provision proctor accounts | `infrastructure/scripts/` |
| `Add-WorkshopParticipants.ps1` | Provision participant accounts | `infrastructure/scripts/` |
| `New-TeamResourceGroups.ps1` | Create team Azure resource groups | `infrastructure/scripts/` |
| `Deploy-TeamInfrastructure.ps1` | Deploy Azure resources per team | `infrastructure/scripts/` |
| `Grant-TeamAccess.ps1` | Assign RBAC permissions | `infrastructure/scripts/` |
| `Test-WorkshopReadiness.ps1` | Validate all provisioning | `infrastructure/scripts/` |
| `Remove-WorkshopResources.ps1` | Clean up after workshop | `infrastructure/scripts/` |

## Cost Estimation

### Per Team Resources (20 teams)
- Azure AI Foundry: ~$50/day
- Azure OpenAI (GPT-4): ~$100/day (workshop usage)
- App Service Plan (B2): ~$3/day
- Container Apps: ~$2/day
- SQL Database (Basic): ~$0.17/day
- Storage & misc: ~$5/day

**Total per team**: ~$160/day  
**Total for 20 teams**: ~$3,200/day  
**Workshop duration**: 1 day (with 2-day buffer for testing)  
**Estimated total cost**: ~$9,600 (including pre-workshop testing)

## Provisioning Timeline

### Day 1 (Nov 1 - 5 days before workshop)
- ✅ Create tenant users (proctors + participants)
- ✅ Assign Global Admin roles to proctors
- ✅ Create Azure subscription
- ✅ Create 20 team resource groups

### Day 2 (Nov 2 - 4 days before workshop)
- ✅ Deploy Azure AI Foundry workspaces (20 instances)
- ✅ Deploy Azure OpenAI services (20 instances)
- ✅ Configure model deployments (GPT-4, GPT-4o)

### Day 3 (Nov 3 - 3 days before workshop)
- ✅ Deploy Fabrikam API (20 instances)
- ✅ Deploy MCP servers (20 instances)
- ✅ Configure databases with sample data
- ✅ Assign team RBAC permissions

### Day 4 (Nov 4 - 2 days before workshop)
- ✅ Test all team environments
- ✅ Validate participant access
- ✅ Create access documentation
- ✅ Prepare proctor runbooks

### Day 5 (Nov 5 - 1 day before workshop)
- ✅ Final validation and smoke tests
- ✅ Proctor walkthrough and training
- ✅ Backup and disaster recovery prep

## Post-Workshop Cleanup (Nov 7)
- Remove participant access (keep accounts for 30 days)
- Delete team resource groups
- Archive workshop data and learnings
- Export cost analysis and metrics
- Preserve proctor access for documentation

---

## 🔄 **Disaster Recovery Procedures**

### Pre-Workshop Preparation
1. **Provision Both Tenants Identically**
   ```powershell
   # Primary tenant
   .\Provision-WorkshopB2B.ps1 -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" -SubscriptionName "Workshop-AgentAThon-Nov2025"
   
   # Backup tenant (identical configuration)
   .\Provision-WorkshopB2B.ps1 -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c" -SubscriptionName "Workshop-AgentAThon-Nov2025-Backup"
   ```

2. **Sync Data Between Tenants**
   - Same B2B guest invitations (both tenants)
   - Identical Azure resource configurations
   - Same Fabrikam API/MCP deployments
   - Synchronized sample data

3. **Test Both Environments**
   - Validate primary tenant access
   - Validate backup tenant access
   - Test failover procedures with sample users

### Failure Scenarios & Response

#### Scenario 1: Copilot Studio Outage (Primary Tenant)
**Detection**: Participants cannot access Copilot Studio with primary URL

**Response**:
1. Proctors announce failover to backup tenant
2. Share backup Copilot Studio URL: `https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c`
3. Participants switch to backup tenant (same @microsoft.com login)
4. Continue workshop on backup infrastructure

**Recovery Time**: < 5 minutes (URL change only)

#### Scenario 2: Azure Subscription Issues
**Detection**: Resource groups unavailable, API endpoints down

**Response**:
1. Verify backup subscription is healthy
2. Update workshop materials with backup endpoints
3. Redirect participants to backup Fabrikam instances
4. Monitor backup subscription performance

**Recovery Time**: < 15 minutes (DNS/endpoint updates)

#### Scenario 3: Complete Tenant Failure
**Detection**: Cannot authenticate, global tenant issues

**Response**:
1. **IMMEDIATE**: Announce switch to backup tenant
2. Distribute backup access URLs to all participants
3. Proctors verify backup tenant accessibility
4. Resume workshop on backup tenant

**Recovery Time**: < 30 minutes (full tenant switch)

### Failover Communication Template

```markdown
🚨 WORKSHOP ANNOUNCEMENT 🚨

We are experiencing technical issues with the primary workshop environment.
Please switch to the BACKUP environment using these URLs:

Copilot Studio (BACKUP):
https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c

Azure Portal:
https://portal.azure.com
(Switch to backup tenant in top-right)

Your @microsoft.com login credentials remain the same.
Your team assignments are unchanged.

Thank you for your patience!
```

### Backup Tenant Monitoring
- **Health Checks**: Every 4 hours before workshop
- **Validation**: Full environment test 24 hours before event
- **Standby Mode**: Backup tenant kept warm on workshop day
- **Cost**: Backup tenant runs minimal resources until activated

---

**Configuration managed by**: David Bjurman-Birr (DAVIDB)  
**Last updated**: October 27, 2025  
**Disaster Recovery**: Backup tenant `26764e2b-92cb-448e-a938-16ea018ddc4c` available