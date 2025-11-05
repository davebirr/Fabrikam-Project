using Microsoft.AspNetCore.SignalR;
using FabrikamDashboard.Services;
using FabrikamDashboard.Models;
using FabrikamContracts.DTOs.Orders;
using FabrikamContracts.DTOs.Support;

namespace FabrikamDashboard.BackgroundServices;

/// <summary>
/// Background service that polls FabrikamApi and FabrikamSimulator every few seconds
/// and broadcasts updates to all connected clients via SignalR
/// </summary>
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
        _logger.LogInformation("Dashboard data polling service started (interval: {Interval}s)", _pollingInterval.TotalSeconds);

        // Wait a bit before starting to allow services to initialize
        await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await PollAndBroadcastAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in data polling cycle");
            }

            await Task.Delay(_pollingInterval, stoppingToken);
        }

        _logger.LogInformation("Dashboard data polling service stopped");
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

        // Broadcast to all connected clients
        await _hubContext.Clients.All.SendAsync("DashboardUpdate", dashboardData, cancellationToken);

        _logger.LogDebug("Broadcasted dashboard update: {Orders} orders, {Tickets} tickets, ${Revenue:N0} revenue",
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
