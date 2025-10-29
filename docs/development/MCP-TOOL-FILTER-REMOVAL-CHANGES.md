# MCP Tool Default Filter Removal - October 29, 2025

## Objective
Remove implicit default filters from MCP tools to make them more robust and flexible. The tools should be **data providers**, with filtering logic driven by the AI agent working with the user, not hardcoded in the tools.

## Problem Statement
MCP tools were applying hidden default filters that limited data access:
- `GetOrders` - Applied 30-day filter when no date parameters provided
- `GetSupportTickets` - Applied "Open,InProgress" status filter when no parameters provided

This caused issues:
- Production orders older than 30 days were invisible to users
- Historical data analysis was impossible without knowing to override defaults
- Analysts couldn't access data from 5, 10+ years ago
- The tool made assumptions about what users wanted instead of letting the agent decide

## Changes Made

### 1. FabrikamSalesTools.cs - GetOrders Tool

#### Before:
```csharp
// If no filters provided, default to recent orders (last 30 days)
if (string.IsNullOrEmpty(status) && string.IsNullOrEmpty(region) &&
    string.IsNullOrEmpty(fromDate) && string.IsNullOrEmpty(toDate))
{
    var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30).ToString("yyyy-MM-dd");
    queryParams.Add($"fromDate={thirtyDaysAgo}");
    fromDate = thirtyDaysAgo;
}
```

**Description**: "When called without parameters, returns recent orders."

#### After:
```csharp
// No default filters - let the AI agent determine what data is needed
// The tool provides ALL orders unless filters are explicitly specified
```

**Description**: "When called without parameters, returns ALL orders (paginated). Supports historical data queries - no date restrictions."

**Impact**: 
- ✅ Can now access orders from any time period
- ✅ Agent can query 5, 10+ years of historical data
- ✅ No hidden filtering behavior
- ✅ Pagination still prevents overwhelming responses

### 2. FabrikamCustomerServiceTools.cs - GetSupportTickets Tool

#### Before:
```csharp
// If no filters provided, default to active tickets requiring attention
if (string.IsNullOrEmpty(status) && string.IsNullOrEmpty(priority) && ...)
{
    // Default to open/in-progress tickets that need attention
    queryParams.Add("status=Open,InProgress");
}
```

**Description**: "When called without parameters, returns active tickets requiring attention."

#### After:
```csharp
// No default filters - let the AI agent determine what tickets are needed
// The tool provides ALL tickets unless filters are explicitly specified
```

**Description**: "When called without parameters, returns ALL tickets (paginated). No default filters - agent determines what data is needed."

**Impact**:
- ✅ Can access closed/resolved tickets for analysis
- ✅ Historical ticket analysis possible
- ✅ Trend analysis across all ticket statuses
- ✅ No assumptions about user intent

### 3. FabrikamBusinessIntelligenceTools.cs - GetBusinessDashboard Tool

**No changes to filtering logic** - This tool is designed to show metrics for a specific timeframe, so having a default parameter makes sense.

#### Updated Description:
```
"Timeframe options: '7days'/'week', '30days'/'month', '90days'/'quarter', '365days'/'year'. 
Defaults to 30 days if not specified."
```

**Rationale**: Dashboard metrics are inherently timeframe-based. The default is explicit in the parameter signature (`timeframe = "30days"`), not hidden logic.

## Benefits

### For Users
- ✅ **No surprises** - Tool behavior is transparent
- ✅ **Historical analysis** - Access to all data across any time period
- ✅ **Flexibility** - Agent can request exactly what's needed
- ✅ **Consistency** - Same tool works for recent and historical queries

### For Developers
- ✅ **Simpler code** - Less conditional logic
- ✅ **Easier debugging** - No hidden filters to troubleshoot
- ✅ **Clearer intent** - Tools do what they say
- ✅ **Better testability** - Predictable behavior

