# 🔄 Workshop User Mapping - Native Accounts Strategy

**Strategy**: Create native users in workshop tenant with fictitious names, maintain mapping to real identities for communication.

---

## 📊 **User Mapping Structure**

### **Format**
```
Workshop Username: [FirstName][LastName]@fabrikam1.csplevelup.com
Display Name: [First Name] [Last Name] (fictitious)
Real User: [Alias]@microsoft.com
Team: [Team Assignment]
Role: Proctor | Participant
```

---

## 👥 **Proctor Mappings (20 Users)**

| Workshop Account | Display Name | Real User | Notes |
|------------------|--------------|-----------|-------|
| davidb@fabrikam1.csplevelup.com | David Birrueta | davidb@microsoft.com | Already exists, initial admin |
| oscarw@fabrikam1.csplevelup.com | Oscar Ward | oscarw@microsoft.com | Already exists, co-admin |
| mertu@fabrikam1.csplevelup.com | Mert Unan | mertunan@microsoft.com | Lead proctor |
| kirkd@fabrikam1.csplevelup.com | Kirk Daues | kirkda@microsoft.com | Lead proctor |
| zahids@fabrikam1.csplevelup.com | Zahid Saeed | zahids@microsoft.com | Proctor |
| olgab@fabrikam1.csplevelup.com | Olga Burmistrov | olgabu@microsoft.com | Proctor |
| rachellg@fabrikam1.csplevelup.com | Rachel Gross | ragrose@microsoft.com | Proctor |
| rubenh@fabrikam1.csplevelup.com | Ruben Huber | rubhuber@microsoft.com | Proctor |
| samts@fabrikam1.csplevelup.com | Sam Tsassen | stsassen@microsoft.com | Proctor |
| mattb@fabrikam1.csplevelup.com | Matt Bennett | mattben@microsoft.com | Proctor |
| sarahf@fabrikam1.csplevelup.com | Sarah Farnsworth | sarafa@microsoft.com | Proctor |
| jessicar@fabrikam1.csplevelup.com | Jessica Renfro | jessicar@microsoft.com | Proctor |
| lukep@fabrikam1.csplevelup.com | Luke Pelton | lukep@microsoft.com | Proctor |
| ashleyh@fabrikam1.csplevelup.com | Ashley Heckert | ashleyhe@microsoft.com | Proctor |
| michaelsc@fabrikam1.csplevelup.com | Michael Schoening | michaesc@microsoft.com | Proctor |
| briand@fabrikam1.csplevelup.com | Brian Dunn | briand@microsoft.com | Proctor |
| robertp@fabrikam1.csplevelup.com | Robert Pearce | robertpe@microsoft.com | Proctor |
| mandis@fabrikam1.csplevelup.com | Mandi Sisk | mandis@microsoft.com | Proctor |
| christianc@fabrikam1.csplevelup.com | Christian Chilcott | christianc@microsoft.com | Proctor |
| kayed@fabrikam1.csplevelup.com | Kaye DeMattia | kayed@microsoft.com | Proctor |

---

## 🎓 **Participant Mappings (107 Users)**

**Naming Strategy**: Use fictitious but professional names from attendees.csv

**Import from**: workshops/cs-agent-a-thon/infrastructure/attendees.csv

**Mapping File**: Will be generated with real email mapping for communications

---

## 📧 **Communication Strategy**

### **Pre-Workshop Emails (Sent to Real @microsoft.com)**

**Subject**: CS Agent-A-Thon Workshop - Your Login Credentials

**Template**:
```
Hi [Real First Name],

Welcome to the CS Agent-A-Thon Workshop on November 6, 2025!

Your workshop login credentials:
Username: [workshop-username]@fabrikam1.csplevelup.com
Password: [Generated-Password]
Team: [Team Name]

IMPORTANT - Test Your Access NOW:
1. Navigate to: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
2. Sign in with your workshop credentials above
3. Verify you can access Copilot Studio
4. Reply to this email if you have any issues

Workshop Details:
Date: November 6, 2025
Time: 9:00 AM - 4:00 PM
Location: [Location]

See you soon!
CS Agent-A-Thon Team
```

