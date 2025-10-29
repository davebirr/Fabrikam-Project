# 🚨 Proctor Disaster Recovery Runbook
**Emergency Failover Procedures for November 6, 2025 Workshop**

---

## 🎯 **Overview**

This runbook provides step-by-step disaster recovery procedures for the 19 workshop proctors. As a proctor, you have **Global Administrator** access in both the primary and backup tenants, giving you the authority to execute emergency failover procedures if catastrophic failures occur.

---

## 🏢 **Tenant Information**

### **Primary Tenant (ACTIVE)**
```
Tenant ID: fd268415-22a5-4064-9b5e-d039761c5971
Domain: levelupcspfy26cs01.onmicrosoft.com
Subscription: Workshop-AgentAThon-Nov2025
Status: ACTIVE (participants use by default)
```

### **Backup Tenant (STANDBY)**
```
Tenant ID: 26764e2b-92cb-448e-a938-16ea018ddc4c
Domain: TBD (will match primary pattern)
Subscription: Workshop-AgentAThon-Nov2025-Backup
Status: STANDBY (emergency use only)
```

---

## 📊 **Monitoring Dashboard**

### **Pre-Workshop Health Checks** (Every 4 Hours)

**Primary Tenant:**
```powershell
# Run from PowerShell as Global Admin
Connect-AzAccount -TenantId "fd268415-22a5-4064-9b5e-d039761c5971"

# Check resource groups
Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "rg-agentathon-team-*" } | Select-Object ResourceGroupName, ProvisioningState

# Check Copilot Studio access
Start-Process "https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971"

# Validate B2B guests
.\infrastructure\scripts\Test-WorkshopReadiness.ps1
```

**Backup Tenant:**
```powershell
# Switch to backup tenant
Connect-AzAccount -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"

# Verify identical configuration
Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "rg-agentathon-team-*" } | Select-Object ResourceGroupName, ProvisioningState

# Test Copilot Studio backup access
Start-Process "https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a038-16ea018ddc4c"
```

---

## 🚨 **Failure Scenarios & Recovery Procedures**

### **Scenario 1: Copilot Studio Outage** 🔴
**Recovery Time Objective (RTO): 5 minutes**

#### **Symptoms:**
- Participants report "503 Service Unavailable" in Copilot Studio
- Cannot create or edit agents
- Tools not responding in Copilot interface

#### **Diagnosis:**
```powershell
# Test primary Copilot Studio
Test-NetConnection copilotstudio.microsoft.com -Port 443

# Check Azure Service Health
Get-AzureADServiceHealth | Where-Object { $_.Service -eq "CopilotStudio" }
```

#### **Recovery Steps:**
1. **Announce Failover** (Proctor Lead):
   ```markdown
   🚨 ATTENTION ALL PARTICIPANTS 🚨
   
   We are experiencing issues with Copilot Studio in the primary environment.
   Please switch to the backup environment immediately:
   
   NEW COPILOT STUDIO URL:
   https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c
   
   Bookmark this URL and refresh your browser.
   All your work is preserved in the backup tenant.
   ```

2. **Verify Backup Accessibility**:
   - All proctors test backup Copilot Studio URL
   - Confirm participants can access backup environment
   - Monitor Teams chat for participant issues

3. **Document Incident**:
   ```powershell
   # Log failover event
   Add-Content -Path ".\workshop-incident-log.txt" -Value @"
   [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FAILOVER EXECUTED
   Scenario: Copilot Studio Outage (Primary Tenant)
   Action: Switched all participants to backup tenant
   Backup Tenant ID: 26764e2b-92cb-448e-a938-16ea018ddc4c
   Proctor: $env:USERNAME
   "@
   ```

---

### **Scenario 2: Azure Subscription Quota Exceeded** 🟡
**Recovery Time Objective (RTO): 15 minutes**

#### **Symptoms:**
- "Quota exceeded" errors when deploying resources
- Participants cannot create new Azure resources
- Existing resources work but scaling fails

#### **Diagnosis:**
```powershell
# Check quota usage
Connect-AzAccount -TenantId "fd268415-22a5-4064-9b5e-d039761c5971"
Get-AzVMUsage -Location "eastus" | Where-Object { $_.CurrentValue -ge ($_.Limit * 0.9) }

# Check OpenAI quota
Get-AzCognitiveServicesAccountUsage -ResourceGroupName "rg-agentathon-team-01"
```

#### **Recovery Steps:**
1. **Request Emergency Quota Increase**:
   ```powershell
   # Create support ticket
   New-AzSupportTicket `
       -Name "Workshop Emergency Quota" `
       -Severity "A" `
       -ProblemClassificationId "/providers/Microsoft.Support/services/quota" `
       -Title "Agent-A-Thon Workshop - Emergency Quota Increase"
   ```

