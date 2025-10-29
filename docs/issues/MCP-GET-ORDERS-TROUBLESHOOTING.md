# MCP get_orders Tool Troubleshooting - October 29, 2025

## Issue Summary
Copilot Studio calling `get_orders` MCP tool returns empty `{}` or 0 orders in production.

## Root Cause Analysis

### Production Environment Details
- **MCP Server**: `https://fabrikam-mcp-development-tzjeje.azurewebsites.net`
- **API Server**: `https://fabrikam-api-development-tzjeje.azurewebsites.net`
- **Authentication Mode**: Disabled (requires X-User-GUID header)

### Investigation Results

#### ✅ Production API Status
- **Orders in database**: 20 orders
- **Date range**: August 28, 2025 - September 2, 2025
- **Most recent order**: September 2, 2025 (57 days old as of Oct 29, 2025)

#### ✅ Production MCP Status
- **Server**: Working correctly
- **API connectivity**: Successfully calling production API
- **Tool execution**: Functioning as designed

#### ❌ The Problem
**Default Date Filter Too Restrictive**

The `get_orders` MCP tool applies a **30-day default filter** when no date parameters are provided:

```csharp
// From FabrikamSalesTools.cs, line ~143
if (string.IsNullOrEmpty(status) && string.IsNullOrEmpty(region) &&
    string.IsNullOrEmpty(fromDate) && string.IsNullOrEmpty(toDate))
{
    var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30).ToString("yyyy-MM-dd");
    queryParams.Add($"fromDate={thirtyDaysAgo}");
    fromDate = thirtyDaysAgo;
}
```

**Result**: With today being October 29, 2025, the filter looks for orders from September 29, 2025 onwards. Since all production orders are from September 2 or earlier, they are filtered out.

### Test Results

#### Test 1: No Date Filter (Default Behavior)
```bash
curl -X POST https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -H "X-User-GUID: a1b2c3d4-e5f6-7890-abcd-123456789012" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_orders","arguments":{}}}'
```

**Result**: 
- Total Orders: **0**
- Filter Applied: `fromDate=2025-09-29`
- Orders Data: `[]` (empty)

#### Test 2: Explicit Date Range (2025-08-01 to 2025-10-29)
```bash
curl -X POST https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -H "X-User-GUID: a1b2c3d4-e5f6-7890-abcd-123456789012" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_orders","arguments":{"fromDate":"2025-08-01","toDate":"2025-10-29"}}}'
```

**Expected Result**: Should return 20 orders

## Solutions

### Option 1: Update Default Filter (Recommended for Production)
**File**: `FabrikamMcp/src/Tools/FabrikamSalesTools.cs` (around line 143)

Change the default from 30 days to 90 or 180 days:

```csharp
// Current (30 days)
var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30).ToString("yyyy-MM-dd");

// Recommended (90 days)
var ninetyDaysAgo = DateTime.UtcNow.AddDays(-90).ToString("yyyy-MM-dd");

// Or (180 days for demo environments)
var sixMonthsAgo = DateTime.UtcNow.AddDays(-180).ToString("yyyy-MM-dd");
```

### Option 2: Seed Fresh Data in Production
Run the data seeding process to add orders with current dates.

### Option 3: Copilot Studio Configuration
Configure Copilot Studio to always pass explicit date ranges when calling `get_orders`:

```json
{
  "name": "get_orders",
  "arguments": {
    "fromDate": "2025-01-01",
    "toDate": "2025-12-31"
  }
}
```

### Option 4: Remove Default Filter Entirely
Make the tool return ALL orders when no filter is specified (may impact performance with large datasets).

## Verification Steps

### PowerShell Test Script
```powershell
# Test production MCP get_orders with date range
$headers = @{
    "Accept" = "application/json, text/event-stream"
    "Content-Type" = "application/json"
    "X-User-GUID" = "a1b2c3d4-e5f6-7890-abcd-123456789012"
}

# Test with explicit date range
$body = @{
    jsonrpc = "2.0"
    id = 1
    method = "tools/call"
    params = @{
        name = "get_orders"
        arguments = @{
            fromDate = "2025-08-01"
            toDate = "2025-10-29"
        }
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-WebRequest `
    -Uri "https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp" `
    -Method POST `
    -Headers $headers `
    -Body $body

$response.Content
```

## Copilot Studio Integration Notes

### Required Headers
```yaml
X-User-GUID: a1b2c3d4-e5f6-7890-abcd-123456789012  # Required in Disabled auth mode
Accept: application/json, text/event-stream         # Required by MCP protocol
Content-Type: application/json
```

### Swagger Configuration
The production MCP swagger correctly specifies the `X-User-GUID` header as required:

```yaml
parameters:
  - name: X-User-GUID
    in: header
    required: true
    type: string
    default: a1b2c3d4-e5f6-7890-abcd-123456789012
```

## Recommendations

1. **Short-term**: Configure Copilot Studio to pass explicit date ranges
2. **Medium-term**: Increase default filter to 90-180 days for demo/development environments
3. **Long-term**: Implement automatic data seeding in production to maintain fresh demo data

## Related Files
- `FabrikamMcp/src/Tools/FabrikamSalesTools.cs` - MCP tool implementation
- `FabrikamMcp/src/appsettings.json` - Production configuration
- `deployment-config.json` - Deployment URLs and settings

## Testing Environment
- **Local API**: https://localhost:7297 - ✅ Has 20 orders (Aug-Sep 2025 dates)
- **Local MCP**: https://localhost:5001 - ✅ Working
- **Production API**: https://fabrikam-api-development-tzjeje.azurewebsites.net - ✅ Has 20 orders
- **Production MCP**: https://fabrikam-mcp-development-tzjeje.azurewebsites.net - ✅ Working (but filters out old data)

---
**Resolved**: October 29, 2025  
**Next Action**: Choose and implement one of the solutions above
