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
        Console.WriteLine($"🔍 FabrikamApiClient - Auth Mode: {authMode}");
        
        if (authMode.Equals("Disabled", StringComparison.OrdinalIgnoreCase))
        {
            // Use user's GUID if provided, otherwise use dashboard service GUID
            var rawGuid = userGuid ?? _configuration["Dashboard:ServiceGuid"] ?? "dashboard-00000000-0000-0000-0000-000000000001";
            
            // Strip "dashboard-" prefix if present to get valid GUID format
            var guid = rawGuid.StartsWith("dashboard-", StringComparison.OrdinalIgnoreCase) 
                ? rawGuid.Substring(10)  // Remove "dashboard-" (10 characters)
                : rawGuid;
            
            request.Headers.Add("X-Tracking-Guid", guid);
            Console.WriteLine($"✅ Added X-Tracking-Guid header: {guid} (raw: {rawGuid}) for {requestUri}");
            _logger.LogInformation("Adding X-Tracking-Guid header: {Guid} for {Uri}", guid, requestUri);
        }
        else
        {
            Console.WriteLine($"⚠️ NOT adding X-Tracking-Guid - auth mode is: {authMode}");
        }
        
        return request;
    }

    /// <summary>
    /// Get all orders from the API
    /// </summary>
    public async Task<List<OrderDto>> GetOrdersAsync(DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
    {
        try
        {
            // pageSize=0 means "get all records" (API supports unlimited)
            var queryParams = new List<string> { "pageSize=0" };
            
            if (fromDate.HasValue)
            {
                queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
            }
            
            if (toDate.HasValue)
            {
                queryParams.Add($"toDate={toDate.Value:yyyy-MM-dd}");
            }
            
            var queryString = string.Join("&", queryParams);
            using var request = CreateRequestWithGuid(HttpMethod.Get, $"/api/orders?{queryString}");
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (response.IsSuccessStatusCode)
            {
                var orders = await response.Content.ReadFromJsonAsync<List<OrderDto>>(cancellationToken) 
                    ?? new List<OrderDto>();
                Console.WriteLine($"✅ Successfully fetched {orders.Count} orders");
                return orders;
            }

            var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
            Console.WriteLine($"❌ Failed to get orders: {response.StatusCode} - {errorContent}");
            _logger.LogWarning("Failed to get orders: {StatusCode} - {Error}", response.StatusCode, errorContent);
            return new List<OrderDto>();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"💥 Exception fetching orders: {ex.Message}");
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
    public async Task<List<SupportTicketListItemDto>> GetSupportTicketsAsync(DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
    {
        try
        {
            // pageSize=0 means "get all records" (API supports unlimited)
            var queryParams = new List<string> { "pageSize=0" };
            
            if (fromDate.HasValue)
            {
                queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
            }
            
            if (toDate.HasValue)
            {
                queryParams.Add($"toDate={toDate.Value:yyyy-MM-dd}");
            }
            
            var queryString = string.Join("&", queryParams);
            using var request = CreateRequestWithGuid(HttpMethod.Get, $"/api/supporttickets?{queryString}");
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
