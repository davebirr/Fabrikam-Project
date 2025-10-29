# 🚀 Workshop Infrastructure Provisioning Scripts
**Automated provisioning for cs-agent-a-thon workshop**

---

## 📋 **Overview**

This directory contains PowerShell scripts to provision and manage a complete workshop environment including:

- **126 Entra ID user accounts** (19 proctors + 107 participants)
- **21 Azure resource groups** (one per team)
- **RBAC role assignments** (proctors as Global Admin, participants as Contributor)
- **Validation and cleanup** utilities

## 🏗️ Workshop Environment

### Tenant Configuration

- **Tenant ID**: `fd268415-22a5-4064-9b5e-d039761c5971`
- **Domain**: `levelupcspfy26cs01.onmicrosoft.com`
- **Primary Domain**: `csfabrikam1.cspsecurityaccelerate.com`
- **Workshop Date**: November 6, 2025

### User Structure

- **Proctors**: 19 Microsoft employees (B2B guests) with Global Administrator role
- **Participants**: 107 Microsoft employees (B2B guests) divided into 21 teams (5-6 members each)
- **Authentication**: @microsoft.com accounts (existing Microsoft credentials)
- **Licensing**: Zero cost - participants use existing Microsoft licenses

### Azure Structure

- **Subscription**: Workshop-AgentAThon-Nov2025
- **Resource Groups**: 21 team resource groups (`rg-agentathon-team-01` through `rg-agentathon-team-21`)
- **RBAC**: Each team member has Contributor access to their team's resource group


## 🚀 Quick Start

### Prerequisites

```powershell
# Install required PowerShell modules
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
Install-Module -Name Az.Resources -Scope CurrentUser -Force
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
```

### Complete Provisioning (Recommended)

Run the B2B-optimized master orchestrator script for complete automated provisioning:

```powershell
cd workshops/cs-agent-a-thon/infrastructure/scripts

# Dry run first (recommended)
.\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025" `
    -DryRun

# Actual provisioning
.\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

This will:
1. ✅ Check prerequisites
2. ✅ Invite 126 Microsoft employees as B2B guests
3. ✅ Assign Global Admin to 19 proctors
4. ✅ Create 21 resource groups
5. ✅ Assign RBAC permissions
6. ✅ Validate complete environment

**Why B2B Guests?**
- ✅ Zero licensing costs (participants use Microsoft licenses)
- ✅ No password management (use @microsoft.com)
- ✅ Familiar login experience
- ✅ Simple post-workshop cleanup

## 📜 Script Reference

### 1. Provision-WorkshopB2B.ps1 (Master Orchestrator) ⭐ **RECOMMENDED**

**Purpose**: One-click provisioning using B2B guest invitations for Microsoft employees.

**Features**:
- Prerequisites validation
- Dry-run capability
- B2B guest invitations (no native accounts)
- Progress tracking
- Comprehensive validation

**Usage**:
```powershell
.\Provision-WorkshopB2B.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025" `
    [-DryRun]
```

**Why B2B?**
- Zero licensing costs
- No password management
- Familiar @microsoft.com login
- Simple cleanup

---

### 2. Invite-WorkshopUsers.ps1

**Purpose**: Invite all 126 Microsoft employees as B2B guests.

**Creates**:
- 19 proctor B2B guests with Global Administrator role
- 107 participant B2B guests with Contributor RBAC
- Email invitations to @microsoft.com addresses

**Usage**:
```powershell
.\Invite-WorkshopUsers.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

---

### 3. New-TeamResourceGroups.ps1

**Purpose**: Create Azure resource groups for each team (21 resource groups).

**Usage**:
```powershell
.\New-TeamResourceGroups.ps1 `
    -SubscriptionName "Workshop-AgentAThon-Nov2025" `
    -Location "eastus"
```

---

### 4. Grant-TeamAccess.ps1

**Purpose**: Assign RBAC permissions to team members.

**Usage**:
```powershell
.\Grant-TeamAccess.ps1 `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

---

### 5. Test-WorkshopReadiness.ps1

**Purpose**: Validate complete workshop environment.

