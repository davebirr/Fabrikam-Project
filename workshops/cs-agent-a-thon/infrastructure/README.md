# 🏗️ cs-agent-a-thon Infrastructure Overview
**B2B Guest Workshop Environment for 126 Microsoft Employees**

---

## 📋 **Infrastructure Strategy**

### **🏢 Dual-Tenant Disaster Recovery Architecture**
```
Workshop Infrastructure (November 6, 2025):

PRIMARY TENANT (ACTIVE):
├── Tenant ID: fd268415-22a5-4064-9b5e-d039761c5971
├── Domain: levelupcspfy26cs01.onmicrosoft.com
├── Azure Subscription: Workshop-AgentAThon-Nov2025
├── B2B Guests: 126 Microsoft employees (@microsoft.com)
│   ├── 19 Proctors (Global Administrator role)
│   └── 107 Participants (Contributor on team RGs)
└── Resource Groups: 21 (rg-agentathon-team-01 through 21)

BACKUP TENANT (STANDBY):
├── Tenant ID: 26764e2b-92cb-448e-a938-16ea018ddc4c
├── Domain: TBD (will match primary pattern)
├── Azure Subscription: Workshop-AgentAThon-Nov2025-Backup
├── Configuration: Identical to primary tenant
└── Purpose: Emergency failover only (catastrophic failure scenarios)

Total: 21 team resource groups with full disaster recovery
```

### **🎯 Team Structure**
- **21 Teams** with 5-6 members each
- **19 Proctors** on dedicated proctor team
- **107 Participants** distributed across 20 participant teams
- **Team names**: Copilot Commanders, Prompt Pioneers, Agent Architects, etc.
- **Balanced experience distribution** across all teams
- **Zero licensing cost**: All participants use existing Microsoft licenses

---

## 🔧 **Technical Components**

### **Per Team Resource Group**
- **Azure AI Foundry Hub** - Centralized AI model access
- **Azure OpenAI Service** - GPT-4, GPT-4o model deployments
- **Azure App Service** - FabrikamApi hosting (Linux Standard S1)
- **Azure Container Apps** - FabrikamMcp server hosting
- **Azure SQL Database** - Business data (Basic tier)
- **Azure Key Vault** - Secrets and credential management
- **Azure Storage Account** - Blob storage for assets
- **Azure Application Insights** - Monitoring and telemetry

### **Shared Workshop Infrastructure**
- **Azure Monitor** - Cross-team health monitoring
- **Azure Log Analytics** - Centralized logging
- **Azure Virtual Network** - Network isolation and security
- **Azure DNS** - Custom domain management (optional)

### **Access URLs (Primary Tenant)**
- **Copilot Studio**: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
- **Azure Portal**: https://portal.azure.com
- **AI Foundry**: https://ai.azure.com

### **Disaster Recovery (Backup Tenant)**
- **Identical provisioning** in backup tenant 26764e2b-92cb-448e-a938-16ea018ddc4c
- **5-minute failover** for Copilot Studio outages
- **15-minute failover** for Azure subscription issues
- **30-minute failover** for complete tenant failure

---

## 👥 **B2B Guest Access Strategy**

### **Why B2B Guests?**
All 126 participants are **Microsoft employees with existing licenses**:
- ✅ **Zero licensing cost** - Use existing M365/Copilot/Copilot Studio licenses
- ✅ **Familiar authentication** - @microsoft.com accounts, no password distribution
- ✅ **Full Azure RBAC support** - Global Admin and Contributor roles work perfectly
- ✅ **Simplified management** - Invitation-based onboarding, easy cleanup
- ✅ **Production-realistic** - Mirrors real cross-tenant collaboration scenarios

### **B2B Guest Provisioning**
```powershell
# Automated invitation script
.\infrastructure\scripts\Invite-WorkshopUsers.ps1

# Process:
# 1. Reads MICROSOFT-ATTENDEES.md (126 participants)
# 2. Sends B2B invitations to @microsoft.com addresses
# 3. Assigns Global Administrator to 19 proctors
# 4. Assigns Contributor RBAC to 107 participants on team RGs
# 5. Sends email invitations automatically
```

### **Participant Experience**
1. **Accept B2B Invitation** - Email from Microsoft Invitations
2. **Bookmark Workshop URLs** - Copilot Studio with `?tenant=` parameter
3. **Access Azure Resources** - Switch tenant in Azure Portal top-right
4. **Start Building** - Full Copilot Studio access on workshop day

