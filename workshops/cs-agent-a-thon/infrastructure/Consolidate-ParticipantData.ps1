<#
.SYNOPSIS
Consolidates all participant/proctor CSVs into a single comprehensive tracking file.

.DESCRIPTION
Creates a unified participant database with:
- All participants and proctors
- Mail merge fields (name, email, country)
- Access preference status (disable, currentTenant, continuous, externalParticipant)
- Role tracking (Participant, Proctor)
- Fictitious identity information for tenant
- No team assignments (can be mapped separately)
#>

$ScriptDir = $PSScriptRoot

# Load source CSVs
# Note: After cleanup, source files are in archive/source-files/
# Check both locations for backward compatibility
$participantsFile = if (Test-Path (Join-Path $ScriptDir "participants-final.csv")) {
    Join-Path $ScriptDir "participants-final.csv"
} else {
    Join-Path $ScriptDir "archive/source-files/participants-final.csv"
}

$proctorsFile = if (Test-Path (Join-Path $ScriptDir "proctors-final.csv")) {
    Join-Path $ScriptDir "proctors-final.csv"
} else {
    Join-Path $ScriptDir "archive/source-files/proctors-final.csv"
}

$accessPreferencesFile = Join-Path $ScriptDir "Fabrikam Agent-a-thon Workshop_ Tenant Access Preferences(1-8).csv"

Write-Host "Loading source files..." -ForegroundColor Cyan

# Load participants and proctors
$participants = Import-Csv $participantsFile
$proctors = Import-Csv $proctorsFile

# Load access preferences
$accessPreferences = Import-Csv $accessPreferencesFile

# Create access preference lookup by email (lowercase for case-insensitive matching)
$accessLookup = @{}
foreach ($pref in $accessPreferences) {
    $email = $pref.Email.Trim().ToLower()
    $accessLookup[$email] = $pref.'What would you like to do with your Fabrikam tenant access? (These tenants are ephemeral and expire after about 90 days)'
}

Write-Host "Found $($participants.Count) participants" -ForegroundColor Green
Write-Host "Found $($proctors.Count) proctors" -ForegroundColor Green
Write-Host "Found $($accessPreferences.Count) access preference responses" -ForegroundColor Green

# Create consolidated list
$consolidated = @()

# Process participants
foreach ($person in $participants) {
    $email = $person.RealEmail.Trim().ToLower()
    
    # Determine access preference status
    $accessPref = $accessLookup[$email]
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
    
    # Extract first name from full name (everything before last space)
    $realFirstName = if ($person.RealFullName -match '^(.+)\s+\S+$') {
        $matches[1]
    } else {
        $person.RealFullName  # Fallback if no space found
    }
    
    $consolidated += [PSCustomObject]@{
        UserNumber = $person.UserNumber
        Role = "Participant"
        Status = $status
        RealFullName = $person.RealFullName
        RealFirstName = $realFirstName
        RealAlias = $person.RealAlias
        RealEmail = $person.RealEmail
        Country = $person.Country
        FictitiousFirstName = $person.FictitiousFirstName
        FictitiousLastName = $person.FictitiousLastName
        FictitiousFullName = $person.FictitiousFullName
        FictitiousGender = $person.FictitiousGender
        FictitiousLanguage = $person.FictitiousLanguage
        NativeUserPrincipalName = $person.NativeUserPrincipalName
        DisplayName = $person.DisplayName
        Alias = $person.Alias
        AccessPreferenceResponse = $accessPref
    }
}

# Process proctors
foreach ($person in $proctors) {
    $email = $person.RealEmail.Trim().ToLower()
    
    # Determine access preference status
    $accessPref = $accessLookup[$email]
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
    
    # Extract first name from full name for mail merge
    $realFirstName = if ($person.RealFullName -match '^(.+)\s+\S+$') {
        $matches[1]  # Everything before last space
    } else {
        $person.RealFullName  # Fallback if no space found
    }
    
    $consolidated += [PSCustomObject]@{
        UserNumber = $person.UserNumber
        Role = "Proctor"
        Status = $status
        RealFullName = $person.RealFullName
        RealFirstName = $realFirstName
        RealAlias = $person.RealAlias
        RealEmail = $person.RealEmail
        Country = $person.Country
        FictitiousFirstName = $person.FictitiousFirstName
        FictitiousLastName = $person.FictitiousLastName
        FictitiousFullName = $person.FictitiousFullName
        FictitiousGender = $person.FictitiousGender
        FictitiousLanguage = $person.FictitiousLanguage
        NativeUserPrincipalName = $person.NativeUserPrincipalName
        DisplayName = $person.DisplayName
        Alias = $person.Alias
        AccessPreferenceResponse = $accessPref
    }
}

