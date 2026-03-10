# CSV File Organization and Cleanup Plan

## 📋 Current State Analysis

**Total CSV files**: 20 files (262 KB total)

---

## ✅ KEEP - Active/Essential Files

### **Primary Tracking File**
- **`workshop-participants-consolidated.csv`** (31 KB) - **SINGLE SOURCE OF TRUTH**
  - Contains: All participants, proctors, and external users
  - Used for: Long-term tracking, mail merges, access management
  - Updated by: `Consolidate-ParticipantData.ps1` script
  - Scope: Persistent across all workshop events

### **Event-Specific Team Management** (Per Workshop Event)
- **`team-assignments-balanced.csv`** (14.9 KB) - Team assignments for current event
- **`teams-final.csv`** (23.5 KB) - Team compositions and metadata
- **`participant-assignments.csv`** (28.8 KB) - Detailed participant-to-team mapping
- **Rationale**: Team configurations vary by event, need separate tracking

### **Access Preference Tracking**
- **`Fabrikam Agent-a-thon Workshop_ Tenant Access Preferences(1-8).csv`** (3.1 KB)
  - Contains: Survey responses for tenant access preferences
  - Used by: Consolidation script to map Status field
  - Keep: Active data source for status mapping

### **Challenge Preference Tracking** (Optional - Event-Specific)
- **`challenge-survey-responses.csv`** (12.3 KB)
  - Contains: Participant challenge level preferences
  - Used for: Event planning and team balancing
  - Keep: May be useful for future events

---

## 🗄️ ARCHIVE - Superseded by Consolidated File

These files were used to BUILD the consolidated file but are now redundant:

### **Source Files (Now Consolidated)**
- **`participants-final.csv`** (26 KB) - Merged into `workshop-participants-consolidated.csv`
- **`proctors-final.csv`** (4.6 KB) - Merged into `workshop-participants-consolidated.csv`
- **`workshop-user-mapping.csv`** (30.9 KB) - Merged into `workshop-participants-consolidated.csv`

### **Mail Merge Files (Superseded)**
- **`proctor-mail-merge.csv`** (2.6 KB) - Use consolidated file instead
- **`participant-credentials-MAILMERGE.csv`** (28.4 KB) - Use consolidated file instead

### **Credential Tracking Files (Superseded)**
- **`participant-credentials-TRACKING.csv`** (30.6 KB) - Old tracking format
- **`participant-credentials-TRACKING-CLEAN.csv`** (32.2 KB) - Old tracking format
- **`workshop-user-credentials.csv`** (2.8 KB) - Old credentials format

### **Bulk Invite Templates (One-Time Use)**
- **`bulk-invite-proctors.csv`** (2.4 KB) - Used for initial tenant setup
- **`bulk-invite-users.csv`** (16 KB) - Used for initial tenant setup
- **`UserInviteTemplate.csv`** (0.3 KB) - Template file

### **Raw Survey Data (Processing Complete)**
- **`Agent-A-Thon Workshop Sign Up - Custom Solution Team(1-89).csv`** (10.5 KB)
- **`FNF-2025-10-28-00059-0262.csv`** (8.9 KB) - Fictitious name file (processed)
- **`FNF-2025-10-28-00060-0901.csv`** (8.8 KB) - Fictitious name file (processed)

---

## 📂 Recommended File Structure

```
infrastructure/
├── 📄 workshop-participants-consolidated.csv  (MASTER FILE)
├── 📄 Fabrikam Agent-a-thon Workshop_ Tenant Access Preferences(1-8).csv
├── 📄 Consolidate-ParticipantData.ps1  (regeneration script)
├── 📄 PARTICIPANT-TRACKING-README.md  (documentation)
│
├── event-2025-11/  (Current Event - November 2025)
│   ├── team-assignments-balanced.csv
│   ├── teams-final.csv
│   ├── participant-assignments.csv
│   └── challenge-survey-responses.csv
│
└── archive/  (Historical/Superseded Files)
    ├── source-files/
    │   ├── participants-final.csv
    │   ├── proctors-final.csv
    │   └── workshop-user-mapping.csv
    ├── mail-merge-legacy/
    │   ├── proctor-mail-merge.csv
    │   └── participant-credentials-MAILMERGE.csv
    ├── credential-tracking-legacy/
    │   ├── participant-credentials-TRACKING.csv
    │   ├── participant-credentials-TRACKING-CLEAN.csv
    │   └── workshop-user-credentials.csv
    ├── bulk-invite-templates/
    │   ├── bulk-invite-proctors.csv
    │   ├── bulk-invite-users.csv
    │   └── UserInviteTemplate.csv
    └── raw-survey-data/
        ├── Agent-A-Thon Workshop Sign Up - Custom Solution Team(1-89).csv
        ├── FNF-2025-10-28-00059-0262.csv
        └── FNF-2025-10-28-00060-0901.csv
```

