# Seed Data Extension to November 5, 2025

## Overview
Extended sample data for workshop participants to have fresh, realistic data that appears current as of the workshop date (late October/early November 2025).

## Changes Made

### Orders Data (`FabrikamApi/src/Data/SeedData/orders.json`)

**Previous Range**: March 2020 - September 2, 2025 (46 orders)  
**Extended Range**: March 2020 - November 4, 2025 (56 unique order IDs, 58 total entries)

**New Orders Added** (September 3 - November 4, 2025):

| Order ID | Order Number | Customer | Order Date | Status | Amount |
|----------|--------------|----------|------------|--------|---------|
| 47 | FAB-2025-047 | Megan Bowen (6) | 2025-09-10 | InProduction | $130,000 |
| 48 | FAB-2025-048 | Irvin Sayers (9) | 2025-09-18 | Shipped | $185,000 |
| 49 | FAB-2025-049 | Diego Siciliani (10) | 2025-09-25 | Delivered | $243,500 |
| 50 | FAB-2025-050 | Ben Walters (2) | 2025-10-03 | InProduction | $307,500 |
| 51 | FAB-2025-051 | Patti Fernandez (7) | 2025-10-08 | Pending | $116,000 |
| 52 | FAB-2025-052 | Grady Archie (11) | 2025-10-15 | InProduction | $169,500 |
| 53 | FAB-2025-053 | Adele Vance (4) | 2025-10-22 | Shipped | $175,000 |
| 54 | FAB-2025-054 | Allan Deyoung (8) | 2025-10-28 | Pending | $200,000 |
| 55 | FAB-2025-055 | Isaiah Langer (12) | 2025-11-01 | Pending | $225,000 |
| 56 | FAB-2025-056 | Johanna Lorenz (3) | 2025-11-04 | Pending | $351,500 |

**Total New Orders**: 10  
**Date Range**: 2 months (September 3 - November 4, 2025)  
**Status Distribution**: 
- Pending: 4 orders
- InProduction: 3 orders
- Shipped: 2 orders
- Delivered: 1 order

### Support Tickets Data (`FabrikamApi/src/Data/SeedData/supporttickets.json`)

**Previous Range**: February 2020 - September 2, 2025 (30 tickets)  
**Extended Range**: February 2020 - November 5, 2025 (40 tickets)

**New Support Tickets Added** (September 15 - November 5, 2025):

| Ticket ID | Ticket Number | Customer | Created Date | Status | Priority | Category |
|-----------|---------------|----------|--------------|--------|----------|----------|
| 31 | FAB-2025-009 | Megan Bowen (6) | 2025-09-15 | InProgress | Medium | Technical Support |
| 32 | FAB-2025-010 | Irvin Sayers (9) | 2025-09-20 | Resolved | Low | Delivery |
| 33 | FAB-2025-011 | Diego Siciliani (10) | 2025-09-28 | Resolved | Low | General Feedback |
| 34 | FAB-2025-012 | Ben Walters (2) | 2025-10-05 | InProgress | Medium | Customization |
| 35 | FAB-2025-013 | Patti Fernandez (7) | 2025-10-10 | Open | Medium | Customization |
| 36 | FAB-2025-014 | Grady Archie (11) | 2025-10-18 | InProgress | Low | General |
| 37 | FAB-2025-015 | Adele Vance (4) | 2025-10-25 | InProgress | Medium | Technical Support |
| 38 | FAB-2025-016 | Allan Deyoung (8) | 2025-10-29 | Open | Low | General |
| 39 | FAB-2025-017 | Isaiah Langer (12) | 2025-11-02 | Open | Medium | Technical Support |
| 40 | FAB-2025-018 | Johanna Lorenz (3) | 2025-11-05 | Open | Medium | Customization |

**Total New Tickets**: 10  
**Date Range**: ~2 months (September 15 - November 5, 2025)  
**Status Distribution**:
- Open: 4 tickets
- InProgress: 4 tickets
- Resolved: 2 tickets

### Content Themes

The new tickets and orders reflect realistic business scenarios:

**Orders**:
- Mix of products across all categories (studios, cottages, villas, manors)
- Geographic distribution across all US regions
- Various status states to show active pipeline
- Recent orders (last week of October, first week of November) in "Pending" status
- Older orders progressing through production/shipping/delivery

**Support Tickets**:
- Installation and site preparation questions (most common for new orders)
- Customization requests (smart home, finishes, multi-unit configurations)
- Positive customer feedback (realistic 2 of 10 tickets)
- Technical support for regional considerations (climate, elevation, soil)
- Commercial/bulk order inquiries (business development)

