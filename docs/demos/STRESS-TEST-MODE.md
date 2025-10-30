# 🔥 Stress Test Mode - Workshop Guide

## Overview

Stress Test Mode is a toggleable feature that dramatically increases support ticket generation to demonstrate the value of AI agents handling high-volume support scenarios.

**Purpose**: Workshop facilitators can enable this mode to show how AI agents handle overwhelming support ticket volumes that would be challenging for human support teams.

## Ticket Generation Rates

| Mode | Interval | Tickets/Interval | Est. Tickets/Day |
|------|----------|------------------|------------------|
| **Normal** | 60 min | 1-2 | ~24-48 |
| **Stress Test (Production)** | 5 min | 5-10 | ~144-288 |
| **Stress Test (Development)** | 2 min | 3-7 | ~2,160-5,040 |

## Ticket Scenarios

The ticket generator uses weighted scenario selection:

- **85% AI-Solvable** (Medium/Low priority): Order status, delivery dates, product info, payment questions, etc.
- **15% Escalation-Required** (High priority): Product defects, water damage, safety issues, structural concerns

This ensures demos show both AI agent success AND appropriate escalation to human experts.

## API Endpoints

### Check Status
```powershell
# Get current stress test mode status
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/status" | ConvertTo-Json

# Response shows:
# - stressTestMode: true/false
# - source: "configuration" or "runtime-override"
# - currentSettings: interval, ticket counts, estimated daily volume
```

### Enable Stress Test Mode
```powershell
# Enable high-volume ticket generation
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/enable" -Method Post

# Warning: This immediately activates 150+ tickets/day generation!
```

### Disable Stress Test Mode
```powershell
# Return to normal operation
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/disable" -Method Post
```

### Reset to Configuration
```powershell
# Clear runtime override and use appsettings.json value
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/reset" -Method Post
```

## Workshop Usage Scenario

### Phase 1: Normal Operation (Setup)
1. Start workshop with normal mode (~24-48 tickets/day)
2. Show participants the baseline support ticket volume
3. Demonstrate manual customer service agent workflow
4. **Key Message**: "Manageable but time-consuming"

### Phase 2: Stress Test Activation (Challenge)
```powershell
# Enable stress test mode
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/enable" -Method Post
```
1. Activate stress test mode during workshop
2. Show ticket queue growing rapidly (150+ tickets/day)
3. Attempt manual handling - becomes overwhelming
4. **Key Message**: "Human agents can't keep up"

### Phase 3: AI Agent Solution (Resolution)
1. Deploy AI agent using GitHub Copilot / Azure AI
2. Show AI agent handling high volume effortlessly
3. Demonstrate proper escalation of complex issues (15%)
4. Monitor with MCP tools: ticket queue reduction, response times
5. **Key Message**: "AI agents handle scale, humans handle complexity"

### Phase 4: Cleanup
```powershell
# Return to normal mode
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/disable" -Method Post
```

## Monitoring During Stress Test

### Use Monitor-Simulator.ps1
```powershell
# Run from repository root
.\Monitor-Simulator.ps1 -Interval 30 -Count 20

# Shows real-time:
# - Total support tickets (watch this grow!)
# - Ticket distribution by priority
# - Worker status and run counts
```

### Watch Ticket Queue Growth
```powershell
# Quick ticket count check
$tickets = Invoke-RestMethod -Uri "https://fabrikam-api-development-tzjeje.azurewebsites.net/api/supporttickets?pageSize=1000"
$tickets.Count
```

### Check Activity Logs
```powershell
# See recent simulator activity
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/logs?count=50" | ConvertTo-Json
```

## Important Notes

### Runtime vs Configuration
- **Runtime Override**: Changes via API endpoints are **temporary** (lost on restart)
- **Configuration File**: Changes to `appsettings.json` are **permanent** (survive restart)
- Use runtime override for workshop demos (no deployment needed)
- Use configuration for long-term stress testing environments

### Service Restart Behavior
When the simulator service restarts:
- Runtime overrides are **cleared**
- Mode returns to `appsettings.json` value (default: `false`)
- Re-enable via API if needed after Azure deployment

### Performance Considerations
- **Development Mode**: 2-minute intervals can create thousands of tickets/day (use for short demos only!)
- **Production Mode**: 5-minute intervals are more sustainable for day-long workshops
- Monitor database size if running stress test for extended periods
- Clear old tickets periodically if needed

## Troubleshooting

### Stress Test Not Activating
1. Check simulator is running: `GET /api/simulator/status`
2. Verify TicketGenerator worker is enabled
3. Check logs: `GET /api/simulator/logs`
4. Restart simulator if needed

### Too Many Tickets
```powershell
# Disable stress test mode immediately
Invoke-RestMethod -Uri "https://fabrikam-sim-development-tzjeje.azurewebsites.net/api/simulator/stresstest/disable" -Method Post

# Optionally clear old tickets via API
# (Add cleanup endpoint if needed)
```

### Not Enough Tickets
1. Verify stress test mode is enabled: `GET /api/simulator/stresstest/status`
2. Check interval settings in response
3. Wait for next interval cycle (2-5 minutes)
4. Verify orders exist (tickets require active orders)

## Example Workshop Timeline

| Time | Action | Stress Mode |
|------|--------|-------------|
| 0:00 | Workshop starts, introduce Fabrikam scenario | OFF (normal) |
| 0:15 | Show baseline: ~2-4 tickets/hour | OFF |
| 0:30 | Build AI agent (following workshop guide) | OFF |
| 1:00 | **Enable stress test mode** | **ON** (150+/day) |
| 1:05 | Show overwhelming ticket volume | ON |
| 1:15 | Deploy AI agent to handle volume | ON |
| 1:30 | Demonstrate AI agent success + escalation | ON |
| 1:45 | **Disable stress test mode** | **OFF** |
| 2:00 | Workshop wrap-up and Q&A | OFF |

---

**Created**: October 30, 2025  
**Workshop**: CS Agent-a-thon (November 4-5, 2025)  
**Last Updated**: October 30, 2025
