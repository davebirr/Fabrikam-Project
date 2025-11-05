using System.Net.Http.Json;
using FabrikamContracts.DTOs.Orders;
using FabrikamContracts.DTOs.Support;
using FabrikamContracts.DTOs.Customers;

namespace FabrikamDashboard.Services;

/// <summary>
/// HTTP client for communicating with FabrikamApi
/// </summary>
public class FabrikamApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<FabrikamApiClient> _logger;
    private readonly IConfiguration _configuration;

    public FabrikamApiClient(HttpClient httpClient, ILogger<FabrikamApiClient> logger, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Add X-Tracking-Guid header for Disabled authentication mode
    /// </summary>
    private HttpRequestMessage CreateRequestWithGuid(HttpMethod method, string requestUri, string? userGuid = null)
    {
        var request = new HttpRequestMessage(method, requestUri);
        
        // In Disabled mode, use X-Tracking-Guid header
        var authMode = _configuration.GetValue<string>("Authentication:Mode", "Disabled");
        if (authMode.Equals("Disabled", StringComparison.OrdinalIgnoreCase))
        {
            // Use user's GUID if provided, otherwise use dashboard service GUID
            var guid = userGuid ?? _configuration["Dashboard:ServiceGuid"] ?? "dashboard-00000000-0000-0000-0000-000000000001";
            request.Headers.Add("X-Tracking-Guid", guid);
            _logger.LogDebug("Adding X-Tracking-Guid header: {Guid}", guid);
        }
        
        return request;
    }

    /// <summary>
    /// Get all orders from the API
    /// </summary>
    public async Task<List<OrderDto>> GetOrdersAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using var request = CreateRequestWithGuid(HttpMethod.Get, "/api/orders");
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<List<OrderDto>>(cancellationToken) 
                    ?? new List<OrderDto>();
            }

            _logger.LogWarning("Failed to get orders: {StatusCode}", response.StatusCode);
            return new List<OrderDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching orders from API");
            return new List<OrderDto>();
        }
    }

    /// <summary>
    /// Get order analytics/statistics
    /// </summary>
    public async Task<SalesAnalyticsDto?> GetOrderAnalyticsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using var request = CreateRequestWithGuid(HttpMethod.Get, "/api/orders/analytics");
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<SalesAnalyticsDto>(cancellationToken);
            }

            _logger.LogWarning("Failed to get order analytics: {StatusCode}", response.StatusCode);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching order analytics from API");
            return null;
        }
    }

    /// <summary>
    /// Get all support tickets
    /// </summary>
    public async Task<List<SupportTicketListItemDto>> GetSupportTicketsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using var request = CreateRequestWithGuid(HttpMethod.Get, "/api/supporttickets");
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<List<SupportTicketListItemDto>>(cancellationToken) 
                    ?? new List<SupportTicketListItemDto>();
            }

            _logger.LogWarning("Failed to get support tickets: {StatusCode}", response.StatusCode);
            return new List<SupportTicketListItemDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching support tickets from API");
            return new List<SupportTicketListItemDto>();
        }
    }

    /// <summary>
    /// Get all customers
    /// </summary>
    public async Task<List<CustomerListItemDto>> GetCustomersAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using var request = CreateRequestWithGuid(HttpMethod.Get, "/api/customers");
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                return await response.Content.ReadFromJsonAsync<List<CustomerListItemDto>>(cancellationToken) 
                    ?? new List<CustomerListItemDto>();
            }

            _logger.LogWarning("Failed to get customers: {StatusCode}", response.StatusCode);
            return new List<CustomerListItemDto>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching customers from API");
            return new List<CustomerListItemDto>();
        }
    }
}
