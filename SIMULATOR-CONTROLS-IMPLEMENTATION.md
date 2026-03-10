# 🎛️ Simulator Configuration Controls - Implementation Summary

## Overview

Implemented runtime-configurable simulator controls to enable workshop participants to test AI agent capacity scenarios without overwhelming infrastructure. Users can now adjust order and ticket generation rates dynamically through REST API endpoints.

## Problem Statement

**Before**: Simulator had only two modes:
- **Normal**: 1-3 orders/hour, 1-2 tickets/hour (~24-72 orders/day, ~24-48 tickets/day) - Too slow for testing
- **Stress Test**: 5-10 tickets every 5 minutes (~1440-2880 tickets/day) - All-or-nothing, tickets only

**Issues**:
- No granular control over generation rates
- No way to adjust order volumes in stress test mode
- Couldn't simulate realistic "AI agent needed" scenarios
- Had to restart service to change settings
- Risk of overwhelming infrastructure with testing

**Solution**: Runtime configuration API with validation and safety limits

## Features Implemented

### ✅ 1. Extended RuntimeConfigService

**File**: `FabrikamSimulator/src/Services/RuntimeConfigService.cs`

**Changes**:
- Added `OrderGeneratorConfigOverride` class with IntervalMinutes, MinOrdersPerInterval, MaxOrdersPerInterval
- Added `TicketGeneratorConfigOverride` class with IntervalMinutes, MinTicketsPerInterval, MaxTicketsPerInterval
- Implemented thread-safe methods:
  - `SetOrderGeneratorConfig(int intervalMinutes, int minOrders, int maxOrders)`
  - `GetOrderGeneratorConfig(IConfiguration)` - Returns effective config (override or appsettings)
  - `ClearOrderGeneratorOverride()`
  - `SetTicketGeneratorConfig(int intervalMinutes, int minTickets, int maxTickets)`
  - `GetTicketGeneratorConfig(IConfiguration)` - Returns effective config (override or appsettings)
  - `ClearTicketGeneratorOverride()`
  - `HasOrderGeneratorOverride()` - Check if runtime override is active
  - `HasTicketGeneratorOverride()` - Check if runtime override is active

**Pattern**: Same three-state nullable pattern used for StressTestMode (null = use config, value = override)

### ✅ 2. New API Endpoints

**File**: `FabrikamSimulator/src/Controllers/SimulatorController.cs`

#### Order Configuration

**POST /api/simulator/config/orders**
```json
{
  "intervalMinutes": 60,
  "minOrdersPerInterval": 2,
  "maxOrdersPerInterval": 5
}
```

**Response**:
```json
{
  "message": "Order generator configuration updated",
  "intervalMinutes": 60,
  "minOrdersPerInterval": 2,
  "maxOrdersPerInterval": 5,
  "estimatedOrdersPerDay": 84,
  "note": "Configuration is runtime-only and will reset on service restart..."
}
```

**POST /api/simulator/config/orders/reset**
- Clears runtime override and returns to appsettings.json defaults

#### Ticket Configuration

**POST /api/simulator/config/tickets**
```json
{
  "intervalMinutes": 30,
  "minTicketsPerInterval": 2,
  "maxTicketsPerInterval": 5
}
```

**Response**:
```json
{
  "message": "Ticket generator configuration updated",
  "intervalMinutes": 30,
  "minTicketsPerInterval": 2,
  "maxTicketsPerInterval": 5,
  "estimatedTicketsPerDay": 168,
  "note": "Configuration is runtime-only and will reset on service restart..."
}
```

**POST /api/simulator/config/tickets/reset**
- Clears runtime override and returns to appsettings.json defaults

### ✅ 3. Validation & Safety Limits

All endpoints include validation:

**Interval Validation**:
- Minimum: 1 minute (prevents rapid-fire generation)
- Maximum: 1440 minutes / 24 hours (prevents excessively long intervals)
- Error: `"Interval must be between 1 and 1440 minutes (24 hours)"`

**Volume Validation**:
- Minimum: 0 for min, 1 for max (prevents negative volumes)
- Maximum: 50 per interval (prevents infrastructure overload)
- Min cannot exceed Max
- Errors: 
  - `"MinOrdersPerInterval must be between 0 and 50"`
  - `"MaxOrdersPerInterval must be between 1 and 50"`
  - `"MinOrdersPerInterval cannot exceed MaxOrdersPerInterval"`

