<#
.SYNOPSIS
    Generate native user mappings from attendees.csv
    
.DESCRIPTION
    Creates workshop user accounts mapping real Microsoft emails to native accounts
    Maintains mapping for communication purposes
    
.PARAMETER AttendeesFile
    Path to attendees.csv file
    
.PARAMETER ProctorsOnly
    Generate only proctor mappings
    
.PARAMETER ParticipantsOnly
    Generate only participant mappings
    
.EXAMPLE
    .\Generate-UserMappings.ps1 -AttendeesFile "attendees.csv"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AttendeesFile = "..\attendees.csv",
    
    [Parameter(Mandatory = $false)]
    [switch]$ProctorsOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$ParticipantsOnly
)

$ErrorActionPreference = "Stop"

Write-Host "🔄 Generating Native User Mappings" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
$outputDir = ".."
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Read attendees file
Write-Host "Reading attendees from: $AttendeesFile" -ForegroundColor Yellow
if (-not (Test-Path $AttendeesFile)) {
    Write-Host "❌ File not found: $AttendeesFile" -ForegroundColor Red
    exit 1
}

$attendees = Import-Csv -Path $AttendeesFile
Write-Host "✅ Found $($attendees.Count) total attendees" -ForegroundColor Green
Write-Host ""

# Proctor mappings (hardcoded based on team-roster.md)
$proctorMappings = @(
    @{ WorkshopUsername = "davidb"; DisplayName = "David Birrueta"; RealEmail = "davidb@microsoft.com"; Team = "Proctors"; Notes = "Initial admin" },
    @{ WorkshopUsername = "oscarw"; DisplayName = "Oscar Ward"; RealEmail = "oscarw@microsoft.com"; Team = "Proctors"; Notes = "Co-admin" },
    @{ WorkshopUsername = "mertu"; DisplayName = "Mert Unan"; RealEmail = "mertunan@microsoft.com"; Team = "Proctors"; Notes = "Lead proctor" },
    @{ WorkshopUsername = "kirkd"; DisplayName = "Kirk Daues"; RealEmail = "kirkda@microsoft.com"; Team = "Proctors"; Notes = "Lead proctor" },
    @{ WorkshopUsername = "zahids"; DisplayName = "Zahid Saeed"; RealEmail = "zahids@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "olgab"; DisplayName = "Olga Burmistrov"; RealEmail = "olgabu@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "rachellg"; DisplayName = "Rachel Gross"; RealEmail = "ragrose@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "rubenh"; DisplayName = "Ruben Huber"; RealEmail = "rubhuber@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "samts"; DisplayName = "Sam Tsassen"; RealEmail = "stsassen@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "mattb"; DisplayName = "Matt Bennett"; RealEmail = "mattben@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "sarahf"; DisplayName = "Sarah Farnsworth"; RealEmail = "sarafa@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "jessicar"; DisplayName = "Jessica Renfro"; RealEmail = "jessicar@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "lukep"; DisplayName = "Luke Pelton"; RealEmail = "lukep@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "ashleyh"; DisplayName = "Ashley Heckert"; RealEmail = "ashleyhe@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "michaelsc"; DisplayName = "Michael Schoening"; RealEmail = "michaesc@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "briand"; DisplayName = "Brian Dunn"; RealEmail = "briand@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "robertp"; DisplayName = "Robert Pearce"; RealEmail = "robertpe@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "mandis"; DisplayName = "Mandi Sisk"; RealEmail = "mandis@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "christianc"; DisplayName = "Christian Chilcott"; RealEmail = "christianc@microsoft.com"; Team = "Proctors"; Notes = "" },
    @{ WorkshopUsername = "kayed"; DisplayName = "Kaye DeMattia"; RealEmail = "kayed@microsoft.com"; Team = "Proctors"; Notes = "" }
)

