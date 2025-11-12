using System.Net.Http.Json;
using FabrikamContracts.DTOs.Orders;
using FabrikamContracts.DTOs.Support;
using FabrikamContracts.DTOs.Customers;
using FabrikamContracts.DTOs.Invoices;

namespace FabrikamDashboard.Services;

/// <summary>
/// HTTP client for communicating with FabrikamApi
/// </summary>
public class FabrikamApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<FabrikamApiClient> _logger;
    private readonly IConfiguration _configuration;
    private const int MaxPageSize = 100; // Maximum allowed by API validation

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
    /// Get all orders from the API with automatic pagination
    /// </summary>
    public async Task<List<OrderDto>> GetOrdersAsync(DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var allOrders = new List<OrderDto>();
            var page = 1;
            var totalCount = 0;
            var pageSize = MaxPageSize; // Use maximum page size (100) for efficiency
            
            do
            {
                // Build query parameters
                var queryParams = new List<string> 
                { 
                    $"page={page}",
                    $"pageSize={pageSize}"
                };
                
                if (fromDate.HasValue)
                {
                    queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
                }
                
                // Don't send toDate - we want all data up to "now" without truncating current day
                // (sending toDate=2025-11-12 excludes orders created later that same day)
                
                var queryString = string.Join("&", queryParams);
                using var request = CreateRequestWithGuid(HttpMethod.Get, $"/api/orders?{queryString}");
                var response = await _httpClient.SendAsync(request, cancellationToken);
                
                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
                    Console.WriteLine($"❌ Failed to get orders (page {page}): {response.StatusCode} - {errorContent}");
                    _logger.LogWarning("Failed to get orders (page {Page}): {StatusCode} - {Error}", page, response.StatusCode, errorContent);
                    break;
                }
                
                // Parse X-Total-Count header to know how many total records exist
                if (response.Headers.TryGetValues("X-Total-Count", out var totalCountValues))
                {
                    totalCount = int.Parse(totalCountValues.First());
                }
                
                var pageOrders = await response.Content.ReadFromJsonAsync<List<OrderDto>>(cancellationToken) 
                    ?? new List<OrderDto>();
                
                allOrders.AddRange(pageOrders);
                Console.WriteLine($"📄 Fetched page {page}: {pageOrders.Count} orders (total so far: {allOrders.Count}/{totalCount})");
                
                // If we got less than pageSize, we're done
                if (pageOrders.Count < pageSize)
                {
                    break;
                }
                
                page++;
                
            } while (allOrders.Count < totalCount);
            
            Console.WriteLine($"✅ Successfully fetched all {allOrders.Count} orders across {page} page(s)");
            return allOrders;
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
    /// Get all support tickets with automatic pagination
    /// </summary>
    public async Task<List<SupportTicketListItemDto>> GetSupportTicketsAsync(DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var allTickets = new List<SupportTicketListItemDto>();
            var page = 1;
            var totalCount = 0;
            var pageSize = MaxPageSize;
            
            do
            {
                var queryParams = new List<string> 
                { 
                    $"page={page}",
                    $"pageSize={pageSize}"
                };
                
                if (fromDate.HasValue)
                {
                    queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
                }
                
                var queryString = string.Join("&", queryParams);
                using var request = CreateRequestWithGuid(HttpMethod.Get, $"/api/supporttickets?{queryString}");
                var response = await _httpClient.SendAsync(request, cancellationToken);
                
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Failed to get support tickets (page {Page}): {StatusCode}", page, response.StatusCode);
                    break;
                }
                
                if (response.Headers.TryGetValues("X-Total-Count", out var totalCountValues))
                {
                    totalCount = int.Parse(totalCountValues.First());
                }
                
                var pageTickets = await response.Content.ReadFromJsonAsync<List<SupportTicketListItemDto>>(cancellationToken) 
                    ?? new List<SupportTicketListItemDto>();
                
                allTickets.AddRange(pageTickets);
                
                if (pageTickets.Count < pageSize)
                {
                    break;
                }
                
                page++;
                
            } while (allTickets.Count < totalCount);
            
            Console.WriteLine($"✅ Successfully fetched all {allTickets.Count} support tickets across {page} page(s)");
            return allTickets;
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

    /// <summary>
    /// Get all invoices from the API with automatic pagination
    /// </summary>
    public async Task<List<InvoiceDto>> GetInvoicesAsync(
        string? status = null,
        string? vendor = null,
        DateTime? fromDate = null, 
        DateTime? toDate = null, 
        CancellationToken cancellationToken = default)
    {
        try
        {
            var allInvoices = new List<InvoiceDto>();
            var page = 1;
            var totalCount = 0;
            var pageSize = MaxPageSize;
            
            do
            {
                var queryParams = new List<string> 
                { 
                    $"page={page}",
                    $"pageSize={pageSize}"
                };
                
                if (!string.IsNullOrEmpty(status))
                {
                    queryParams.Add($"status={Uri.EscapeDataString(status)}");
                }
                
                if (!string.IsNullOrEmpty(vendor))
                {
                    queryParams.Add($"vendor={Uri.EscapeDataString(vendor)}");
                }
                
                if (fromDate.HasValue)
                {
                    queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
                }
                
                if (toDate.HasValue)
                {
                    queryParams.Add($"toDate={toDate.Value:yyyy-MM-dd}");
                }
                
                var queryString = string.Join("&", queryParams);
                using var request = CreateRequestWithGuid(HttpMethod.Get, $"/api/invoices?{queryString}");
                var response = await _httpClient.SendAsync(request, cancellationToken);
                
                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
                    Console.WriteLine($"❌ Failed to get invoices (page {page}): {response.StatusCode} - {errorContent}");
                    _logger.LogWarning("Failed to get invoices (page {Page}): {StatusCode} - {Error}", page, response.StatusCode, errorContent);
                    break;
                }
                
                if (response.Headers.TryGetValues("X-Total-Count", out var totalCountValues))
                {
                    totalCount = int.Parse(totalCountValues.First());
                }
                
                var pageInvoices = await response.Content.ReadFromJsonAsync<List<InvoiceDto>>(cancellationToken) 
                    ?? new List<InvoiceDto>();
                
                allInvoices.AddRange(pageInvoices);
                Console.WriteLine($"📄 Fetched page {page}: {pageInvoices.Count} invoices (total so far: {allInvoices.Count}/{totalCount})");
                
                if (pageInvoices.Count < pageSize)
                {
                    break;
                }
                
                page++;
                
            } while (allInvoices.Count < totalCount);
            
            Console.WriteLine($"✅ Successfully fetched all {allInvoices.Count} invoices across {page} page(s)");
            return allInvoices;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"💥 Exception fetching invoices: {ex.Message}");
            _logger.LogError(ex, "Error fetching invoices from API");
            return new List<InvoiceDto>();
        }
    }
}