**Estimated Throughput Calculation**:
```csharp
var intervalsPerDay = 1440 / intervalMinutes;
var avgPerInterval = (min + max) / 2.0;
var estimatedPerDay = intervalsPerDay * avgPerInterval;
```

### ✅ 4. Updated Background Workers

**File**: `FabrikamSimulator/src/Workers/OrderGeneratorWorker.cs`

**Changes**:
- Injected `RuntimeConfigService` in constructor
- Changed `ExecuteAsync` to call `_runtimeConfig.GetOrderGeneratorConfig(_configuration)`
- Uses effective config values (runtime override or appsettings)
- Updated `GenerateOrders` method to accept `minOrders, maxOrders` parameters

**File**: `FabrikamSimulator/src/Workers/TicketGeneratorWorker.cs`

**Changes**:
- Already had `RuntimeConfigService` injected (for stress test mode)
- Updated `ExecuteAsync` to call `_runtimeConfig.GetTicketGeneratorConfig(_configuration)` in normal mode
- Stress test mode still uses separate `StressTestConfig` (unchanged)
- Uses effective config values in normal mode

## Usage Scenarios

### Scenario 1: Beginner (Low Volume)
**Goal**: Test basic functionality with minimal load

**Configuration**:
```json
// Orders: ~12-24 per day
{"intervalMinutes": 120, "minOrdersPerInterval": 1, "maxOrdersPerInterval": 2}

// Tickets: ~12-24 per day
{"intervalMinutes": 120, "minTicketsPerInterval": 1, "maxTicketsPerInterval": 1}
```

**When to use**: Initial testing, debugging, low-resource environments

### Scenario 2: Normal (Default)
**Goal**: Standard simulation for development

**Configuration**: Use defaults from appsettings.json
```http
POST /api/simulator/config/orders/reset
POST /api/simulator/config/tickets/reset
```

**Throughput**: ~24-72 orders/day, ~24-48 tickets/day

**When to use**: Daily development, standard demos

### Scenario 3: Intermediate (Medium-High Volume)
**Goal**: Test automation capabilities

**Configuration**:
```json
// Orders: ~144-336 per day
{"intervalMinutes": 30, "minOrdersPerInterval": 3, "maxOrdersPerInterval": 7}

// Tickets: ~144-360 per day
{"intervalMinutes": 30, "minTicketsPerInterval": 2, "maxTicketsPerInterval": 5}
```

**When to use**: Testing AI agent helpers, partial automation scenarios

### Scenario 4: AI Agent Challenge (Very High Volume)
**Goal**: Test full AI agent capacity - requires automated handling

**Configuration**:
```json
// Orders: ~720-2160 per day
{"intervalMinutes": 10, "minOrdersPerInterval": 5, "maxOrdersPerInterval": 15}

// Tickets: ~720-2160 per day
{"intervalMinutes": 10, "minTicketsPerInterval": 5, "maxTicketsPerInterval": 15}
```

**When to use**: Demonstrating AI agent value, capacity testing, workshop challenges

**Warning**: This generates significant load - ensure infrastructure can handle it

## Testing

**Test File**: `test-simulator-config.http`

Contains comprehensive tests for:
- ✅ Updating order configuration
- ✅ Updating ticket configuration
- ✅ Resetting to defaults
- ✅ All 4 preset scenarios
- ✅ Validation tests (should return errors)
- ✅ Stress test mode compatibility

**How to Test**:
1. Start FabrikamSimulator: `dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj`
2. Open `test-simulator-config.http` in VS Code
3. Use REST Client extension to execute requests
4. Verify responses show correct estimated throughput
5. Check simulator logs to confirm new config is being used
6. Verify workers generate at new rates

## Architecture Benefits

### Thread-Safe Design
- Uses lock pattern for all runtime config operations
- Safe for concurrent API calls
- No race conditions

### Fallback Pattern
- Runtime overrides are optional (nullable)
- Falls back to appsettings.json when override is null
- Service restart clears all overrides

### Validation First
- All inputs validated before applying
- Safety limits prevent infrastructure overload
- Clear error messages for invalid inputs

### Estimated Throughput
- Shows projected daily volume before applying
- Helps users understand impact
- Prevents accidental overload

### Separation of Concerns
- RuntimeConfigService manages overrides
- SimulatorController handles HTTP/validation
- Workers consume effective config
- Clean dependency injection