### For AI Agents
- ✅ **Better context** - Can see all available data
- ✅ **User-driven** - Can ask user for timeframe preferences
- ✅ **Adaptive** - Can adjust queries based on results
- ✅ **Transparent** - Can explain filtering to users

## Migration Notes

### Copilot Studio Integration
If you have Copilot Studio actions configured to call these tools without parameters, they will now return ALL data (paginated). You may want to:

1. **Update prompts** to guide the agent to ask users about date ranges
2. **Add conversation flow** to determine filtering before calling tools
3. **Test scenarios** where users want recent vs. historical data

Example conversation flow:
```
Agent: "I can help you find orders. What time period are you interested in?"
User: "Show me orders from last month"
Agent: [Calls get_orders with fromDate/toDate for last month]

vs.

Agent: "I can help you find orders. What time period are you interested in?"
User: "Show me all orders from 2020"
Agent: [Calls get_orders with fromDate=2020-01-01&toDate=2020-12-31]
```

### API Performance Considerations
- Pagination limits still apply (default pageSize=20 for orders, tickets)
- The API will handle performance - tools just pass through parameters
- For large datasets, agents should guide users to refine queries

### Testing
To verify the changes work:

#### Test 1: All Orders (No Filter)
```powershell
$headers = @{
    "Accept" = "application/json, text/event-stream"
    "Content-Type" = "application/json"
    "X-User-GUID" = "a1b2c3d4-e5f6-7890-abcd-123456789012"
}
$body = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_orders","arguments":{}}}'

Invoke-WebRequest -Uri "https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp" `
    -Method POST -Headers $headers -Body $body
```

**Expected**: Returns all orders (paginated), including old orders from 2020-2025

#### Test 2: Historical Date Range
```powershell
$body = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_orders","arguments":{"fromDate":"2020-01-01","toDate":"2020-12-31"}}}'

Invoke-WebRequest -Uri "https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp" `
    -Method POST -Headers $headers -Body $body
```

**Expected**: Returns orders from 2020 only

#### Test 3: All Support Tickets
```powershell
$body = '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_support_tickets","arguments":{}}}'

Invoke-WebRequest -Uri "https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp" `
    -Method POST -Headers $headers -Body $body
```

**Expected**: Returns all tickets regardless of status

## Related Files Modified
- `FabrikamMcp/src/Tools/FabrikamSalesTools.cs` - GetOrders tool
- `FabrikamMcp/src/Tools/FabrikamCustomerServiceTools.cs` - GetSupportTickets tool
- `FabrikamMcp/src/Tools/FabrikamBusinessIntelligenceTools.cs` - GetBusinessDashboard description

## Deployment
These changes are in the main branch and will be deployed to production via CI/CD:
- **Production MCP**: https://fabrikam-mcp-development-tzjeje.azurewebsites.net
- **Production API**: https://fabrikam-api-development-tzjeje.azurewebsites.net

After deployment, test the tools to ensure they return all data as expected.

## Best Practices Going Forward

### When Adding New MCP Tools
1. **No hidden defaults** - Don't apply filters unless explicitly requested
2. **Clear descriptions** - Document what happens with no parameters
3. **Agent-driven** - Let the AI agent work with the user to determine filters
4. **Pagination** - Use pagination to handle large result sets
5. **Explicit parameters** - Make optional parameters visible in signatures

### Good Example:
```csharp
[McpServerTool, Description("Get products. Returns ALL products when called without parameters. Use filters (category, priceMin, priceMax) to narrow results.")]
public async Task<object> GetProducts(
    string? category = null,
    decimal? priceMin = null,
    decimal? priceMax = null,
    int page = 1,
    int pageSize = 20)
{
    // Build query from explicit parameters only
    // No hidden filtering logic
}
```

### Bad Example:
```csharp
// DON'T DO THIS
if (string.IsNullOrEmpty(category)) {
    queryParams.Add("category=Popular"); // Hidden default!
}
```

---

**Implemented**: October 29, 2025  
**Status**: Ready for deployment  
**Breaking Change**: Yes - Tools now return more data than before (but properly paginated)
