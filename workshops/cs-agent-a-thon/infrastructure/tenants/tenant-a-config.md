# ⚠️ **OBSOLETE - Reference Only**

**This file describes an older multi-tenant workshop design that is no longer being used.**

## 🔄 **Current Workshop Configuration**

The workshop now uses a **single unified tenant** instead of multiple BAMI tenants.

### **Active Configuration**
See the current tenant documentation: [TENANT-CONFIG.md](../TENANT-CONFIG.md)

**Current Tenant Details**:
- **Tenant ID**: `fd268415-22a5-4064-9b5e-d039761c5971`
- **Domain**: `levelupcspfy26cs01.onmicrosoft.com`
- **Participants**: 126 Microsoft employees (B2B guests)
- **Teams**: 21 teams
- **Approach**: B2B guest invitations (zero licensing cost)

### **🚨 CRITICAL: Copilot Studio Access URL**
```
https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
```

**Participants MUST use the tenant parameter to access the workshop tenant!**

---

# 🏢 ~~BAMI Tenant A Configuration~~ (OLD DESIGN)
**~~Workshop Tenant for Teams A01-A10 (50 Participants)~~**

> **Note**: This document is preserved for historical reference only. The workshop architecture changed from multiple BAMI tenants to a single unified tenant with B2B guest access.

---

## 📋 **Tenant Details**

### **Basic Information**
- **Tenant Name**: `cs-agent-a-thon-tenant-a`
- **Domain**: `workshopa.onmicrosoft.com` (will be assigned by BAMI)
- **Participant Capacity**: 50 users
- **Fabrikam Instances**: A01 through A10
- **Team Size**: 5 participants per instance

---

## 🔐 **Licensing Requirements**

### **M365 E5 Licensing (50 Users)**
```yaml
Required Licenses:
  Microsoft 365 E5: 50 seats
  
Included Features:
  - Copilot Studio: ✅ Premium features
  - Power Platform: ✅ Premium connectors
  - Azure Active Directory P2: ✅ Advanced identity features
  - Office 365 ProPlus: ✅ Full productivity suite
  - Exchange Online Plan 2: ✅ Email and calendar
  - SharePoint Online Plan 2: ✅ Team collaboration
  - Microsoft Teams: ✅ Communication platform
```

### **Additional Services**
```yaml
Azure Services:
  - Azure OpenAI Service: Pay-per-use
  - Azure AI Foundry: Included with Azure subscription
  - Application Insights: Basic tier included
  
Power Platform:
  - Power Apps: Included in E5
  - Power Automate: Included in E5
  - Dataverse: 2GB included per E5 user
```

---

## 🎯 **User Management Strategy**

### **B2B Guest Access (Primary Option)**
```powershell
# PowerShell script for B2B guest invitations
$TenantAParticipants = @(
    "participant001@microsoft.com",
    "participant002@microsoft.com",
    "participant003@microsoft.com"
    # ... up to 50 participants
)

# Team assignments (5 participants per Fabrikam instance)
$TeamAssignments = @{
    "A01" = $TenantAParticipants[0..4]    # Team A01: Users 1-5
    "A02" = $TenantAParticipants[5..9]    # Team A02: Users 6-10
    "A03" = $TenantAParticipants[10..14]  # Team A03: Users 11-15
    "A04" = $TenantAParticipants[15..19]  # Team A04: Users 16-20
    "A05" = $TenantAParticipants[20..24]  # Team A05: Users 21-25
    "A06" = $TenantAParticipants[25..29]  # Team A06: Users 26-30
    "A07" = $TenantAParticipants[30..34]  # Team A07: Users 31-35
    "A08" = $TenantAParticipants[35..39]  # Team A08: Users 36-40
    "A09" = $TenantAParticipants[40..44]  # Team A09: Users 41-45
    "A10" = $TenantAParticipants[45..49]  # Team A10: Users 46-50
}

# Invite guests and assign to teams
ForEach ($Team in $TeamAssignments.Keys) {
    $Members = $TeamAssignments[$Team]
    Write-Host "Inviting Team $Team members..."
    
    ForEach ($Member in $Members) {
        # Invite as B2B guest
        $Invitation = New-AzureADMSInvitation `
            -InvitedUserEmailAddress $Member `
            -InviteRedirectUrl "https://fabrikam-$Team.azurewebsites.net" `
            -InvitedUserDisplayName "Workshop Participant - Team $Team"
        
        # Add to team-specific security group
        Add-AzureADGroupMember `
            -ObjectId (Get-AzureADGroup -Filter "DisplayName eq 'Workshop-Team-$Team'").ObjectId `
            -RefObjectId $Invitation.InvitedUser.Id
    }
}
```

### **Native User Provisioning (Backup Option)**
```powershell
# Alternative: Create native tenant users
$Password = ConvertTo-SecureString "Workshop2025!" -AsPlainText -Force

