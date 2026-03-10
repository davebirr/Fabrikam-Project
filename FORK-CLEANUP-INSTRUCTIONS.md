# Fork Cleanup Instructions - PII Removal

**Date**: December 1, 2025  
**Issue**: Git history contains Microsoft employee PII that must be removed

## Affected Forks

The following forks contain the PII commit (6b298bd) and need cleanup:

1. `jimbanach/Fabrikam-Project`
2. `oscarw-fab1/Fabrikam-Project`
3. `sarahburg/Fabrikam-Project`
4. `mariuszo-at-microsoft-com/Fabrikam-Project-CS-Agent-A-Thon`
5. `jfernandez192/Fabrikam-Project`

## What Happened

On November 4, 2025, a CSV file (`attendees.csv`) containing 138 Microsoft employee records (names, emails, aliases, managers, teams, countries) was committed to the repository. While it was removed in the next commit, **it remained in Git history** and was publicly accessible.

The main repository has been cleaned using `git-filter-repo`, but forks created before the cleanup still contain the PII.

## Required Action for Fork Owners

### Option 1: Sync with Cleaned Upstream (Recommended)

If you haven't made custom changes:

```bash
# Backup your current state
git branch backup-my-work

# Fetch the cleaned upstream
git remote add upstream https://github.com/davebirr/Fabrikam-Project.git
git fetch upstream

# Reset to cleaned main
git checkout main
git reset --hard upstream/main

# Force push to your fork
git push --force origin main
```

### Option 1B: Sync with Cleaned Upstream + Preserve Your Changes (PowerShell)

If you have specific files you want to keep (like CI/CD workflows):

```powershell
# Backup your workflow files (or other custom files)
$backupDir = "$env:TEMP\fork-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force
if (Test-Path ".github\workflows") {
    Copy-Item -Path ".github\workflows\*" -Destination $backupDir -Recurse -Force
    Write-Host "✅ Workflows backed up to: $backupDir" -ForegroundColor Green
}

# Fetch the cleaned upstream
git remote add upstream https://github.com/davebirr/Fabrikam-Project.git
git fetch upstream

# Reset to cleaned main
git checkout main
git reset --hard upstream/main

# Restore your workflow files
if (Test-Path $backupDir) {
    New-Item -ItemType Directory -Path ".github\workflows" -Force
    Copy-Item -Path "$backupDir\*" -Destination ".github\workflows\" -Recurse -Force
    Write-Host "✅ Workflows restored" -ForegroundColor Green
}

# Commit your workflows back
git add .github/workflows/
git commit -m "Restore custom CI/CD workflows after PII cleanup"

# Force push to your fork
git push --force origin main
```

### Option 2: Clean Your Fork Independently

If you have custom changes you want to preserve:

```bash
# Install git-filter-repo
pip install git-filter-repo

# Backup your work
git branch backup-before-cleanup

# Create list of files to remove
cat > pii-files.txt << EOF
workshops/cs-agent-a-thon/infrastructure/attendees.csv
workshops/cs-agent-a-thon/infrastructure/participants-final.csv
workshops/cs-agent-a-thon/infrastructure/proctors-final.csv
workshops/cs-agent-a-thon/infrastructure/participant-assignments.csv
workshops/cs-agent-a-thon/infrastructure/challenge-survey-responses.csv
workshops/cs-agent-a-thon/infrastructure/team-assignments-balanced.csv
workshops/cs-agent-a-thon/infrastructure/teams-final.csv
workshops/cs-agent-a-thon/infrastructure/workshop-user-mapping.csv
workshops/cs-agent-a-thon/infrastructure/bulk-invite-proctors.csv
workshops/cs-agent-a-thon/infrastructure/bulk-invite-users.csv
workshops/cs-agent-a-thon/infrastructure/UserInviteTemplate.csv
workshops/cs-agent-a-thon/infrastructure/FNF-2025-10-28-00059-0262.csv
workshops/cs-agent-a-thon/infrastructure/FNF-2025-10-28-00060-0901.csv
EOF

# Remove PII from history
git filter-repo --invert-paths --paths-from-file pii-files.txt --force

# Re-add remote (filter-repo removes it)
git remote add origin <YOUR_FORK_URL>

# Force push
git push --force --all
```

### Option 3: Delete and Re-Fork

