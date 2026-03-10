# GitHub Support Ticket - PII Removal Request

**Submit at:** https://support.github.com/

---

## Subject
Emergency PII Removal - Purge Orphaned Commits from Repository

---

## Repository Information
**Repository:** davebirr/Fabrikam-Project

---

## Issue Description

Dear GitHub Support,

I need assistance with fully removing sensitive Microsoft employee PII from my repository. I have successfully completed all local cleanup steps as documented in the [GitHub guide for removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository), but orphaned commits remain accessible on GitHub.

---

## Cleanup Actions Completed

✅ Used `git-filter-repo` to remove sensitive files from history (5 cleanup rounds)  
✅ Force-pushed cleaned history to GitHub  
✅ Deleted all branches containing PII  
✅ Deleted all forks (0 forks currently exist)  
✅ Verified all current branches are clean  

---

## Affected Pull Requests

**Number of PRs affected:** Unable to determine exact count from local metadata (filter-repo was run 5 separate times over multiple cleanup rounds, overwriting the metadata each time). 

Estimated 0-10 PRs may be affected. The `.git/filter-repo/changed-refs` file is not available due to multiple sequential cleanups.

---

## Commits Requiring Purge

The following orphaned commits are still accessible via direct SHA and contain Microsoft employee PII:

### Primary PII Commits (Most Critical):
- `6b298bd091d47be0454e696fbb5e4bff63fe3387` - Contains **attendees.csv** with 138 Microsoft employee records
- `704474b2d6b1fced77914884e1c36ba06225d15e` - Parent commit, may also contain PII

### Additional PII Commits from Previous Cleanup Rounds:
- `03004d9*` - Contains **MICROSOFT-ATTENDEES.md** with 126 employee records
- `9aaf809*` - Related PII commit
- `0ce6fca*` - Contains **service-principal-github.json** with Azure credentials
- `c89d4ce*` - Merge commit containing PII

*(Exact full SHAs for secondary commits can be provided if needed)*

---

## Sensitive Data Details

The orphaned commits contain:
- **Microsoft employee names, email addresses, and aliases** (138 unique individuals)
- **Manager relationships and organizational structure**
- **Team assignments and country locations**
- **Azure service principal credentials** (client ID, client secret, subscription ID)
- **Workshop participant information**

---

## Risk Mitigation Actions Taken

✅ **Azure credentials rotated** - Old service principal secret has been invalidated and replaced  
✅ **Affected parties notified** - Microsoft security team and employees informed  
✅ **All branches cleaned** - Only 3 branches remain, all verified clean of PII  
✅ **All forks deleted** - 0 forks currently exist  
⚠️ **Orphaned commits remain accessible** - Via direct SHA lookup for up to 90 days  

---

## LFS Objects

Repository uses Git LFS for large files. There may be orphaned LFS objects that require cleanup.

**LFS Status:**
- `.git/lfs` directory exists (LFS is in use)
- No specific "LFS Objects Orphaned" warning was captured in available filter-repo output
- Request that GitHub Support check for and purge any orphaned LFS objects as a precautionary measure

---

## First Changed Commit(s)

Unable to provide the exact "First Changed Commit(s)" output from `git-filter-repo` because:
1. The tool was executed 5 separate times across multiple cleanup rounds (Dec 1, 7, 11, 12, 2025)
2. Each execution overwrote the previous metadata in `.git/filter-repo/`
3. The repository has 292 commits total after cleanup

**Instead, here are the specific orphaned commit SHAs that require purging** (listed in the "Commits Requiring Purge" section above). These represent the full scope of commits containing sensitive data.

---

## Request

Please purge the orphaned commits listed above and run garbage collection on the server to permanently remove this sensitive data from GitHub's storage. This is required for SDL (Security Development Lifecycle) compliance.

**Specific actions requested:**
1. Dereference or delete any affected pull requests
2. Run garbage collection on the server to expunge sensitive data
3. Remove cached views of the commits
4. Delete/purge any orphaned LFS objects

---

## Why Credential Rotation Alone is Insufficient

While we have rotated the Azure service principal credentials, the majority of the sensitive data is **Microsoft employee PII** (names, emails, organizational relationships) which **cannot be rotated or mitigated**. This PII must be permanently removed to comply with privacy regulations and Microsoft's SDL requirements.

---

## Timeline

- **Initial PII commit:** November 4, 2025 (commit 6b298bd)
- **Cleanup rounds:** December 1, 7, 11, 12, 2025 (5 separate cleanups)
- **Exposure duration:** ~38 days (Nov 4 - Dec 12, 2025)
- **Current status:** Branches cleaned, but orphaned commits accessible

---

## Contact Information

Repository Owner: davebirr  
Urgency: High - SDL compliance requirement

Thank you for your assistance with this security incident.

---

## Submission Instructions

1. Go to: https://support.github.com/
2. Click "Contact Support"
3. Select Category: **"Account and Security"** or **"Repository"**
4. Copy and paste the content above
5. Submit ticket

**Expected Response Time:** 1-3 business days
