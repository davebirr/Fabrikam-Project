# B2B Guest Strategy - Workshop Provisioning Update

**Date**: October 27, 2025  
**Change**: Switched from native accounts to B2B guest invitations  
**Reason**: All 126 participants are Microsoft employees with existing licenses

---

## 🎯 **What Changed**

### **Previous Approach** ❌
- Create 126 native accounts in workshop tenant
- Manage passwords (`WorkshopTemp2025!`)
- Assign licenses from workshop tenant
- Complex cleanup (delete accounts)

### **New B2B Approach** ✅
- Invite 126 Microsoft employees as B2B guests
- Use existing @microsoft.com credentials
- Zero licensing costs (use Microsoft licenses)
- Simple cleanup (revoke invitations)

---

## 📋 **New Scripts Created**

1. **Invite-WorkshopUsers.ps1** ⭐ **NEW**
   - Invites all 126 Microsoft employees as B2B guests
   - Assigns Global Admin to 19 proctors
   - Assigns Contributor RBAC to 107 participants
   - Sends email invitations automatically

2. **Provision-WorkshopB2B.ps1** ⭐ **NEW** (Master Orchestrator)
   - Complete one-click provisioning using B2B approach
   - Dry-run capability
   - Comprehensive validation
   - **RECOMMENDED for workshop setup**

---

## ✅ **Advantages of B2B Approach**

### **Cost Savings**
- **$0 licensing costs** - Participants use existing Microsoft licenses
- No need to purchase M365/Entra ID licenses for workshop tenant

### **Simplified Management**
- **No password management** - Participants use familiar @microsoft.com login
- **No account creation** - B2B invitations only
- **Familiar experience** - Same login they use daily

### **Security & Compliance**
- **Existing MFA** - Participants use Microsoft's MFA policies
- **Conditional Access** - Microsoft's CA policies apply
- **No credential sharing** - Each person uses their own account

### **Simple Cleanup**
- **Revoke invitations** instead of deleting accounts
- **Faster cleanup** - No password resets or orphaned data
- **Audit trail** - B2B invitation logs maintained

---

## 🚀 **Quick Start (Updated)**

```powershell
cd workshops/cs-agent-a-thon/infrastructure/scripts

# 1. Preview what will happen (safe)
.\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025" `
    -DryRun

# 2. Execute provisioning
.\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"

# 3. Validate environment
.\Test-WorkshopReadiness.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

---

## 📧 **Participant Experience**

### Before Workshop
1. Receive B2B invitation email to @microsoft.com address
2. Click "Accept invitation" link in email
3. One-time acceptance grants access to workshop tenant

### During Workshop (Nov 6)
1. Navigate to https://portal.azure.com
2. Login with @microsoft.com credentials (same as always)
3. Switch to workshop tenant (if needed)
4. Access their team's resource group with Contributor permissions

**🚨 CRITICAL - Copilot Studio Access:**
- **MUST use**: `https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971`
- Without the `?tenant=` parameter, users will access their home Microsoft tenant
- Bookmark this URL or provide in workshop materials

### After Workshop
- No action required from participants
- Admin revokes B2B invitations
- Access automatically removed

---

## 🔐 **Azure RBAC Works Perfectly**

B2B guests have **full Azure RBAC support**:

✅ **Proctors** (19 people):
- Global Administrator role in workshop tenant
- Full tenant management capabilities
- Can assist all teams

✅ **Participants** (107 people):
- Contributor role on their team's resource group only
- Cannot access other teams' resources
- Cannot modify tenant settings

---

## 📊 **Comparison: Native vs B2B**

| Aspect | Native Accounts | B2B Guests (NEW) |
|--------|-----------------|------------------|
| **Licensing Cost** | Requires licenses | **$0 - Use Microsoft** |
| **Login** | UPN@levelupcspfy26cs01.onmicrosoft.com | **alias@microsoft.com** |
| **Password** | Manage workshop password | **Use existing** |
| **MFA** | Configure separately | **Microsoft's MFA** |
| **Azure RBAC** | ✅ Works | **✅ Works** |
| **Global Admin** | ✅ Works | **✅ Works** |
| **Cleanup** | Delete 126 accounts | **Revoke invitations** |
| **Time to provision** | ~30 minutes | **~15 minutes** |
| **Participant friction** | New password to manage | **Use daily login** |

---

## ⚠️ **Important Notes**

### Invitation Acceptance Required
- Participants **must accept** B2B invitation before workshop
- Send invitations **1 week before** November 6th
- Track acceptance rate with `Test-WorkshopReadiness.ps1`
- Follow up with non-responders

### Email Invitations
- Sent to @microsoft.com addresses automatically
- Email subject: "Invitation to access CS-Agent-A-Thon Workshop"
- Contains "Accept invitation" link
- Valid for 90 days (sufficient for workshop)

### Tenant Switching
- Participants may need to switch tenants in Azure Portal
- Top-right corner → Directory + Subscription filter
- Select "levelupcspfy26cs01" tenant
- First-time only (portal remembers preference)

---

## 📁 **Updated File Structure**

```
workshops/cs-agent-a-thon/infrastructure/scripts/
├── Provision-WorkshopB2B.ps1       ⭐ NEW - Master orchestrator (B2B)
├── Invite-WorkshopUsers.ps1        ⭐ NEW - B2B invitation script
├── New-TeamResourceGroups.ps1      ✅ Works with B2B
├── Grant-TeamAccess.ps1            ✅ Works with B2B
├── Test-WorkshopReadiness.ps1      ✅ Works with B2B
├── Remove-WorkshopResources.ps1    ✅ Works with B2B
├── README.md                       ✅ Updated for B2B
│
├── Add-WorkshopProctors.ps1        ⚠️ LEGACY - Native accounts (kept for reference)
├── Add-WorkshopParticipants.ps1    ⚠️ LEGACY - Native accounts (kept for reference)
└── Provision-WorkshopTenant.ps1    ⚠️ LEGACY - Native approach (kept for reference)
```

---

## ✅ **Decision Summary**

**APPROVED**: Use B2B guest invitations for all 126 Microsoft employee participants

**Rationale**:
1. Zero licensing costs (saves workshop budget)
2. Simplified participant experience (@microsoft.com login)
3. No password management overhead
4. Faster provisioning and cleanup
5. Leverages existing Microsoft security policies

**Next Steps**:
1. Use `Provision-WorkshopB2B.ps1` for workshop setup
2. Send invitations ~1 week before workshop (by Oct 30)
3. Track acceptance with validation script
4. Test with sample participants
5. Provide tenant-switching instructions if needed

---

**Status**: B2B approach ready for deployment! 🚀
