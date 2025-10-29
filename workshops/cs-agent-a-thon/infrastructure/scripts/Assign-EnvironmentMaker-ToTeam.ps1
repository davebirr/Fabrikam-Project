<#
.SYNOPSIS
    Assign Environment Maker role to existing Workshop-Team-Proctors team
    
.DESCRIPTION
    The Dataverse team already exists, we just need to assign the Environment Maker role to it
    
.EXAMPLE
    .\Assign-EnvironmentMaker-ToTeam.ps1
#>

Write-Host "🎯 Assigning Environment Maker Role to Existing Team" -ForegroundColor Cyan
Write-Host ""
Write-Host "The Workshop-Team-Proctors team already exists in Dataverse." -ForegroundColor Green
Write-Host "We just need to assign the Environment Maker security role to it." -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 STEP-BY-STEP INSTRUCTIONS (For oscarw or davidb):" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to: https://make.powerapps.com" -ForegroundColor White
Write-Host ""
Write-Host "2. Sign in as: oscarw@fabrikam1.csplevelup.com (or davidb@microsoft.com)" -ForegroundColor White
Write-Host ""
Write-Host "3. Switch to: Fabrikam (default) environment" -ForegroundColor White
Write-Host ""
Write-Host "4. Click: Settings (gear icon) > Advanced settings" -ForegroundColor White
Write-Host "   This opens the Dynamics 365 Settings portal" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Navigate to: Settings > Security > Teams" -ForegroundColor White
Write-Host ""
Write-Host "6. Find the team linked to Workshop-Team-Proctors:" -ForegroundColor White
Write-Host "   - Look for a team with 'Workshop' or 'Proctor' in the name" -ForegroundColor Gray
Write-Host "   - Or filter by Team Type = 'AAD Security Group'" -ForegroundColor Gray
Write-Host ""
Write-Host "7. Click on the team name to open it" -ForegroundColor White
Write-Host ""
Write-Host "8. Click: Manage Roles (ribbon button at top)" -ForegroundColor White
Write-Host ""
Write-Host "9. In the dialog, check the box for: Environment Maker" -ForegroundColor White
Write-Host ""
Write-Host "10. Click: OK" -ForegroundColor White
Write-Host ""
Write-Host "11. Save the team" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 ALTERNATIVE: Assign to Individual Users" -ForegroundColor Yellow
Write-Host ""
Write-Host "If the team approach still doesn't work, assign Environment Maker to individual B2B guests:" -ForegroundColor White
Write-Host ""
Write-Host "1. Still in: Settings > Security > Users" -ForegroundColor White
Write-Host ""
Write-Host "2. Click: + New" -ForegroundColor White
Write-Host ""
Write-Host "3. Search for: davidb_microsoft.com#EXT#@fabrikam1.csplevelup.com" -ForegroundColor White
Write-Host "   (or just search 'davidb')" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Select the user and click: Add" -ForegroundColor White
Write-Host ""
Write-Host "5. Once user is added, click on the user name" -ForegroundColor White
Write-Host ""
Write-Host "6. Click: Manage Roles" -ForegroundColor White
Write-Host ""
Write-Host "7. Check: Environment Maker" -ForegroundColor White
Write-Host ""
Write-Host "8. Click: OK" -ForegroundColor White
Write-Host ""
Write-Host "9. Repeat for other proctors as needed for testing" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ AFTER ASSIGNMENT:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Wait 5-10 minutes for permissions to propagate" -ForegroundColor White
Write-Host ""
Write-Host "2. Test as davidb:" -ForegroundColor White
Write-Host "   - Navigate to: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971" -ForegroundColor Cyan
Write-Host "   - Sign in as: davidb@microsoft.com" -ForegroundColor Gray
Write-Host "   - Create/edit an agent" -ForegroundColor Gray
Write-Host "   - Go to: Settings > Actions > Add action" -ForegroundColor Gray
Write-Host "   - Search for the MCP connector" -ForegroundColor Gray
Write-Host "   - Should add WITHOUT authentication prompt" -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 KEY REMINDER:" -ForegroundColor Yellow
Write-Host ""
Write-Host "For B2B guests to use the MCP connection, they need:" -ForegroundColor White
Write-Host "  ✅ Connection shared with 'Can use' permission (oscarw did this)" -ForegroundColor Green
Write-Host "  ⏳ Environment Maker role (assign via team or individually)" -ForegroundColor Yellow
Write-Host "  ✅ Member of Workshop-Team-Proctors Entra group (already done)" -ForegroundColor Green
Write-Host ""
