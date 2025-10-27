# 🏗️ cs-agent-a-thon Infrastructure Overview
**Multi-Tenant Workshop Environment for 100 Participants**

---

## 📋 **Infrastructure Strategy**

### **🏢 Tenant Architecture**
```
Workshop Infrastructure:
├── BAMI Tenant A (50 participants)
│   ├── Azure Subscription A
│   ├── M365 E5 Licensing (50 users)
│   └── Fabrikam Instances: A01-A10 (5 participants each)
│
└── BAMI Tenant B (50 participants)
    ├── Azure Subscription B
    ├── M365 E5 Licensing (50 users)
    └── Fabrikam Instances: B01-B10 (5 participants each)

Total: 20 Fabrikam instances across 2 tenants
```

### **🎯 Team Structure**
- **20 Teams** of 5 participants each
- **Small team collaboration** on shared customer service scenarios
- **Instance isolation** prevents cross-team interference
- **Tenant redundancy** ensures workshop continuity

---

## 🔧 **Technical Components**

### **Per Fabrikam Instance**
- **FabrikamApi** - ASP.NET Core Web API with business simulator
- **FabrikamMcp** - Model Context Protocol server
- **Azure App Service** - API hosting (Linux Premium v2 P1)
- **Azure Container Apps** - MCP server hosting
- **Azure SQL Database** - Business data (Basic tier)
- **Azure Application Insights** - Monitoring and telemetry
- **Azure Key Vault** - Secrets management

### **Per Azure Subscription**
- **10 Resource Groups** (one per Fabrikam instance)
- **Shared Azure AI Foundry** - Model access for all teams
- **Shared Azure OpenAI** - GPT-4 model deployment
- **Azure Monitor** - Cross-instance monitoring
- **Azure Container Registry** - Shared container images

### **Per BAMI Tenant**
- **M365 E5 Licensing** - Full feature access
- **Copilot Studio** - Available to all users
- **Power Platform** - Premium connectors enabled
- **Entra ID** - User management and B2B guest access
- **SharePoint/Teams** - Team collaboration spaces

---

## 👥 **User Access Strategy**

### **Option A: B2B Guest Access (Preferred for Testing)**
```powershell
# Test B2B guest invitation
$GuestEmail = "participant@microsoft.com"
$InviteResult = New-AzureADMSInvitation -InvitedUserEmailAddress $GuestEmail `
    -InviteRedirectUrl "https://teams.microsoft.com" `
    -InvitedUserDisplayName "Workshop Participant"

# Assign to specific team/instance group
```

**Pros:**
- ✅ Uses existing @microsoft.com accounts
- ✅ No password management needed
- ✅ Familiar authentication experience
- ✅ Easier cleanup post-workshop

**Cons:**
- ❓ Potential permission limitations
- ❓ External user restrictions in Copilot Studio
- ❓ Cross-tenant access complexity

### **Option B: Provisioned Users**
```powershell
# Create workshop-specific users
$Users = @(
    "fabrikam-team01-user1@workshoptenant.onmicrosoft.com",
    "fabrikam-team01-user2@workshoptenant.onmicrosoft.com"
    # ... etc
)

ForEach ($User in $Users) {
    New-AzureADUser -UserPrincipalName $User `
        -Password $DefaultPassword `
        -DisplayName "Workshop Participant"
}
```

**Pros:**
- ✅ Full native tenant permissions
- ✅ Complete Copilot Studio access
- ✅ No external user limitations
- ✅ Simplified permission management

**Cons:**
- ❌ Password distribution complexity
- ❌ User account management overhead
- ❌ Cleanup requirements post-workshop

---

## 📊 **Resource Planning**

### **Cost Estimation (Per Instance)**
```
Azure Services:
- App Service (Linux P1): $54/month × 0.25 = $13.50
- Container Apps: $10/month × 0.25 = $2.50
- SQL Database (Basic): $5/month × 0.25 = $1.25
- Application Insights: $2/month × 0.25 = $0.50
- Key Vault: $1/month × 0.25 = $0.25

Per Instance Cost: ~$18/day
Total 20 Instances: ~$360/day
Workshop Duration: 1 day + 2 setup days = $1,080
```

