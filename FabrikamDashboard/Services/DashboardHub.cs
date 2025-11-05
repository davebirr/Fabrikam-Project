using Microsoft.AspNetCore.SignalR;
using FabrikamDashboard.Models;

namespace FabrikamDashboard.Services;

/// <summary>
/// SignalR hub for broadcasting real-time dashboard updates to all connected clients
/// </summary>
public class DashboardHub : Hub
{
    private readonly ILogger<DashboardHub> _logger;

    public DashboardHub(ILogger<DashboardHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
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
        _logger.LogDebug("Client {ConnectionId} requested refresh", Context.ConnectionId);
        await Clients.All.SendAsync("RefreshRequested");
    }
}
