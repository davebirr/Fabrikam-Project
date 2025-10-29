<#
.SYNOPSIS
    Adds Role column to participant-assignments.csv to identify proctors vs participants

.DESCRIPTION
    Reads participant-assignments.csv, adds a "Role" column based on proctor list,
    and exports as workshop-user-mapping.csv for provisioning

.NOTES
    Real Microsoft employees → Fictitious workshop identities
    NO PII in workshop tenant, only fictitious names
#>

#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define proctor aliases (from team-roster.md)
$proctorAliases = @(
    'DAVIDB',          # David Bjurman-Birr - Workshop Lead
    'MERTUNAN',        # Mert Unan - Regional Expert
    'KIRKDA',          # Kirk Daues - Solutions Architect
    'APRILDELSING',    # April Delsing
    'CDEPAEPE',        # Cedric Depaepe
    'ESALVAREZ',       # Estefanie Alvarez
    'FRANVANH',        # Francois van Hemert
    'JIMBANACH',       # Jim Banach
    'JOWRIG',          # Jojo Wright
    'MADERIDD',        # Mario De Ridder
    'MARIUSZO',        # Mariusz Ostrowski
    'MABOAM',          # Martin Boam
    'MADAVI',          # Matthew Davis
    'MIKEPALITTO',     # Mike Palitto
    'OGORDON',         # Olga Gordon
    'RAGNARPITLA',     # Ragnar Pitla
    'RUNAUWEL',        # Ruben Nauwelaers
    'SARAHBURG',       # Sarah Burg
    'STSCHULZ',        # Stefan Schulz
    'ZASAEED'          # Zahid Saeed
)

Write-Host "`n🎯 Adding Role Column to Participant Assignments" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Read participant assignments  
$infrastructurePath = Join-Path $PSScriptRoot ".." ".."
$csvPath = Join-Path $infrastructurePath "infrastructure" "participant-assignments.csv"
if (-not (Test-Path $csvPath)) {
    throw "participant-assignments.csv not found at: $csvPath"
}

Write-Host "`n📂 Reading: participant-assignments.csv" -ForegroundColor Yellow
$assignments = Import-Csv $csvPath

Write-Host "   Found $($assignments.Count) total attendees" -ForegroundColor White

# Add Role column
$enrichedAssignments = $assignments | ForEach-Object {
    $role = if ($proctorAliases -contains $_.RealAlias) { "Proctor" } else { "Participant" }
    
    [PSCustomObject]@{
        UserNumber               = $_.UserNumber
        RealFullName             = $_.RealFullName
        RealAlias                = $_.RealAlias
        RealEmail                = $_.RealEmail
        Team                     = $_.Team
        Country                  = $_.Country
        Role                     = $role
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

# Count roles
$proctorCount = ($enrichedAssignments | Where-Object { $_.Role -eq "Proctor" }).Count
$participantCount = ($enrichedAssignments | Where-Object { $_.Role -eq "Participant" }).Count

Write-Host "`n✅ Role Distribution:" -ForegroundColor Green
Write-Host "   Proctors:     $proctorCount" -ForegroundColor Cyan
Write-Host "   Participants: $participantCount" -ForegroundColor Cyan
Write-Host "   Total:        $($enrichedAssignments.Count)" -ForegroundColor White

# Export to new file
$outputPath = Join-Path $infrastructurePath "infrastructure" "workshop-user-mapping.csv"
$enrichedAssignments | Export-Csv -Path $outputPath -NoTypeInformation -Force

Write-Host "`n📁 Exported: workshop-user-mapping.csv" -ForegroundColor Green
Write-Host "   Location: $outputPath" -ForegroundColor White

# Also create proctor-only and participant-only lists for reference
$proctorPath = Join-Path $infrastructurePath "infrastructure" "proctors-final.csv"
$participantPath = Join-Path $infrastructurePath "infrastructure" "participants-final.csv"

$enrichedAssignments | Where-Object { $_.Role -eq "Proctor" } | 
    Export-Csv -Path $proctorPath -NoTypeInformation -Force

$enrichedAssignments | Where-Object { $_.Role -eq "Participant" } | 
    Export-Csv -Path $participantPath -NoTypeInformation -Force

Write-Host "`n📁 Created reference files:" -ForegroundColor Yellow
Write-Host "   - proctors-final.csv ($proctorCount users)" -ForegroundColor White
Write-Host "   - participants-final.csv ($participantCount users)" -ForegroundColor White

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "✅ COMPLETE - Ready for user provisioning!" -ForegroundColor Green
Write-Host "`nNext Step: Use workshop-user-mapping.csv to provision users" -ForegroundColor Yellow
Write-Host ""
