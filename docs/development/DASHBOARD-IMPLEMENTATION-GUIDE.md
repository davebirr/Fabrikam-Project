# 📊 Fabrikam Real-Time Dashboard - Implementation Guide

**Goal**: Build a real-time dashboard for workshop participants to visualize Fabrikam business activity and control the simulator.

---

## 🎯 Technology Choice: Blazor Server

**Selected**: **Blazor Server with SignalR**

### Why Blazor Server?

| Benefit | Details |
|---------|---------|
| ✅ **Native .NET** | No JavaScript framework learning curve |
| ✅ **Real-time by Default** | SignalR built-in for live updates |
| ✅ **OpenAPI Integration** | Auto-generate API clients from FabrikamApi swagger |
| ✅ **Monorepo Friendly** | Single solution, shared DTOs via FabrikamContracts |
| ✅ **Fast Development** | Working dashboard in < 2 hours |
| ✅ **Workshop Compatible** | Participants understand C# better than React/Vue |

### Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **React + Vite** | Modern, popular | Requires TypeScript/JavaScript expertise | ❌ Too much context switching |
| **ASP.NET Core MVC** | Traditional | No real-time without extra work | ❌ Not real-time friendly |
| **Blazor WebAssembly** | Client-side | Larger payload, CORS complexity | ❌ Overkill for internal dashboard |
| **Blazor Server** | Real-time, .NET native | Requires persistent connection | ✅ **SELECTED** |

---

## 🏗️ Project Structure

```
Fabrikam-Project/
├── FabrikamDashboard/              # NEW PROJECT
│   ├── FabrikamDashboard.csproj
│   ├── Program.cs
│   ├── Components/
│   │   ├── Pages/
│   │   │   ├── Index.razor         # Main dashboard page
│   │   │   ├── Orders.razor        # Orders view
│   │   │   ├── Tickets.razor       # Support tickets view
│   │   │   └── Simulator.razor     # Simulator controls
│   │   ├── Layout/
│   │   │   └── MainLayout.razor
│   │   └── Shared/
│   │       ├── MetricCard.razor    # Reusable metric display
│   │       ├── OrderChart.razor    # Chart component
│   │       └── SimulatorToggle.razor
│   ├── Services/
│   │   ├── FabrikamApiClient.cs    # Generated from OpenAPI
│   │   ├── SimulatorClient.cs      # Generated from OpenAPI
│   │   └── DashboardHub.cs         # SignalR hub for real-time updates
│   ├── BackgroundServices/
│   │   └── DataPollingService.cs   # Polls APIs every 5s, broadcasts via SignalR
│   ├── wwwroot/
│   │   ├── css/
│   │   │   └── dashboard.css       # Custom styles
│   │   └── js/
│   │       └── charts.min.js       # Chart.js for visualizations
│   └── appsettings.json
├── FabrikamApi/                     # Existing
├── FabrikamSimulator/               # Existing
└── FabrikamContracts/               # Shared DTOs
```

---

## 🚀 Step-by-Step Implementation

### **Step 1: Create the Blazor Server Project**

```powershell
# From repository root
dotnet new blazor -o FabrikamDashboard --name FabrikamDashboard --framework net9.0 --interactivity Server
cd FabrikamDashboard
dotnet add reference ../FabrikamContracts/FabrikamContracts.csproj
```

### **Step 2: Add Required NuGet Packages**

```powershell
dotnet add package Microsoft.Extensions.Http
dotnet add package Microsoft.AspNetCore.SignalR.Client
dotnet add package NSwag.MSBuild  # For OpenAPI client generation
```

### **Step 3: Configure OpenAPI Client Generation**

Add to `FabrikamDashboard.csproj`:

```xml
<ItemGroup>
  <!-- Auto-generate API clients from Swagger -->
  <OpenApiReference Include="../FabrikamApi/openapi.json" 
                     CodeGenerator="NSwagCSharp" 
                     Namespace="FabrikamDashboard.Clients.Api" />
  <OpenApiReference Include="../FabrikamSimulator/openapi.json" 
                     CodeGenerator="NSwagCSharp" 
                     Namespace="FabrikamDashboard.Clients.Simulator" />
</ItemGroup>
```

