<#
.SYNOPSIS
Adds Emmy Jäger (BGLead) to the consolidated participants file with InitialPassword field.

.DESCRIPTION
This script:
1. Reads the current consolidated CSV
2. Adds InitialPassword column with placeholder values for existing users
3. Generates a new password for Emmy
4. Adds Emmy with role "BGLead" and a unique fictitious identity
5. Exports the updated CSV
#>

$ScriptDir = $PSScriptRoot

# Function to generate a strong random password
function New-RandomPassword {
    param([int]$Length = 16)
    
    $uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $lowercase = "abcdefghijkmnopqrstuvwxyz"
    $numbers = "23456789"
    $special = "@#$*"
    
    $password = @()
    $password += $uppercase[(Get-Random -Maximum $uppercase.Length)]
    $password += $lowercase[(Get-Random -Maximum $lowercase.Length)]
    $password += $numbers[(Get-Random -Maximum $numbers.Length)]
    $password += $special[(Get-Random -Maximum $special.Length)]
    
    $allChars = $uppercase + $lowercase + $numbers + $special
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    # Shuffle the password
    return -join ($password | Get-Random -Count $password.Count)
}

Write-Host "`n👤 Adding Emmy Jäger to Consolidated Participants" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Load current consolidated file
$csvPath = Join-Path $ScriptDir "workshop-participants-consolidated.csv"
$participants = Import-Csv $csvPath

Write-Host "Loaded $($participants.Count) existing participants" -ForegroundColor Green

# Add InitialPassword column to existing participants
Write-Host "`nAdding InitialPassword field to existing users..." -ForegroundColor Yellow

$updatedParticipants = $participants | ForEach-Object {
    $_ | Add-Member -NotePropertyName "InitialPassword" -NotePropertyValue "CredentialsSent" -Force -PassThru
}

# Generate new password for Emmy
$emmyPassword = New-RandomPassword -Length 16

# Get next user number (140)
$maxUserNumber = ($participants | ForEach-Object { [int]$_.UserNumber } | Measure-Object -Maximum).Maximum
$newUserNumber = $maxUserNumber + 1

Write-Host "Assigned UserNumber: $newUserNumber" -ForegroundColor Green

# Create Emmy's record with fictitious identity
$emmy = [PSCustomObject]@{
    UserNumber = $newUserNumber
    Role = "BGLead"
    Status = "continuous"  # BG Lead should have continuous access
    RealFullName = "Emmy Jäger"
    RealFirstName = "Emmy"  # For mail merge compatibility
    RealAlias = "EMMYHE"
    RealEmail = "emmyhe@microsoft.com"
    Country = "Sweden"
    FictitiousFirstName = "Diana"
    FictitiousLastName = "Bergqvist"
    FictitiousFullName = "Diana Bergqvist"
    FictitiousGender = "Female"
    FictitiousLanguage = "Swedish"
    NativeUserPrincipalName = "DianaB@fabrikam1.csplevelup.com"
    DisplayName = "Diana Bergqvist"
    Alias = "DianaB"
    AccessPreferenceResponse = ""
    InitialPassword = $emmyPassword
}

Write-Host "`nEmmy's Details:" -ForegroundColor Cyan
Write-Host "  Real Name:      Emmy Jäger (EMMYHE)" -ForegroundColor White
Write-Host "  Email:          emmyhe@microsoft.com" -ForegroundColor White
Write-Host "  Role:           BGLead" -ForegroundColor White
Write-Host "  Status:         continuous (BG Lead access)" -ForegroundColor White
Write-Host "  Fictitious:     Diana Bergqvist (Female, Swedish)" -ForegroundColor White
Write-Host "  Tenant UPN:     DianaB@fabrikam1.csplevelup.com" -ForegroundColor White
Write-Host "  Password:       $emmyPassword" -ForegroundColor Yellow

# Add Emmy to the list
$updatedParticipants += $emmy

# Sort by role priority, then by last name
$sortedParticipants = $updatedParticipants | Sort-Object @{Expression = {
    switch ($_.Role) {
        "BGLead" { 0 }      # BG Lead first
        "Proctor" { 1 }
        "Participant" { 2 }
        "ExternalParticipant" { 3 }
        default { 4 }
    }
}}, @{Expression = { 
    if ($_.RealFullName -match ' ') {
        ($_.RealFullName -split ' ')[-1]  # Last name
    } else {
        $_.RealFullName
    }
}}

# Export updated CSV
$sortedParticipants | Export-Csv $csvPath -NoTypeInformation -Force

Write-Host "`n✅ Updated consolidated file!" -ForegroundColor Green
Write-Host "  Total records: $($sortedParticipants.Count)" -ForegroundColor White
Write-Host "  BG Leads: $(($sortedParticipants | Where-Object Role -eq 'BGLead').Count)" -ForegroundColor White
Write-Host "  Proctors: $(($sortedParticipants | Where-Object Role -eq 'Proctor').Count)" -ForegroundColor White
Write-Host "  Participants: $(($sortedParticipants | Where-Object Role -eq 'Participant').Count)" -ForegroundColor White
Write-Host "  External: $(($sortedParticipants | Where-Object Role -eq 'ExternalParticipant').Count)" -ForegroundColor White

# Save credentials to a separate file for Emmy
$credentialFile = Join-Path $ScriptDir "emmy-credentials.txt"
@"
Emmy Jäger - Tenant Credentials
================================

Real Identity:
  Name:  Emmy Jäger
  Email: emmyhe@microsoft.com
  Role:  BG Lead (Business Group Lead)

Fictitious Identity (Tenant):
  Name:     Diana Bergqvist
  UPN:      DianaB@fabrikam1.csplevelup.com
  Password: $emmyPassword
  
Tenant Details:
  Domain:   fabrikam1.csplevelup.com
  Status:   Continuous access (BG Lead)
  
Next Steps:
  1. Create user in tenant
  2. Send credentials to Emmy
  3. Grant appropriate permissions for BG Lead role
  
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@ | Out-File $credentialFile -Force

Write-Host "`n📄 Credentials saved to: emmy-credentials.txt" -ForegroundColor Cyan
Write-Host "`n🔐 IMPORTANT: Securely send credentials to Emmy!" -ForegroundColor Yellow

# Display next steps
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. ✅ Emmy added to consolidated CSV" -ForegroundColor Green
Write-Host "  2. ⏳ Create user in tenant (use Setup-Instance.ps1 or manual)" -ForegroundColor Yellow
Write-Host "  3. ⏳ Send credentials from emmy-credentials.txt" -ForegroundColor Yellow
Write-Host "  4. ⏳ Grant BG Lead permissions in tenant" -ForegroundColor Yellow
