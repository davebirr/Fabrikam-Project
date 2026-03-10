# Workshop Participant Tracking

## Overview

This directory contains the **single source of truth** for all workshop participants, proctors, and external collaborators. The consolidated CSV file is designed for:

- 📧 **Mail merge campaigns**
- 🔐 **Tenant access management**
- 📊 **Participant tracking and reporting**
- 👥 **Role-based communications**

## Primary File

### `workshop-participants-consolidated.csv`

**Total Records**: 138 (117 participants + 20 proctors + 1 external)

**Purpose**: Unified tracking file combining participant data, proctor data, and access preferences into a single comprehensive record set.

**Generated**: By `Consolidate-ParticipantData.ps1` script

---

## File Structure

### Column Definitions

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| **UserNumber** | Integer | Unique identifier for each person | `135` |
| **Role** | Enum | Role in workshop | `Participant`, `Proctor`, `ExternalParticipant` |
| **Status** | Enum | Access preference status | `continuous`, `currentTenant`, `disable`, `externalParticipant` |
| **RealFullName** | String | Actual full name | `David Bjurman-Birr` |
| **RealAlias** | String | Microsoft alias (uppercase) | `DAVIDB` |
| **RealEmail** | String | Microsoft email address | `DAVIDB@microsoft.com` |
| **Country** | String | Home country | `United States` |
| **FictitiousFirstName** | String | Fictitious first name for tenant | `Oscar` |
| **FictitiousLastName** | String | Fictitious last name for tenant | `Ward` |
| **FictitiousFullName** | String | Complete fictitious name | `Oscar Ward` |
| **FictitiousGender** | String | Gender for fictitious identity | `Male`, `Female`, `Gender neutral` |
| **FictitiousLanguage** | String | Language for fictitious identity | `English (United States)` |
| **NativeUserPrincipalName** | String | Azure AD UPN in tenant | `oscarw@fabrikam1.csplevelup.com` |
| **DisplayName** | String | Display name in tenant | `Oscar Ward` |
| **Alias** | String | Alias in tenant | `oscarw` |
| **AccessPreferenceResponse** | String | Full survey response text | `✅ Keep my access active...` |

---

## Status Values

The **Status** column reflects access preferences and determines tenant provisioning decisions:

| Status | Count | Description | Survey Response |
|--------|-------|-------------|-----------------|
| **continuous** | 8 | Keep tenant access active for 90 days | "✅ Keep my access active for the next 90 days" OR "🔄 This tenant + the next one" |
| **currentTenant** | 129 | Access only during current workshop | Default if no survey response provided |
| **disable** | 0 | Disable tenant access immediately | "❌ Disable my access immediately" |
| **externalParticipant** | 1 | External user (not Microsoft employee) | N/A - Manual assignment |

### Status Mapping Logic

```powershell
# From Consolidate-ParticipantData.ps1
$status = if ($accessPref) {
    switch -Wildcard ($accessPref) {
        "*Keep my access active*" { "continuous" }
        "*This tenant + the next one*" { "continuous" }
        "*Disable my access*" { "disable" }
        default { "currentTenant" }
    }
} else {
    "currentTenant"  # Default if no response
}
```

---

## Role Breakdown

| Role | Count | Description |
|------|-------|-------------|
| **Proctor** | 20 | Workshop facilitators and support staff |
| **Participant** | 117 | Workshop attendees |
| **ExternalParticipant** | 1 | Non-Microsoft collaborators (e.g., Yara) |

---

## Source Files

The consolidated file is generated from three source files:

### 1. `participants-final.csv`
- **Records**: 117
- **Content**: Workshop participants with fictitious identities
- **Fields**: All personal and tenant access information

### 2. `proctors-final.csv`
- **Records**: 20
- **Content**: Workshop proctors/facilitators
- **Fields**: Same structure as participants

### 3. `Fabrikam Agent-a-thon Workshop_ Tenant Access Preferences(1-8).csv`
- **Records**: 8 responses
- **Content**: Survey responses for access preferences
- **Purpose**: Maps to Status values (continuous, disable, currentTenant)

---

## Consolidation Process

### Script: `Consolidate-ParticipantData.ps1`

**Execution**:
```powershell
cd workshops\cs-agent-a-thon\infrastructure
.\Consolidate-ParticipantData.ps1
```

**What It Does**:
1. Loads all three source CSV files
2. Creates email-based lookup for access preferences (case-insensitive)
3. Processes participants:
   - Maps access preference to status
   - Defaults to "currentTenant" if no response
   - Preserves all mail merge fields
4. Processes proctors (same logic)
5. Adds external participants with custom status
6. Sorts by role priority (Proctor → Participant → External), then last name
7. Exports to `workshop-participants-consolidated.csv`
8. Displays comprehensive summary statistics

**Output Example**:
```
Found 117 participants
Found 20 proctors
Found 8 access preference responses

Consolidation complete!
Output file: workshop-participants-consolidated.csv

Summary:
  Total records: 138
  Participants: 117
  Proctors: 20
  External: 1

Status breakdown:
  Continuous access: 8
  Current tenant only: 129
  Disable access: 0
  External participant: 1
```

