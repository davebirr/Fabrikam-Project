# 🏢 BAMI Tenant B Configuration
**Workshop Tenant for Teams B01-B10 (50 Participants)**

---

## 📋 **Tenant Details**

### **Basic Information**
- **Tenant Name**: `cs-agent-a-thon-tenant-b`
- **Domain**: `workshopb.onmicrosoft.com` (will be assigned by BAMI)
- **Participant Capacity**: 50 users
- **Fabrikam Instances**: B01 through B10
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
$TenantBParticipants = @(
    "participant051@microsoft.com",
    "participant052@microsoft.com",
    "participant053@microsoft.com"
    # ... up to participant100@microsoft.com
)

# Team assignments (5 participants per Fabrikam instance)
$TeamAssignments = @{
    "B01" = $TenantBParticipants[0..4]    # Team B01: Users 51-55
    "B02" = $TenantBParticipants[5..9]    # Team B02: Users 56-60
    "B03" = $TenantBParticipants[10..14]  # Team B03: Users 61-65
    "B04" = $TenantBParticipants[15..19]  # Team B04: Users 66-70
    "B05" = $TenantBParticipants[20..24]  # Team B05: Users 71-75
    "B06" = $TenantBParticipants[25..29]  # Team B06: Users 76-80
    "B07" = $TenantBParticipants[30..34]  # Team B07: Users 81-85
    "B08" = $TenantBParticipants[35..39]  # Team B08: Users 86-90
    "B09" = $TenantBParticipants[40..44]  # Team B09: Users 91-95
    "B10" = $TenantBParticipants[45..49]  # Team B10: Users 96-100
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

ForEach ($Team in @("B01","B02","B03","B04","B05","B06","B07","B08","B09","B10")) {
    For ($i = 1; $i -le 5; $i++) {
        $UserName = "team$Team-user$i@workshopb.onmicrosoft.com"
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
  - rg-fabrikam-b01-workshop
  - rg-fabrikam-b02-workshop
  - rg-fabrikam-b03-workshop
  - rg-fabrikam-b04-workshop
  - rg-fabrikam-b05-workshop
  - rg-fabrikam-b06-workshop
  - rg-fabrikam-b07-workshop
  - rg-fabrikam-b08-workshop
  - rg-fabrikam-b09-workshop
  - rg-fabrikam-b10-workshop

Shared Resources:
  - rg-fabrikam-shared-b
    - Azure Container Registry
    - Azure AI Foundry workspace
    - Azure OpenAI service
    - Azure Monitor workspace
```

### **Per-Instance Resources**
```yaml
Each Fabrikam Instance (B01-B10):
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
    - Workspace: law-fabrikam-shared-b
    
  Key Vault:
    - Name: kv-fabrikam-{instance}
    - Access Policies: Team-specific
```

---

## 🔧 **Copilot Studio Configuration**

### **Environment Setup**
```yaml
Copilot Studio Environment:
  Name: "cs-agent-a-thon-env-b"
  Region: "United States"
  Type: "Production"
  
Security Groups:
  - Workshop-Team-B01: Access to Fabrikam B01 instance
  - Workshop-Team-B02: Access to Fabrikam B02 instance
  - Workshop-Team-B03: Access to Fabrikam B03 instance
  # ... etc for B04-B10
  
Custom Connectors:
  - Fabrikam API Connector (per instance)
  - Fabrikam MCP Connector (per instance)
```

### **Team-Specific Access**
```powershell
# Configure Copilot Studio access per team
$Teams = @("B01","B02","B03","B04","B05","B06","B07","B08","B09","B10")

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
  Name: law-fabrikam-shared-b
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
Workshop Dashboard B:
  Widgets:
    - Instance Health Status (B01-B10)
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

## 🔄 **Load Balancing Strategy**

### **Cross-Tenant Distribution**
```yaml
Participant Distribution Strategy:
  Tenant A (Teams A01-A10): Participants 1-50
  Tenant B (Teams B01-B10): Participants 51-100
  
Benefits:
  - Risk Mitigation: Single tenant failure affects max 50 participants
  - Performance Isolation: Independent Azure subscriptions
  - Scaling Flexibility: Can adjust per-tenant based on usage
  - Administrative Separation: Different admin teams if needed
```

### **Regional Considerations**
```yaml
Deployment Regions:
  Tenant A: East US 2 (Primary)
  Tenant B: East US 2 (Consistency)
  
Reasoning:
  - Consistent latency for all participants
  - Single region reduces complexity
  - Azure OpenAI availability
  - Copilot Studio region alignment
```

---

## 🚀 **Deployment Checklist**

### **Pre-Workshop (1 Week Before)**
- [ ] BAMI tenant provisioned with M365 E5 licensing
- [ ] Azure subscription linked and configured
- [ ] B2B guest policies configured and tested
- [ ] Team security groups created (B01-B10)
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
- [ ] Send B2B guest invitations to participants 51-100
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

## 🔗 **Cross-Tenant Coordination**

### **Shared Resources**
```yaml
Common Elements:
  - Workshop Management Scripts
  - Monitoring Dashboards
  - Support Documentation
  - Cleanup Procedures
  
Tenant-Specific:
  - User Management
  - Instance Deployments
  - Access Permissions
  - Cost Tracking
```

### **Failover Strategy**
```yaml
If Tenant A Issues:
  - Redirect affected participants to Tenant B spare capacity
  - Use B11-B15 emergency instances if needed
  - Maintain team collaboration where possible
  
If Tenant B Issues:
  - Redirect affected participants to Tenant A spare capacity
  - Use A11-A15 emergency instances if needed
  - Preserve data and progress where possible
```

---

**Tenant B provides identical capabilities to Tenant A, ensuring consistent workshop experience for participants 51-100 across teams B01-B10! 🏢**