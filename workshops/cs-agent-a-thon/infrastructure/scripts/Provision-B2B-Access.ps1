# 🔐 Microsoft Workshop B2B Provisioning Script
# CS Agent-A-Thon Workshop - November 6, 2025
# Provisions B2B guest access for 126 Microsoft attendees

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$WorkshopUrl = "https://fabrikam-workshop.azurewebsites.net",
    
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = ".\attendees.csv",
    
    [Parameter(Mandatory=$false)]
    [bool]$DryRun = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\provisioning-log.txt"
)

# Initialize logging
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

Write-Log "=== Microsoft Workshop B2B Provisioning Started ==="
Write-Log "Tenant ID: $TenantId"
Write-Log "Workshop URL: $WorkshopUrl"
Write-Log "CSV Path: $CsvPath"
Write-Log "Dry Run: $DryRun"

# Connect to Azure AD
try {
    Write-Log "Connecting to Azure AD..."
    Connect-AzureAD -TenantId $TenantId
    Write-Log "Successfully connected to Azure AD"
}
catch {
    Write-Log "Failed to connect to Azure AD: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Read attendee data
try {
    Write-Log "Reading attendee data from $CsvPath..."
    $attendees = Import-Csv -Path $CsvPath
    Write-Log "Found $($attendees.Count) attendees"
}
catch {
    Write-Log "Failed to read CSV file: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Validate attendee data
$validAttendees = @()
foreach ($attendee in $attendees) {
    if (-not [string]::IsNullOrWhiteSpace($attendee.Email)) {
        $validAttendees += $attendee
    } else {
        Write-Log "Skipping attendee with missing email: $($attendee.FullName)" "WARN"
    }
}

Write-Log "Valid attendees: $($validAttendees.Count)"

# Process invitations
$successCount = 0
$errorCount = 0
$invitationResults = @()

foreach ($attendee in $validAttendees) {
    try {
        Write-Log "Processing invitation for $($attendee.FullName) ($($attendee.Email))..."
        
        if ($DryRun) {
            Write-Log "[DRY RUN] Would invite: $($attendee.Email)" "INFO"
            $invitationResults += [PSCustomObject]@{
                Name = $attendee.FullName
                Email = $attendee.Email
                Team = $attendee.Team
                Country = $attendee.Country
                Status = "DryRun"
                InvitationId = "N/A"
                Message = "Dry run - no actual invitation sent"
            }
            $successCount++
        }
        else {
            # Create B2B invitation
            $invitation = New-AzureADMSInvitation `
                -InvitedUserEmailAddress $attendee.Email `
                -InviteRedirectUrl $WorkshopUrl `
                -InvitedUserDisplayName $attendee.FullName `
                -SendInvitationMessage $true `
                -InvitedUserMessageInfo @{
                    customizedMessageBody = @"
Welcome to the CS Agent-A-Thon Workshop!

You're invited to participate in our hands-on AI agent building workshop on November 6, 2025.

During this workshop, you'll:
• Build real AI agents using the Fabrikam business platform
• Choose from beginner, intermediate, or advanced challenges
• Collaborate with peers from across Microsoft
• Use cutting-edge AI frameworks and tools

Your workshop details:
• Date: November 6, 2025 at 8:15 AM PT
• Duration: 2 hours
• Format: Interactive, hands-on learning

Please accept this invitation to access the workshop environment.

See you there!
The CS Agent-A-Thon Team
"@
                }
            
            $invitationResults += [PSCustomObject]@{
                Name = $attendee.FullName
                Email = $attendee.Email
                Team = $attendee.Team
                Country = $attendee.Country
                Status = "Success"
                InvitationId = $invitation.Id
                RedeemUrl = $invitation.InviteRedeemUrl
                Message = "Invitation sent successfully"
            }
            
            Write-Log "Successfully invited $($attendee.Email) - Invitation ID: $($invitation.Id)" "SUCCESS"
            $successCount++
        }
        
        # Small delay to avoid throttling
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Log "Failed to invite $($attendee.Email): $($_.Exception.Message)" "ERROR"
        $invitationResults += [PSCustomObject]@{
            Name = $attendee.FullName
            Email = $attendee.Email
            Team = $attendee.Team
            Country = $attendee.Country
            Status = "Error"
            InvitationId = "N/A"
            Message = $_.Exception.Message
        }
        $errorCount++
    }
}

# Generate summary report
Write-Log "=== Provisioning Summary ==="
Write-Log "Total attendees processed: $($validAttendees.Count)"
Write-Log "Successful invitations: $successCount"
Write-Log "Failed invitations: $errorCount"
Write-Log "Success rate: $(($successCount / $validAttendees.Count * 100).ToString('F1'))%"

# Export detailed results
$resultsPath = ".\invitation-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$invitationResults | Export-Csv -Path $resultsPath -NoTypeInformation
Write-Log "Detailed results exported to: $resultsPath"

# Team assignment recommendations
Write-Log "=== Team Assignment Recommendations ==="

# Group attendees by geographic region for team balance
$regions = $invitationResults | Where-Object { $_.Status -eq "Success" -or $_.Status -eq "DryRun" } | Group-Object Country
$teamSize = 25
$teamCount = 5

Write-Log "Geographic distribution for team assignments:"
Write-Log "Target: $teamCount teams of $teamSize participants each"
foreach ($region in $regions | Sort-Object Count -Descending) {
    Write-Log "  $($region.Name): $($region.Count) attendees"
}

# Suggest proctor assignments based on management roles and geographic distribution
$suggestedProctors = @(
    "DAVIDB@microsoft.com",      # David Bjurman-Birr - Workshop organizer
    "PAULKALSBEEK@microsoft.com", # Paul Kalsbeek - AI Transformation manager
    "KENNITHS@microsoft.com",     # Ken St. Cyr - Security Solutioning manager
    "DSTOKER@microsoft.com",      # David Stoker - M&M Solutioning manager  
    "PHNARAS@microsoft.com"       # Pani Murthy - BA Solutioning manager
)

Write-Log "Suggested proctors (management roles with geographic/expertise distribution):"
foreach ($proctor in $suggestedProctors) {
    $proctorInfo = $invitationResults | Where-Object { $_.Email -eq $proctor }
    if ($proctorInfo) {
        Write-Log "  $($proctorInfo.Name) ($($proctorInfo.Email)) - $($proctorInfo.Team) - $($proctorInfo.Country)"
    }
}

# Azure resource requirements
Write-Log "=== Azure Resource Requirements ==="
Write-Log "Required Fabrikam instances: $teamCount"
Write-Log "Expected concurrent users: $($validAttendees.Count)"
Write-Log "Required App Service plan: Premium (P2v2 or higher)"
Write-Log "Required database tier: Standard S2 or higher"
Write-Log "Required storage: General Purpose v2 with hot tier"

Write-Log "=== Next Steps ==="
if ($DryRun) {
    Write-Log "1. Review the dry run results"
    Write-Log "2. Validate attendee email addresses"
    Write-Log "3. Run with -DryRun `$false to send actual invitations"
}
else {
    Write-Log "1. Monitor invitation acceptance rates"
    Write-Log "2. Send reminder emails 48 hours before workshop"
    Write-Log "3. Assign teams based on geographic and skill distribution"
    Write-Log "4. Configure proctor access and training materials"
}

Write-Log "=== Provisioning Complete ==="

# Return summary for pipeline integration
return @{
    TotalAttendees = $validAttendees.Count
    SuccessfulInvitations = $successCount
    FailedInvitations = $errorCount
    SuccessRate = ($successCount / $validAttendees.Count * 100)
    ResultsPath = $resultsPath
    SuggestedProctors = $suggestedProctors
}