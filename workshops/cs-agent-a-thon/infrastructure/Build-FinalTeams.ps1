# Build-FinalTeams.ps1
# Creates final team assignments with table seating for Agent-A-Thon workshop
# Tables seat 10 people (2 teams of 5 per table)
# Advanced participants grouped together, Beginner/Intermediate mixed
# Non-responders treated as Beginners

[CmdletBinding()]
param(
    [int]$IdealTeamSize = 5,
    [int]$MinTeamSize = 4,
    [int]$MaxTeamSize = 6,
    [int]$PeoplePerTable = 10
)

$ErrorActionPreference = "Stop"

Write-Host "`n🎯 Agent-A-Thon Final Team Builder" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Target: $IdealTeamSize per team, $PeoplePerTable per table (2 teams)" -ForegroundColor Gray
Write-Host ""

# Load data
$participants = Import-Csv "participant-assignments.csv"
$survey = Import-Csv "challenge-survey-responses.csv"

# Build survey lookup
$surveyLookup = @{}
foreach ($response in $survey) {
    $email = $response.Email.ToLower().Trim()
    $level = $response.'Preferred Challenge Level'
    
    # Normalize levels
    $normalizedLevel = switch ($level) {
        'Beginner' { 'Beginner' }
        'Intermediate' { 'Intermediate' }
        'Advanced' { 'Advanced' }
        'Proctor' { 'Proctor' }
        default { 'Beginner' } # Default non-responders to Beginner
    }
    
    $surveyLookup[$email] = $normalizedLevel
}

# Process participants (exclude proctors UserNumber 1-20)
$allParticipants = @()
foreach ($p in $participants) {
    # Skip proctors
    if ([int]$p.UserNumber -le 20) { continue }
    
    $email = $p.RealEmail.ToLower().Trim()
    
    # Get challenge level from survey, default to Beginner
    $challengeLevel = if ($surveyLookup.ContainsKey($email)) {
        $surveyLookup[$email]
    } else {
        'Beginner' # Non-responders = Beginner
    }
    
    # Skip if marked as Proctor in survey
    if ($challengeLevel -eq 'Proctor') { continue }
    
    $allParticipants += [PSCustomObject]@{
        UserNumber = [int]$p.UserNumber
        RealFirstName = $p.RealFirstName
        RealLastName = $p.RealLastName
        RealFullName = $p.RealFullName
        RealAlias = $p.RealAlias
        RealEmail = $p.RealEmail
        FictitiousFirstName = $p.FictitiousFirstName
        FictitiousLastName = $p.FictitiousLastName
        FictitiousFullName = $p.FictitiousFullName
        Alias = $p.Alias
        WorkshopUsername = "$($p.Alias)@fabrikam1.csplevelup.com"
        OriginalTeam = $p.Team
        Country = $p.Country
        Gender = $p.Gender
        Language = $p.Language
        ChallengeLevel = $challengeLevel
    }
}

Write-Host "📊 Participant Summary:" -ForegroundColor Yellow
Write-Host "   Total participants: $($allParticipants.Count)" -ForegroundColor Gray

# Separate by challenge level
$beginner = @($allParticipants | Where-Object { $_.ChallengeLevel -eq 'Beginner' })
$intermediate = @($allParticipants | Where-Object { $_.ChallengeLevel -eq 'Intermediate' })
$advanced = @($allParticipants | Where-Object { $_.ChallengeLevel -eq 'Advanced' })

Write-Host "   Beginner: $($beginner.Count)" -ForegroundColor Green
Write-Host "   Intermediate: $($intermediate.Count)" -ForegroundColor Yellow
Write-Host "   Advanced: $($advanced.Count)" -ForegroundColor Red
Write-Host ""

# Shuffle participants for random distribution
function Get-ShuffledArray($array) {
    $array | Sort-Object { Get-Random }
}

$shuffledAdvanced = Get-ShuffledArray $advanced
$shuffledBeginner = Get-ShuffledArray $beginner
$shuffledIntermediate = Get-ShuffledArray $intermediate

# Build teams
$teams = @()
$teamNumber = 1
$tableNumber = 1

Write-Host "🏗️  Building Teams..." -ForegroundColor Cyan
Write-Host ""

# STEP 1: Create Advanced-only teams
Write-Host "Creating Advanced Teams:" -ForegroundColor Red
$advancedRemaining = [System.Collections.ArrayList]::new($shuffledAdvanced)

