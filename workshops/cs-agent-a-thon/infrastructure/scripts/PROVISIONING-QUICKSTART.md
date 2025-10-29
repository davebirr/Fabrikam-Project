<#
.SYNOPSIS
    Quick start guide for workshop user provisioning

.DESCRIPTION
    Step-by-step commands to provision all 137 workshop users
#>

Write-Host @"

🚀 Workshop User Provisioning - Quick Start
================================================

Prerequisites:
--------------
1. Install Microsoft Graph PowerShell SDK:
   Install-Module Microsoft.Graph -Scope CurrentUser

2. Authenticate to workshop tenant:
   Connect-MgGraph -TenantId fd268415-22a5-4064-9b5e-d039761c5971 `
       -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"

3. Authenticate Azure CLI to workshop subscription:
   az login --tenant fd268415-22a5-4064-9b5e-d039761c5971
   az account set --subscription d3c2f651-1a5a-4781-94f3-460c4c4bffce


Option 1: TEST WITH PROCTORS FIRST (Recommended)
-------------------------------------------------
# 1. Dry run to preview
.\Provision-WorkshopUsers.ps1 -ProctorsOnly -DryRun

# 2. Create 20 proctor users
.\Provision-WorkshopUsers.ps1 -ProctorsOnly

# 3. Verify proctors can login
# Test with 2-3 proctors before proceeding

# 4. Create all remaining users
.\Provision-WorkshopUsers.ps1


Option 2: CREATE ALL USERS AT ONCE
-----------------------------------
# 1. Dry run to preview
.\Provision-WorkshopUsers.ps1 -DryRun

# 2. Create all 137 users
.\Provision-WorkshopUsers.ps1


What Gets Created:
------------------
✅ 137 native Entra ID users
   - Username: alias@fabrikam1.csplevelup.com
   - Display Name: Fictitious persona (e.g., "Oscar Ward")
   - Temporary password (force change on first login)
   - Usage Location: US

Output Files:
-------------
📁 workshop-user-credentials.csv
   - Contains temporary passwords
   - ⚠️  KEEP SECURE - Delete after distributing to users


Next Steps After User Creation:
--------------------------------
1. Assign licenses:
   .\Assign-Licenses.ps1

2. Add to security groups:
   .\Add-UsersToGroups.ps1

3. Assign Azure RBAC:
   .\Assign-AzureRoles.ps1

4. Send credential emails:
   .\Send-CredentialEmails.ps1


Troubleshooting:
----------------
❌ "User already exists"
   - Script will skip existing users
   - Check workshop-user-credentials.csv for their passwords

❌ "Insufficient privileges"
   - Ensure you have Global Administrator or User Administrator role
   - Re-authenticate: Connect-MgGraph -TenantId <tenant>

❌ "Rate limit exceeded"  
   - Script includes automatic throttling
   - If needed, reduce -BatchSize parameter


Estimated Time:
---------------
- Proctors only (20 users): ~3-5 minutes
- All users (137 users): ~15-20 minutes

"@
