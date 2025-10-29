# 👥 Workshop Team Assignment Generator
# CS Agent-A-Thon Workshop - November 6, 2025
# Assigns 126 attendees to 5 balanced teams

param(
    [Parameter(Mandatory=$false)]
    [string]$AttendeeCsvPath = ".\attendees.csv",
    
    [Parameter(Mandatory=$false)]
    [int]$TeamCount = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$TargetTeamSize = 25,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\team-assignments.csv"
)

Write-Host "=== CS Agent-A-Thon Team Assignment Generator ===" -ForegroundColor Green
Write-Host "Target: $TeamCount teams of ~$TargetTeamSize participants each"

# Load attendee data
try {
    $attendees = Import-Csv -Path $AttendeeCsvPath
    Write-Host "Loaded $($attendees.Count) attendees from $AttendeeCsvPath" -ForegroundColor Green
}
catch {
    Write-Host "Error loading attendee data: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define team themes and focus areas
$teamThemes = @(
    @{
        Name = "Team Alpha"
        InstanceUrl = "https://fabrikam-api-a01.azurewebsites.net"
        Focus = "Customer Service Hero - Beginner Focus"
        Color = "Blue"
        ProctorSuggestion = "DAVIDB@microsoft.com (David Bjurman-Birr)"
    },
    @{
        Name = "Team Beta"
        InstanceUrl = "https://fabrikam-api-a02.azurewebsites.net"
        Focus = "Sales Intelligence Wizard - Intermediate Focus"
        Color = "Green"
        ProctorSuggestion = "PAULKALSBEEK@microsoft.com (Paul Kalsbeek)"
    },
    @{
        Name = "Team Gamma"
        InstanceUrl = "https://fabrikam-api-a03.azurewebsites.net"
        Focus = "Executive Assistant Ecosystem - Advanced Focus"
        Color = "Red"
        ProctorSuggestion = "KENNITHS@microsoft.com (Ken St. Cyr)"
    },
    @{
        Name = "Team Delta"
        InstanceUrl = "https://fabrikam-api-a04.azurewebsites.net"
        Focus = "Mixed Scenarios - Choose Your Adventure"
        Color = "Orange"
        ProctorSuggestion = "DSTOKER@microsoft.com (David Stoker)"
    },
    @{
        Name = "Team Epsilon"
        InstanceUrl = "https://fabrikam-api-a05.azurewebsites.net"
        Focus = "Experimental/Advanced - Innovation Lab"
        Color = "Purple"
        ProctorSuggestion = "PHNARAS@microsoft.com (Pani Murthy)"
    }
)

# Prepare attendees with assignment priorities
$attendeesWithPriority = @()
foreach ($attendee in $attendees) {
    $priority = 1
    
    # Higher priority for managers and leadership
    $leadershipRoles = @("BRENTSIN", "ROBINRH", "ANNADEITZ", "PHNARAS", "FABIANS", "PAULKALSBEEK", "KENNITHS", "DSTOKER")
    if ($attendee.Alias -in $leadershipRoles) {
        $priority = 3
    }
    
    # Medium priority for team leads and senior roles
    $teamLeadIndicators = @("manager", "lead", "principal", "senior")
    if ($teamLeadIndicators | Where-Object { $attendee.Team -like "*$_*" }) {
        $priority = 2
    }
    
    $attendeesWithPriority += [PSCustomObject]@{
        FullName = $attendee.FullName
        Alias = $attendee.Alias
        Email = $attendee.Email
        Manager = $attendee.Manager
        Team = $attendee.Team
        Country = $attendee.Country
        Priority = $priority
        AssignedTeam = ""
        AssignedInstance = ""
        AssignedFocus = ""
    }
}

# Sort attendees for balanced assignment
# 1. By priority (leaders first for even distribution)
# 2. By country (geographic distribution)  
# 3. By team (organizational diversity)
$sortedAttendees = $attendeesWithPriority | Sort-Object @{Expression="Priority"; Descending=$true}, Country, Team

Write-Host "`nAssigning attendees to teams..." -ForegroundColor Yellow

# Round-robin assignment with balancing
$teamAssignments = @()
for ($i = 0; $i -lt $TeamCount; $i++) {
    $teamAssignments += @{
        TeamInfo = $teamThemes[$i]
        Members = @()
        Countries = @{}
        Teams = @{}
    }
}

# Assign attendees in round-robin fashion
$currentTeamIndex = 0
foreach ($attendee in $sortedAttendees) {
    $team = $teamAssignments[$currentTeamIndex]
    
    # Add to team
    $attendee.AssignedTeam = $team.TeamInfo.Name
    $attendee.AssignedInstance = $team.TeamInfo.InstanceUrl
    $attendee.AssignedFocus = $team.TeamInfo.Focus
    
    $team.Members += $attendee
    
    # Track diversity metrics
    if (-not $team.Countries.ContainsKey($attendee.Country)) {
        $team.Countries[$attendee.Country] = 0
    }
    $team.Countries[$attendee.Country]++
    
    if (-not $team.Teams.ContainsKey($attendee.Team)) {
        $team.Teams[$attendee.Team] = 0
    }
    $team.Teams[$attendee.Team]++
    
    # Move to next team
    $currentTeamIndex = ($currentTeamIndex + 1) % $TeamCount
}

# Display team assignments
Write-Host "`n=== Team Assignment Results ===" -ForegroundColor Green

foreach ($team in $teamAssignments) {
    $teamInfo = $team.TeamInfo
    $members = $team.Members
    
    Write-Host "`n🎯 $($teamInfo.Name) ($($teamInfo.Color))" -ForegroundColor Yellow
    Write-Host "   Focus: $($teamInfo.Focus)"
    Write-Host "   Instance: $($teamInfo.InstanceUrl)"
    Write-Host "   Suggested Proctor: $($teamInfo.ProctorSuggestion)"
    Write-Host "   Members: $($members.Count)"
    
    # Show diversity metrics
    Write-Host "   Countries: $($team.Countries.Keys -join ', ')"
    Write-Host "   Teams: $($team.Teams.Keys.Count) different Microsoft teams"
    
    # Show member sample
    $sampleMembers = $members | Select-Object -First 3
    Write-Host "   Sample Members:"
    foreach ($member in $sampleMembers) {
        Write-Host "     • $($member.FullName) ($($member.Country), $($member.Team))"
    }
    if ($members.Count -gt 3) {
        Write-Host "     • ... and $($members.Count - 3) more"
    }
}

# Export assignments
Write-Host "`nExporting team assignments to $OutputPath..." -ForegroundColor Yellow

$allAssignments = @()
foreach ($team in $teamAssignments) {
    foreach ($member in $team.Members) {
        $allAssignments += $member
    }
}

$allAssignments | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Team assignments exported successfully!" -ForegroundColor Green

# Generate summary statistics
Write-Host "`n=== Assignment Summary ===" -ForegroundColor Green
Write-Host "Total attendees assigned: $($allAssignments.Count)"
Write-Host "Team size range: $(($teamAssignments | ForEach-Object { $_.Members.Count } | Measure-Object -Minimum).Minimum) - $(($teamAssignments | ForEach-Object { $_.Members.Count } | Measure-Object -Maximum).Maximum)"

$countryDistribution = $allAssignments | Group-Object Country | Sort-Object Count -Descending
Write-Host "`nCountry distribution across all teams:"
foreach ($country in $countryDistribution | Select-Object -First 10) {
    Write-Host "  $($country.Name): $($country.Count) attendees"
}

$teamDistribution = $allAssignments | Group-Object Team | Sort-Object Count -Descending
Write-Host "`nMicrosoft team distribution across all teams:"
foreach ($msTeam in $teamDistribution | Select-Object -First 10) {
    Write-Host "  $($msTeam.Name): $($msTeam.Count) attendees"
}

# Generate proctor instructions
$proctorInstructions = @"
# 🎯 Proctor Team Assignments

## Team Distribution Summary
$(foreach ($team in $teamAssignments) {
"**$($team.TeamInfo.Name)** - $($team.Members.Count) members
- Focus: $($team.TeamInfo.Focus)
- Instance: $($team.TeamInfo.InstanceUrl)
- Suggested Proctor: $($team.TeamInfo.ProctorSuggestion)
- Countries: $($team.Countries.Keys -join ', ')
- Microsoft Teams: $($team.Teams.Keys.Count) different teams

"})

## Proctor Responsibilities
1. **Pre-Workshop Setup** (30 minutes before)
   - Verify your team's Fabrikam instance is running
   - Test MCP tools and API connectivity
   - Prepare challenge materials and templates

2. **Workshop Opening** (First 15 minutes)
   - Welcome your team members
   - Explain the challenge focus
   - Help with environment setup and login

3. **Build Phase** (90 minutes)
   - Circulate among team members
   - Provide technical guidance and hints
   - Encourage collaboration and knowledge sharing
   - Escalate critical issues to technical support

4. **Showcase Phase** (Final 15 minutes)
   - Help teams prepare demonstrations
   - Facilitate knowledge sharing between teams
   - Celebrate achievements and creative solutions

## Emergency Contacts
- Technical Lead: David Bjurman-Birr (DAVIDB@microsoft.com)
- Workshop Coordinator: [Contact Info]
- Azure Support: [Escalation Info]
"@

$proctorInstructionsPath = ".\proctor-assignments.md"
$proctorInstructions | Out-File -FilePath $proctorInstructionsPath -Encoding UTF8
Write-Host "Proctor instructions saved to $proctorInstructionsPath" -ForegroundColor Green

Write-Host "`n🎉 Team assignment complete! Ready for November 6th workshop!" -ForegroundColor Green

return @{
    TotalAttendees = $allAssignments.Count
    TeamCount = $TeamCount
    AssignmentsPath = $OutputPath
    ProctorInstructionsPath = $proctorInstructionsPath
    Teams = $teamAssignments
}