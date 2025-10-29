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
    private const string WorkerName = "OrderProgression";

    public OrderProgressionWorker(
        ILogger<OrderProgressionWorker> logger,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        WorkerStateService stateService)
    {
        _logger = logger;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _stateService = stateService;
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
                    await ProcessOrderProgression(config);
                    _stateService.UpdateLastRun(WorkerName, DateTime.UtcNow.AddMinutes(config.IntervalMinutes));
                    _logger.LogInformation("OrderProgressionWorker completed successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in OrderProgressionWorker");
                    _stateService.SetError(WorkerName, ex.Message);
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(config.IntervalMinutes), stoppingToken);
        }
    }

    private async Task ProcessOrderProgression(OrderProgressionConfig config)
    {
        var apiBaseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
        var httpClient = _httpClientFactory.CreateClient();

        // Get all orders
        var ordersResponse = await httpClient.GetAsync($"{apiBaseUrl}/api/orders?pageSize=100");
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
            return;
        }

        var random = new Random();
        var updatedCount = 0;

        foreach (var order in orders)
        {
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
                    }
                    break;
            }

            if (shouldUpdate && newStatus != null)
            {
                await UpdateOrderStatus(httpClient, apiBaseUrl, order.Id, newStatus, newDate);
                updatedCount++;
            }
        }

        _logger.LogInformation("Processed {TotalOrders} orders, updated {UpdatedCount}", orders.Count, updatedCount);
    }

    private async Task UpdateOrderStatus(HttpClient httpClient, string baseUrl, int orderId, string status, DateTime? date)
    {
        try
        {
            var updateData = new { status, shippedDate = date, deliveredDate = date };
            var response = await httpClient.PatchAsJsonAsync($"{baseUrl}/api/orders/{orderId}/status", updateData);

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

    // Simple DTO for deserialization
    private class OrderDto
    {
        public int Id { get; set; }
        public string OrderNumber { get; set; } = "";
        public string? Status { get; set; }
        public DateTime OrderDate { get; set; }
        public DateTime? ShippedDate { get; set; }
    }
}