## Next Steps (Pending Dashboard UI)

### 🔄 5. Dashboard UI Controls (Not Started)

**Planned Features**:
- Simulator configuration panel on Home page
- Sliders for intervals and volumes
- Preset buttons (Low, Normal, High, AI Challenge)
- Estimated throughput display (orders/day, tickets/day)
- Apply and Reset buttons
- Visual feedback when runtime overrides are active

**Implementation Plan**:
1. Add configuration section to `FabrikamDashboard/Components/Pages/Home.razor`
2. Create `SimulatorConfigService` to call new API endpoints
3. Add range input controls with value displays
4. Add preset button handlers
5. Show estimated throughput calculations
6. Add visual indicators for active overrides
7. Style with CSS matching existing dashboard theme

**User Experience**:
- No need to use REST client or curl
- Visual feedback of current settings
- Easy presets for common scenarios
- Safety warnings for high volumes

### 🔄 6. Testing & Verification (Pending UI)

Once Dashboard UI is complete:
- Test all presets through UI
- Verify workers respond to config changes
- Validate throughput estimates match actual generation
- Test concurrent users changing settings
- Verify override indicators work
- Test reset functionality

## Files Modified

### Backend Implementation (✅ Complete)
1. **FabrikamSimulator/src/Services/RuntimeConfigService.cs** (+118 lines)
   - Added override classes
   - Implemented config management methods
   
2. **FabrikamSimulator/src/Controllers/SimulatorController.cs** (+184 lines)
   - Added 4 new endpoints
   - Implemented validation
   - Added request/response models
   
3. **FabrikamSimulator/src/Workers/OrderGeneratorWorker.cs** (Modified)
   - Injected RuntimeConfigService
   - Uses effective config instead of appsettings
   
4. **FabrikamSimulator/src/Workers/TicketGeneratorWorker.cs** (Modified)
   - Updated to use effective config in normal mode

### Testing Resources (✅ Complete)
5. **test-simulator-config.http** (New file, 223 lines)
   - Comprehensive API testing
   - All scenarios documented
   - Validation test cases

## Safety Considerations

### Infrastructure Protection
- Max 50 items per interval prevents overload
- Min 1 minute interval prevents rapid-fire
- Estimated throughput shown before applying
- Runtime-only (resets on restart)

### Workshop Safety
- Start with low volumes and increase gradually
- Monitor infrastructure during high-volume tests
- Use presets rather than custom values when possible
- Keep "Reset to Defaults" easily accessible

### Development Safety
- Validation happens before applying changes
- Invalid requests return 400 Bad Request
- Activity log tracks all config changes
- Structured logging shows effective config values

## Benefits for Workshop

### Demonstrating AI Agent Value
- Start at normal volume (human can handle)
- Increase to intermediate (human + some automation)
- Increase to high volume (AI agent required)
- Show performance difference clearly

### Safe Experimentation
- Try different load scenarios
- No permanent changes
- Easy reset to defaults
- Estimated impact shown upfront

### Realistic Testing
- Gradual load increases
- Different patterns (orders vs tickets)
- Customizable to specific scenarios
- Matches real-world scaling challenges

## Technical Notes

### Runtime Overrides vs Configuration
- **Runtime overrides**: Temporary, cleared on restart, API-managed
- **appsettings.json**: Permanent, requires file edit, default fallback

### Compatibility with Stress Test Mode
- Stress test mode still works independently
- Affects ticket generation only
- Uses separate `StressTestConfig` section
- Runtime config only applies in normal mode

### Logging
All configuration changes are logged:
```
Order generator configuration updated via API: Interval=10min, Min=5, Max=15, Estimated=1080/day
```

Activity log entries created for:
- Config updates
- Reset to defaults
- Shows estimated throughput

## Summary

✅ **Completed**: Backend infrastructure for configurable simulator controls
- Runtime configuration service
- REST API endpoints with validation
- Worker integration
- Comprehensive testing resources
- Safety limits and validation

🔄 **Pending**: Dashboard UI controls
- Visual configuration panel
- Preset buttons
- Real-time throughput estimates
- User-friendly controls

**Impact**: Enables workshop participants to safely test AI agent capacity scenarios with realistic, adjustable load patterns without risking infrastructure overload.

---

**Last Updated**: 2025-01-XX  
**Status**: Backend Complete, UI Pending  
**Build Status**: ✅ All projects compile successfully