The simplest approach if you don't need the history:

1. Delete your fork on GitHub
2. Create a new fork from the cleaned `davebirr/Fabrikam-Project`

---

## PowerShell - Complete Cleanup Script for Windows

For Windows users with PowerShell, here's a complete script to clean a fork:

```powershell
# Configuration - EDIT THESE VALUES
$forkOwner = "oscarw-fab1"  # Replace with fork owner username
$forkName = "Fabrikam-Project"
$forkUrl = "https://github.com/$forkOwner/$forkName.git"
$upstreamUrl = "https://github.com/davebirr/Fabrikam-Project.git"
$localPath = "C:\Temp\fork-cleanup-$forkOwner"

Write-Host "`n🔧 Starting PII cleanup for fork: $forkOwner/$forkName`n" -ForegroundColor Cyan

# Step 1: Clone the fork
Write-Host "📥 Cloning fork..." -ForegroundColor Yellow
if (Test-Path $localPath) {
    Remove-Item -Path $localPath -Recurse -Force
}
git clone $forkUrl $localPath
Set-Location $localPath

# Step 2: Backup custom workflow files
Write-Host "`n💾 Backing up custom workflows..." -ForegroundColor Yellow
$backupDir = "$env:TEMP\workflows-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path ".github\workflows") {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item -Path ".github\workflows\*" -Destination $backupDir -Recurse -Force
    Write-Host "   ✅ Backed up to: $backupDir" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No workflows found to backup" -ForegroundColor Gray
}

# Step 3: Add upstream and fetch cleaned history
Write-Host "`n🔗 Adding cleaned upstream repository..." -ForegroundColor Yellow
git remote add upstream $upstreamUrl
git fetch upstream

# Step 4: Reset to cleaned main (removes PII)
Write-Host "`n🧹 Resetting to cleaned upstream (this removes PII)..." -ForegroundColor Yellow
git checkout main
git reset --hard upstream/main

# Step 5: Restore custom workflows
Write-Host "`n📂 Restoring custom workflows..." -ForegroundColor Yellow
if (Test-Path $backupDir) {
    New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null
    Copy-Item -Path "$backupDir\*" -Destination ".github\workflows\" -Recurse -Force
    
    # Commit workflows back
    git add .github/workflows/
    git commit -m "Restore custom CI/CD workflows after PII cleanup"
    Write-Host "   ✅ Workflows restored and committed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  No workflows to restore" -ForegroundColor Gray
}

# Step 6: Force push to remove PII from public history
Write-Host "`n🚀 Force pushing cleaned history to fork..." -ForegroundColor Yellow
Write-Host "   ⚠️  This will rewrite public Git history!" -ForegroundColor Red
$confirm = Read-Host "   Continue? (yes/no)"
if ($confirm -eq "yes") {
    git push --force origin main
    Write-Host "`n✅ Fork cleaned successfully! PII removed from history.`n" -ForegroundColor Green
    
    # Step 7: Verify cleanup
    Write-Host "🔍 Verifying PII removal..." -ForegroundColor Yellow
    $attendeesCheck = git log --all --oneline -- "**/attendees.csv" 2>&1
    if ([string]::IsNullOrWhiteSpace($attendeesCheck)) {
        Write-Host "   ✅ Verified: attendees.csv not in history" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Warning: attendees.csv still found in history!" -ForegroundColor Red
    }
    
    Write-Host "`n📋 Backup location: $backupDir" -ForegroundColor Cyan
    Write-Host "🗂️  Local repo: $localPath`n" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Cleanup cancelled. No changes pushed.`n" -ForegroundColor Red
}
```

**To use this script:**

1. Open PowerShell
2. Edit the `$forkOwner` variable to match the fork owner
3. Copy and paste the entire script
4. Type `yes` when prompted to confirm the force push

## Verification

After cleanup, verify the PII is gone:

```bash
# This should return nothing
git log --all --oneline -- "**/attendees.csv"

# This commit should not exist or not contain the CSV
git show 6b298bd:workshops/cs-agent-a-thon/infrastructure/attendees.csv 2>&1
```

## Questions?

Contact: davidb@microsoft.com

## Security Note

This cleanup is required for compliance with Microsoft data protection policies. The PII exposure was unintentional and has been reported to the appropriate security teams.
