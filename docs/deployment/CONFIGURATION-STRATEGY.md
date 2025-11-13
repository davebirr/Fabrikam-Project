# Configuration Strategy for Multi-Instance Deployments

## Problem Statement

The Fabrikam Project supports spinning up multiple independent instances (workshop teams, dev/test/prod environments). Hardcoding instance-specific URLs in `appsettings.json` creates maintenance issues and deployment fragility.

## Current Approach ✅

**Base appsettings.json**: Use localhost defaults (works for local development)
```json
{
  "FabrikamApi": {
    "BaseUrl": "https://localhost:7297"
  }
}
```

**Azure App Settings**: Workflows override with instance-specific values
```bash
az webapp config appsettings set \
  --settings FabrikamApi__BaseUrl="https://fabrikam-api-team01.azurewebsites.net"
```

### Why This Works

1. ✅ **Local Development**: Developers get working defaults (localhost)
2. ✅ **Azure Deployment**: App Settings override configuration at runtime
3. ✅ **No Code Changes**: Each instance gets correct URLs via deployment
4. ✅ **No Secrets in Code**: Environment-specific values stay out of source control

## Configuration Hierarchy

ASP.NET Core reads configuration in this order (later sources override earlier):

1. `appsettings.json` (localhost defaults)
2. `appsettings.{Environment}.json` (Development/Production overrides)
3. **Environment Variables** (Azure App Settings)
4. Command-line arguments

## Best Practices for Multi-Instance Projects

### ✅ DO: Use Localhost Defaults

```json
// appsettings.json
{
  "FabrikamApi": {
    "BaseUrl": "https://localhost:7297"
  }
}
```

### ✅ DO: Override in Workflows

```yaml
# .github/workflows/deploy-workshop-instances.yml
- name: Configure App Settings
  run: |
    az webapp config appsettings set \
      --name ${{ env.MCP_APP_NAME }} \
      --resource-group ${{ env.RESOURCE_GROUP }} \
      --settings \
        FabrikamApi__BaseUrl="https://${{ env.API_APP_NAME }}.azurewebsites.net"
```

### ✅ DO: Document Required Settings

Create a checklist for each deployment:

**Required App Settings for MCP Server:**
- `FabrikamApi__BaseUrl` - URL to API instance
- `Authentication__Jwt__SecretKey` - (if auth enabled)
- `ASPNETCORE_ENVIRONMENT` - Development/Production

**Required App Settings for Dashboard:**
- `FabrikamApi__BaseUrl` - URL to API instance
- `FabrikamSimulator__BaseUrl` - URL to Simulator instance

### ❌ DON'T: Hardcode Instance-Specific URLs

```json
// ❌ BAD: Hardcoded instance URL
{
  "FabrikamApi": {
    "BaseUrl": "https://fabrikam-api-team01-abc123.azurewebsites.net"
  }
}
```

### ❌ DON'T: Commit Azure-Specific Values

Keep `appsettings.json` environment-agnostic. Use `appsettings.Production.json` for production-specific settings, but don't commit instance URLs.

## Alternative Patterns (For Consideration)

### Option A: Service Discovery Pattern

For complex microservices, use Azure Service Discovery:

```csharp
// Use Azure App Configuration or Key Vault
builder.Configuration.AddAzureAppConfiguration(options =>
{
    options.Connect(Environment.GetEnvironmentVariable("APP_CONFIG_CONNECTION"))
           .ConfigureKeyVault(kv => kv.SetCredential(new DefaultAzureCredential()));
});
```

**Pros**: Centralized configuration, dynamic updates
**Cons**: Additional Azure service cost, more complexity

### Option B: Environment Variable Fallback

```csharp
// Program.cs - Read from environment with fallback
var apiBaseUrl = builder.Configuration["FabrikamApi:BaseUrl"] 
    ?? Environment.GetEnvironmentVariable("FABRIKAM_API_URL")
    ?? "https://localhost:7297";
```

**Pros**: Maximum flexibility
**Cons**: More code, non-standard pattern

### Option C: Convention-Based Discovery

For predictable naming patterns:

```csharp
// Derive MCP URL from API URL automatically
var apiUrl = builder.Configuration["FabrikamApi:BaseUrl"];
var mcpUrl = apiUrl.Replace("-api-", "-mcp-"); // fabrikam-api-team01 → fabrikam-mcp-team01
```

**Pros**: Reduces configuration duplication
**Cons**: Brittle if naming changes, harder to debug

## Current Implementation Status

✅ **Implemented**:
- Localhost defaults in base `appsettings.json`
- Development overrides in `appsettings.Development.json`
- Workflow-based App Settings configuration for all services
- Multi-instance workshop deployment support

📋 **Recommended Next Steps**:
1. ✅ Update `appsettings.json` to use localhost (just completed)
2. Validate all workflows set required App Settings
3. Document required settings in deployment README
4. Consider Azure App Configuration for secrets management

## Testing Your Configuration

### Local Development
```bash
# Should use localhost from appsettings.Development.json
dotnet run --project FabrikamMcp/src/FabrikamMcp.csproj
```

### Azure Deployment
```bash
# Verify App Settings override
az webapp config appsettings list \
  --name fabrikam-mcp-team01 \
  --resource-group rg-fabrikam-workshop \
  --query "[?name=='FabrikamApi__BaseUrl']"
```

### Runtime Verification
```csharp
// Add diagnostic logging in Program.cs
var apiUrl = builder.Configuration["FabrikamApi:BaseUrl"];
builder.Services.AddLogging(logging => 
    logging.AddConsole().SetMinimumLevel(LogLevel.Information));

// Log on startup
app.Logger.LogInformation("🔧 FabrikamApi BaseUrl: {BaseUrl}", apiUrl);
```

## Summary

**Current Strategy**: Localhost defaults + Azure App Settings overrides ✅

This is the **recommended approach** for your project because:
- ✅ Simple and standard ASP.NET Core pattern
- ✅ Works for local development without changes
- ✅ Supports unlimited instances via workflows
- ✅ No additional Azure services required
- ✅ Clear separation of concerns

Your workflows already implement this correctly - the fix was simply updating the base `appsettings.json` to use localhost instead of a hardcoded instance.
