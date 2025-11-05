# Manage-Deployments.ps1 - Deployment Configuration Management
# Helper script to manage Azure deployment URLs and configurations

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("list", "add", "update", "remove", "test", "set-active", "help")]
    [string]$Action = "help",
    
    [string]$Name,
    [string]$ApiUrl,
    [string]$McpUrl,
    [string]$AuthMode = "BearerToken",
    [string]$Description,
    [string]$Branch,
    [string]$Suffix,
    [switch]$SetAsProduction
)

$ConfigPath = "$PSScriptRoot\deployment-config.json"

function Get-DeploymentConfig {
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-DeploymentConfig {
    param($Config)
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
}

function Show-Help {
    Write-Host ""
    Write-Host "🚀 Fabrikam Deployment Configuration Manager" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  .\Manage-Deployments.ps1 list" -ForegroundColor White
    Write-Host "  .\Manage-Deployments.ps1 add -Name ""feature-auth-bearer"" -ApiUrl ""https://fabrikam-api-development-rxnmcw.azurewebsites.net"" -McpUrl ""https://fabrikam-mcp-development-rxnmcw.azurewebsites.net"" -AuthMode ""BearerToken"" -Suffix ""rxnmcw""" -ForegroundColor White
    Write-Host "  .\Manage-Deployments.ps1 update -Name ""feature-auth-bearer"" -Suffix ""newxyz"""
    Write-Host "  .\Manage-Deployments.ps1 test -Name ""feature-auth-bearer""" -ForegroundColor White
    Write-Host "  .\Manage-Deployments.ps1 set-active -Name ""feature-auth-bearer"" -SetAsProduction" -ForegroundColor White
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Yellow
    Write-Host "  list           - Show all configured deployments"
    Write-Host "  add            - Add a new deployment configuration"
    Write-Host "  update         - Update an existing deployment"
    Write-Host "  remove         - Remove a deployment configuration"
    Write-Host "  test           - Test connectivity to a deployment"
    Write-Host "  set-active     - Set deployment as active/production"
    Write-Host ""
}

function Show-Deployments {
    $config = Get-DeploymentConfig
    if (-not $config) {
        Write-Host "❌ No deployment configuration found" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "📋 Configured Deployments:" -ForegroundColor Cyan
    Write-Host "=" * 50
    
    foreach ($deploymentName in $config.deployments.PSObject.Properties.Name) {
        $deployment = $config.deployments.$deploymentName
        $activeStatus = if ($deployment.active) { "✅ Active" } else { "⚪ Inactive" }
        $prodAlias = if ($config.aliases.production -eq $deploymentName) { " (🚀 Production)" } else { "" }
        
        Write-Host ""
        Write-Host "🔹 $deploymentName$prodAlias" -ForegroundColor Yellow
        Write-Host "   Status: $activeStatus" -ForegroundColor $(if ($deployment.active) { "Green" } else { "Gray" })
        Write-Host "   Description: $($deployment.description)" -ForegroundColor Gray
        Write-Host "   API: $($deployment.apiUrl)" -ForegroundColor White
        Write-Host "   MCP: $($deployment.mcpUrl)" -ForegroundColor White
        Write-Host "   Auth Mode: $($deployment.authMode)" -ForegroundColor Cyan
        if ($deployment.suffix) {
            Write-Host "   Suffix: $($deployment.suffix)" -ForegroundColor Gray
        }
        if ($deployment.branch) {
            Write-Host "   Branch: $($deployment.branch)" -ForegroundColor Gray
        }
        if ($deployment.lastUpdated) {
            Write-Host "   Updated: $($deployment.lastUpdated)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "🎯 Aliases:" -ForegroundColor Cyan
    foreach ($alias in $config.aliases.PSObject.Properties.Name) {
        Write-Host "   $alias → $($config.aliases.$alias)" -ForegroundColor White
    }
    Write-Host ""
}

function Add-Deployment {
    if (-not $Name -or -not $ApiUrl -or -not $McpUrl) {
        Write-Host "❌ Name, ApiUrl, and McpUrl are required for adding a deployment" -ForegroundColor Red
        return
    }
    
    $config = Get-DeploymentConfig
    if (-not $config) {
        Write-Host "❌ Could not load deployment configuration" -ForegroundColor Red
        return
    }
    
    $newDeployment = @{
        description = if ($Description) { $Description } else { "Custom deployment: $Name" }
        apiUrl = $ApiUrl
        mcpUrl = $McpUrl
        authMode = $AuthMode
        active = $true
        lastUpdated = (Get-Date).ToString("yyyy-MM-dd")
    }
    
    if ($Suffix) { $newDeployment.suffix = $Suffix }
    if ($Branch) { $newDeployment.branch = $Branch }
    
    # Add the deployment
    $config.deployments | Add-Member -Name $Name -Value $newDeployment -MemberType NoteProperty -Force
    
    # Set as production if requested
    if ($SetAsProduction) {
        $config.aliases.production = $Name
    }
    
    Save-DeploymentConfig $config
    
    Write-Host "✅ Added deployment '$Name'" -ForegroundColor Green
    if ($SetAsProduction) {
        Write-Host "🚀 Set as production deployment" -ForegroundColor Green
    }
}

function Update-Deployment {
    if (-not $Name) {
        Write-Host "❌ Deployment name is required for updating" -ForegroundColor Red
        return
    }
    
    $config = Get-DeploymentConfig
    if (-not $config) {
        Write-Host "❌ Could not load deployment configuration" -ForegroundColor Red
        return
    }
    
    if (-not ($config.deployments.PSObject.Properties.Name -contains $Name)) {
        Write-Host "❌ Deployment '$Name' not found" -ForegroundColor Red
        return
    }
    
    $deployment = $config.deployments.$Name
    
    # Update provided fields
    if ($ApiUrl) { $deployment.apiUrl = $ApiUrl }
    if ($McpUrl) { $deployment.mcpUrl = $McpUrl }
    if ($AuthMode) { $deployment.authMode = $AuthMode }
    if ($Description) { $deployment.description = $Description }
    if ($Branch) { $deployment.branch = $Branch }
    if ($Suffix) { $deployment.suffix = $Suffix }
    
    # Update timestamp
    $deployment.lastUpdated = (Get-Date).ToString("yyyy-MM-dd")
    
    # Set as production if requested
    if ($SetAsProduction) {
        $config.aliases.production = $Name
    }
    
    Save-DeploymentConfig $config
    
    Write-Host "✅ Updated deployment '$Name'" -ForegroundColor Green
    if ($SetAsProduction) {
        Write-Host "🚀 Set as production deployment" -ForegroundColor Green
    }
}

function Test-Deployment {
    if (-not $Name) {
        Write-Host "❌ Deployment name is required" -ForegroundColor Red
        return
    }
    
    Write-Host "🧪 Testing deployment: $Name" -ForegroundColor Yellow
    & "$PSScriptRoot\test.ps1" -DeploymentName $Name -Quick -ApiOnly
}

# Main execution
switch ($Action) {
    "list" { Show-Deployments }
    "add" { Add-Deployment }
    "update" { Update-Deployment }
    "test" { Test-Deployment }
    "help" { Show-Help }
    default { Show-Help }
}