### **Reminder Email (T-7 Days)**
Send to real @microsoft.com with workshop credentials reminder

### **Final Reminder (T-1 Day)**
Send to real @microsoft.com with access verification checklist

---

## 🔐 **Password Strategy**

**Initial Password**: Generate secure random password (16 chars)
**Force Change**: Yes, on first login
**MFA**: Optional (recommend enabling for proctors)

**Password Generation**:
```powershell
# Generate secure password
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(16, 4)
```

---

## 📋 **User Provisioning Script**

**Script**: `Provision-NativeUsers.ps1`

**Inputs**:
1. `proctors-mapping.csv` - Proctor mappings
2. `participants-mapping.csv` - Participant mappings (generated from attendees.csv)

**Outputs**:
1. Users created in Entra ID
2. `user-credentials.csv` - Credentials for email distribution (SECURE!)
3. `user-mapping.csv` - Real user to workshop user mapping

**Actions**:
1. Create native users in workshop tenant
2. Assign licenses (M365 E3 + Copilot Studio)
3. Add to security groups (Workshop-Team-Proctors, Workshop-Team-01, etc.)
4. Assign RBAC roles on resource groups
5. Generate credential report for distribution

---

## 🔒 **Security Considerations**

### **Credential Distribution**
- ✅ Send via encrypted email or secure portal
- ✅ Force password change on first login
- ✅ Delete credential CSV after distribution
- ❌ Never commit credentials to Git

### **User Cleanup Post-Workshop**
- Disable accounts (don't delete immediately)
- Export workshop data for analysis
- Delete after 30-day retention period

---

## 📊 **Team Assignment Strategy**

**Proctors**: All in Workshop-Team-Proctors security group
**Participants**: Distributed across 21 teams based on challenge level survey

### **Security Groups**
- Workshop-Team-Proctors (20 members)
- Workshop-Team-01 (5-6 members)
- Workshop-Team-02 (5-6 members)
- ... Workshop-Team-21 (5-6 members)

---

## ✅ **Advantages Over B2B Guest Approach**

| Aspect | B2B Guests | Native Users |
|--------|------------|--------------|
| MCP Connector Auth | ❌ Complex, broken | ✅ Simple, works |
| Environment Maker | ❌ Permission issues | ✅ Easy assignment |
| System Admin | ❌ Chicken-and-egg | ✅ Direct assignment |
| User Experience | ❌ Tenant switching | ✅ Single tenant |
| Management | ❌ Complex | ✅ Straightforward |
| Communication | ✅ Direct to @microsoft.com | ⚠️ Requires mapping |

---

## 🎯 **Next Steps**

1. **Generate participant mappings** from attendees.csv
2. **Create provisioning script** for bulk user creation
3. **Provision proctor accounts** (20 users)
4. **Test MCP connector** with native proctors
5. **Provision participant accounts** (107 users)
6. **Distribute credentials** via secure email
7. **Send test access reminders** (T-7, T-3, T-1 days)

---

## 📁 **File Structure**

```
workshops/cs-agent-a-thon/infrastructure/
├── proctors-mapping.csv          # Proctor real-to-workshop mapping
├── participants-mapping.csv      # Participant real-to-workshop mapping
├── user-credentials.csv.gpg      # Encrypted credentials (NOT in Git)
└── scripts/
    ├── Provision-NativeUsers.ps1 # Bulk user creation
    ├── Generate-Credentials.ps1  # Password generation
    └── Send-AccessEmails.ps1     # Email distribution
```

---

**Status**: ⏳ Pending implementation
**Owner**: davidb / oscarw
**Timeline**: Complete before November 1 (T-5 days for testing)
