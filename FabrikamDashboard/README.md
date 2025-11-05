# 📊 Fabrikam Dashboard

**Real-time dashboard for visualizing Fabrikam Modular Homes business operations and controlling the FabrikamSimulator.**

---

## 🎯 Overview

The Fabrikam Dashboard is a Blazor Server application that provides workshop participants with:

- **Real-time business metrics** - Orders, support tickets, revenue, and averages
- **Live visualizations** - Charts showing order status and regional distribution  
- **Simulator controls** - Start/stop background workers with one click
- **Auto-updates** - SignalR broadcasts new data every 5 seconds

Perfect for workshops where participants want to **see their AI agents in action** as they create orders, process tickets, and interact with the Fabrikam business.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│  Browser (Blazor UI)                       │
│  - Metric cards                            │
│  - Status charts                           │
│  - Simulator toggles                       │
└──────────────┬──────────────────────────────┘
               │ SignalR WebSocket
               ↓
┌──────────────────────────────────────────────┐
│  FabrikamDashboard (Blazor Server)          │
│  ┌──────────────┐  ┌───────────────────┐   │
│  │ DashboardHub │  │ DataPollingService│   │
│  │ (SignalR)    │←─│ (5s intervals)    │   │
│  └──────────────┘  └───────────────────┘   │
│         │                    ↓               │
│         │          ┌─────────────────────┐  │
│         │          │ FabrikamApiClient   │  │
│         │          │ SimulatorClient     │  │
│         │          └─────────────────────┘  │
└─────────┼──────────────────┬─────────────────┘
          │                  │
          ↓                  ↓
   ┌─────────────┐    ┌──────────────────┐
   │ FabrikamApi │    │ FabrikamSimulator│
   │ Port 7297   │    │ Port 5000        │
   └─────────────┘    └──────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- .NET 9.0 SDK
- FabrikamApi running on `https://localhost:7297`
- FabrikamSimulator running on `https://localhost:5000` (optional for simulator controls)

### Running the Dashboard

#### Option 1: VS Code Task (Recommended)

Press `Ctrl+Shift+P` → "Tasks: Run Task" → Select:
- **"📊 Start Dashboard"** - Dashboard only
- **"🚀 Start All Services"** - API + MCP + Simulator + Dashboard

#### Option 2: Command Line

```powershell
# From repository root
dotnet run --project FabrikamDashboard/FabrikamDashboard.csproj
```

#### Option 3: Start with all services

```powershell
# Start API server (Terminal 1)
dotnet run --project FabrikamApi/src/FabrikamApi.csproj

# Start Simulator (Terminal 2)
dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj

# Start Dashboard (Terminal 3)
dotnet run --project FabrikamDashboard/FabrikamDashboard.csproj
```

### Accessing the Dashboard

Open your browser to:
- **Dashboard**: `https://localhost:5200` (or the port shown in console)
- **Swagger**: Not available (Blazor UI only)

---

## 📋 Features

### 1. Real-Time Metrics

Four key business metrics updated every 5 seconds:

| Metric | Description | Color |
|--------|-------------|-------|
| **Active Orders** | Total number of orders in the system | Blue |
| **Open Tickets** | Support tickets in "Open" or "InProgress" status | Orange |
| **Total Revenue** | Sum of all order totals | Green |
| **Avg Order Value** | Revenue divided by order count | Purple |

### 2. Visual Charts

#### Orders by Status Chart
- **Pending** - Orders waiting to start (yellow bar)
- **InProduction** - Orders being manufactured (blue bar)
- **Shipped** - Orders in transit (purple bar)
- **Delivered** - Completed orders (green bar)

Each bar shows:
- Status badge with count
- Progress bar (proportional width)
- Percentage of total orders

#### Orders by Region Chart
- **Northeast** 🏔️
- **Southeast** 🌴
- **Midwest** 🌾
- **Southwest** 🌵
- **West** 🏖️

### 3. Simulator Controls

Control three background workers:

| Worker | Function | Default Interval |
|--------|----------|------------------|
| **Order Progression** | Moves orders through lifecycle (Pending→InProduction→Shipped→Delivered) | 5 minutes |
| **Order Generator** | Creates 1-3 new orders per run | 60 minutes |
| **Ticket Generator** | Creates 1-2 support tickets per run | 60 minutes |

Each control shows:
- **Status**: 🟢 ON / 🔴 OFF
- **Last Run**: Time since last execution
- **Next Run**: Time until next execution (when enabled)
- **Toggle Button**: Start/Stop worker

### 4. Connection Status

Top-right corner shows:
- **🟢 Connected** - SignalR connection active, receiving updates
- **🔴 Disconnected** - Connection lost, attempting reconnect
- **Updated**: Timestamp of last data refresh

---

## 🔧 Configuration

### appsettings.json

```json
{
  "FabrikamApi": {
    "BaseUrl": "https://localhost:7297"
  },
  "FabrikamSimulator": {
    "BaseUrl": "https://localhost:5000"
  }
}
```

### Environment Variables

Override URLs via environment variables:

```powershell
$env:FabrikamApi__BaseUrl = "https://your-api-url"
$env:FabrikamSimulator__BaseUrl = "https://your-simulator-url"
dotnet run --project FabrikamDashboard/FabrikamDashboard.csproj
```

---

## 🧩 Technical Details

### Tech Stack

- **Framework**: ASP.NET Core Blazor Server (.NET 9.0)
- **Real-time**: SignalR for WebSocket communication
- **HTTP Client**: Typed HttpClient with DI
- **DTOs**: Shared via `FabrikamContracts` project
- **Styling**: Custom CSS with responsive design
- **Background Service**: Hosted service for polling APIs

### Project Structure

