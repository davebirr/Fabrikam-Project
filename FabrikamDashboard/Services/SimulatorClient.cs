using System.Net.Http.Json;
using FabrikamDashboard.Models;

namespace FabrikamDashboard.Services;

/// <summary>
/// HTTP client for communicating with FabrikamSimulator control API
/// </summary>
public class SimulatorClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<SimulatorClient> _logger;

    public SimulatorClient(HttpClient httpClient, ILogger<SimulatorClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    /// <summary>
    /// Get the current status of all simulator workers
    /// </summary>
    public async Task<SimulatorStatusDto?> GetStatusAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("/api/simulator/status", cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<SimulatorStatusDto>(cancellationToken);
            }

            _logger.LogWarning("Failed to get simulator status: {StatusCode}", response.StatusCode);
            return null;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Simulator service unavailable - this is expected if simulator is not running");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching simulator status");
            return null;
        }
    }

    /// <summary>
    /// Start or stop a simulator worker
    /// </summary>
    public async Task<bool> ToggleWorkerAsync(string workerEndpoint, bool enable, CancellationToken cancellationToken = default)
    {
        try
        {
            var action = enable ? "start" : "stop";
            var endpoint = $"/api/simulator/{workerEndpoint}/{action}";
            
            var response = await _httpClient.PostAsync(endpoint, null, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully {Action} worker {Worker}", action, workerEndpoint);
                return true;
            }

            _logger.LogWarning("Failed to {Action} worker {Worker}: {StatusCode}", action, workerEndpoint, response.StatusCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling worker {Worker}", workerEndpoint);
            return false;
        }
    }

    /// <summary>
    /// Update order generator configuration
    /// </summary>
    public async Task<bool> UpdateOrderConfigAsync(int intervalMinutes, int minOrders, int maxOrders, CancellationToken cancellationToken = default)
    {
        try
        {
            var config = new
            {
                intervalMinutes,
                minOrdersPerInterval = minOrders,
                maxOrdersPerInterval = maxOrders
            };

            var response = await _httpClient.PostAsJsonAsync("/api/simulator/config/orders", config, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully updated order configuration: {Interval}min, {Min}-{Max} orders", 
                    intervalMinutes, minOrders, maxOrders);
                return true;
            }

            var error = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning("Failed to update order configuration: {StatusCode} - {Error}", response.StatusCode, error);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order configuration");
            return false;
        }
    }

    /// <summary>
    /// Update ticket generator configuration
    /// </summary>
    public async Task<bool> UpdateTicketConfigAsync(int intervalMinutes, int minTickets, int maxTickets, CancellationToken cancellationToken = default)
    {
        try
        {
            var config = new
            {
                intervalMinutes,
                minTicketsPerInterval = minTickets,
                maxTicketsPerInterval = maxTickets
            };

            var response = await _httpClient.PostAsJsonAsync("/api/simulator/config/tickets", config, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully updated ticket configuration: {Interval}min, {Min}-{Max} tickets", 
                    intervalMinutes, minTickets, maxTickets);
                return true;
            }

            var error = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning("Failed to update ticket configuration: {StatusCode} - {Error}", response.StatusCode, error);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating ticket configuration");
            return false;
        }
    }

    /// <summary>
    /// Reset order generator configuration to defaults
    /// </summary>
    public async Task<bool> ResetOrderConfigAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync("/api/simulator/config/orders/reset", null, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully reset order configuration to defaults");
                return true;
            }

            _logger.LogWarning("Failed to reset order configuration: {StatusCode}", response.StatusCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resetting order configuration");
            return false;
        }
    }

    /// <summary>
    /// Reset ticket generator configuration to defaults
    /// </summary>
    public async Task<bool> ResetTicketConfigAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.PostAsync("/api/simulator/config/tickets/reset", null, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully reset ticket configuration to defaults");
                return true;
            }

            _logger.LogWarning("Failed to reset ticket configuration: {StatusCode}", response.StatusCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resetting ticket configuration");
            return false;
        }
    }
}