### **Security & Permissions**
- **Proctors**: Global Administrator in workshop tenant
- **Participants**: Contributor on assigned team resource group only
- **Isolation**: Teams cannot access other teams' resources
- **Audit**: All actions logged in Azure Activity Log

---

## 📊 **Cost Analysis**

### **Primary Tenant (Per Team Resource Group)**
```
Azure Services (21 teams × $18/day × 3 days):
- AI Foundry Hub: $5/day
- OpenAI Service (GPT-4): $3/day
- App Service (Standard S1): $4/day
- Container Apps: $2/day
- SQL Database (Basic): $2/day
- Storage Account: $1/day
- Application Insights: $0.50/day
- Key Vault: $0.50/day

Per Team Cost: ~$18/day
21 Teams × 3 days: $1,134
```

### **Backup Tenant (Disaster Recovery)**
```
Identical infrastructure for standby:
- Same 21 resource groups
- Same Azure service configuration
- Pre-provisioned but idle until failover
- Minimal usage cost (<$100 if unused)

Backup Tenant Cost: ~$100 (standby)
```

### **Licensing & Additional Services**
```
Licensing:
- B2B Guests: $0 (use existing Microsoft licenses) ✅
- Copilot Studio: $0 (included in participants' licenses) ✅
- Power Platform: $0 (included in participants' licenses) ✅

Operational:
- Azure OpenAI token usage: ~$200 estimated
- Data transfer: ~$50
- Monitoring & logs: ~$50

Additional Services: ~$300
```

### **Total Workshop Cost Estimate**
```
Primary Tenant Infrastructure: $1,134
Backup Tenant (standby): $100
Additional Services: $300
B2B Guest Licensing: $0 ✅

TOTAL: ~$1,534 (vs. original $9,600 native user estimate)
SAVINGS: $8,066 (83% cost reduction via B2B strategy)
```

---

## 🚀 **Deployment Strategy**

### **Phase 1: Dual-Tenant Provisioning (5 Days Before Workshop)**
```powershell
# Primary tenant provisioning
.\infrastructure\scripts\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionId "Workshop-AgentAThon-Nov2025"

# Backup tenant provisioning (identical configuration)
.\infrastructure\scripts\Provision-WorkshopB2B.ps1 `
    -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c" `
    -SubscriptionId "Workshop-AgentAThon-Nov2025-Backup"
```

**Tasks:**
1. **B2B Guest Invitations** - 126 Microsoft employees invited to both tenants
2. **Resource Group Creation** - 21 team RGs in each tenant
3. **RBAC Assignment** - Proctors get Global Admin, participants get Contributor
4. **Infrastructure Deployment** - Azure resources provisioned in all RGs
5. **Validation** - Test-WorkshopReadiness.ps1 confirms all systems operational

### **Phase 2: Pre-Workshop Validation (24 Hours Before)**
```powershell
# Primary tenant health check
.\infrastructure\scripts\Test-WorkshopReadiness.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971"

# Backup tenant health check
.\infrastructure\scripts\Test-WorkshopReadiness.ps1 `
    -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"
```

**Validation Checklist:**
- ✅ All 126 B2B invitations accepted
- ✅ 21 resource groups exist in both tenants
- ✅ All Azure services healthy in both tenants
- ✅ RBAC permissions verified for all users
- ✅ Copilot Studio accessible with tenant parameters
- ✅ Sample data loaded in all instances
- ✅ Monitoring dashboards configured

### **Phase 3: Workshop Day Operations**
1. **Primary Environment Active** - All participants use primary tenant URLs
2. **Backup Monitoring** - Proctors monitor backup tenant health every 4 hours
3. **Failover Ready** - Backup URLs prepared for emergency distribution
4. **Real-time Support** - Proctor team ready for disaster recovery activation

### **Phase 4: Post-Workshop Cleanup**
```powershell
# Remove B2B guests and delete resources
.\infrastructure\scripts\Remove-WorkshopResources.ps1 `
    -WhatIf  # Preview deletion
.\infrastructure\scripts\Remove-WorkshopResources.ps1 `
    -Confirm:$false  # Execute cleanup
```