2. **Activate Backup Subscription** (if quota increase > 30 min):
   ```powershell
   # Switch participants to backup subscription
   Connect-AzAccount -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"
   
   # Verify backup subscription has capacity
   Get-AzVMUsage -Location "eastus"
   ```

3. **Announce Subscription Switch**:
   ```markdown
   📢 ATTENTION ALL PARTICIPANTS 📢
   
   We are switching to our backup Azure subscription due to capacity limits.
   
   ACTION REQUIRED:
   1. Log out of Azure Portal
   2. Log back in at: https://portal.azure.com
   3. Switch directory to backup tenant (top-right dropdown)
   4. Your team resource group name remains the same
   
   Copilot Studio URL UNCHANGED - no action needed there.
   ```

---

### **Scenario 3: Complete Tenant Failure** 🔴🔴🔴
**Recovery Time Objective (RTO): 30 minutes**

#### **Symptoms:**
- Cannot authenticate to primary tenant
- All Azure services unreachable
- Copilot Studio returns authentication errors
- Azure Portal shows "Tenant not found"

#### **Diagnosis:**
```powershell
# Test tenant reachability
Connect-AzAccount -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" -ErrorAction SilentlyContinue

if ($Error[0] -match "AADSTS50034") {
    Write-Host "🚨 PRIMARY TENANT DOWN - FULL FAILOVER REQUIRED" -ForegroundColor Red
}

# Verify backup tenant health
Connect-AzAccount -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"
.\infrastructure\scripts\Test-WorkshopReadiness.ps1
```

#### **Recovery Steps:**
1. **Proctor Leadership Coordination**:
   - Designate **Proctor Lead** to coordinate failover
   - All 19 proctors join emergency Teams call
   - Confirm backup tenant 100% operational before announcement

2. **Full Failover Announcement**:
   ```markdown
   🚨🚨🚨 CRITICAL ANNOUNCEMENT - ALL PARTICIPANTS 🚨🚨🚨
   
   We are experiencing a complete outage of the primary workshop environment.
   We are activating our backup environment NOW.
   
   IMMEDIATE ACTION REQUIRED:
   
   1. COPILOT STUDIO - Use this NEW URL:
      https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c
      (BOOKMARK THIS - Do NOT use old URL)
   
   2. AZURE PORTAL:
      - Log out completely
      - Log in at: https://portal.azure.com
      - Top-right: Switch directory to backup tenant
      - Your team resource group name is UNCHANGED
   
   3. AI FOUNDRY:
      - https://ai.azure.com
      - Verify you see your team's resources
   
   All your work is preserved. Backup environment is fully operational.
   Proctors are available for assistance.
   
   Workshop will resume in 10 minutes - please test your access now.
   ```

3. **Participant Validation** (All 19 Proctors):
   - Each proctor checks in with assigned teams
   - Verify every participant can access backup environment
   - Document any participants with access issues
   - Assist with directory switching in Azure Portal

4. **Incident Documentation**:
   ```powershell
   # Comprehensive incident report
   $IncidentReport = @{
       Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
       Scenario = "Complete Tenant Failure"
       PrimaryTenant = "fd268415-22a5-4064-9b5e-d039761c5971"
       BackupTenant = "26764e2b-92cb-448e-a938-16ea018ddc4c"
       FailoverDuration = "30 minutes"
       ParticipantsAffected = 126
       ProctorLead = $env:USERNAME
       ResolutionNotes = "Full failover to backup tenant successful"
   }
   
   $IncidentReport | ConvertTo-Json | Out-File ".\workshop-critical-incident.json"
   
   # Email incident report to workshop organizers
   Send-MailMessage -To "workshop-leads@microsoft.com" `
       -Subject "Workshop DR Activation - Complete Tenant Failure" `
       -Body ($IncidentReport | Format-List | Out-String) `
       -Attachments ".\workshop-critical-incident.json"
   ```

---

## 📋 **Proctor Pre-Workshop Checklist**

### **24 Hours Before Workshop**
- [ ] Run `Test-WorkshopReadiness.ps1` on **both** primary and backup tenants
- [ ] Verify Global Administrator access in both tenants
- [ ] Test Copilot Studio access with both tenant URLs
- [ ] Confirm Azure Portal access and resource group visibility
- [ ] Review this DR runbook with all 19 proctors
- [ ] Bookmark all emergency URLs in browser
- [ ] Join proctor Teams channel for coordination

### **Workshop Morning** (2 Hours Before Start)
- [ ] Final health check: Primary tenant operational
- [ ] Final health check: Backup tenant operational
- [ ] Proctor lead designated for DR coordination
- [ ] Emergency contact list confirmed (all 19 proctors)
- [ ] Incident log file created and ready
- [ ] Teams channel open for real-time communication
- [ ] Backup URL announcement template ready to copy/paste

### **During Workshop** (Every 4 Hours)
- [ ] Monitor Azure Service Health dashboard
- [ ] Check Copilot Studio response times
- [ ] Review Azure Portal login success rates
- [ ] Verify backup tenant health (passive monitoring)
- [ ] Document any participant access issues
- [ ] Coordinate with other proctors on Teams

---

## 🛠️ **Proctor Tools & Resources**

### **PowerShell Scripts**
```powershell
# Health check automation (run every 4 hours)
.\infrastructure\scripts\Test-WorkshopReadiness.ps1 -TenantId "fd268415-22a5-4064-9b5e-d039761c5971"