### **Step 4: Configure Services (Program.cs)**

```csharp
using FabrikamDashboard.Services;
using FabrikamDashboard.BackgroundServices;

var builder = WebApplication.CreateBuilder(args);

// Add Blazor services
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Add SignalR for real-time updates
builder.Services.AddSignalR();

// Add HTTP clients for APIs
builder.Services.AddHttpClient("FabrikamApi", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["FabrikamApi:BaseUrl"] 
        ?? "https://localhost:7297");
});

builder.Services.AddHttpClient("FabrikamSimulator", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["FabrikamSimulator:BaseUrl"] 
        ?? "https://localhost:5000");
});

// Register API clients (auto-generated from OpenAPI)
builder.Services.AddScoped<IFabrikamApiClient>(sp =>
{
    var httpClient = sp.GetRequiredService<IHttpClientFactory>()
        .CreateClient("FabrikamApi");
    return new FabrikamApiClient(httpClient);
});

builder.Services.AddScoped<ISimulatorClient>(sp =>
{
    var httpClient = sp.GetRequiredService<IHttpClientFactory>()
        .CreateClient("FabrikamSimulator");
    return new SimulatorClient(httpClient);
});

// Add background service for polling and broadcasting
builder.Services.AddHostedService<DataPollingService>();

// Add CORS for development
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseAntiforgery();
app.UseCors();

// Map Blazor components
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Map SignalR hub
app.MapHub<DashboardHub>("/dashboardHub");

app.Run();
```

### **Step 5: Create Data Polling Background Service**

`BackgroundServices/DataPollingService.cs`:

```csharp
using Microsoft.AspNetCore.SignalR;
using FabrikamDashboard.Clients.Api;
using FabrikamDashboard.Clients.Simulator;

namespace FabrikamDashboard.BackgroundServices;

public class DataPollingService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IHubContext<DashboardHub> _hubContext;
    private readonly ILogger<DataPollingService> _logger;
    private readonly TimeSpan _pollingInterval = TimeSpan.FromSeconds(5);

    public DataPollingService(
        IServiceProvider serviceProvider,
        IHubContext<DashboardHub> hubContext,
        ILogger<DataPollingService> logger)
    {
        _serviceProvider = serviceProvider;
        _hubContext = hubContext;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Data polling service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var apiClient = scope.ServiceProvider.GetRequiredService<IFabrikamApiClient>();
                var simulatorClient = scope.ServiceProvider.GetRequiredService<ISimulatorClient>();

                // Fetch data from APIs
                var orders = await apiClient.GetOrdersAsync();
                var tickets = await apiClient.GetSupportTicketsAsync();
                var analytics = await apiClient.GetOrderAnalyticsAsync();
                var simulatorStatus = await simulatorClient.GetStatusAsync();

                // Broadcast to all connected clients via SignalR
                await _hubContext.Clients.All.SendAsync("UpdateOrders", orders, stoppingToken);
                await _hubContext.Clients.All.SendAsync("UpdateTickets", tickets, stoppingToken);
                await _hubContext.Clients.All.SendAsync("UpdateAnalytics", analytics, stoppingToken);
                await _hubContext.Clients.All.SendAsync("UpdateSimulatorStatus", simulatorStatus, stoppingToken);

                _logger.LogDebug("Broadcasted dashboard updates to all clients");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error polling APIs for dashboard updates");
            }

            await Task.Delay(_pollingInterval, stoppingToken);
        }

        _logger.LogInformation("Data polling service stopped");
    }
}
```

### **Step 6: Create SignalR Hub**

`Services/DashboardHub.cs`:

```csharp
using Microsoft.AspNetCore.SignalR;

namespace FabrikamDashboard.Services;

public class DashboardHub : Hub
{
    public async Task RequestRefresh()
    {
        // Client can request immediate refresh
        await Clients.All.SendAsync("RefreshRequested");
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
        // Optionally send initial data to new client
    }
}
```

### **Step 7: Create Main Dashboard Page**

`Components/Pages/Index.razor`:

