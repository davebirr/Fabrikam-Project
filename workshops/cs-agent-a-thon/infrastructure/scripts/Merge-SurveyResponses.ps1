<#
.SYNOPSIS
    Merges challenge level survey responses into workshop user mapping

.DESCRIPTION
    Reads challenge-survey-responses.csv and updates workshop-user-mapping.csv
    with ChallengeLevel preferences. Handles incremental updates as more
    responses come in throughout the week.

.PARAMETER SurveyFile
    Path to survey responses CSV (default: challenge-survey-responses.csv)

.PARAMETER UpdateMapping
    Path to workshop user mapping CSV (default: workshop-user-mapping.csv)

.NOTES
    Survey CSV Format:
    - Email: Real @microsoft.com email address
    - ChallengeLevel: Beginner, Intermediate, or Advanced
    - Timestamp: When they responded (optional)

    Mapping will be updated with ChallengeLevel column
    Unresponded attendees will have ChallengeLevel = "Not Responded"
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$SurveyFile = "challenge-survey-responses.csv",
    [string]$MappingFile = "workshop-user-mapping.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$infrastructurePath = Split-Path -Parent $PSScriptRoot

Write-Host "`n📊 Merging Challenge Survey Responses" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Read survey responses
$surveyPath = Join-Path $infrastructurePath $SurveyFile
if (-not (Test-Path $surveyPath)) {
    Write-Host "`n⚠️  No survey responses file found at:" -ForegroundColor Yellow
    Write-Host "   $surveyPath" -ForegroundColor White
    Write-Host "`nCreating sample file for you to populate..." -ForegroundColor Yellow
    
    $sampleContent = @"
Email,ChallengeLevel,Timestamp
EXAMPLE@microsoft.com,Beginner,10/28/2025 10:00:00 AM
"@
    Set-Content -Path $surveyPath -Value $sampleContent -Force
    Write-Host "✅ Created: $surveyPath" -ForegroundColor Green
    Write-Host "`nPlease populate with actual survey responses and re-run." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n📂 Reading survey responses..." -ForegroundColor Yellow
$surveyResponses = Import-Csv $surveyPath

# Filter out example row
$surveyResponses = $surveyResponses | Where-Object { $_.Email -ne "EXAMPLE@microsoft.com" }

Write-Host "   Found $($surveyResponses.Count) survey responses" -ForegroundColor White

# Read current workshop mapping
$mappingPath = Join-Path $infrastructurePath $MappingFile
if (-not (Test-Path $mappingPath)) {
    throw "Workshop user mapping not found at: $mappingPath"
}

Write-Host "📂 Reading workshop user mapping..." -ForegroundColor Yellow
$mapping = Import-Csv $mappingPath
Write-Host "   Found $($mapping.Count) total users" -ForegroundColor White

# Create lookup dictionary for survey responses (case-insensitive email matching)
$surveyLookup = @{}
foreach ($response in $surveyResponses) {
    $email = $response.Email.ToLower()
    $surveyLookup[$email] = $response.ChallengeLevel
}

# Update mapping with challenge levels
$updatedMapping = $mapping | ForEach-Object {
    $realEmail = $_.RealEmail.ToLower()
    $challengeLevel = if ($surveyLookup.ContainsKey($realEmail)) {
        $surveyLookup[$realEmail]
    } else {
        "Not Responded"
    }
    
    [PSCustomObject]@{
        UserNumber               = $_.UserNumber
        RealFullName             = $_.RealFullName
        RealAlias                = $_.RealAlias
        RealEmail                = $_.RealEmail
        Team                     = $_.Team
        Country                  = $_.Country
        Role                     = $_.Role
        ChallengeLevel           = $challengeLevel
        FictitiousFirstName      = $_.FictitiousFirstName
        FictitiousLastName       = $_.FictitiousLastName
        FictitiousFullName       = $_.FictitiousFullName
        FictitiousGender         = $_.FictitiousGender
        FictitiousLanguage       = $_.FictitiousLanguage
        NativeUserPrincipalName  = $_.NativeUserPrincipalName
        DisplayName              = $_.DisplayName
        Alias                    = $_.Alias
    }
}

# Export updated mapping
$updatedMapping | Export-Csv -Path $mappingPath -NoTypeInformation -Force

Write-Host "`n✅ Updated workshop-user-mapping.csv" -ForegroundColor Green

# Generate statistics
Write-Host "`n📊 Challenge Level Distribution:" -ForegroundColor Cyan
$levelStats = $updatedMapping | Group-Object -Property ChallengeLevel | 
    Select-Object @{Name='Level';Expression={$_.Name}}, Count | 
    Sort-Object Count -Descending

$levelStats | Format-Table -AutoSize

# Show response rate
$responseCount = ($updatedMapping | Where-Object { $_.ChallengeLevel -ne "Not Responded" }).Count
$totalCount = $updatedMapping.Count
$responseRate = [math]::Round(($responseCount / $totalCount) * 100, 1)

Write-Host "📈 Response Rate: $responseCount / $totalCount ($responseRate%)" -ForegroundColor Yellow

if ($responseRate -lt 100) {
    $remaining = $totalCount - $responseCount
    Write-Host "   ⏳ Still waiting for $remaining responses" -ForegroundColor White
}

# Show who hasn't responded (proctors vs participants)
$notResponded = $updatedMapping | Where-Object { $_.ChallengeLevel -eq "Not Responded" }
if ($notResponded) {
    $proctorsNotResponded = ($notResponded | Where-Object { $_.Role -eq "Proctor" }).Count
    $participantsNotResponded = ($notResponded | Where-Object { $_.Role -eq "Participant" }).Count
    
    Write-Host "`n⏳ Not Yet Responded:" -ForegroundColor Yellow
    Write-Host "   Proctors: $proctorsNotResponded" -ForegroundColor Cyan
    Write-Host "   Participants: $participantsNotResponded" -ForegroundColor Cyan
    
    if ($proctorsNotResponded -gt 0) {
        Write-Host "`n   Proctors without response:" -ForegroundColor Yellow
        $notResponded | Where-Object { $_.Role -eq "Proctor" } | 
            Select-Object RealFullName, RealEmail | 
            Format-Table -AutoSize
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "✅ Survey responses merged successfully!" -ForegroundColor Green
Write-Host "`nRe-run this script as more survey responses come in." -ForegroundColor Yellow
Write-Host ""