**Cleanup includes:**
- Revoke all 126 B2B guest invitations
- Delete all 21 resource groups (both tenants)
- Remove RBAC role assignments
- Archive workshop logs and telemetry
- Cost analysis and reporting

---

## 📁 **Folder Structure**

```
infrastructure/
├── TENANT-CONFIG.md                  # Primary + Backup tenant configuration with DR
├── B2B-STRATEGY-UPDATE.md            # B2B guest approach rationale
├── README.md                         # This file - infrastructure overview
├── scripts/
│   ├── Provision-WorkshopB2B.ps1     # Master orchestrator for B2B provisioning
│   ├── Invite-WorkshopUsers.ps1      # B2B guest invitation automation
│   ├── New-TeamResourceGroups.ps1    # Create 21 team resource groups
│   ├── Grant-TeamAccess.ps1          # RBAC assignment for B2B guests
│   ├── Test-WorkshopReadiness.ps1    # Comprehensive validation script
│   └── Remove-WorkshopResources.ps1  # Post-workshop cleanup automation
└── tenants/
    └── tenant-a-config.md            # OBSOLETE - Old BAMI design (see TENANT-CONFIG.md)
```

**Key Documentation:**
- **TENANT-CONFIG.md** - Primary source for tenant details, DR procedures
- **B2B-STRATEGY-UPDATE.md** - Why we chose B2B over native users
- **../docs/MICROSOFT-ATTENDEES.md** - 126 participant roster
- **../docs/team-roster.md** - 21 team assignments
- **../docs/PARTICIPANT-QUICKSTART.md** - Participant onboarding guide

---

## 🎯 **Success Metrics**

### **Technical KPIs**
- **Primary Tenant Availability**: >99.9% uptime during workshop
- **Backup Tenant Readiness**: 100% failover capability (tested pre-workshop)
- **Failover Speed**: <5 min for Copilot Studio, <15 min for Azure, <30 min for full tenant
- **B2B Invitation Acceptance**: 100% of 126 participants by Day -1
- **Resource Provisioning**: All 21 resource groups operational in both tenants
- **API Response Times**: <2 seconds for FabrikamApi endpoints
- **MCP Tool Performance**: <3 seconds for Copilot Studio tool execution

### **Participant Experience**
- **Onboarding Speed**: <10 minutes from B2B invitation to Copilot Studio access
- **Team Collaboration**: 21 teams of 5-6 members on dedicated resources
- **Access Reliability**: Zero "wrong tenant" issues via bookmarked URLs
- **Support Ticket Volume**: <5% participants need technical assistance
- **Learning Outcomes**: 100% participants build functional AI agent

### **Disaster Recovery Metrics**
- **Backup Tenant Validation**: 100% health check pass 24h before workshop
- **Monitoring Frequency**: Health checks every 4 hours on workshop day
- **Proctor Readiness**: All 19 proctors trained on failover procedures
- **Communication Speed**: <2 minutes to distribute backup URLs if needed

### **Cost & Operational Goals**
- **Budget Adherence**: Stay within $1,600 total workshop budget
- **B2B Cost Savings**: $8,066 saved vs. native user licensing (83% reduction)
- **Cleanup Completion**: All resources decommissioned within 24 hours post-workshop
- **Audit Compliance**: Complete activity logs archived for 90 days

---

## 🚨 **Disaster Recovery Quick Reference**

### **Failure Scenarios & Recovery Times**

| Scenario | Detection | Recovery Action | RTO | Impact |
|----------|-----------|-----------------|-----|--------|
| Copilot Studio outage | Proctors notice 503 errors | Switch to backup URL | 5 min | Minimal - just URL change |
| Azure subscription quota | Deployment failures | Activate backup subscription | 15 min | Low - proctors handle |
| Complete tenant failure | All services down | Full failover to backup | 30 min | Moderate - coordinated switch |

### **Emergency Failover Commands**
```powershell
# Proctor command - activate backup tenant
Announce-Failover -BackupTenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"

# Participants switch to backup URLs:
# Copilot Studio: https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c
```

---

**This B2B dual-tenant infrastructure provides enterprise-grade reliability for 126 Microsoft employees while achieving 83% cost savings through intelligent license reuse! 🏗️✅**

---

**Primary Tenant**: fd268415-22a5-4064-9b5e-d039761c5971 | **Backup Tenant**: 26764e2b-92cb-448e-a938-16ea018ddc4c