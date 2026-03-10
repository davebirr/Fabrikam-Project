# Create-RajDuggal-Account.ps1
# Creates Entra ID account for late participant Raj Duggal

[CmdletBinding()]
param(
    [string]$TenantDomain = "levelupcspfy26cs01.onmicrosoft.com"
)

$ErrorActionPreference = "Stop"

Write-Host "`n🎯 Creating Workshop Account for Raj Duggal" -ForegroundColor Cyan
Write-Host "==========================================`n" -ForegroundColor Cyan

# Account details
$userDetails = @{
    UserNumber = 139
    RealFullName = "Raj Duggal"
    RealFirstName = "Raj"
    RealLastName = "Duggal"
    RealEmail = "rduggal@microsoft.com"
    FictitiousFirstName = "Dimitris"
    FictitiousLastName = "Papadopoulos"
    FictitiousFullName = "Dimitris Papadopoulos"
    Alias = "DimitrisP"
    WorkshopUsername = "DimitrisP@fabrikam1.csplevelup.com"
    DisplayName = "Dimitris Papadopoulos"
    MailNickname = "DimitrisP"
    UserPrincipalName = "DimitrisP@$TenantDomain"
    TemporaryPassword = "Raj!Temp#2025"
    Team = "Team-04"
    TableNumber = 2
    ChallengeLevel = "No Preference"
}

Write-Host "📋 Account Details:" -ForegroundColor Yellow
Write-Host "   Display Name: $($userDetails.FictitiousFullName)" -ForegroundColor Gray
Write-Host "   UPN: $($userDetails.UserPrincipalName)" -ForegroundColor Gray
Write-Host "   Workshop Email: $($userDetails.WorkshopUsername)" -ForegroundColor Gray
Write-Host "   Temporary Password: $($userDetails.TemporaryPassword)" -ForegroundColor Gray
Write-Host "   Team: $($userDetails.Team) (Table $($userDetails.TableNumber))" -ForegroundColor Gray
Write-Host ""

# Connect to Microsoft Graph
Write-Host "🔐 Connecting to Microsoft Graph..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome
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
    UsageLocation = "US"
}

# Create the user
Write-Host "`n👤 Creating user account..." -ForegroundColor Yellow
try {
    $user = New-MgUser -BodyParameter $newUser
    Write-Host "   ✅ User created successfully!" -ForegroundColor Green
    Write-Host "   User ID: $($user.Id)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Failed to create user: $_" -ForegroundColor Red
    Disconnect-MgGraph
    exit 1
}

# Summary
Write-Host "`n✅ ACCOUNT CREATION COMPLETE!" -ForegroundColor Green
Write-Host "============================`n" -ForegroundColor Green

Write-Host "📧 Send to Raj Duggal ($($userDetails.RealEmail)):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Your Agent-A-Thon Workshop Credentials" -ForegroundColor White
Write-Host "   --------------------------------------" -ForegroundColor Gray
Write-Host "   Workshop Username: $($userDetails.WorkshopUsername)" -ForegroundColor Yellow
Write-Host "   Temporary Password: $($userDetails.TemporaryPassword)" -ForegroundColor Yellow
Write-Host "   Team Assignment: $($userDetails.Team)" -ForegroundColor Yellow
Write-Host "   Table Number: $($userDetails.TableNumber)" -ForegroundColor Yellow
Write-Host "   Your Fictitious Identity: $($userDetails.FictitiousFullName)" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Teammates:" -ForegroundColor White
Write-Host "   • Aberehet Gebre Tsadik (Pardeep Atwal)" -ForegroundColor Gray
Write-Host "   • Dimitrios Sirigos (Francesco Sparacio)" -ForegroundColor Gray
Write-Host "   • Papia Chakrabarty (Olivier Stéphan)" -ForegroundColor Gray
Write-Host ""

# Disconnect
Disconnect-MgGraph
Write-Host "`n✨ Done!" -ForegroundColor Green
Write-Host ""
