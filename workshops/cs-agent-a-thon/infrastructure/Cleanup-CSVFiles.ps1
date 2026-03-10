<#
.SYNOPSIS
Organizes CSV files in the infrastructure directory into a clean structure.

.DESCRIPTION
This script:
- Keeps workshop-participants-consolidated.csv as the master file
- Creates event-specific folder for team management files
- Archives superseded source files, mail merge files, and credential tracking files
- Preserves all data but organizes it logically

.NOTES
See CLEANUP-CSV-FILES.md for detailed explanation of the file organization.
#>

$ScriptDir = $PSScriptRoot

Write-Host "`n🧹 CSV File Cleanup and Organization" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# --- Step 1: Create Event-Specific Folder ---
Write-Host "📁 Creating event folder for November 2025..." -ForegroundColor Yellow
$eventFolder = Join-Path $ScriptDir "event-2025-11"
New-Item -ItemType Directory -Path $eventFolder -Force | Out-Null

$eventFiles = @(
    "team-assignments-balanced.csv",
    "teams-final.csv",
    "participant-assignments.csv",
    "challenge-survey-responses.csv"
)

foreach ($file in $eventFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $eventFolder -Force
        Write-Host "  ✅ Moved $file to event-2025-11/" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Step 2: Create Archive Structure ---
Write-Host "`n📦 Creating archive structure..." -ForegroundColor Yellow
$archiveFolders = @(
    "archive/source-files",
    "archive/mail-merge-legacy",
    "archive/credential-tracking-legacy",
    "archive/bulk-invite-templates",
    "archive/raw-survey-data"
)

foreach ($folder in $archiveFolders) {
    $folderPath = Join-Path $ScriptDir $folder
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    Write-Host "  ✅ Created $folder/" -ForegroundColor Green
}

# --- Step 3: Move Source Files to Archive ---
Write-Host "`n📚 Archiving source files (used to build consolidated file)..." -ForegroundColor Yellow
$sourceFiles = @(
    "participants-final.csv",
    "proctors-final.csv",
    "workshop-user-mapping.csv"
)

foreach ($file in $sourceFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $destPath = Join-Path $ScriptDir "archive/source-files"
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  ✅ Archived $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Step 4: Move Mail Merge Legacy Files ---
Write-Host "`n📧 Archiving legacy mail merge files..." -ForegroundColor Yellow
$mailMergeFiles = @(
    "proctor-mail-merge.csv",
    "participant-credentials-MAILMERGE.csv"
)

foreach ($file in $mailMergeFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $destPath = Join-Path $ScriptDir "archive/mail-merge-legacy"
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  ✅ Archived $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Step 5: Move Credential Tracking Legacy Files ---
Write-Host "`n🔑 Archiving legacy credential tracking files..." -ForegroundColor Yellow
$credentialFiles = @(
    "participant-credentials-TRACKING.csv",
    "participant-credentials-TRACKING-CLEAN.csv",
    "workshop-user-credentials.csv"
)

foreach ($file in $credentialFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $destPath = Join-Path $ScriptDir "archive/credential-tracking-legacy"
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  ✅ Archived $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Step 6: Move Bulk Invite Templates ---
Write-Host "`n👥 Archiving bulk invite templates..." -ForegroundColor Yellow
$inviteFiles = @(
    "bulk-invite-proctors.csv",
    "bulk-invite-users.csv",
    "UserInviteTemplate.csv"
)

foreach ($file in $inviteFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $destPath = Join-Path $ScriptDir "archive/bulk-invite-templates"
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  ✅ Archived $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Step 7: Move Raw Survey Data ---
Write-Host "`n📊 Archiving raw survey data..." -ForegroundColor Yellow
$surveyFiles = @(
    "Agent-A-Thon Workshop Sign Up - Custom Solution Team(1-89).csv",
    "FNF-2025-10-28-00059-0262.csv",
    "FNF-2025-10-28-00060-0901.csv"
)

foreach ($file in $surveyFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $destPath = Join-Path $ScriptDir "archive/raw-survey-data"
    if (Test-Path $sourcePath) {
        Move-Item $sourcePath $destPath -Force
        Write-Host "  ✅ Archived $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $file not found (skipping)" -ForegroundColor DarkGray
    }
}

# --- Summary ---
Write-Host "`n✅ Cleanup Complete!" -ForegroundColor Green
Write-Host "==================`n" -ForegroundColor Green

Write-Host "📂 File Organization:" -ForegroundColor Cyan
Write-Host "  Root Directory:" -ForegroundColor White
Write-Host "    • workshop-participants-consolidated.csv (MASTER FILE)" -ForegroundColor Green
Write-Host "    • Fabrikam Agent-a-thon Workshop_ Tenant Access Preferences(1-8).csv" -ForegroundColor Green
Write-Host "    • Consolidate-ParticipantData.ps1" -ForegroundColor Green
Write-Host "    • PARTICIPANT-TRACKING-README.md" -ForegroundColor Green
Write-Host "`n  Event-Specific (event-2025-11/):" -ForegroundColor White
Write-Host "    • Team assignments and management files" -ForegroundColor Yellow
Write-Host "`n  Archive (archive/):" -ForegroundColor White
Write-Host "    • Legacy source files, mail merge files, credentials, templates, surveys" -ForegroundColor DarkGray

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the organized structure" -ForegroundColor White
Write-Host "  2. Verify workshop-participants-consolidated.csv is complete" -ForegroundColor White
Write-Host "  3. For next event: Create event-YYYY-MM/ folder and move team files there" -ForegroundColor White
Write-Host "  4. See CLEANUP-CSV-FILES.md for detailed documentation`n" -ForegroundColor White