**Validates**:
- ✅ All 126 B2B guests invited and accepted invitations
- ✅ All 21 resource groups exist with proper tags
- ✅ RBAC assignments are correct (samples teams 1, 10, 21)
- ✅ Proctors have Global Admin access

**Usage**:
```powershell
.\Test-WorkshopReadiness.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

---

### 7. Remove-WorkshopResources.ps1

**Purpose**: Post-workshop cleanup of all resources.

**Safety Features**:
- WhatIf mode for previewing deletions
- Confirmation prompt requiring "DELETE" input
- Progress tracking

**Usage**:
```powershell
# Preview what would be deleted (safe)
.\Remove-WorkshopResources.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025" `
    -WhatIf

# Actual deletion (requires confirmation)
.\Remove-WorkshopResources.ps1 `
    -TenantId "fd268415-22a5-4064-9b5e-d039761c5971" `
    -SubscriptionName "Workshop-AgentAThon-Nov2025"
```

---

## 📅 Provisioning Timeline

### Phase 1: B2B Guest Invitations (Day 1)
1. Run `Provision-WorkshopB2B.ps1` (or `Invite-WorkshopUsers.ps1` individually)
2. Participants receive email invitations to @microsoft.com
3. **Action Required**: Participants must accept B2B invitations before workshop

### Phase 2: Azure Resources (Day 1-2)
1. Resource groups created automatically (via Provision-WorkshopB2B.ps1)
2. RBAC permissions assigned automatically
3. Validate Azure setup with `Test-WorkshopReadiness.ps1`

### Phase 3: Validation (Day 3-5)
1. Run full validation: `Test-WorkshopReadiness.ps1`
2. Test sample B2B guest logins
3. Verify resource group access
4. Confirm invitation acceptance rate

### Phase 4: Workshop Day (Nov 6)
- Participants login with @microsoft.com credentials
- Monitor access and usage
- Provide support as needed

### Phase 5: Cleanup (Post-Workshop)
1. Run `Remove-WorkshopResources.ps1 -WhatIf` to preview
2. Revoke B2B guest invitations (simpler than deleting accounts)
3. Delete resource groups
4. Verify complete cleanup

---

## 🔐 Security Considerations

### Authentication
- All scripts use interactive authentication
- No credentials stored in scripts or configuration
- Supports MFA-enabled accounts

### Permissions Required

**Microsoft Graph Permissions**:
- `User.ReadWrite.All`
- `Directory.ReadWrite.All`
- `RoleManagement.ReadWrite.Directory`

**Azure Permissions**:
- Owner or User Access Administrator on subscription
- Ability to create resource groups
- Ability to assign RBAC roles

### Best Practices
- ✅ Use dry-run/WhatIf modes first
- ✅ Review validation reports before workshop
- ✅ Test with sample accounts before bulk provisioning
- ✅ Keep attendee CSV secure (contains personal info)
- ✅ Change default password policy before workshop
- ✅ Clean up resources promptly after workshop

---

## 🐛 Troubleshooting

### Common Issues

#### "Insufficient privileges" error
**Solution**: Ensure you have Global Administrator role or required Graph permissions

#### "Subscription not found" error
**Solution**: Verify subscription name is exact match (case-sensitive)

#### "User already exists" error
**Solution**: Scripts handle existing users gracefully - check output for conflicts

#### RBAC assignment fails
**Solution**: Ensure resource groups exist first, verify user accounts are created

### Debugging

Enable verbose output:
```powershell
$VerbosePreference = "Continue"
.\Provision-WorkshopTenant.ps1 -TenantId "..." -SubscriptionName "..." -Verbose
```

---

## 📚 Additional Resources

- [Attendee List](../../docs/MICROSOFT-ATTENDEES.md) - Complete attendee roster
- [Team Roster](../../docs/team-roster.md) - Team assignments and details
- [Tenant Configuration](../TENANT-CONFIG.md) - Complete infrastructure specification
- [Workshop Challenges](../../challenges/) - Challenge documentation

---

## 👤 Maintainer

**David Bjurman-Birr**  
Workshop Administrator  
Created: October 27, 2025

---
---

**Complete automation for workshop infrastructure lifecycle from provisioning through cleanup! �**