---

## 🚀 Cleanup Actions

### **Step 1: Create Event-Specific Folder**
```powershell
New-Item -ItemType Directory -Path "event-2025-11" -Force
Move-Item "team-assignments-balanced.csv" "event-2025-11/"
Move-Item "teams-final.csv" "event-2025-11/"
Move-Item "participant-assignments.csv" "event-2025-11/"
Move-Item "challenge-survey-responses.csv" "event-2025-11/"
```

### **Step 2: Create Archive Structure**
```powershell
New-Item -ItemType Directory -Path "archive/source-files" -Force
New-Item -ItemType Directory -Path "archive/mail-merge-legacy" -Force
New-Item -ItemType Directory -Path "archive/credential-tracking-legacy" -Force
New-Item -ItemType Directory -Path "archive/bulk-invite-templates" -Force
New-Item -ItemType Directory -Path "archive/raw-survey-data" -Force
```

### **Step 3: Move Source Files to Archive**
```powershell
Move-Item "participants-final.csv" "archive/source-files/"
Move-Item "proctors-final.csv" "archive/source-files/"
Move-Item "workshop-user-mapping.csv" "archive/source-files/"
```

### **Step 4: Move Mail Merge Legacy Files**
```powershell
Move-Item "proctor-mail-merge.csv" "archive/mail-merge-legacy/"
Move-Item "participant-credentials-MAILMERGE.csv" "archive/mail-merge-legacy/"
```

### **Step 5: Move Credential Tracking Legacy Files**
```powershell
Move-Item "participant-credentials-TRACKING.csv" "archive/credential-tracking-legacy/"
Move-Item "participant-credentials-TRACKING-CLEAN.csv" "archive/credential-tracking-legacy/"
Move-Item "workshop-user-credentials.csv" "archive/credential-tracking-legacy/"
```

### **Step 6: Move Bulk Invite Templates**
```powershell
Move-Item "bulk-invite-proctors.csv" "archive/bulk-invite-templates/"
Move-Item "bulk-invite-users.csv" "archive/bulk-invite-templates/"
Move-Item "UserInviteTemplate.csv" "archive/bulk-invite-templates/"
```

### **Step 7: Move Raw Survey Data**
```powershell
Move-Item "Agent-A-Thon Workshop Sign Up - Custom Solution Team(1-89).csv" "archive/raw-survey-data/"
Move-Item "FNF-2025-10-28-00059-0262.csv" "archive/raw-survey-data/"
Move-Item "FNF-2025-10-28-00060-0901.csv" "archive/raw-survey-data/"
```

---

## 🔄 Future Workflow

### **For Each New Workshop Event:**

1. **Create event folder**: `event-YYYY-MM/`
2. **Generate team assignments** for that event
3. **Store event-specific CSVs** in event folder
4. **Update consolidated file** with new participants/proctors if needed
5. **Collect access preferences** survey responses
6. **Regenerate consolidated file** using `Consolidate-ParticipantData.ps1`

### **For Mail Merges:**

Use `workshop-participants-consolidated.csv` which contains:
- ✅ All real names and emails
- ✅ All fictitious identities
- ✅ All tenant access credentials
- ✅ Access preference status
- ✅ Role information

Filter by event using team assignments from `event-YYYY-MM/` folder if needed.

### **For Team Management:**

Use event-specific files from `event-YYYY-MM/` folder:
- `team-assignments-balanced.csv` - Who's on which team
- `teams-final.csv` - Team metadata
- `participant-assignments.csv` - Detailed assignments

---

## 🎯 Benefits

✅ **Single Source of Truth**: `workshop-participants-consolidated.csv` for long-term tracking  
✅ **Event Isolation**: Team data separate, doesn't pollute master tracking  
✅ **Historical Archive**: Old files preserved but organized  
✅ **Clear Purpose**: Each file has a specific, documented role  
✅ **Easy Regeneration**: Consolidation script pulls from archived sources if needed  
✅ **Future Scalability**: Pattern works for multiple workshop events

---

## ⚠️ Important Notes

- **DO NOT DELETE** archived source files - they're inputs to consolidation script
- **DO NOT DELETE** access preferences survey - it's an active data source
- **DO** update `Consolidate-ParticipantData.ps1` if source file locations change
- **DO** create new event folders for each workshop
- **DO** keep consolidated file as the primary tracking database

---

**Last Updated**: November 11, 2025  
**Maintained By**: Workshop Infrastructure Team