ForEach ($Team in @("A01","A02","A03","A04","A05","A06","A07","A08","A09","A10")) {
    For ($i = 1; $i -le 5; $i++) {
        $UserName = "team$Team-user$i@workshopa.onmicrosoft.com"
        $DisplayName = "Workshop Participant - Team $Team User $i"
        
        New-AzureADUser `
            -UserPrincipalName $UserName `
            -Password $Password `
            -DisplayName $DisplayName `
            -MailNickName "team$Team-user$i" `
            -UsageLocation "US" `
            -AccountEnabled $true
        
        # Assign M365 E5 license
        Set-AzureADUserLicense `
            -ObjectId (Get-AzureADUser -Filter "UserPrincipalName eq '$UserName'").ObjectId `
            -AssignedLicenses @{
                AddLicenses = @("SPE_E5")  # M365 E5 SKU
                RemoveLicenses = @()
            }
    }
}
```

---

## 🏗️ **Azure Subscription Configuration**

### **Resource Groups (10 instances)**
```yaml
Resource Group Naming:
  - rg-fabrikam-a01-workshop
  - rg-fabrikam-a02-workshop
  - rg-fabrikam-a03-workshop
  - rg-fabrikam-a04-workshop
  - rg-fabrikam-a05-workshop
  - rg-fabrikam-a06-workshop
  - rg-fabrikam-a07-workshop
  - rg-fabrikam-a08-workshop
  - rg-fabrikam-a09-workshop
  - rg-fabrikam-a10-workshop

Shared Resources:
  - rg-fabrikam-shared-a
    - Azure Container Registry
    - Azure AI Foundry workspace
    - Azure OpenAI service
    - Azure Monitor workspace
```

### **Per-Instance Resources**
```yaml
Each Fabrikam Instance (A01-A10):
  App Service Plan:
    - Name: asp-fabrikam-{instance}-workshop
    - SKU: P1v2 (Linux)
    - Location: East US 2
    
  App Service (API):
    - Name: fabrikam-api-{instance}
    - Runtime: .NET 9.0
    - URL: https://fabrikam-api-{instance}.azurewebsites.net
    
  Container App (MCP):
    - Name: fabrikam-mcp-{instance}
    - Environment: cae-fabrikam-{instance}
    - URL: https://fabrikam-mcp-{instance}.eastus2.azurecontainerapps.io
    
  SQL Database:
    - Server: sql-fabrikam-{instance}
    - Database: FabrikamDb
    - Tier: Basic (5 DTU)
    - Backup: 7-day retention
    
  Application Insights:
    - Name: ai-fabrikam-{instance}
    - Workspace: law-fabrikam-shared-a
    
  Key Vault:
    - Name: kv-fabrikam-{instance}
    - Access Policies: Team-specific
```

---

## 🔧 **Copilot Studio Configuration**

### **Environment Setup**
```yaml
Copilot Studio Environment:
  Name: "cs-agent-a-thon-env-a"
  Region: "United States"
  Type: "Production"
  
Security Groups:
  - Workshop-Team-A01: Access to Fabrikam A01 instance
  - Workshop-Team-A02: Access to Fabrikam A02 instance
  - Workshop-Team-A03: Access to Fabrikam A03 instance
  # ... etc for A04-A10
  
