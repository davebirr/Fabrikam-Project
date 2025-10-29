<#
.SYNOPSIS
    Create service principal-based MCP connector for B2B guest access
    
.DESCRIPTION
    This script sets up a service principal and MCP connection that works with B2B guest users.
    User-bound connections don't work for B2B guests in Copilot Studio.
    
.PARAMETER TenantId
    The workshop tenant ID (levelupcspfy26cs01)
    
.PARAMETER SubscriptionId
    The workshop subscription ID (cs-agent-a-thon)
    
.PARAMETER McpServerUrl
    The URL of the MCP server endpoint (from Azure App Service deployment)
    
.PARAMETER EnvironmentId
    Power Platform environment ID (default environment)
    
.EXAMPLE
    .\Setup-MCP-ServicePrincipal.ps1 -McpServerUrl "https://fabrikam-mcp-proctor.azurewebsites.net"
    
.NOTES
    Prerequisites:
    - Azure CLI authenticated as admin
    - Power Platform admin rights
    - Microsoft Graph PowerShell module (or Azure CLI REST API fallback)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId = "fd268415-22a5-4064-9b5e-d039761c5971",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = "d3c2f651-1a5a-4781-94f3-460c4c4bffce",
    
    [Parameter(Mandatory = $true)]
    [string]$McpServerUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentId = "Default-fd268415-22a5-4064-9b5e-d039761c5971",
    
    [Parameter(Mandatory = $false)]
    [string]$ConnectorName = "Fabrikam MCP Connector"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Setting up service principal-based MCP connector for B2B guest access" -ForegroundColor Cyan
Write-Host ""

#region Step 1: Create Azure AD Application and Service Principal
Write-Host "📋 Step 1: Create Azure AD Application and Service Principal" -ForegroundColor Yellow

$appName = "Fabrikam-MCP-ServicePrincipal"

# Check if app already exists
Write-Host "Checking if application already exists..." -ForegroundColor Gray
$existingApp = az ad app list --display-name $appName --query "[0]" | ConvertFrom-Json