```razor
@page "/"
@using FabrikamContracts.DTOs
@inject NavigationManager Navigation
@inject IJSRuntime JS
@implements IAsyncDisposable

<PageTitle>Fabrikam Dashboard</PageTitle>

<div class="dashboard-container">
    <h1 class="dashboard-title">
        🏭 Fabrikam Modular Homes - Live Dashboard
    </h1>

    <!-- Metric Cards -->
    <div class="metrics-grid">
        <MetricCard Title="Active Orders" 
                    Value="@_totalOrders" 
                    Icon="📦" 
                    Color="blue" />
        <MetricCard Title="Open Tickets" 
                    Value="@_openTickets" 
                    Icon="🎫" 
                    Color="orange" />
        <MetricCard Title="Revenue (MTD)" 
                    Value="@($"${_revenue:N0}")" 
                    Icon="💰" 
                    Color="green" />
        <MetricCard Title="Avg Order Value" 
                    Value="@($"${_avgOrderValue:N0}")" 
                    Icon="📊" 
                    Color="purple" />
    </div>

    <!-- Charts Row -->
    <div class="charts-row">
        <div class="chart-card">
            <h3>Orders by Status</h3>
            <canvas id="ordersChart"></canvas>
        </div>
        <div class="chart-card">
            <h3>Orders by Region</h3>
            <canvas id="regionsChart"></canvas>
        </div>
    </div>

    <!-- Simulator Controls -->
    <div class="simulator-section">
        <h2>🎲 Simulator Controls</h2>
        <div class="simulator-controls">
            <SimulatorToggle Name="Order Progression" 
                             Enabled="@_simulatorStatus?.OrderProgression?.Enabled ?? false"
                             OnToggle="@(() => ToggleSimulator("orders/progression"))" />
            <SimulatorToggle Name="Order Generator" 
                             Enabled="@_simulatorStatus?.OrderGenerator?.Enabled ?? false"
                             OnToggle="@(() => ToggleSimulator("orders/generator"))" />
            <SimulatorToggle Name="Ticket Generator" 
                             Enabled="@_simulatorStatus?.TicketGenerator?.Enabled ?? false"
                             OnToggle="@(() => ToggleSimulator("tickets"))" />
        </div>
    </div>

    <!-- Recent Orders Table -->
    <div class="recent-orders">
        <h3>Recent Orders</h3>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Order #</th>
                    <th>Customer</th>
                    <th>Status</th>
                    <th>Total</th>
                    <th>Date</th>
                </tr>
            </thead>
            <tbody>
                @foreach (var order in _recentOrders)
                {
                    <tr>
                        <td>@order.OrderNumber</td>
                        <td>@order.CustomerName</td>
                        <td><span class="status-badge status-@order.Status.ToLower()">@order.Status</span></td>
                        <td>$@order.TotalAmount.ToString("N2")</td>
                        <td>@order.OrderDate.ToString("MMM dd, yyyy")</td>
                    </tr>
                }
            </tbody>
        </table>
    </div>
</div>

@code {
    private HubConnection? _hubConnection;
    private int _totalOrders;
    private int _openTickets;
    private decimal _revenue;
    private decimal _avgOrderValue;
    private List<OrderDto> _recentOrders = new();
    private SimulatorStatusDto? _simulatorStatus;

    protected override async Task OnInitializedAsync()
    {
        // Connect to SignalR hub
        _hubConnection = new HubConnectionBuilder()
            .WithUrl(Navigation.ToAbsoluteUri("/dashboardHub"))
            .WithAutomaticReconnect()
            .Build();

        // Subscribe to real-time updates
        _hubConnection.On<List<OrderDto>>("UpdateOrders", orders =>
        {
            _totalOrders = orders.Count;
            _recentOrders = orders.OrderByDescending(o => o.OrderDate).Take(10).ToList();
            _revenue = orders.Sum(o => o.TotalAmount);
            _avgOrderValue = _totalOrders > 0 ? _revenue / _totalOrders : 0;
            StateHasChanged();
            UpdateCharts();
        });

        _hubConnection.On<List<SupportTicketDto>>("UpdateTickets", tickets =>
        {
            _openTickets = tickets.Count(t => t.Status == "Open" || t.Status == "InProgress");
            StateHasChanged();
        });

        _hubConnection.On<SimulatorStatusDto>("UpdateSimulatorStatus", status =>
        {
            _simulatorStatus = status;
            StateHasChanged();
        });

        await _hubConnection.StartAsync();
    }

    private async Task ToggleSimulator(string endpoint)
    {
        var action = _simulatorStatus?.GetEnabled(endpoint) == true ? "stop" : "start";
        // Call simulator API
        // await SimulatorClient.ToggleAsync(endpoint, action);
    }

    private async Task UpdateCharts()
    {
        // Call JavaScript to update Chart.js charts
        await JS.InvokeVoidAsync("updateCharts", _recentOrders);
    }

    public async ValueTask DisposeAsync()
    {
        if (_hubConnection is not null)
        {
            await _hubConnection.DisposeAsync();
        }
    }
}
```

