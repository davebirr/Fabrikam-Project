using Microsoft.AspNetCore.SignalR;
using FabrikamDashboard.Services;
using FabrikamDashboard.Models;
using FabrikamContracts.DTOs.Orders;
using FabrikamContracts.DTOs.Support;

namespace FabrikamDashboard.BackgroundServices;

/// <summary>
/// Background service that polls FabrikamApi and FabrikamSimulator every few seconds
/// and updates the dashboard state for all connected clients
/// </summary>
public class DataPollingService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IHubContext<DashboardHub> _hubContext;
    private readonly DashboardStateService _stateService;
    private readonly ILogger<DataPollingService> _logger;
    private readonly TimeSpan _pollingInterval = TimeSpan.FromSeconds(5);
    private readonly SemaphoreSlim _refreshTrigger = new(0);
    private CancellationTokenSource? _pollingCts;

    public DataPollingService(
        IServiceProvider serviceProvider,
        IHubContext<DashboardHub> hubContext,
        DashboardStateService stateService,
        ILogger<DataPollingService> logger)
    {
        _serviceProvider = serviceProvider;
        _hubContext = hubContext;
        _stateService = stateService;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Dashboard data polling service started (interval: {Interval}s)", _pollingInterval.TotalSeconds);
        _pollingCts = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);

        // Listen for refresh requests from the hub
        _ = Task.Run(async () =>
        {
            using var scope = _serviceProvider.CreateScope();
            var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<DashboardHub>>();
            
            // Subscribe to refresh requests
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(100, stoppingToken); // Check frequently
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }
        }, stoppingToken);

        // Wait a bit before starting to allow services to initialize
        await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);

        // Immediate first poll for new connections
        try
        {
            await PollAndBroadcastAsync(stoppingToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in initial data poll");
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // Wait for either the interval or a manual refresh trigger
                var delayTask = Task.Delay(_pollingInterval, stoppingToken);
                var triggerTask = _refreshTrigger.WaitAsync(stoppingToken);
                
                await Task.WhenAny(delayTask, triggerTask);
                
                // If triggered manually, consume the signal
                if (triggerTask.IsCompleted)
                {
                    _logger.LogInformation("Manual refresh triggered");
                }
                
                await PollAndBroadcastAsync(stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in data polling cycle");
            }
        }

        _logger.LogInformation("Dashboard data polling service stopped");
    }

    /// <summary>
    /// Trigger an immediate data refresh (called via SignalR)
    /// </summary>
    public void TriggerRefresh()
    {
        _refreshTrigger.Release();
    }

    private async Task PollAndBroadcastAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var apiClient = scope.ServiceProvider.GetRequiredService<FabrikamApiClient>();
        var simulatorClient = scope.ServiceProvider.GetRequiredService<SimulatorClient>();

        // Fetch data from APIs in parallel
        var ordersTask = apiClient.GetOrdersAsync(cancellationToken);
        var ticketsTask = apiClient.GetSupportTicketsAsync(cancellationToken);
        var analyticsTask = apiClient.GetOrderAnalyticsAsync(cancellationToken);
        var simulatorStatusTask = simulatorClient.GetStatusAsync(cancellationToken);

        await Task.WhenAll(ordersTask, ticketsTask, analyticsTask, simulatorStatusTask);

        var orders = ordersTask.Result;
        var tickets = ticketsTask.Result;
        var analytics = analyticsTask.Result;
        var simulatorStatus = simulatorStatusTask.Result;

        // Calculate dashboard metrics
        var dashboardData = CalculateDashboardMetrics(orders, tickets, analytics, simulatorStatus);

        // Update state service (triggers component updates)
        _stateService.UpdateData(dashboardData);

        // Also broadcast via SignalR for any external clients
        await _hubContext.Clients.All.SendAsync("DashboardUpdate", dashboardData, cancellationToken);

        _logger.LogInformation("📡 Updated dashboard state: {Orders} orders, {Tickets} tickets, ${Revenue:N0} revenue",
            dashboardData.TotalOrders, dashboardData.OpenTickets, dashboardData.TotalRevenue);
    }

    private DashboardDataDto CalculateDashboardMetrics(
        List<OrderDto> orders,
        List<SupportTicketListItemDto> tickets,
        SalesAnalyticsDto? analytics,
        SimulatorStatusDto? simulatorStatus)
    {
        var data = new DashboardDataDto
        {
            Timestamp = DateTime.UtcNow,
            TotalOrders = orders.Count,
            OpenTickets = tickets.Count(t => t.Status == "Open" || t.Status == "InProgress"),
            TotalRevenue = orders.Sum(o => o.Total),
            SimulatorStatus = simulatorStatus
        };

        // Calculate average order value
        data.AverageOrderValue = data.TotalOrders > 0 ? data.TotalRevenue / data.TotalOrders : 0;

        // Group orders by status
        data.OrdersByStatus = orders
            .GroupBy(o => o.Status)
            .ToDictionary(g => g.Key, g => g.Count());

        // Group orders by customer region
        data.OrdersByRegion = orders
            .Where(o => o.Customer?.Region != null)
            .GroupBy(o => o.Customer.Region!)
            .ToDictionary(g => g.Key, g => g.Count());

        return data;
    }
}