if ($existingApp) {
    Write-Host "✅ Application '$appName' already exists (App ID: $($existingApp.appId))" -ForegroundColor Green
    $appId = $existingApp.appId
    $objectId = $existingApp.id
} else {
    Write-Host "Creating new application..." -ForegroundColor Gray
    
    # Create the Azure AD app
    $app = az ad app create `
        --display-name $appName `
        --sign-in-audience "AzureADMyOrg" `
        | ConvertFrom-Json
    
    $appId = $app.appId
    $objectId = $app.id
    
    Write-Host "✅ Created application: $appName" -ForegroundColor Green
    Write-Host "   App ID: $appId" -ForegroundColor Gray
}

# Check if service principal exists
Write-Host "Checking if service principal exists..." -ForegroundColor Gray
$existingSp = az ad sp list --display-name $appName --query "[0]" | ConvertFrom-Json

if ($existingSp) {
    Write-Host "✅ Service principal already exists" -ForegroundColor Green
    $spObjectId = $existingSp.id
} else {
    Write-Host "Creating service principal..." -ForegroundColor Gray
    
    # Create service principal
    $sp = az ad sp create --id $appId | ConvertFrom-Json
    $spObjectId = $sp.id
    
    Write-Host "✅ Created service principal" -ForegroundColor Green
}

# Create client secret
Write-Host "Creating client secret (valid for 1 year)..." -ForegroundColor Gray
$secretName = "MCP-Connector-Secret-$(Get-Date -Format 'yyyyMMdd')"

$secret = az ad app credential reset `
    --id $appId `
    --append `
    --display-name $secretName `
    --years 1 `
    | ConvertFrom-Json

$clientSecret = $secret.password

Write-Host "✅ Client secret created" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  SAVE THESE CREDENTIALS - They won't be shown again:" -ForegroundColor Yellow
Write-Host "   Application (client) ID: $appId" -ForegroundColor Cyan
Write-Host "   Client Secret: $clientSecret" -ForegroundColor Cyan
Write-Host "   Tenant ID: $TenantId" -ForegroundColor Cyan
Write-Host ""

#endregion

#region Step 2: Grant Service Principal Permissions (Optional)
Write-Host "📋 Step 2: Grant Service Principal Permissions" -ForegroundColor Yellow
Write-Host "ℹ️  If your MCP server requires authentication, grant appropriate permissions here." -ForegroundColor Gray
Write-Host "   For this workshop, the MCP server uses 'No Auth' mode." -ForegroundColor Gray
Write-Host ""
#endregion

#region Step 3: Create Custom Connector in Power Platform
Write-Host "📋 Step 3: Create Custom Connector in Power Platform" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  MANUAL STEP REQUIRED - Use Power Platform Admin Center:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to: https://make.powerapps.com" -ForegroundColor White
Write-Host "   - Switch to environment: $EnvironmentId" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Go to: Data > Custom Connectors > + New custom connector > Create from blank" -ForegroundColor White
Write-Host ""
Write-Host "3. Configure General Tab:" -ForegroundColor White
Write-Host "   - Connector name: $ConnectorName" -ForegroundColor Gray
Write-Host "   - Host: $(([System.Uri]$McpServerUrl).Host)" -ForegroundColor Gray
Write-Host "   - Base URL: /" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Configure Security Tab:" -ForegroundColor White
Write-Host "   - Authentication type: No authentication" -ForegroundColor Gray
Write-Host "   ⚠️  This is CRITICAL for B2B guest access!" -ForegroundColor Yellow
Write-Host ""
Write-Host "5. Configure Definition Tab:" -ForegroundColor White
Write-Host "   - Add actions for MCP tools (list_tools, call_tool, etc.)" -ForegroundColor Gray
Write-Host "   - Or import from OpenAPI/Swagger if available" -ForegroundColor Gray
Write-Host ""
Write-Host "6. Click: Create connector" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter when connector is created..." -ForegroundColor Cyan
Read-Host
#endregion

#region Step 4: Create Environment-Scoped Connection
Write-Host "📋 Step 4: Create Environment-Scoped Connection" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  MANUAL STEP REQUIRED - Use Power Platform Admin Center:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to: https://make.powerapps.com" -ForegroundColor White
Write-Host "   - Switch to environment: $EnvironmentId" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Go to: Data > Connections > + New connection" -ForegroundColor White
Write-Host ""
Write-Host "3. Find and select: $ConnectorName" -ForegroundColor White
Write-Host ""
Write-Host "4. Since authentication is 'No Auth', just click: Create" -ForegroundColor White
Write-Host "   - Connection will be created immediately" -ForegroundColor Gray
Write-Host "   - No credentials needed" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Note the Connection Name (e.g., 'shared-fabrikam-mcp-connector-xxxxx')" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter when connection is created..." -ForegroundColor Cyan
$connectionName = Read-Host "Enter the connection name (or press Enter to skip)"
Write-Host ""
#endregion

#region Step 5: Share Connection with Security Group
Write-Host "📋 Step 5: Share Connection with Workshop Teams" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  MANUAL STEP REQUIRED - Share connection with security groups:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to: https://make.powerapps.com" -ForegroundColor White
Write-Host "   - Switch to environment: $EnvironmentId" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Go to: Data > Connections" -ForegroundColor White
Write-Host ""
Write-Host "3. Find connection: $connectionName" -ForegroundColor White
Write-Host "   - Click the three dots (...) > Share" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Add security groups with 'Can use' permission:" -ForegroundColor White
Write-Host "   - Workshop-Team-Proctors" -ForegroundColor Gray
Write-Host "   - (Later) Workshop-Team-01, Workshop-Team-02, etc." -ForegroundColor Gray
Write-Host ""
Write-Host "5. Permission level: Can use (NOT 'Can edit')" -ForegroundColor White
Write-Host "   ⚠️  'Can use' is sufficient for B2B guests to use the connection" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter when sharing is complete..." -ForegroundColor Cyan
Read-Host
#endregion

#region Step 6: Verify Environment Roles
Write-Host "📋 Step 6: Verify Environment Roles" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  Ensure B2B guests have Environment Maker role:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to: https://admin.powerplatform.microsoft.com" -ForegroundColor White
Write-Host ""
Write-Host "2. Go to: Environments > Default environment" -ForegroundColor White
Write-Host ""
Write-Host "3. Click: Settings > Users + permissions > Security roles" -ForegroundColor White
Write-Host ""
Write-Host "4. Assign 'Environment Maker' role to:" -ForegroundColor White
Write-Host "   - Workshop-Team-Proctors security group" -ForegroundColor Gray
Write-Host "   - Or individual B2B guest users" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Without this role, B2B guests cannot access shared connections" -ForegroundColor White
Write-Host ""
#endregion

#region Step 7: Test with B2B Guest User
Write-Host "📋 Step 7: Test with B2B Guest User" -ForegroundColor Yellow
Write-Host ""
Write-Host "Test the connection with a B2B guest (e.g., davidb):" -ForegroundColor White
Write-Host ""
Write-Host "1. Login to Copilot Studio as B2B guest:" -ForegroundColor White
Write-Host "   https://copilotstudio.microsoft.com/?tenant=$TenantId" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Create new agent or edit existing agent" -ForegroundColor White
Write-Host ""
Write-Host "3. Go to: Settings > Actions > Add action" -ForegroundColor White
Write-Host ""
Write-Host "4. Search for: $ConnectorName" -ForegroundColor White
Write-Host ""
Write-Host "5. Select connector and add to agent" -ForegroundColor White
Write-Host "   - Should NOT prompt for authentication (No Auth)" -ForegroundColor Gray
Write-Host "   - Connection should be automatically available" -ForegroundColor Gray
Write-Host ""
Write-Host "6. Test connector action in agent conversation" -ForegroundColor White
Write-Host ""
#endregion

#region Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Service Principal Setup Complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Key Configuration:" -ForegroundColor Yellow
Write-Host "   Application Name: $appName" -ForegroundColor White
Write-Host "   Application ID: $appId" -ForegroundColor White
Write-Host "   Tenant ID: $TenantId" -ForegroundColor White
Write-Host "   MCP Server URL: $McpServerUrl" -ForegroundColor White
Write-Host "   Environment: $EnvironmentId" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Authentication Model:" -ForegroundColor Yellow
Write-Host "   ✅ Connector Auth: No authentication" -ForegroundColor Green
Write-Host "   ✅ Connection Scope: Environment-level (not user-bound)" -ForegroundColor Green
Write-Host "   ✅ B2B Guest Compatible: YES" -ForegroundColor Green
Write-Host ""
Write-Host "👥 Required Permissions:" -ForegroundColor Yellow
Write-Host "   ✅ Security Groups: Shared with 'Can use' permission" -ForegroundColor White
Write-Host "   ✅ Environment Role: Environment Maker (for B2B guests)" -ForegroundColor White
Write-Host ""
Write-Host "📖 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Complete manual connector creation in Power Platform" -ForegroundColor White
Write-Host "   2. Create environment-scoped connection (No Auth)" -ForegroundColor White
Write-Host "   3. Share connection with Workshop-Team-Proctors ('Can use')" -ForegroundColor White
Write-Host "   4. Verify Environment Maker role assigned to B2B guests" -ForegroundColor White
Write-Host "   5. Test with davidb in Copilot Studio" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: Save the client credentials shown above!" -ForegroundColor Yellow
Write-Host ""
#endregion