### **Step 8: Create Reusable Components**

`Components/Shared/MetricCard.razor`:

```razor
<div class="metric-card metric-@Color">
    <div class="metric-icon">@Icon</div>
    <div class="metric-content">
        <div class="metric-value">@Value</div>
        <div class="metric-title">@Title</div>
    </div>
</div>

@code {
    [Parameter] public string Title { get; set; } = "";
    [Parameter] public string Value { get; set; } = "";
    [Parameter] public string Icon { get; set; } = "";
    [Parameter] public string Color { get; set; } = "blue";
}
```

`Components/Shared/SimulatorToggle.razor`:

```razor
<div class="simulator-toggle">
    <div class="toggle-info">
        <span class="toggle-name">@Name</span>
        <span class="toggle-status status-@(Enabled ? "on" : "off")">
            @(Enabled ? "🟢 ON" : "🔴 OFF")
        </span>
    </div>
    <button class="toggle-button" @onclick="HandleToggle">
        @(Enabled ? "Stop" : "Start")
    </button>
</div>

@code {
    [Parameter] public string Name { get; set; } = "";
    [Parameter] public bool Enabled { get; set; }
    [Parameter] public EventCallback OnToggle { get; set; }

    private async Task HandleToggle()
    {
        await OnToggle.InvokeAsync();
    }
}
```

### **Step 9: Add Styling**

`wwwroot/css/dashboard.css`:

```css
.dashboard-container {
    padding: 2rem;
    max-width: 1400px;
    margin: 0 auto;
}

.dashboard-title {
    font-size: 2rem;
    margin-bottom: 2rem;
    color: #2c3e50;
}

.metrics-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
}

.metric-card {
    background: white;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    display: flex;
    align-items: center;
    gap: 1rem;
}

.metric-icon {
    font-size: 3rem;
}

.metric-value {
    font-size: 2rem;
    font-weight: bold;
    color: #2c3e50;
}

.metric-title {
    font-size: 0.9rem;
    color: #7f8c8d;
}

.charts-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
}

.chart-card {
    background: white;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.simulator-section {
    background: white;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    margin-bottom: 2rem;
}

.simulator-controls {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1rem;
}

.simulator-toggle {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 8px;
}

.toggle-button {
    background: #3498db;
    color: white;
    border: none;
    padding: 0.5rem 1.5rem;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
}

.toggle-button:hover {
    background: #2980b9;
}

.status-badge {
    padding: 0.25rem 0.75rem;
    border-radius: 12px;
    font-size: 0.85rem;
    font-weight: 600;
}

.status-pending { background: #f39c12; color: white; }
.status-inproduction { background: #3498db; color: white; }
.status-shipped { background: #9b59b6; color: white; }
.status-delivered { background: #2ecc71; color: white; }

.status-on { color: #2ecc71; }
.status-off { color: #e74c3c; }

.data-table {
    width: 100%;
    border-collapse: collapse;
}

.data-table th,
.data-table td {
    padding: 0.75rem;
    text-align: left;
    border-bottom: 1px solid #ecf0f1;
}

.data-table th {
    background: #f8f9fa;
    font-weight: 600;
    color: #2c3e50;
}

.data-table tr:hover {
    background: #f8f9fa;
}
```

