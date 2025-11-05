using Microsoft.AspNetCore.SignalR;
using FabrikamDashboard.Models;
using FabrikamDashboard.BackgroundServices;

namespace FabrikamDashboard.Services;

/// <summary>
/// SignalR hub for broadcasting real-time dashboard updates to all connected clients
/// </summary>
public class DashboardHub : Hub
{
    private readonly ILogger<DashboardHub> _logger;
    private readonly DataPollingService _pollingService;

    public DashboardHub(ILogger<DashboardHub> logger, IServiceProvider serviceProvider)
    {
        _logger = logger;
        // Get the DataPollingService from hosted services
        _pollingService = serviceProvider.GetServices<IHostedService>()
            .OfType<DataPollingService>()
            .FirstOrDefault() ?? throw new InvalidOperationException("DataPollingService not found");
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
        
        // Trigger immediate refresh for new clients
        _pollingService.TriggerRefresh();
        
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Client disconnected: {ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Client can request an immediate data refresh
    /// </summary>
    public async Task RequestRefresh()
    {
        _logger.LogInformation("Client {ConnectionId} requested manual refresh", Context.ConnectionId);
        _pollingService.TriggerRefresh();
        await Task.CompletedTask;
    }
}