Custom Connectors:
  - Fabrikam API Connector (per instance)
  - Fabrikam MCP Connector (per instance)
```

### **Team-Specific Access**
```powershell
# Configure Copilot Studio access per team
$Teams = @("A01","A02","A03","A04","A05","A06","A07","A08","A09","A10")

ForEach ($Team in $Teams) {
    # Create team-specific environment
    New-AdminPowerAppEnvironment `
        -DisplayName "Workshop-Team-$Team" `
        -Location "unitedstates" `
        -EnvironmentSku "Production"
    
    # Set up custom connector for team's Fabrikam instance
    $ConnectorConfig = @{
        DisplayName = "Fabrikam API - Team $Team"
        ApiDefinitionUrl = "https://fabrikam-api-$Team.azurewebsites.net/swagger/v1/swagger.json"
        IconUri = "https://fabrikam-api-$Team.azurewebsites.net/assets/logo.png"
    }
    
    # Grant team access to their specific environment
    New-AdminPowerAppRoleAssignment `
        -PrincipalType "Group" `
        -PrincipalObjectId (Get-AzureADGroup -Filter "DisplayName eq 'Workshop-Team-$Team'").ObjectId `
        -RoleName "Environment Admin" `
        -EnvironmentName "Workshop-Team-$Team"
}
```

---

## 📊 **Monitoring and Alerting**

### **Azure Monitor Configuration**
```yaml
Log Analytics Workspace:
  Name: law-fabrikam-shared-a
  Retention: 30 days
  Daily Cap: 5 GB
  
Alert Rules:
  - High CPU Usage: >80% for 10 minutes
  - High Memory Usage: >90% for 5 minutes
  - HTTP Error Rate: >5% for 2 minutes
  - Database Connection Failures: >3 in 5 minutes
  
Notification Groups:
  - Workshop Administrators
  - Technical Support Team
```

### **Application Insights Dashboards**
```yaml
Workshop Dashboard A:
  Widgets:
    - Instance Health Status (A01-A10)
    - Request Volume per Instance
    - Response Time Trends
    - Error Rate by Instance
    - User Activity Heatmap
    
Real-time Monitoring:
  - Live Metrics Stream
  - User Journey Analytics
  - Performance Counters
  - Custom Events Tracking
```

---

## 🚀 **Deployment Checklist**

### **Pre-Workshop (1 Week Before)**
- [ ] BAMI tenant provisioned with M365 E5 licensing
- [ ] Azure subscription linked and configured
- [ ] B2B guest policies configured and tested
- [ ] Team security groups created (A01-A10)
- [ ] Resource groups and naming conventions established
- [ ] Shared services deployed (ACR, AI Foundry, OpenAI)

### **Infrastructure Deployment (3 Days Before)**
- [ ] Deploy all 10 Fabrikam instances via automation
- [ ] Configure SQL databases with seed data
- [ ] Set up Application Insights monitoring
- [ ] Test instance isolation and connectivity
- [ ] Validate Copilot Studio environments
- [ ] Configure team-specific access permissions

### **User Onboarding (1 Day Before)**
- [ ] Send B2B guest invitations to all 50 participants
- [ ] Provide team assignment notifications
- [ ] Share instance URLs and access instructions
- [ ] Test participant login flow
- [ ] Verify Copilot Studio access per team
- [ ] Prepare technical support contact information

### **Workshop Day**
- [ ] Health check all instances (6:00 AM)
- [ ] Verify user access and permissions (7:00 AM)
- [ ] Enable workshop mode on business simulators (8:00 AM)
- [ ] Monitor instance performance throughout workshop
- [ ] Provide technical support as needed
- [ ] Collect usage metrics and feedback

### **Post-Workshop Cleanup**
- [ ] Export workshop analytics and metrics
- [ ] Backup any participant-created agents/data
- [ ] Revoke B2B guest access
- [ ] Deprovision all workshop resources
- [ ] Generate cost analysis report
- [ ] Document lessons learned for future workshops

---

**Tenant A is designed to provide a seamless, isolated workshop experience for 50 participants across 10 collaborative teams! 🏢**