### **Step 10: Add to Solution**

```powershell
# Add to Fabrikam.sln
dotnet sln add FabrikamDashboard/FabrikamDashboard.csproj
```

### **Step 11: Update VS Code Tasks**

Add to `.vscode/tasks.json`:

```json
{
    "label": "📊 Start Dashboard",
    "type": "shell",
    "command": "dotnet",
    "args": [
        "run",
        "--project",
        "FabrikamDashboard/FabrikamDashboard.csproj"
    ],
    "group": "build",
    "isBackground": true
},
{
    "label": "🌐 Start All Services (API + MCP + Simulator + Dashboard)",
    "dependsOn": [
        "🚀 Start API Server",
        "🤖 Start MCP Server",
        "🎲 Start Simulator",
        "📊 Start Dashboard"
    ],
    "dependsOrder": "parallel"
}
```

---

## 📊 Chart Integration (Optional)

### Add Chart.js

In `wwwroot/index.html` or `_Host.cshtml`:

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="js/charts.js"></script>
```

`wwwroot/js/charts.js`:

```javascript
let ordersChart = null;
let regionsChart = null;

window.updateCharts = function(orders) {
    // Group by status
    const statusCounts = {};
    orders.forEach(order => {
        statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
    });

    // Update orders chart
    const ctx = document.getElementById('ordersChart');
    if (ordersChart) {
        ordersChart.destroy();
    }
    ordersChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: Object.keys(statusCounts),
            datasets: [{
                data: Object.values(statusCounts),
                backgroundColor: ['#f39c12', '#3498db', '#9b59b6', '#2ecc71']
            }]
        }
    });

    // Similar for regions chart...
};
```

---

## 🚀 Running the Dashboard

### Development

```powershell
# Terminal 1: API
dotnet run --project FabrikamApi/src/FabrikamApi.csproj

# Terminal 2: Simulator
dotnet run --project FabrikamSimulator/src/FabrikamSimulator.csproj

# Terminal 3: Dashboard
dotnet run --project FabrikamDashboard/FabrikamDashboard.csproj
```

**Access**: `https://localhost:5200` (or assigned port)

### Using VS Code Tasks

Press `Ctrl+Shift+P` → "Tasks: Run Task" → "🌐 Start All Services"

---

## 🎯 Features Delivered

✅ **Real-time updates** - 5-second refresh via SignalR  
✅ **Business metrics** - Orders, tickets, revenue, avg value  
✅ **Visual charts** - Order status and regional distribution  
✅ **Simulator controls** - Start/stop workers with one click  
✅ **Recent activity** - Latest orders and tickets  
✅ **Clean UI** - Professional dashboard for workshops  

---

## 🔄 Alternative: Simple HTML + JavaScript

If you want **even simpler** (no Blazor), you can create a static HTML page:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Fabrikam Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Fabrikam Dashboard</h1>
    <div id="metrics"></div>
    <canvas id="chart"></canvas>
    <div id="simulator-controls"></div>

    <script>
        // Fetch data every 5 seconds
        setInterval(async () => {
            const orders = await fetch('https://localhost:7297/api/orders').then(r => r.json());
            const status = await fetch('https://localhost:5000/api/simulator/status').then(r => r.json());
            updateDashboard(orders, status);
        }, 5000);

        function updateDashboard(orders, status) {
            // Update UI
        }
    </script>
</body>
</html>
```

**But**: Blazor Server is **better** because:
- Type-safe API clients
- Component reusability
- SignalR efficiency
- Integrated with your .NET solution

---

## 📝 Next Steps

1. ✅ Review this guide
2. 🔲 Create FabrikamDashboard project
3. 🔲 Build basic layout with metric cards
4. 🔲 Add SignalR real-time updates
5. 🔲 Integrate simulator controls
6. 🔲 Add charts (Chart.js)
7. 🔲 Test with workshop scenarios
8. 🔲 Deploy alongside other services

**Estimated time**: 2-3 hours for full implementation

---

**Ready to make your workshop participants see Fabrikam come alive! 🚀**