---

## Usage Examples

### Mail Merge Fields

For email campaigns, use these fields:

```plaintext
Dear {{FictitiousFirstName}},

Your tenant access for the Fabrikam Agent-a-thon Workshop is ready!

Login URL: https://portal.azure.com
UPN: {{NativeUserPrincipalName}}
Display Name: {{DisplayName}}

Status: {{Status}}
Role: {{Role}}

Best regards,
Workshop Team
```

### Filter by Role

**Proctors Only**:
```powershell
Import-Csv workshop-participants-consolidated.csv | 
    Where-Object { $_.Role -eq "Proctor" } |
    Export-Csv proctors-only.csv -NoTypeInformation
```

**Participants Only**:
```powershell
Import-Csv workshop-participants-consolidated.csv | 
    Where-Object { $_.Role -eq "Participant" } |
    Export-Csv participants-only.csv -NoTypeInformation
```

### Filter by Status

**Continuous Access Users**:
```powershell
Import-Csv workshop-participants-consolidated.csv | 
    Where-Object { $_.Status -eq "continuous" } |
    Export-Csv continuous-access.csv -NoTypeInformation
```

**Current Tenant Only**:
```powershell
Import-Csv workshop-participants-consolidated.csv | 
    Where-Object { $_.Status -eq "currentTenant" } |
    Export-Csv current-tenant-only.csv -NoTypeInformation
```

### Count by Country

```powershell
Import-Csv workshop-participants-consolidated.csv | 
    Group-Object Country | 
    Sort-Object Count -Descending |
    Select-Object Name, Count
```

---

## External Participants

External participants (non-Microsoft employees) are tracked in the same file with:

- **Role**: `ExternalParticipant`
- **Status**: `externalParticipant`
- **Email**: External email address (not @microsoft.com)

### Current External Users

| UserNumber | Name | Email | Status |
|------------|------|-------|--------|
| 999 | Yara (External) | yara@example.com | externalParticipant |

**Note**: Update placeholder email (`yara@example.com`) with actual contact information.

### Adding New External Users

Edit `Consolidate-ParticipantData.ps1` and add to the external participants section:

```powershell
$externalUsers += [PSCustomObject]@{
    UserNumber = 1000
    Role = "ExternalParticipant"
    Status = "externalParticipant"
    RealFullName = "Jane Doe"
    RealAlias = "JANEDOE"
    RealEmail = "jane.doe@partner.com"
    Country = "Canada"
    # ... other fields
}
```

Then re-run the script to regenerate the consolidated file.

---

## Data Integrity

### Validation Rules

- **UserNumber**: Must be unique across all records
- **Email**: Used for access preference lookup (case-insensitive)
- **Status**: Must be one of: `continuous`, `currentTenant`, `disable`, `externalParticipant`
- **Role**: Must be one of: `Participant`, `Proctor`, `ExternalParticipant`
- **NativeUserPrincipalName**: Must follow format `alias@fabrikam1.csplevelup.com`

### Deduplication

The consolidation script does NOT deduplicate records. If a person appears in both participants and proctors files, they will have two records. Review source files before consolidation.

### Missing Access Preferences

Only **8 out of 137** people responded to the access preference survey. All others default to:

- **Status**: `currentTenant`
- **AccessPreferenceResponse**: (empty)

This is expected behavior. Access preferences may change over time.

---

## Team Assignments

**Team assignments have been REMOVED from the consolidated file** as requested.

If team-based filtering is needed in the future, create a separate team mapping file:

```powershell
# Extract team assignments from participants-final.csv
Import-Csv participants-final.csv |
    Select-Object UserNumber, RealFullName, Team |
    Export-Csv team-mapping.csv -NoTypeInformation
```

This maintains clean separation between participant tracking and team organization.

---

## Maintenance

### When to Regenerate

Re-run `Consolidate-ParticipantData.ps1` when:

- ✅ New access preference survey responses received
- ✅ Participant or proctor lists updated
- ✅ External users added/removed
- ✅ Status overrides needed for specific individuals

### Backup Strategy

Before regenerating, back up the current file:

```powershell
Copy-Item workshop-participants-consolidated.csv `
    "workshop-participants-consolidated.$(Get-Date -Format 'yyyyMMdd-HHmmss').backup.csv"
```

### Version Control

The consolidated CSV file is included in git for tracking changes over time. Review diffs before committing:

```bash
git diff workshop-participants-consolidated.csv
```

---

## Contact

For questions about participant tracking or access management, contact:

- **Project Owner**: David Bjurman-Birr (DAVIDB@microsoft.com)
- **Workshop Team**: See proctors in consolidated file (Role = "Proctor")

---

## Change Log

| Date | Change | Updated By |
|------|--------|------------|
| 2025-02-01 | Initial consolidation from 3 source files | GitHub Copilot |
| 2025-02-01 | Added external participant example (Yara) | GitHub Copilot |

---

**Last Generated**: See file modification timestamp on `workshop-participants-consolidated.csv`
