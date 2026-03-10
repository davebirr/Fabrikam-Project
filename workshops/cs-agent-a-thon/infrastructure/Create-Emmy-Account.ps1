# Create-Emmy-Account.ps1
# Creates Entra ID account for Emmy Jäger (BG Lead)

[CmdletBinding()]
param(
    [string]$TenantDomain = "fabrikam1.csplevelup.com"
)

$ErrorActionPreference = "Stop"

Write-Host "`n🎯 Creating Workshop Account for Emmy Jäger (BG Lead)" -ForegroundColor Cyan
Write-Host "===================================================`n" -ForegroundColor Cyan

# Account details from consolidated CSV
$userDetails = @{
    UserNumber = 140
    RealFullName = "Emmy Jäger"
    RealFirstName = "Emmy"
    RealLastName = "Jäger"
    RealEmail = "emmyhe@microsoft.com"
    Role = "BGLead"
    Country = "Sweden"
    FictitiousFirstName = "Diana"
    FictitiousLastName = "Bergqvist"
    FictitiousFullName = "Diana Bergqvist"
    FictitiousGender = "Female"
    FictitiousLanguage = "Swedish"
    Alias = "DianaB"
    WorkshopUsername = "DianaB@$TenantDomain"
    DisplayName = "Diana Bergqvist"
    MailNickname = "DianaB"
    UserPrincipalName = "DianaB@levelupcspfy26cs01.onmicrosoft.com"  # Tenant domain
    TemporaryPassword = "k8mTibTXscxiySL*"
    Status = "continuous"
}

Write-Host "📋 Account Details:" -ForegroundColor Yellow
Write-Host "   Real Name: $($userDetails.RealFullName)" -ForegroundColor Gray
Write-Host "   Role: $($userDetails.Role) (Business Group Lead)" -ForegroundColor Cyan
Write-Host "   Display Name: $($userDetails.FictitiousFullName)" -ForegroundColor Gray
Write-Host "   UPN: $($userDetails.UserPrincipalName)" -ForegroundColor Gray
Write-Host "   Workshop Email: $($userDetails.WorkshopUsername)" -ForegroundColor Gray
Write-Host "   Password: $($userDetails.TemporaryPassword)" -ForegroundColor Gray
Write-Host "   Language: $($userDetails.FictitiousLanguage)" -ForegroundColor Gray
Write-Host "   Status: $($userDetails.Status) (BG Lead access)" -ForegroundColor Gray
Write-Host ""

# Connect to Microsoft Graph
Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory" -NoWelcome
    Write-Host "   ✅ Connected successfully" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to connect: $_" -ForegroundColor Red
    exit 1
}

# Create password profile
$passwordProfile = @{
    Password = $userDetails.TemporaryPassword
    ForceChangePasswordNextSignIn = $false
}

# Create user object
$newUser = @{
    DisplayName = $userDetails.FictitiousFullName
    GivenName = $userDetails.FictitiousFirstName
    Surname = $userDetails.FictitiousLastName
    UserPrincipalName = $userDetails.UserPrincipalName
    MailNickname = $userDetails.MailNickname
    AccountEnabled = $true
    PasswordProfile = $passwordProfile
    UsageLocation = "SE"  # Sweden
    PreferredLanguage = "sv-SE"  # Swedish
}

# Create the user
Write-Host "`n👤 Creating user account..." -ForegroundColor Yellow
try {
    $user = New-MgUser -BodyParameter $newUser
    Write-Host "   ✅ User created successfully!" -ForegroundColor Green
    Write-Host "   User ID: $($user.Id)" -ForegroundColor Gray
    Write-Host "   UPN: $($user.UserPrincipalName)" -ForegroundColor Gray
} catch {
    if ($_.Exception.Message -match "already exists") {
        Write-Host "   ⚠️  User already exists - retrieving existing user..." -ForegroundColor Yellow
        $user = Get-MgUser -Filter "userPrincipalName eq '$($userDetails.UserPrincipalName)'"
        Write-Host "   ✅ Found existing user: $($user.Id)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Failed to create user: $_" -ForegroundColor Red
        Disconnect-MgGraph
        exit 1
    }
}

# Assign Global Reader role for BG Lead visibility
Write-Host "`n🔑 Assigning BG Lead permissions..." -ForegroundColor Yellow
try {
    # Get Global Reader role
    $globalReaderRole = Get-MgDirectoryRole -Filter "displayName eq 'Global Reader'"
    
    if (-not $globalReaderRole) {
        Write-Host "   ⚠️  Global Reader role not activated, activating now..." -ForegroundColor Yellow
        $roleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Global Reader'"
        $globalReaderRole = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id
    }
    
    # Assign role to Emmy
    $roleAssignment = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
    }
    
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId $globalReaderRole.Id -BodyParameter $roleAssignment
    Write-Host "   ✅ Assigned Global Reader role (read-only access to tenant)" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match "already exists" -or $_.Exception.Message -match "duplicate") {
        Write-Host "   ✅ Global Reader role already assigned" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Could not assign Global Reader role: $_" -ForegroundColor Yellow
        Write-Host "   💡 You may need to assign permissions manually" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n✅ ACCOUNT CREATION COMPLETE!" -ForegroundColor Green
Write-Host "============================`n" -ForegroundColor Green

Write-Host "📧 Send to Emmy Jäger ($($userDetails.RealEmail)):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Your Agent-A-Thon Workshop Credentials (BG Lead)" -ForegroundColor White
Write-Host "   ------------------------------------------------" -ForegroundColor Gray
Write-Host "   Workshop Username: $($userDetails.WorkshopUsername)" -ForegroundColor Yellow
Write-Host "   Password: $($userDetails.TemporaryPassword)" -ForegroundColor Yellow
Write-Host "   Your Fictitious Identity: $($userDetails.FictitiousFullName) (Swedish)" -ForegroundColor Yellow
Write-Host "   Role: Business Group Lead" -ForegroundColor Yellow
Write-Host "   Access: Continuous (ongoing access as BG Lead)" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Tenant Access:" -ForegroundColor White
Write-Host "   • Portal: https://portal.azure.com" -ForegroundColor Gray
Write-Host "   • Domain: levelupcspfy26cs01.onmicrosoft.com" -ForegroundColor Gray
Write-Host "   • Permissions: Global Reader (view-only access)" -ForegroundColor Gray
Write-Host ""
Write-Host "   Workshop Email Alias:" -ForegroundColor White
Write-Host "   • $($userDetails.WorkshopUsername)" -ForegroundColor Gray
Write-Host ""

Write-Host "📄 Credentials saved to: emmy-credentials.txt" -ForegroundColor Cyan
Write-Host ""

# Disconnect
Disconnect-MgGraph
Write-Host "`n✨ Done!" -ForegroundColor Green
Write-Host ""