# --- Add External Participants from workshop-user-mapping.csv ---
Write-Host "Adding external participants..." -ForegroundColor Cyan

# Load external users (like Yara) from workshop-user-mapping.csv
# These are users with non-@microsoft.com emails
# Note: After cleanup, this file is in archive/source-files/
$userMappingPath = if (Test-Path (Join-Path $ScriptDir "workshop-user-mapping.csv")) {
    Join-Path $ScriptDir "workshop-user-mapping.csv"
} else {
    Join-Path $ScriptDir "archive/source-files/workshop-user-mapping.csv"
}

$allUsers = Import-Csv $userMappingPath

# Filter for external users (non-Microsoft emails)
$externalUsers = $allUsers | Where-Object { 
    $_.RealEmail -notlike "*@microsoft.com" 
}

Write-Host "Found $($externalUsers.Count) external participants" -ForegroundColor Green

# Add external users to consolidated list
foreach ($user in $externalUsers) {
    # Check if they have an access preference
    $accessPref = $accessPreferences[$user.RealEmail.ToLower()]
    
    # Determine status - external users should keep their tenant access by default
    $status = if ($accessPref) {
        switch -Wildcard ($accessPref) {
            "*Keep my access active*" { "continuous" }
            "*This tenant + the next one*" { "continuous" }
            "*Disable my access*" { "disable" }
            default { "externalParticipant" }
        }
    } else {
        "externalParticipant"  # Default for external users
    }
    
    # Extract first name from full name for mail merge
    $realFirstName = if ($user.RealFullName -match '^(.+)\s+\S+$') {
        $matches[1]  # Everything before last space
    } else {
        $user.RealFullName  # Fallback if no space found
    }
    
    $consolidated += [PSCustomObject]@{
        UserNumber = $user.UserNumber
        Role = "ExternalParticipant"
        Status = $status
        RealFullName = $user.RealFullName
        RealFirstName = $realFirstName
        RealAlias = $user.RealAlias
        RealEmail = $user.RealEmail
        Country = $user.Country
        FictitiousFirstName = $user.FictitiousFirstName
        FictitiousLastName = $user.FictitiousLastName
        FictitiousFullName = $user.FictitiousFullName
        FictitiousGender = $user.FictitiousGender
        FictitiousLanguage = $user.FictitiousLanguage
        NativeUserPrincipalName = $user.NativeUserPrincipalName
        DisplayName = $user.DisplayName
        Alias = $user.Alias
        AccessPreferenceResponse = if ($accessPref) { $accessPref } else { "" }
    }
}

# Sort by role (Proctor first, then Participant, then External), then by last name
$consolidated = $consolidated | Sort-Object @{Expression = {
    switch ($_.Role) {
        "Proctor" { 1 }
        "Participant" { 2 }
        "ExternalParticipant" { 3 }
    }
}}, @{Expression = { $_.RealFullName.Split(' ')[-1] }}

# Export consolidated file
$outputFile = Join-Path $ScriptDir "workshop-participants-consolidated.csv"
$consolidated | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "`nConsolidation complete!" -ForegroundColor Green
Write-Host "Output file: $outputFile" -ForegroundColor Cyan
Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  Total records: $($consolidated.Count)" -ForegroundColor White
Write-Host "  Participants: $(($consolidated | Where-Object Role -eq 'Participant').Count)" -ForegroundColor White
Write-Host "  Proctors: $(($consolidated | Where-Object Role -eq 'Proctor').Count)" -ForegroundColor White
Write-Host "  External: $(($consolidated | Where-Object Role -eq 'ExternalParticipant').Count)" -ForegroundColor White
Write-Host "`nStatus breakdown:" -ForegroundColor Yellow
Write-Host "  Continuous access: $(($consolidated | Where-Object Status -eq 'continuous').Count)" -ForegroundColor Green
Write-Host "  Current tenant only: $(($consolidated | Where-Object Status -eq 'currentTenant').Count)" -ForegroundColor Cyan
Write-Host "  Disable access: $(($consolidated | Where-Object Status -eq 'disable').Count)" -ForegroundColor Red
Write-Host "  External participant: $(($consolidated | Where-Object Status -eq 'externalParticipant').Count)" -ForegroundColor Magenta

# Show sample records
Write-Host "`nSample records:" -ForegroundColor Yellow
$consolidated | Select-Object -First 5 | Format-Table Role, Status, RealFullName, RealEmail, Country -AutoSize