## Workshop Impact

### For Participants
- **Fresh data**: Latest entries are from October 29 - November 5, 2025
- **Realistic pipeline**: Mix of pending, in-production, shipped, and delivered orders
- **Active support cases**: Open tickets require attention, showing real workflow
- **No default filters needed**: With MCP tool changes, all data is accessible

### For MCP Tools
With the removal of default date filters (see `MCP-TOOL-FILTER-REMOVAL-CHANGES.md`):
- `get_orders` with no parameters now returns ALL orders (2020-2025)
- `get_support_tickets` with no parameters returns ALL tickets
- Agents can query any historical period or focus on recent data
- Analysts can compare 2020 vs 2025 trends

### Testing Scenarios

**Scenario 1: Recent Activity**
```
"Show me orders from the last 30 days"
→ Returns orders 50-56 (Oct 3 - Nov 4, 2025)
```

**Scenario 2: Active Pipeline**
```
"What orders are currently in production?"
→ Returns orders 47, 50, 52 (InProduction status)
```

**Scenario 3: Support Workload**
```
"Show me open support tickets"
→ Returns tickets 35, 38, 39, 40
```

**Scenario 4: Customer Journey**
```
"Show me all activity for customer Johanna Lorenz (ID 3)"
→ Returns multiple orders including latest (Nov 4) + support ticket (Nov 5)
```

**Scenario 5: Historical Analysis**
```
"Compare orders from 2020 vs 2025"
→ Can access full 5-year dataset for trend analysis
```

## Data Quality Notes

### Realistic Patterns
- Order frequency: ~5 orders per month (realistic for boutique modular home company)
- Support ticket ratio: ~1 ticket per order (10 tickets for 10 new orders)
- Status progression: Most recent orders in "Pending", older ones move to production/shipping
- Geographic variety: All US regions represented
- Product mix: All product lines in use
- Price range: $116K - $351K (matches product catalog)

### Regional Distribution
- Midwest: 4 orders (historical strength)
- Pacific Northwest: 1 order
- West Coast: 1 order  
- Northeast: 1 order
- Southeast: 1 order
- Southwest: 2 orders

### Intentional Duplicates
Note: Original data contains duplicate IDs 40 and 41. This is acknowledged and not a data error from this extension. Total unique order IDs = 56, total entries = 58.

## Files Modified
- `FabrikamApi/src/Data/SeedData/orders.json` - Added 10 new orders
- `FabrikamApi/src/Data/SeedData/supporttickets.json` - Added 10 new support tickets

## Testing

### Validation Tests Run
```powershell
# JSON validity
✅ orders.json is valid JSON
✅ supporttickets.json is valid JSON

# Data counts
✅ Total orders: 58 (from 46)
✅ Total support tickets: 40 (from 30)

# Date ranges
✅ Last order: November 4, 2025
✅ Last support ticket: November 5, 2025
```

### Recommended Post-Deployment Tests

1. **API Endpoint Test**:
   ```powershell
   # Should return 58 orders including new Nov 2025 entries
   Invoke-RestMethod -Uri "https://localhost:7297/api/orders"
   ```

2. **MCP Tool Test** (no date filter):
   ```json
   {
     "jsonrpc": "2.0",
     "method": "tools/call",
     "params": {
       "name": "get_orders",
       "arguments": {}
     }
   }
   ```
   Expected: Returns all 58 orders (paginated)

3. **Date Range Test**:
   ```json
   {
     "jsonrpc": "2.0",
     "method": "tools/call",
     "params": {
       "name": "get_orders",
       "arguments": {
         "fromDate": "2025-10-01",
         "toDate": "2025-11-05"
       }
     }
   }
   ```
   Expected: Returns orders 50-56 (7 orders from October-November)

## Deployment

These changes are part of the main branch and will deploy via CI/CD:
- **Production API**: https://fabrikam-api-development-tzjeje.azurewebsites.net
- **Production MCP**: https://fabrikam-mcp-development-tzjeje.azurewebsites.net

After deployment, the seeded data will be available in the in-memory database on application startup.

---

**Created**: October 29, 2025  
**Purpose**: Workshop preparation - fresh realistic data  
**Impact**: 10 new orders + 10 new support tickets (Sep-Nov 2025)  
**Related**: MCP-TOOL-FILTER-REMOVAL-CHANGES.md
