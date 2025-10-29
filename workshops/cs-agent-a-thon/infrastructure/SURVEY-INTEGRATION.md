# 📊 Challenge Survey Response Integration

## Overview

This guide explains how to merge challenge level survey responses into the workshop user mapping as responses come in throughout the week.

---

## 📋 Survey Data Format

The survey responses should be exported to: `infrastructure/challenge-survey-responses.csv`

**Required CSV Format**:
```csv
Email,ChallengeLevel,Timestamp
IMRANLAL@microsoft.com,Beginner,10/28/2025 10:00:00 AM
MESCALANTE@microsoft.com,Intermediate,10/28/2025 10:15:00 AM
PRITHAB@microsoft.com,Advanced,10/28/2025 10:30:00 AM
```

**Columns**:
- `Email` - Real @microsoft.com email address (case-insensitive matching)
- `ChallengeLevel` - One of: `Beginner`, `Intermediate`, `Advanced`
- `Timestamp` - When they responded (optional, for tracking)

---

## 🔄 Merging Process

### Step 1: Export Survey Responses

From your survey tool (Microsoft Forms, etc.):

1. Export responses to CSV
2. Ensure columns match the format above
3. Save as: `infrastructure/challenge-survey-responses.csv`

**Example from Microsoft Forms**:
- Download responses
- Rename columns to match: `Email`, `ChallengeLevel`, `Timestamp`
- Remove any extra columns (response ID, etc.)

### Step 2: Run Merge Script

```powershell
cd workshops\cs-agent-a-thon\infrastructure\scripts
.\Merge-SurveyResponses.ps1
```

**What it does**:
- ✅ Reads survey responses
- ✅ Matches emails to workshop users (case-insensitive)
- ✅ Adds `ChallengeLevel` column to workshop-user-mapping.csv
- ✅ Marks unresponded users as "Not Responded"
- ✅ Shows statistics and response rate

### Step 3: Review Output

The script will show:
- **Response Rate**: How many have responded
- **Challenge Level Distribution**: Beginner/Intermediate/Advanced counts
- **Not Yet Responded**: List of people who haven't answered

**Example Output**:
```
📊 Challenge Level Distribution:
Level           Count
-----           -----
Not Responded   109
Beginner        15
Intermediate    8
Advanced        3

📈 Response Rate: 26 / 135 (19.3%)
   ⏳ Still waiting for 109 responses
```

---

## 🔁 Incremental Updates

**As more responses come in this week**:

1. Update `challenge-survey-responses.csv` with new responses
2. Re-run `.\Merge-SurveyResponses.ps1`
3. Script will update mappings incrementally

**Safe to run multiple times** - won't create duplicates or lose data.

---

## 📊 Updated Workshop User Mapping

After merging, `workshop-user-mapping.csv` will have:

**New Column**: `ChallengeLevel`
- `Beginner` - Chose beginner challenge track
- `Intermediate` - Chose intermediate challenge track
- `Advanced` - Chose advanced challenge track
- `Not Responded` - Haven't answered survey yet

**Example Row**:
```csv
UserNumber,RealFullName,RealAlias,RealEmail,Team,Country,Role,ChallengeLevel,FictitiousFullName,...
1,Imran Laljivirani,IMRANLAL,IMRANLAL@microsoft.com,BA Strategy & Shaping,United States,Participant,Beginner,Mahym Amangeldiyewa,...
```

---

## 🎯 Team Assignment Strategy

**After survey closes**:

Use challenge level preferences to:
1. **Balance teams** - Mix of beginner/intermediate/advanced
2. **Assign challenges** - Teams work on appropriate difficulty
3. **Proctor assignment** - Match experienced proctors to advanced teams

**Team Size**: 5-6 people per team
**Total Teams**: ~21 teams (based on 115 participants)

---

## 🔍 Common Issues

### "Survey response not matching"
**Problem**: Email in survey doesn't match attendees.csv
**Solution**: Check for typos, ensure using real @microsoft.com email

### "Duplicate responses"
**Problem**: Same person responded multiple times
**Solution**: Keep latest response, remove duplicates from CSV

### "Invalid challenge level"
**Problem**: Response has typo (e.g., "Intermdiate")
**Solution**: Fix in CSV before merging, must be exact: Beginner/Intermediate/Advanced

---

## 📧 Follow-up Reminders

**Template for non-responders**:

```
Subject: CS Agent-A-Thon - Please Select Your Challenge Level

Hi [Name],

We're preparing for the CS Agent-A-Thon workshop on November 6th!

Please take 30 seconds to select your preferred challenge level:
[Survey Link]

Options:
- Beginner: New to AI agents/Copilot Studio
- Intermediate: Some experience with AI/automation
- Advanced: Experienced with AI agents and development

This helps us assign balanced teams and appropriate challenges.

Thanks!
```

---

## 📁 Files

| File | Purpose | Location |
|------|---------|----------|
| `challenge-survey-responses.csv` | Survey data export | `infrastructure/` |
| `workshop-user-mapping.csv` | Master mapping with challenge levels | `infrastructure/` |
| `Merge-SurveyResponses.ps1` | Merge script | `infrastructure/scripts/` |

---

## ✅ Pre-Workshop Checklist

- [ ] All 135 attendees responded to survey
- [ ] Challenge level distribution is balanced
- [ ] Teams assigned based on preferences
- [ ] Proctors know their assigned teams
- [ ] Challenges matched to team skill levels

---

**Questions?** Contact workshop organizers.

**Next**: After 100% response rate, proceed with team assignments and resource provisioning.
