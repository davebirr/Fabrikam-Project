using FabrikamSimulator.Models;
using FabrikamSimulator.Services;
using System.Text.Json;

namespace FabrikamSimulator.Workers;

public class OrderGeneratorWorker : BackgroundService
{
    private readonly ILogger<OrderGeneratorWorker> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly WorkerStateService _stateService;
    private readonly ActivityLogService _activityLog;
    private readonly RuntimeConfigService _runtimeConfig;
    private const string WorkerName = "OrderGenerator";

    private readonly string[] _regions = new[] { "Northeast", "Southeast", "Midwest", "West Coast", "Pacific Northwest" };
    private readonly string[] _firstNames = new[] { "John", "Sarah", "Michael", "Emily", "David", "Jessica", "James", "Lisa", "Robert", "Jennifer" };
    private readonly string[] _lastNames = new[] { "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez" };

    public OrderGeneratorWorker(
        ILogger<OrderGeneratorWorker> logger,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        WorkerStateService stateService,
        ActivityLogService activityLog,
        RuntimeConfigService runtimeConfig)
    {
        _logger = logger;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _stateService = stateService;
        _activityLog = activityLog;
        _runtimeConfig = runtimeConfig;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("OrderGeneratorWorker started");

        // Wait a bit before starting to avoid startup conflicts
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            // Get effective configuration (runtime override or appsettings)
            var effectiveConfig = _runtimeConfig.GetOrderGeneratorConfig(_configuration);
            var intervalMinutes = effectiveConfig.intervalMinutes;
            var minOrders = effectiveConfig.minOrders;
            var maxOrders = effectiveConfig.maxOrders;

            var status = _stateService.GetStatus(WorkerName);

            if (status.Enabled)
            {
                try
                {
                    await GenerateOrders(minOrders, maxOrders);
                    _stateService.UpdateLastRun(WorkerName, DateTime.UtcNow.AddMinutes(intervalMinutes));
                    _logger.LogInformation("OrderGeneratorWorker completed successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in OrderGeneratorWorker");
                    _stateService.SetError(WorkerName, ex.Message);
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(intervalMinutes), stoppingToken);
        }
    }

    private async Task GenerateOrders(int minOrders, int maxOrders)
    {
        var httpClient = _httpClientFactory.CreateClient("FabrikamApi");
        var random = new Random();

        // Get existing customers
        var customersResponse = await httpClient.GetAsync("/api/customers?pageSize=50");
        if (!customersResponse.IsSuccessStatusCode)
        {
            _logger.LogWarning("Failed to fetch customers: {StatusCode}", customersResponse.StatusCode);
            return;
        }

        var customersJson = await customersResponse.Content.ReadAsStringAsync();
        var customers = JsonSerializer.Deserialize<List<CustomerDto>>(customersJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (customers == null || customers.Count == 0)
        {
            _logger.LogWarning("No customers found to create orders for");
            return;
        }

        // Get product catalog
        var productsResponse = await httpClient.GetAsync("/api/products?pageSize=20");
        List<ProductDto>? products = null;
        if (productsResponse.IsSuccessStatusCode)
        {
            var productsJson = await productsResponse.Content.ReadAsStringAsync();
            products = JsonSerializer.Deserialize<List<ProductDto>>(productsJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }

        var orderCount = random.Next(minOrders, maxOrders + 1);

        for (int i = 0; i < orderCount; i++)
        {
            // Pick a random customer
            var customer = customers[random.Next(customers.Count)];

            // Create order with 1-3 random products
            var orderItems = new List<object>();
            var itemCount = random.Next(1, 4);

            if (products != null && products.Count > 0)
            {
                for (int j = 0; j < itemCount; j++)
                {
                    var product = products[random.Next(products.Count)];
                    orderItems.Add(new
                    {
                        productId = product.Id,
                        quantity = random.Next(1, 3),
                        unitPrice = product.Price
                    });
                }
            }

            var newOrder = new
            {
                customerId = customer.Id,
                orderDate = DateTime.UtcNow,
                status = "Pending",
                items = orderItems
            };

            try
            {
                var response = await httpClient.PostAsJsonAsync("/api/orders", newOrder);

                if (response.IsSuccessStatusCode)
                {
                    var orderJson = await response.Content.ReadAsStringAsync();
                    var order = JsonSerializer.Deserialize<OrderDto>(orderJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    _logger.LogInformation("Created new order {OrderNumber} for customer {CustomerId}", order?.OrderNumber, customer.Id);
                }
                else
                {
                    _logger.LogWarning("Failed to create order for customer {CustomerId}: {StatusCode}",
                        customer.Id, response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating order for customer {CustomerId}", customer.Id);
            }
        }

        _logger.LogInformation("Generated {OrderCount} new orders", orderCount);
    }

    private class CustomerDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Region { get; set; } = "";
    }

    private class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public decimal Price { get; set; }
    }

    private class OrderDto
    {
        public string OrderNumber { get; set; } = "";
    }
}
