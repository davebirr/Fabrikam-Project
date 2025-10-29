# 🎲 Fabrikam Business Simulator

**Automated business activity simulator for the Fabrikam modular homes platform.**

This microservice generates realistic business activity to make the Fabrikam demo platform feel alive during workshops and demonstrations.

---

## 🎯 Purpose

The simulator solves the **static seed data problem** by:
- ✅ Moving orders through their natural lifecycle
- ✅ Creating new customer orders with randomness
- ✅ Generating realistic support tickets
- ✅ Providing a control API for dashboard integration

Perfect for **6-day workshop preparation** - simple, focused, and effective.

---

## 🏗️ Architecture

### Three Background Workers

| Worker | Purpose | Interval | Configuration |
|--------|---------|----------|---------------|
| **OrderProgressionWorker** | Moves orders: Pending → InProduction → Shipped → Delivered | 5 min (prod)<br>2 min (dev) | Days per stage, randomization |
| **OrderGeneratorWorker** | Creates 1-3 new orders per interval | 60 min (prod)<br>10 min (dev) | Min/max orders, customer selection |
| **TicketGeneratorWorker** | Creates 1-2 support tickets per interval | 60 min (prod)<br>15 min (dev) | Ticket scenarios, priorities |

### Control API

Simple REST API for dashboard integration:

```http
GET  /api/simulator/status              # Get all simulator statuses
GET  /api/simulator/config              # Get configuration
GET  /api/simulator/info                # API information

POST /api/simulator/orders/progression/start
POST /api/simulator/orders/progression/stop
POST /api/simulator/orders/generator/start
POST /api/simulator/orders/generator/stop
POST /api/simulator/tickets/start
POST /api/simulator/tickets/stop
```

---

## 🚀 Quick Start

### Run Locally (Development)

```powershell
# Terminal 1: Start FabrikamApi (required)
dotnet run --project FabrikamApi/src/FabrikamApi.csproj

# Terminal 2: Start Simulator
dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj
```

**Access:**
- Swagger UI: `https://localhost:5000/swagger` (or whatever port is assigned)
- API: `https://localhost:5000/api/simulator/status`

### Configuration

**Development Settings** (`appsettings.Development.json`):
- Fast intervals (2-15 min) for testing
- Short order lifecycles (1-5 days instead of 3-30)
- More logging

**Production Settings** (`appsettings.json`):
- Realistic intervals (5-60 min)
- Real-world timelines (3-30 days)
- Less verbose logging

### Control Simulators via API

```powershell
# Check status
Invoke-RestMethod https://localhost:5000/api/simulator/status

# Stop order progression
Invoke-RestMethod -Method POST https://localhost:5000/api/simulator/orders/progression/stop

# Start ticket generator
Invoke-RestMethod -Method POST https://localhost:5000/api/simulator/tickets/start
```

---

## ⚙️ Configuration Reference

```json
{
  "FabrikamApi": {
    "BaseUrl": "https://localhost:7297"  // FabrikamApi endpoint
  },
  "SimulatorSettings": {
    "OrderProgression": {
      "Enabled": true,                   // Enable on startup
      "IntervalMinutes": 5,              // Run every 5 minutes
      "PendingToProductionDays": 3,      // Days before moving to production
      "ProductionToShippedDays": 30,     // Days in production
      "ShippedToDeliveredDays": 10,      // Days in transit
      "RandomVariationDays": 2           // ±2 days randomization
    },
    "OrderGenerator": {
      "Enabled": true,
      "IntervalMinutes": 60,
      "MinOrdersPerInterval": 1,         // Generate 1-3 orders
      "MaxOrdersPerInterval": 3
    },
    "TicketGenerator": {
      "Enabled": true,
      "IntervalMinutes": 60,
      "MinTicketsPerInterval": 1,
      "MaxTicketsPerInterval": 2
    }
  }
}
```

---

## 📊 Order Lifecycle Logic

### Progression Rules

```
Pending (3-5 days) → InProduction (28-32 days) → Shipped (8-12 days) → Delivered
```

**Worker checks:**
1. Get all orders from FabrikamApi
2. For each order, check days since last status change
3. If threshold reached (with random variation), update status
4. PATCH to `/api/orders/{id}/status` with new status

**Example:**
- Order created Sep 2 as "Pending"
- Oct 29: 57 days old, threshold = 3 days → Move to "InProduction"
- Nov 28: 30 days in production → Move to "Shipped"
- Dec 10: 12 days shipped → Move to "Delivered"

---

## 🎫 Support Ticket Scenarios

The simulator generates realistic tickets based on actual business scenarios:

