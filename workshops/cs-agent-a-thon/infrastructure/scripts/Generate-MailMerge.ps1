<#
.SYNOPSIS
    Generate mail merge CSV for proctor emails with both full UPN and alias

.DESCRIPTION
    Creates a mail merge CSV with:
    - RealFirstName: First name from real identity
    - RealFullName: Full real name
    - FictitiousName: Workshop persona name
    - WorkshopUsername: Full UPN (e.g., oscarw@fabrikam1.csplevelup.com)
    - WorkshopAlias: Just the alias (e.g., oscarw)
    - ToEmail: Real email address for sending
#>

[CmdletBinding()]
param()

$infrastructurePath = Split-Path -Parent $PSScriptRoot

# Load credentials
$credFile = Join-Path $infrastructurePath "workshop-user-credentials.csv"
$creds = Import-Csv $credFile

Write-Host "📧 Generating Mail Merge CSV..." -ForegroundColor Cyan

# Create mail merge data
$mailMergeData = $creds | ForEach-Object {
    # Extract first name from real full name
    $firstName = ($_.RealFullName -split ' ')[0]
    
    # Extract alias (left portion of UPN before @)
    $alias = ($_.WorkshopUsername -split '@')[0]
    
    [PSCustomObject]@{
        ToEmail = $_.RealEmail
        RealFirstName = $firstName
        RealFullName = $_.RealFullName
        FictitiousName = $_.FictitiousName
        WorkshopUsername = $_.WorkshopUsername      # Full UPN: oscarw@fabrikam1.csplevelup.com
        WorkshopAlias = $alias                       # Just alias: oscarw
        Role = $_.Role
        ChallengeLevel = $_.ChallengeLevel
    }
}

# Export for mail merge
$mailMergePath = Join-Path $infrastructurePath "proctor-mail-merge.csv"
$mailMergeData | Export-Csv $mailMergePath -NoTypeInformation

Write-Host "✅ Mail merge CSV created: $mailMergePath" -ForegroundColor Green
Write-Host "`n📊 Preview (first 3 entries):" -ForegroundColor Cyan
$mailMergeData | Select-Object -First 3 ToEmail, RealFirstName, WorkshopUsername, WorkshopAlias | Format-Table -AutoSize

Write-Host "`n📋 Available merge fields:" -ForegroundColor Yellow
Write-Host "  {{ToEmail}}           - Real email address (where to send)" -ForegroundColor Gray
Write-Host "  {{RealFirstName}}     - First name (e.g., David)" -ForegroundColor Gray
Write-Host "  {{RealFullName}}      - Full real name (e.g., David Bjurman-Birr)" -ForegroundColor Gray
Write-Host "  {{FictitiousName}}    - Workshop persona (e.g., Oscar Ward)" -ForegroundColor Gray
Write-Host "  {{WorkshopUsername}}  - Full UPN (e.g., oscarw@fabrikam1.csplevelup.com)" -ForegroundColor Gray
Write-Host "  {{WorkshopAlias}}     - Just alias (e.g., oscarw)" -ForegroundColor Gray
Write-Host "  {{Role}}              - Proctor or Participant" -ForegroundColor Gray
Write-Host "  {{ChallengeLevel}}    - Beginner/Intermediate/Advanced/Not Responded" -ForegroundColor Gray

Write-Host "`n💡 Usage tips:" -ForegroundColor Cyan
Write-Host "  - Use {{WorkshopUsername}} when showing full login credentials" -ForegroundColor Gray
Write-Host "  - Use {{WorkshopAlias}} in agent names or casual references" -ForegroundColor Gray