# Emergency failover validation
.\infrastructure\scripts\Test-WorkshopReadiness.ps1 -TenantId "26764e2b-92cb-448e-a938-16ea018ddc4c"

# Participant support: Check user access
Get-AzRoleAssignment -SignInName "participant@microsoft.com" | Select-Object RoleDefinitionName, Scope
```

### **Monitoring Dashboards**
- **Azure Service Health**: https://portal.azure.com/#view/Microsoft_Azure_Health/AzureHealthBrowseBlade
- **Azure Status**: https://status.azure.com
- **Copilot Studio Status**: https://status.microsoft.com (search "Copilot Studio")

### **Communication Templates**
- **Minor Issue**: "We're aware of [issue] and investigating. Continue working if possible."
- **Moderate Issue**: "We're switching to backup [service]. Please follow these steps: [...]"
- **Critical Issue**: "Full failover to backup environment. IMMEDIATE ACTION REQUIRED: [...]"

### **Support Escalation**
1. **Proctor Team** (19 proctors) - First line of support
2. **Workshop Leads** - Decision authority for failover
3. **Microsoft Azure Support** - Emergency ticket for quota/outages
4. **Microsoft Copilot Studio Support** - Escalation for Copilot issues

---

## 📞 **Emergency Contact Information**

### **Proctor Lead** (Workshop Day Coordinator)
- Name: [TBD - Assigned morning of workshop]
- Teams: @ProctorLead
- Mobile: [TBD]

### **Workshop Organizer**
- Name: [TBD]
- Teams: @WorkshopOrganizer
- Email: workshop-leads@microsoft.com

### **Microsoft Support**
- Azure Emergency Support: 1-800-MICROSOFT
- Copilot Studio Support: Tier 2 escalation via Azure Portal

---

## ✅ **Post-Workshop Validation**

After workshop concludes, all proctors should:

1. **Document DR Events**:
   ```powershell
   # Review incident log
   Get-Content ".\workshop-incident-log.txt"
   
   # If no incidents:
   Add-Content -Path ".\workshop-incident-log.txt" -Value @"
   [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] WORKSHOP COMPLETE
   Primary Tenant: Operational throughout workshop
   Backup Tenant: Not required (standby mode only)
   Zero failover events - Successful DR planning validated
   "@
   ```

2. **Participant Feedback**:
   - Survey participants on access experience
   - Document any "wrong tenant" issues encountered
   - Note effectiveness of bookmark strategy

3. **DR Lessons Learned**:
   - What worked well?
   - What could be improved?
   - Were backup URLs needed?
   - How effective was proctor coordination?

4. **Cleanup Verification**:
   ```powershell
   # Confirm cleanup script execution
   .\infrastructure\scripts\Remove-WorkshopResources.ps1 -WhatIf
   
   # Review resources to be deleted
   # Execute cleanup after approval
   ```

---

## 🎯 **Success Criteria**

A successful DR-ready workshop means:
- ✅ Zero unplanned downtime for participants
- ✅ Failover (if needed) completed within RTO targets
- ✅ All 126 participants can access backup environment
- ✅ Proctor coordination effective and timely
- ✅ Incident documentation complete and accurate
- ✅ Workshop learning outcomes achieved despite any technical issues

---

**Remember: As a Global Administrator, you have the power to ensure workshop success. Stay calm, follow procedures, coordinate with fellow proctors, and prioritize participant experience. The backup tenant is our safety net - don't hesitate to use it if needed! 🚀**

---

**Primary Tenant**: fd268415-22a5-4064-9b5e-d039761c5971 | **Backup Tenant**: 26764e2b-92cb-448e-a938-16ea018ddc4c