```
FabrikamDashboard/
├── Components/
│   ├── Pages/
│   │   └── Home.razor                # Main dashboard page
│   ├── Shared/
│   │   ├── MetricCard.razor          # Reusable metric display
│   │   └── SimulatorToggle.razor     # Worker control component
│   ├── Layout/
│   │   └── MainLayout.razor
│   ├── App.razor
│   └── _Imports.razor
├── Services/
│   ├── FabrikamApiClient.cs          # HTTP client for FabrikamApi
│   ├── SimulatorClient.cs            # HTTP client for Simulator
│   └── DashboardHub.cs               # SignalR hub
├── BackgroundServices/
│   └── DataPollingService.cs         # Polls APIs every 5s
├── Models/
│   └── DashboardModels.cs            # DTOs for dashboard data
├── wwwroot/
│   ├── dashboard.css                 # Custom styles
│   └── app.css
├── Program.cs                        # App configuration
└── appsettings.json
```

### Key Components

#### DataPollingService
- **Purpose**: Polls FabrikamApi and FabrikamSimulator every 5 seconds
- **Pattern**: IHostedService background worker
- **Broadcasts**: Sends `DashboardUpdate` via SignalR to all clients
- **Error Handling**: Continues on API failures, logs warnings

#### DashboardHub
- **Purpose**: SignalR hub for real-time client communication
- **Endpoint**: `/dashboardHub`
- **Events**: 
  - `DashboardUpdate` - Server → Client (every 5s)
  - `RequestRefresh` - Client → Server (manual trigger)

#### Home.razor
- **Purpose**: Main dashboard page with all UI components
- **State**: Subscribes to `DashboardUpdate` SignalR events
- **Reconnection**: Automatically reconnects on connection loss
- **Disposal**: Properly disposes SignalR connection

---

## 🎨 Customization

### Polling Interval

Edit `DataPollingService.cs`:

```csharp
private readonly TimeSpan _pollingInterval = TimeSpan.FromSeconds(5);
// Change to: TimeSpan.FromSeconds(10) for slower updates
```

### Dashboard Colors

Edit `wwwroot/dashboard.css`:

```css
.metric-blue { border-left: 4px solid #3498db; }
.metric-green { border-left: 4px solid #27ae60; }
/* Add custom colors here */
```

### Additional Metrics

1. Add property to `DashboardDataDto`
2. Calculate in `DataPollingService.CalculateDashboardMetrics()`
3. Add `<MetricCard>` to `Home.razor`

---

## 🧪 Testing

### Local Testing

1. **Start services**:
   ```powershell
   # Terminal 1: API
   dotnet run --project FabrikamApi/src/FabrikamApi.csproj
   
   # Terminal 2: Simulator  
   dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj
   
   # Terminal 3: Dashboard
   dotnet run --project FabrikamDashboard/FabrikamDashboard.csproj
   ```

2. **Open dashboard**: `https://localhost:5200`

3. **Verify**:
   - Metrics populate with data
   - Charts render with order status
   - Simulator controls show current state
   - Connection status shows 🟢 Connected

4. **Test simulator controls**:
   - Click "Start" on Order Generator
   - Verify status changes to 🟢 ON
   - Watch for new orders appearing in charts

### Workshop Testing

```powershell
# Create test data
.\scripts\Inject-Orders.ps1 -OrderCount 50

# Start all services
.\test.ps1 -Visible -Quick

# Open dashboard
start https://localhost:5200
```

---

## 🚀 Deployment

### Azure Container Apps

The dashboard can be deployed alongside FabrikamApi:

```bash
# Add to azure.yaml services
services:
  dashboard:
    project: ./FabrikamDashboard
    language: dotnet
    host: containerapp
```

### Environment Variables (Production)

```bash
FabrikamApi__BaseUrl=https://fabrikam-api.azurecontainerapps.io
FabrikamSimulator__BaseUrl=https://fabrikam-simulator.azurecontainerapps.io
```

---

## 🔍 Troubleshooting

### Dashboard shows "Loading..."
- **Cause**: FabrikamApi not running
- **Fix**: Start API on port 7297
- **Check**: `curl https://localhost:7297/api/orders`

### Simulator controls missing
- **Cause**: FabrikamSimulator not running
- **Expected**: Warning message displayed
- **Fix**: Start simulator on port 5000

### Connection drops frequently
- **Cause**: SignalR timeout or network issues
- **Fix**: Dashboard auto-reconnects, check browser console

### Charts not updating
- **Cause**: No new data from API
- **Check**: Watch browser console for `DashboardUpdate` events
- **Verify**: API returns data: `Invoke-RestMethod https://localhost:7297/api/orders -SkipCertificateCheck`

### Build errors
- **Cause**: Missing FabrikamContracts reference
- **Fix**: `dotnet build Fabrikam.sln` from root

---

## 📚 Related Documentation

- **FabrikamApi**: `FabrikamApi/README.md`
- **FabrikamSimulator**: `FabrikamSimulator/README.md`
- **Development Guide**: `docs/development/DASHBOARD-IMPLEMENTATION-GUIDE.md`
- **Workshop Materials**: `challenges/README.md`

---

## 🤝 Contributing

When adding features to the dashboard:

1. **Follow Blazor best practices** - Use components, proper disposal
2. **Use FabrikamContracts DTOs** - Don't create duplicate models
3. **Handle API failures gracefully** - Log warnings, continue operation
4. **Maintain responsive design** - Test on mobile/tablet
5. **Update this README** - Document new features

---

## 📝 License

Part of the Fabrikam Project. See `LICENSE.md` in repository root.

---

**Built with ❤️ for the Agent-A-Thon workshop participants!**

*Last updated: November 4, 2025*
