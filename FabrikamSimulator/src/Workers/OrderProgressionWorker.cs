using FabrikamSimulator.Models;
using FabrikamSimulator.Services;
using System.Text.Json;

namespace FabrikamSimulator.Workers;

public class OrderProgressionWorker : BackgroundService
{
    private readonly ILogger<OrderProgressionWorker> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly WorkerStateService _stateService;
    private readonly ActivityLogService _activityLog;
    private const string WorkerName = "OrderProgression";

    public OrderProgressionWorker(
        ILogger<OrderProgressionWorker> logger,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        WorkerStateService stateService,
        ActivityLogService activityLog)
    {
        _logger = logger;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _stateService = stateService;
        _activityLog = activityLog;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("OrderProgressionWorker started");

        while (!stoppingToken.IsCancellationRequested)
        {
            var config = _configuration.GetSection("SimulatorSettings:OrderProgression").Get<OrderProgressionConfig>() ?? new();
            var status = _stateService.GetStatus(WorkerName);

            if (status.Enabled)
            {
                try
                {
                    _activityLog.LogActivity(WorkerName, "Started", $"Processing order progression (interval: {config.IntervalMinutes}min)");
                    await ProcessOrderProgression(config);
                    _stateService.UpdateLastRun(WorkerName, DateTime.UtcNow.AddMinutes(config.IntervalMinutes));
                    _logger.LogInformation("OrderProgressionWorker completed successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in OrderProgressionWorker");
                    _stateService.SetError(WorkerName, ex.Message);
                    _activityLog.LogActivity(WorkerName, "Error", ex.Message, isError: true);
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(config.IntervalMinutes), stoppingToken);
        }
    }

    private async Task ProcessOrderProgression(OrderProgressionConfig config)
    {
        var httpClient = _httpClientFactory.CreateClient("FabrikamApi");

        // Get all orders
        var ordersResponse = await httpClient.GetAsync("/api/orders?pageSize=100");
        if (!ordersResponse.IsSuccessStatusCode)
        {
            _logger.LogWarning("Failed to fetch orders: {StatusCode}", ordersResponse.StatusCode);
            return;
        }

        var ordersJson = await ordersResponse.Content.ReadAsStringAsync();
        var orders = JsonSerializer.Deserialize<List<OrderDto>>(ordersJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (orders == null || orders.Count == 0)
        {
            _logger.LogInformation("No orders to process");
            _activityLog.LogActivity(WorkerName, "Scan", "No orders found to process");
            return;
        }

        var random = new Random();
        var updatedCount = 0;
        var blockedCount = 0;
        
        _activityLog.LogActivity(WorkerName, "Scan", $"Scanning {orders.Count} orders for status updates");

        foreach (var order in orders)
        {
            // Check for open tickets if configured
            if (config.BlockProgressionWithOpenTickets && await HasOpenTickets(httpClient, order.Id))
            {
                blockedCount++;
                _activityLog.LogActivity(WorkerName, "Blocked", $"Order {order.OrderNumber}: Progression blocked due to open support tickets");
                continue; // Skip this order
            }

            var daysSinceOrder = (DateTime.UtcNow - order.OrderDate).Days;
            var shouldUpdate = false;
            string? newStatus = null;
            DateTime? newDate = null;

            switch (order.Status?.ToLower())
            {
                case "pending":
                    var pendingThreshold = config.PendingToProductionDays + random.Next(-config.RandomVariationDays, config.RandomVariationDays + 1);
                    if (daysSinceOrder >= pendingThreshold)
                    {
                        newStatus = "InProduction";
                        shouldUpdate = true;
                        _logger.LogInformation("Moving order {OrderNumber} from Pending to InProduction", order.OrderNumber);
                        _activityLog.LogActivity(WorkerName, "Update", $"Order {order.OrderNumber}: Pending → InProduction (age: {daysSinceOrder}d, threshold: {pendingThreshold}d)");
                    }
                    break;

                case "inproduction":
                    var productionThreshold = config.ProductionToShippedDays + random.Next(-config.RandomVariationDays, config.RandomVariationDays + 1);
                    if (daysSinceOrder >= productionThreshold)
                    {
                        newStatus = "Shipped";
                        newDate = DateTime.UtcNow;
                        shouldUpdate = true;
                        _logger.LogInformation("Moving order {OrderNumber} from InProduction to Shipped", order.OrderNumber);
                        _activityLog.LogActivity(WorkerName, "Update", $"Order {order.OrderNumber}: InProduction → Shipped (age: {daysSinceOrder}d, threshold: {productionThreshold}d)");
                    }
                    break;

                case "shipped":
                    var shippedDays = order.ShippedDate.HasValue ? (DateTime.UtcNow - order.ShippedDate.Value).Days : daysSinceOrder;
                    var shippedThreshold = config.ShippedToDeliveredDays + random.Next(-config.RandomVariationDays, config.RandomVariationDays + 1);
                    if (shippedDays >= shippedThreshold)
                    {
                        newStatus = "Delivered";
                        newDate = DateTime.UtcNow;
                        shouldUpdate = true;
                        _logger.LogInformation("Moving order {OrderNumber} from Shipped to Delivered", order.OrderNumber);
                        _activityLog.LogActivity(WorkerName, "Update", $"Order {order.OrderNumber}: Shipped → Delivered (shipped: {shippedDays}d ago, threshold: {shippedThreshold}d)");
                    }
                    break;
            }

            if (shouldUpdate && newStatus != null)
            {
                await UpdateOrderStatus(httpClient, order.Id, newStatus, newDate);
                updatedCount++;
            }
        }

        _logger.LogInformation("Processed {TotalOrders} orders, updated {UpdatedCount}", orders.Count, updatedCount);
        _activityLog.LogActivity(WorkerName, "Completed", $"Processed {orders.Count} orders, updated {updatedCount}, blocked {blockedCount}");
    }

    private async Task<bool> HasOpenTickets(HttpClient httpClient, int orderId)
    {
        try
        {
            var response = await httpClient.GetAsync($"/api/support-tickets?orderId={orderId}");
            if (!response.IsSuccessStatusCode)
            {
                return false; // If we can't check, don't block
            }

            var ticketsJson = await response.Content.ReadAsStringAsync();
            var tickets = JsonSerializer.Deserialize<List<TicketDto>>(ticketsJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (tickets == null || tickets.Count == 0)
            {
                return false; // No tickets
            }

            // Check if any tickets are open (not Resolved or Closed)
            // Status: Open=1, InProgress=2, PendingCustomer=3, Resolved=4, Closed=5, Cancelled=6
            var openTickets = tickets.Where(t => t.Status != null && 
                                                  !t.Status.Equals("Resolved", StringComparison.OrdinalIgnoreCase) && 
                                                  !t.Status.Equals("Closed", StringComparison.OrdinalIgnoreCase) &&
                                                  !t.Status.Equals("Cancelled", StringComparison.OrdinalIgnoreCase))
                                     .ToList();

            if (openTickets.Any())
            {
                _logger.LogDebug("Order {OrderId} has {Count} open tickets", orderId, openTickets.Count);
                return true;
            }

            return false;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error checking tickets for order {OrderId}, allowing progression", orderId);
            return false; // On error, don't block progression
        }
    }

    private async Task UpdateOrderStatus(HttpClient httpClient, int orderId, string status, DateTime? date)
    {
        try
        {
            var updateData = new { status, shippedDate = date, deliveredDate = date };
            var response = await httpClient.PatchAsJsonAsync($"/api/orders/{orderId}/status", updateData);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to update order {OrderId} to {Status}: {StatusCode}",
                    orderId, status, response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order {OrderId}", orderId);
        }
    }

    // Simple DTOs for deserialization
    private class OrderDto
    {
        public int Id { get; set; }
        public string OrderNumber { get; set; } = "";
        public string? Status { get; set; }
        public DateTime OrderDate { get; set; }
        public DateTime? ShippedDate { get; set; }
    }

    private class TicketDto
    {
        public int Id { get; set; }
        public int? OrderId { get; set; }
        public string? Status { get; set; }
        public string? Priority { get; set; }
    }
}
