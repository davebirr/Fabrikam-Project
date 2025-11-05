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
}