if (-not $ParticipantsOnly) {
    Write-Host "📋 Generating Proctor Mappings..." -ForegroundColor Yellow
    
    $proctorCsv = $proctorMappings | ForEach-Object {
        [PSCustomObject]@{
            WorkshopUsername = "$($_.WorkshopUsername)@fabrikam1.csplevelup.com"
            DisplayName = $_.DisplayName
            RealEmail = $_.RealEmail
            Team = $_.Team
            Role = "Proctor"
            Notes = $_.Notes
        }
    }
    
    $proctorOutputFile = Join-Path $outputDir "proctors-mapping.csv"
    $proctorCsv | Export-Csv -Path $proctorOutputFile -NoTypeInformation
    Write-Host "✅ Created: $proctorOutputFile ($($proctorCsv.Count) proctors)" -ForegroundColor Green
    Write-Host ""
}

if (-not $ProctorsOnly) {
    Write-Host "📋 Generating Participant Mappings..." -ForegroundColor Yellow
    
    # Filter out proctors from attendees
    $proctorEmails = $proctorMappings | ForEach-Object { $_.RealEmail.Split('@')[0].ToLower() }
    
    $participants = $attendees | Where-Object {
        $email = $_.Email
        if ([string]::IsNullOrWhiteSpace($email)) { return $false }
        
        $alias = $email.Split('@')[0].ToLower()
        return $proctorEmails -notcontains $alias
    }
    
    Write-Host "Found $($participants.Count) participants (filtered out proctors)" -ForegroundColor Gray
    
    # Generate participant mappings
    $participantCsv = $participants | ForEach-Object {
        $fullName = $_.FullName
        $alias = $_.Alias
        $email = $_.Email
        
        # Skip if name or alias is empty
        if ([string]::IsNullOrWhiteSpace($fullName) -or [string]::IsNullOrWhiteSpace($alias)) {
            Write-Host "⚠️  Skipping attendee with empty data: $email" -ForegroundColor Yellow
            return
        }
        
        # Use alias (lowercase) as username - simple and matches their Microsoft email
        $username = $alias.ToLower()
        
        [PSCustomObject]@{
            WorkshopUsername = "$username@fabrikam1.csplevelup.com"
            DisplayName = $fullName
            RealEmail = $email
            Team = "TBD" # Will be assigned after challenge survey
            Role = "Participant"
            Alias = $alias
            Notes = ""
        }
    }
    
    $participantOutputFile = Join-Path $outputDir "participants-mapping.csv"
    $participantCsv | Export-Csv -Path $participantOutputFile -NoTypeInformation
    Write-Host "✅ Created: $participantOutputFile ($($participantCsv.Count) participants)" -ForegroundColor Green
    Write-Host ""
}

# Create combined mapping
if (-not $ProctorsOnly -and -not $ParticipantsOnly) {
    Write-Host "📋 Generating Combined Mapping..." -ForegroundColor Yellow
    
    $allUsers = @()
    $allUsers += $proctorCsv
    $allUsers += $participantCsv
    
    $combinedOutputFile = Join-Path $outputDir "all-users-mapping.csv"
    $allUsers | Export-Csv -Path $combinedOutputFile -NoTypeInformation
    Write-Host "✅ Created: $combinedOutputFile ($($allUsers.Count) total users)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ User Mapping Generation Complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "   Proctors: $($proctorMappings.Count)" -ForegroundColor White
if (-not $ProctorsOnly) {
    Write-Host "   Participants: $($participantCsv.Count)" -ForegroundColor White
    Write-Host "   Total Users: $($proctorMappings.Count + $participantCsv.Count)" -ForegroundColor White
}
Write-Host ""
Write-Host "📁 Output Files:" -ForegroundColor Yellow
if (-not $ParticipantsOnly) {
    Write-Host "   $proctorOutputFile" -ForegroundColor Cyan
}
if (-not $ProctorsOnly) {
    Write-Host "   $participantOutputFile" -ForegroundColor Cyan
    if (-not $ProctorsOnly -and -not $ParticipantsOnly) {
        Write-Host "   $combinedOutputFile" -ForegroundColor Cyan
    }
}
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Review generated mappings for accuracy" -ForegroundColor White
Write-Host "   2. Check for duplicate usernames" -ForegroundColor White
Write-Host "   3. Run Provision-NativeUsers.ps1 to create accounts" -ForegroundColor White
Write-Host "   4. Generate and securely distribute credentials" -ForegroundColor White
Write-Host ""
