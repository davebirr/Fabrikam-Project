<#
.SYNOPSIS
    Provisions workshop users using Microsoft Graph REST API directly

.DESCRIPTION
    Uses Invoke-RestMethod with access token to create users.
    More reliable than Graph SDK for bulk operations.

.PARAMETER ProctorsOnly
    Only create the 20 proctor accounts

.PARAMETER DryRun
    Preview what would be created
#>

[CmdletBinding()]
param(
    [switch]$ProctorsOnly,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$infrastructurePath = Split-Path -Parent $PSScriptRoot

Write-Host "`n🚀 Workshop User Provisioning (Graph REST API)" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# Load user mapping
$mappingPath = Join-Path $infrastructurePath "workshop-user-mapping.csv"
Write-Host "`n📂 Loading user mapping..." -ForegroundColor Yellow
$users = Import-Csv $mappingPath

if ($ProctorsOnly) {
    $proctors = @($users | Where-Object { $_.Role -eq "Proctor" })
    $users = $proctors
    Write-Host "   🎯 Provisioning PROCTORS ONLY: $($proctors.Count) users" -ForegroundColor Yellow
}

Write-Host "`n📊 User Distribution:" -ForegroundColor Yellow
$proctorCount = @($users | Where-Object { $_.Role -eq "Proctor" }).Count
$participantCount = @($users | Where-Object { $_.Role -eq "Participant" }).Count
Write-Host "   Proctors: $proctorCount"
Write-Host "   Participants: $participantCount"

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN MODE - No users will be created" -ForegroundColor Yellow
}

# Get access token using Azure CLI
Write-Host "`n🔐 Getting access token..." -ForegroundColor Yellow
try {
    $tokenResult = az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv 2>$null
    if (-not $tokenResult) {
        throw "Failed to get access token"
    }
    $accessToken = $tokenResult
    Write-Host "   ✅ Access token acquired" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to get access token" -ForegroundColor Red
    Write-Host "   Run: az login --tenant fd268415-22a5-4064-9b5e-d039761c5971" -ForegroundColor Yellow
    exit 1
}

# Function to generate secure password
function New-SecurePassword {
    $length = 16
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    do {
        $password = -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
        $hasUpper = $password -cmatch '[A-Z]'
        $hasLower = $password -cmatch '[a-z]'
        $hasDigit = $password -match '\d'
        $hasSpecial = $password -match '[!@#$%^&*]'
    } while (-not ($hasUpper -and $hasLower -and $hasDigit -and $hasSpecial))
    
    return $password
}

# Prepare credential export
$credentials = @()

Write-Host "`n👥 Creating users..." -ForegroundColor Yellow

$created = 0
$skipped = 0
$failed = 0

# Headers for Graph API
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Process in batches
$batchNumber = 1
$totalBatches = [Math]::Ceiling($users.Count / 10)

for ($i = 0; $i -lt $users.Count; $i += 10) {
    $batch = $users[$i..[Math]::Min($i + 9, $users.Count - 1)]
    
    Write-Host "`n📦 Batch $batchNumber of $totalBatches ($($batch.Count) users)" -ForegroundColor Cyan
    
    foreach ($user in $batch) {
        $upn = $user.NativeUserPrincipalName
        $displayName = $user.DisplayName
        
        Write-Host "   Creating: $upn ($displayName)... " -NoNewline
        
        if ($DryRun) {
            Write-Host "[DRY RUN]" -ForegroundColor Yellow
            continue
        }
        
        try {
            # Check if user already exists
            $checkUrl = "https://graph.microsoft.com/v1.0/users/$upn"
            try {
                $existingUser = Invoke-RestMethod -Uri $checkUrl -Headers $headers -Method Get -ErrorAction Stop
                if ($existingUser) {
                    Write-Host "⏭️  Already exists" -ForegroundColor Yellow
                    $skipped++
                    continue
                }
            } catch {
                # User doesn't exist - this is expected, continue to create
                if ($_.Exception.Response.StatusCode -ne 404) {
                    throw
                }
            }
            
            # Generate secure password
            $tempPassword = New-SecurePassword
            
            # Create user body
            $userBody = @{
                accountEnabled = $true
                displayName = $displayName
                mailNickname = $user.Alias
                userPrincipalName = $upn
                passwordProfile = @{
                    forceChangePasswordNextSignIn = $true
                    password = $tempPassword
                }
                givenName = $user.FictitiousFirstName
                surname = $user.FictitiousLastName
                usageLocation = "US"
            } | ConvertTo-Json -Depth 10
            
            # Create user
            $createUrl = "https://graph.microsoft.com/v1.0/users"
            $result = Invoke-RestMethod -Uri $createUrl -Headers $headers -Method Post -Body $userBody -ErrorAction Stop
            
            Write-Host "✅ Created" -ForegroundColor Green
            $created++
            
            # Store credentials
            $credentials += [PSCustomObject]@{
                UserNumber = $user.UserNumber
                RealFullName = $user.RealFullName
                RealEmail = $user.RealEmail
                Role = $user.Role
                WorkshopUsername = $upn
                FictitiousName = $displayName
                TemporaryPassword = $tempPassword
                ChallengeLevel = $user.ChallengeLevel
            }
            
            # Rate limiting
            Start-Sleep -Milliseconds 500
            
        } catch {
            $errorMessage = $_.Exception.Message
            if ($_.ErrorDetails.Message) {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                $errorMessage = $errorDetails.error.message
            }
            Write-Host "❌ Error: $errorMessage" -ForegroundColor Red
            $failed++
        }
    }
    
    # Pause between batches
    if ($i + 10 -lt $users.Count) {
        Write-Host "`n   ⏸️  Pausing 5 seconds before next batch..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
    
    $batchNumber++
}

# Export credentials
if ($credentials.Count -gt 0 -and -not $DryRun) {
    $credFile = Join-Path $infrastructurePath "workshop-user-credentials.csv"
    $credentials | Export-Csv $credFile -NoTypeInformation
    Write-Host "`n💾 Credentials exported to: $credFile" -ForegroundColor Green
    Write-Host "   ⚠️  SENSITIVE - Delete after distributing passwords" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Provisioning Summary" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "✅ Created: $created users" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "⏭️  Skipped: $skipped users (already exist)" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Host "❌ Failed: $failed users" -ForegroundColor Red
}

if (-not $DryRun -and $created -gt 0) {
    Write-Host "`n✅ User provisioning complete!" -ForegroundColor Green
    Write-Host "`n📧 Credential file contains temporary passwords for email distribution" -ForegroundColor Cyan
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Test proctor login (2-3 users)" -ForegroundColor Gray
    Write-Host "  2. Assign M365 E3 + Copilot Studio licenses" -ForegroundColor Gray
    Write-Host "  3. Add users to security groups" -ForegroundColor Gray
    Write-Host "  4. Assign Azure RBAC roles" -ForegroundColor Gray
    Write-Host "  5. Send credential emails to attendees (using RealEmail column)" -ForegroundColor Gray
}