| Scenario | Priority | Category |
|----------|----------|----------|
| Order status inquiry | Medium | General |
| Delivery date question | Medium | Shipping |
| Product damage report | High | Technical |
| Customization request | Low | General |
| Payment question | Medium | Billing |
| Installation support | Medium | Installation |
| Missing parts | High | Technical |
| Address change request | High | Shipping |

---

## 🔌 Dashboard Integration

### Status Endpoint Response

```json
{
  "orderProgression": {
    "enabled": true,
    "lastRun": "2025-10-29T14:30:00Z",
    "nextRun": "2025-10-29T14:35:00Z",
    "runCount": 42,
    "lastError": null
  },
  "orderGenerator": {
    "enabled": true,
    "lastRun": "2025-10-29T14:00:00Z",
    "nextRun": "2025-10-29T15:00:00Z",
    "runCount": 15,
    "lastError": null
  },
  "ticketGenerator": {
    "enabled": false,
    "lastRun": null,
    "nextRun": null,
    "runCount": 0,
    "lastError": null
  }
}
```

### Dashboard UI Example

Your dashboard developer can use this API to build controls:

```html
<!-- Toggle Switch Example -->
<button onclick="toggleSimulator('orders/progression')">
  Order Progression: <span id="order-status">ON</span>
</button>

<script>
async function toggleSimulator(simulator) {
  const status = document.getElementById('order-status').textContent;
  const action = status === 'ON' ? 'stop' : 'start';
  
  await fetch(`https://simulator-api/api/simulator/${simulator}/${action}`, {
    method: 'POST'
  });
  
  // Refresh status
  updateStatus();
}
</script>
```

---

## 🚢 Deployment

### Azure Deployment

The simulator can be deployed as:
- **Azure Container App** (recommended - alongside FabrikamApi/MCP)
- **Azure App Service**
- **Azure Container Instance**

**Environment Variables:**
```bash
FabrikamApi__BaseUrl=https://fabrikam-api-production.azurewebsites.net
ASPNETCORE_ENVIRONMENT=Production
```

### Docker Support (Future)

```dockerfile
# Future enhancement
FROM mcr.microsoft.com/dotnet/aspnet:9.0
COPY ./publish /app
WORKDIR /app
ENTRYPOINT ["dotnet", "FabrikamSimulator.dll"]
```

---

## 🧪 Testing

### Manual Testing

1. Start FabrikamApi and Simulator
2. Check initial status: `GET /api/simulator/status`
3. Create a test order in FabrikamApi
4. Wait for progression worker (2 min in dev mode)
5. Verify order status changed

### Test Endpoints

```powershell
# Quick health check
curl https://localhost:5000/api/simulator/info

# Check all workers
curl https://localhost:5000/api/simulator/status

# Test start/stop
curl -X POST https://localhost:5000/api/simulator/orders/progression/stop
curl https://localhost:5000/api/simulator/orders/progression/start
```

---

## 📝 Logging

View worker activity:

```powershell
# Watch logs in real-time
dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj
```

**Log Messages:**
- `OrderProgressionWorker started`
- `Moving order FAB-2025-046 from Pending to InProduction`
- `Processed 58 orders, updated 3`
- `Generated 2 new orders`
- `Created support ticket TKT-123 for order FAB-2025-047`

---

## 🛠️ Development Notes

### Why Separate Microservice?

✅ **Clean separation** - Business logic vs simulation  
✅ **Independent scaling** - Can run on schedule without affecting API  
✅ **Easy toggling** - Dashboard can enable/disable without redeploying  
✅ **Monorepo benefits** - Shares infrastructure, single build  

### Design Decisions

- **Simple workers** - Each worker is ~150 lines of focused code
- **No complex AI** - Just randomization and thresholds
- **Singleton state** - `WorkerStateService` coordinates all workers
- **Configuration-driven** - Easy to adjust intervals without code changes
- **Minimal dependencies** - Only needs HttpClient to call FabrikamApi

---

## 📚 Related Documentation

- **FabrikamApi**: Core business API (`/FabrikamApi/README.md`)
- **Monorepo Guide**: Multi-project structure (`/.github/MONOREPO-GUIDE.md`)
- **Workshop Materials**: CS Agent-a-thon (`/workshops/cs-agent-a-thon/`)

---

## 🎯 Workshop Checklist

Before your workshop in 6 days:

- [x] ✅ Simulator project created and building
- [ ] 🔲 Test order progression (create old orders, verify they move)
- [ ] 🔲 Test order generation (verify new orders appear)
- [ ] 🔲 Test ticket generation (verify realistic tickets)
- [ ] 🔲 Deploy to Azure alongside FabrikamApi
- [ ] 🔲 Dashboard integration complete
- [ ] 🔲 Verify simulators can be toggled from dashboard

---

**Built for the Fabrikam CS Agent-a-thon Workshop** 🏆  
*Making static demos feel dynamic since 2025*
