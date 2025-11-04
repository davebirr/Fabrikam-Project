# New Participants to Add to participant-assignments.csv

**Date**: November 2, 2025

## Summary

Found **2 new participants** in the survey responses who are NOT in `participant-assignments.csv`:

1. **jathorwa@microsoft.com** - Preference: Intermediate
2. **yara.chia@outlook.com** - Preference: Beginner (Auditing workshop)

## Action Required

These participants need to be added to `participant-assignments.csv` with:
- User numbers (138 and 139)
- Fictitious names and aliases
- Team assignments
- All other standard fields

## Current Status

- **Total registered participants**: 137
- **Total survey responses**: 82
- **Participants with survey responses**: 80 (matched to registered)
- **New participants**: 2 (need registration)

## Recommendation

1. **jathorwa@microsoft.com**:
   - Need to verify this email exists and get real name
   - Possible typo or unlisted participant
   - Preference: Intermediate

2. **yara.chia@outlook.com**:
   - Confirmed auditor for the workshop
   - Preference: Beginner
   - Should be added as special "Auditor" role or similar

## Next Steps

1. Verify identities of both participants
2. Assign user numbers (138, 139)
3. Generate fictitious personas
4. Add to participant-assignments.csv
5. Re-run team assignment script to include them

---

**Note**: The team assignment script (`team-assignments-balanced.csv`) currently includes only the 137 registered participants. Once new participants are added, re-run `create_team_assignments.py` to update team assignments.