### **Licensing Requirements**
```
M365 E5 Licensing:
- 100 participants × $38/month × 0.1 (3 days) = $380
- Copilot Studio: Included in E5
- Power Platform Premium: Included in E5
- Azure OpenAI: Pay-per-use (~$200 estimated)

Total Licensing: ~$580
```

### **Total Workshop Cost Estimate: ~$1,660**

---

## 🚀 **Deployment Strategy**

### **Phase 1: Tenant Preparation (Week -2)**
1. **BAMI Tenant Provisioning**
   - Request 2 BAMI tenants with Azure subscriptions
   - Configure M365 E5 licensing (50 users each)
   - Set up Entra ID B2B policies
   - Configure Copilot Studio environments

2. **User Management Setup**
   - Test B2B guest access with @microsoft.com accounts
   - Create user provisioning scripts (backup plan)
   - Set up team assignment strategy
   - Configure SharePoint team sites

### **Phase 2: Infrastructure Deployment (Week -1)**
1. **Azure Resource Deployment**
   - Deploy 20 Fabrikam instances via ARM/Bicep templates
   - Configure Azure AI Foundry with shared models
   - Set up monitoring and alerting
   - Test instance isolation and performance

2. **Application Configuration**
   - Deploy FabrikamApi with business simulator enabled
   - Configure MCP servers with workshop settings
   - Load realistic seed data
   - Test cross-instance independence

### **Phase 3: Workshop Day Setup (Day -1)**
1. **Final Validation**
   - Health check all 20 instances
   - Verify user access and permissions
   - Test Copilot Studio connectivity
   - Prepare instance assignment sheets

2. **Team Assignment**
   - Distribute participants across teams (5 per instance)
   - Provide instance-specific URLs and credentials
   - Set up team collaboration spaces
   - Enable workshop monitoring

---

## 📁 **Folder Structure**

```
infrastructure/
├── tenants/
│   ├── tenant-a-config.md          # BAMI Tenant A configuration
│   ├── tenant-b-config.md          # BAMI Tenant B configuration
│   └── user-management.md          # B2B vs native user strategies
├── deployment/
│   ├── bicep/                      # Infrastructure as Code templates
│   ├── arm-templates/              # Alternative ARM templates
│   └── configuration/              # App settings and configs
├── scripts/
│   ├── provision-tenants.ps1       # Tenant setup automation
│   ├── deploy-instances.ps1        # Fabrikam instance deployment
│   ├── manage-users.ps1            # User provisioning/management
│   └── cleanup-workshop.ps1        # Post-workshop cleanup
└── monitoring/
    ├── health-checks.ps1           # Pre-workshop validation
    ├── workshop-dashboard.md       # Monitoring strategy
    └── troubleshooting.md          # Common issues and solutions
```

---

## 🎯 **Success Metrics**

### **Technical KPIs**
- **Instance Availability**: >99% uptime during workshop
- **Response Times**: <2 seconds for API calls
- **User Experience**: <30 seconds from login to agent building
- **Isolation**: Zero cross-team data contamination

### **Participant Experience**
- **Team Collaboration**: 5 participants per shared instance
- **Scenario Variety**: Fresh customer service issues per team
- **Technology Access**: Full Copilot Studio + Azure AI capabilities
- **Learning Outcomes**: Working AI agent per participant

### **Operational Goals**
- **Seamless Setup**: Participants productive within 10 minutes
- **Minimal Support**: <5% participants need technical assistance
- **Clean Teardown**: All resources decommissioned within 24 hours
- **Cost Control**: Stay within $2,000 total workshop budget

---

**This infrastructure strategy provides a robust, scalable foundation for delivering an outstanding workshop experience to 100 participants across 20 collaborative teams! 🏗️**