while ($advancedRemaining.Count -gt 0) {
    # Determine team size
    $teamSize = if ($advancedRemaining.Count -le $MaxTeamSize) {
        $advancedRemaining.Count
    } elseif ($advancedRemaining.Count -le ($MaxTeamSize + $MinTeamSize)) {
        # Split remaining into 2 balanced teams
        [Math]::Ceiling($advancedRemaining.Count / 2.0)
    } else {
        $IdealTeamSize
    }
    
    $teamMembers = $advancedRemaining[0..($teamSize-1)]
    
    foreach ($member in $teamMembers) {
        $teams += [PSCustomObject]@{
            TableNumber = $tableNumber
            TeamNumber = $teamNumber
            TeamType = 'Advanced'
            TeamSize = $teamSize
            UserNumber = $member.UserNumber
            RealFirstName = $member.RealFirstName
            RealLastName = $member.RealLastName
            RealFullName = $member.RealFullName
            RealAlias = $member.RealAlias
            RealEmail = $member.RealEmail
            FictitiousFirstName = $member.FictitiousFirstName
            FictitiousLastName = $member.FictitiousLastName
            FictitiousFullName = $member.FictitiousFullName
            Alias = $member.Alias
            WorkshopUsername = $member.WorkshopUsername
            OriginalTeam = $member.OriginalTeam
            Country = $member.Country
            Gender = $member.Gender
            Language = $member.Language
            ChallengeLevel = $member.ChallengeLevel
        }
        $advancedRemaining.Remove($member)
    }
    
    Write-Host "   Team $teamNumber (Table $tableNumber): $teamSize members" -ForegroundColor Gray
    
    $teamNumber++
    
    # Move to next table after 2 teams
    if ($teamNumber % 2 -eq 1) { $tableNumber++ }
}

# STEP 2: Create Mixed teams (Beginner + Intermediate)
Write-Host "`nCreating Mixed Teams (Beginner/Intermediate):" -ForegroundColor Green

# Combine and shuffle beginner/intermediate
$mixedPool = [System.Collections.ArrayList]::new()
$mixedPool.AddRange($shuffledBeginner)
$mixedPool.AddRange($shuffledIntermediate)

while ($mixedPool.Count -gt 0) {
    # Determine team size
    $teamSize = if ($mixedPool.Count -le $MaxTeamSize) {
        $mixedPool.Count
    } elseif ($mixedPool.Count -le ($MaxTeamSize + $MinTeamSize)) {
        # Split remaining into 2 balanced teams
        [Math]::Ceiling($mixedPool.Count / 2.0)
    } else {
        $IdealTeamSize
    }
    
    $teamMembers = $mixedPool[0..($teamSize-1)]
    
    foreach ($member in $teamMembers) {
        $teams += [PSCustomObject]@{
            TableNumber = $tableNumber
            TeamNumber = $teamNumber
            TeamType = 'Mixed'
            TeamSize = $teamSize
            UserNumber = $member.UserNumber
            RealFirstName = $member.RealFirstName
            RealLastName = $member.RealLastName
            RealFullName = $member.RealFullName
            RealAlias = $member.RealAlias
            RealEmail = $member.RealEmail
            FictitiousFirstName = $member.FictitiousFirstName
            FictitiousLastName = $member.FictitiousLastName
            FictitiousFullName = $member.FictitiousFullName
            Alias = $member.Alias
            WorkshopUsername = $member.WorkshopUsername
            OriginalTeam = $member.OriginalTeam
            Country = $member.Country
            Gender = $member.Gender
            Language = $member.Language
            ChallengeLevel = $member.ChallengeLevel
        }
        $mixedPool.Remove($member)
    }
    
    Write-Host "   Team $teamNumber (Table $tableNumber): $teamSize members" -ForegroundColor Gray
    
    $teamNumber++
    
    # Move to next table after 2 teams
    if ($teamNumber % 2 -eq 1) { $tableNumber++ }
}

# Export to CSV
$outputPath = "teams-final.csv"
$teams | Sort-Object TableNumber, TeamNumber, UserNumber | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "`n✅ Team assignments complete!" -ForegroundColor Green
Write-Host "   Total participants: $($teams.Count)" -ForegroundColor Gray
Write-Host "   Total teams: $($teamNumber - 1)" -ForegroundColor Gray
Write-Host "   Total tables: $($tableNumber - 1)" -ForegroundColor Gray
Write-Host "   Output: $outputPath" -ForegroundColor Gray
Write-Host ""

# Display table summary
Write-Host "📋 Table Summary:" -ForegroundColor Cyan
$tableGroups = $teams | Group-Object TableNumber | Sort-Object Name
foreach ($table in $tableGroups) {
    $tableNum = $table.Name
    $tableMembers = $table.Group
    $teamsAtTable = $tableMembers | Group-Object TeamNumber
    
    Write-Host "`n  Table $tableNum ($($tableMembers.Count) people):" -ForegroundColor Yellow
    foreach ($team in $teamsAtTable) {
        $teamNum = $team.Name
        $teamType = $team.Group[0].TeamType
        $teamSize = $team.Count
        
        $begCount = @($team.Group | Where-Object { $_.ChallengeLevel -eq 'Beginner' }).Count
        $intCount = @($team.Group | Where-Object { $_.ChallengeLevel -eq 'Intermediate' }).Count
        $advCount = @($team.Group | Where-Object { $_.ChallengeLevel -eq 'Advanced' }).Count
        
        $levelBreakdown = @()
        if ($begCount -gt 0) { $levelBreakdown += "B:$begCount" }
        if ($intCount -gt 0) { $levelBreakdown += "I:$intCount" }
        if ($advCount -gt 0) { $levelBreakdown += "A:$advCount" }
        
        Write-Host "    Team $teamNum [$teamType]: $teamSize members ($($levelBreakdown -join ', '))" -ForegroundColor Gray
    }
}

Write-Host "`n✨ Ready for mail merge and table tents!" -ForegroundColor Green
Write-Host ""
