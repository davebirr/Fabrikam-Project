using FabrikamSimulator.Models;
using FabrikamSimulator.Services;
using System.Text.Json;

namespace FabrikamSimulator.Workers;

public class TicketGeneratorWorker : BackgroundService
{
    private readonly ILogger<TicketGeneratorWorker> _logger;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly WorkerStateService _stateService;
    private const string WorkerName = "TicketGenerator";

    private readonly TicketScenario[] _scenarios = new[]
    {
        new TicketScenario("Order status inquiry", "I would like to check on my order status", "Medium", "General"),
        new TicketScenario("Delivery date question", "When will my order be delivered?", "Medium", "Shipping"),
        new TicketScenario("Product damage report", "My delivered home has some damage", "High", "Technical"),
        new TicketScenario("Customization request", "Can I change the floor plan on my order?", "Low", "General"),
        new TicketScenario("Payment question", "I have a question about my payment", "Medium", "Billing"),
        new TicketScenario("Installation support", "Need help scheduling installation", "Medium", "Installation"),
        new TicketScenario("Missing parts", "Some parts are missing from my delivery", "High", "Technical"),
        new TicketScenario("Warranty information", "What is covered under warranty?", "Low", "General"),
        new TicketScenario("Address change request", "Need to update my delivery address", "High", "Shipping"),
        new TicketScenario("General inquiry", "I have a question about modular homes", "Low", "General")
    };

    public TicketGeneratorWorker(
        ILogger<TicketGeneratorWorker> logger,
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
        _logger.LogInformation("TicketGeneratorWorker started");

        // Wait a bit before starting
        await Task.Delay(TimeSpan.FromSeconds(45), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            var config = _configuration.GetSection("SimulatorSettings:TicketGenerator").Get<TicketGeneratorConfig>() ?? new();
            var status = _stateService.GetStatus(WorkerName);

            if (status.Enabled)
            {
                try
                {
                    await GenerateTickets(config);
                    _stateService.UpdateLastRun(WorkerName, DateTime.UtcNow.AddMinutes(config.IntervalMinutes));
                    _logger.LogInformation("TicketGeneratorWorker completed successfully");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in TicketGeneratorWorker");
                    _stateService.SetError(WorkerName, ex.Message);
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(config.IntervalMinutes), stoppingToken);
        }
    }

    private async Task GenerateTickets(TicketGeneratorConfig config)
    {
        var apiBaseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
        var httpClient = _httpClientFactory.CreateClient();
        var random = new Random();

        // Get recent orders (last 90 days) to create realistic tickets
        var fromDate = DateTime.UtcNow.AddDays(-90).ToString("yyyy-MM-dd");
        var ordersResponse = await httpClient.GetAsync($"{apiBaseUrl}/api/orders?fromDate={fromDate}&pageSize=50");

        if (!ordersResponse.IsSuccessStatusCode)
        {
            _logger.LogWarning("Failed to fetch orders: {StatusCode}", ordersResponse.StatusCode);
            return;
        }

        var ordersJson = await ordersResponse.Content.ReadAsStringAsync();
        var orders = JsonSerializer.Deserialize<List<OrderDto>>(ordersJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        if (orders == null || orders.Count == 0)
        {
            _logger.LogWarning("No recent orders found to create tickets for");
            return;
        }

        var ticketCount = random.Next(config.MinTicketsPerInterval, config.MaxTicketsPerInterval + 1);

        for (int i = 0; i < ticketCount; i++)
        {
            // Pick a random order
            var order = orders[random.Next(orders.Count)];

            // Pick a random scenario
            var scenario = _scenarios[random.Next(_scenarios.Length)];

            // Create the ticket
            var newTicket = new
            {
                customerId = order.CustomerId,
                orderId = (int?)order.Id,
                subject = scenario.Subject,
                description = $"{scenario.Description}\n\nOrder: {order.OrderNumber}\nOrder Status: {order.Status}",
                priority = scenario.Priority,
                category = scenario.Category
            };

            try
            {
                var response = await httpClient.PostAsJsonAsync($"{apiBaseUrl}/api/supporttickets", newTicket);

                if (response.IsSuccessStatusCode)
                {
                    var ticketJson = await response.Content.ReadAsStringAsync();
                    var ticket = JsonSerializer.Deserialize<TicketDto>(ticketJson, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    _logger.LogInformation("Created support ticket {TicketNumber} for order {OrderNumber}",
                        ticket?.TicketNumber, order.OrderNumber);
                }
                else
                {
                    _logger.LogWarning("Failed to create ticket for order {OrderNumber}: {StatusCode}",
                        order.OrderNumber, response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating ticket for order {OrderNumber}", order.OrderNumber);
            }
        }

        _logger.LogInformation("Generated {TicketCount} support tickets", ticketCount);
    }

    private record TicketScenario(string Subject, string Description, string Priority, string Category);

    private class OrderDto
    {
        public int Id { get; set; }
        public int CustomerId { get; set; }
        public string OrderNumber { get; set; } = "";
        public string Status { get; set; } = "";
    }

    private class TicketDto
    {
        public string TicketNumber { get; set; } = "";
    }
}
