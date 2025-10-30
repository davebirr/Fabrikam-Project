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
    private readonly ActivityLogService _activityLog;
    private readonly RuntimeConfigService _runtimeConfig;
    private const string WorkerName = "TicketGenerator";

    // AI-solvable tickets (most common - 85% of tickets)
    private readonly TicketScenario[] _aiSolvableScenarios = new[]
    {
        new TicketScenario("Order status inquiry", "I would like to check on my order status", "Medium", "General"),
        new TicketScenario("Delivery date question", "When will my order be delivered?", "Medium", "Shipping"),
        new TicketScenario("Customization request", "Can I change the floor plan on my order?", "Low", "General"),
        new TicketScenario("Payment question", "I have a question about my payment", "Medium", "Billing"),
        new TicketScenario("Installation support", "Need help scheduling installation", "Medium", "Installation"),
        new TicketScenario("Warranty information", "What is covered under warranty?", "Low", "General"),
        new TicketScenario("Address change request", "Need to update my delivery address", "High", "Shipping"),
        new TicketScenario("General inquiry", "I have a question about modular homes", "Low", "General"),
        new TicketScenario("Product specifications", "What are the dimensions of the Alpine model?", "Low", "General"),
        new TicketScenario("Financing options", "What financing plans do you offer?", "Medium", "Billing"),
        new TicketScenario("Delivery tracking", "Can I track my delivery in real-time?", "Low", "Shipping"),
        new TicketScenario("Cancellation inquiry", "How do I cancel my order?", "High", "General"),
        new TicketScenario("Color options", "What color choices are available?", "Low", "General"),
        new TicketScenario("Delivery rescheduling", "I need to reschedule my delivery date", "Medium", "Shipping"),
        new TicketScenario("Invoice request", "Can I get a copy of my invoice?", "Low", "Billing"),
        new TicketScenario("Assembly instructions", "Where can I find assembly documentation?", "Medium", "Installation"),
        new TicketScenario("Upgrade options", "Can I upgrade to a larger model?", "Medium", "General")
    };

    // Escalation-required tickets (rare - 15% of tickets, realistic for high-quality Fabrikam homes)
    private readonly TicketScenario[] _escalationScenarios = new[]
    {
        new TicketScenario("Water damage discovered", "I discovered water damage in the bathroom area during installation. There appears to be a leak in the plumbing connections that has affected the subfloor.", "Critical", "Technical"),
        new TicketScenario("Structural integrity concern", "Some of the wall panels don't seem to be aligning properly during assembly. I'm concerned about structural stability.", "High", "Technical"),
        new TicketScenario("Electrical safety issue", "The electrical panel is showing inconsistent readings and some outlets aren't working. This needs immediate professional attention.", "Critical", "Technical"),
        new TicketScenario("Product damage report", "My delivered home has visible damage to exterior panels", "High", "Technical"),
        new TicketScenario("Missing critical components", "Essential structural components are missing from my delivery, preventing installation", "Critical", "Technical"),
        new TicketScenario("Foundation incompatibility", "The home doesn't fit the foundation specifications that were provided", "High", "Technical")
    };

    public TicketGeneratorWorker(
        ILogger<TicketGeneratorWorker> logger,
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
        _logger.LogInformation("TicketGeneratorWorker started");

        // Wait a bit before starting
        await Task.Delay(TimeSpan.FromSeconds(45), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            // Check if stress test mode is enabled (considering runtime override)
            var stressTestMode = _runtimeConfig.IsStressTestModeEnabled(_configuration);
            
            int intervalMinutes, minTickets, maxTickets;
            
            if (stressTestMode)
            {
                var stressConfig = _configuration.GetSection("SimulatorSettings:StressTest").Get<StressTestConfig>() ?? new StressTestConfig();
                intervalMinutes = stressConfig.TicketIntervalMinutes;
                minTickets = stressConfig.MinTicketsPerInterval;
                maxTickets = stressConfig.MaxTicketsPerInterval;
            }
            else
            {
                var normalConfig = _configuration.GetSection("SimulatorSettings:TicketGenerator").Get<TicketGeneratorConfig>() ?? new TicketGeneratorConfig();
                intervalMinutes = normalConfig.IntervalMinutes;
                minTickets = normalConfig.MinTicketsPerInterval;
                maxTickets = normalConfig.MaxTicketsPerInterval;
            }
            
            var status = _stateService.GetStatus(WorkerName);

            if (status.Enabled)
            {
                try
                {
                    await GenerateTickets(minTickets, maxTickets, stressTestMode);
                    _stateService.UpdateLastRun(WorkerName, DateTime.UtcNow.AddMinutes(intervalMinutes));
                    
                    var mode = stressTestMode ? "STRESS TEST MODE" : "normal mode";
                    _logger.LogInformation("TicketGeneratorWorker completed successfully ({Mode})", mode);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in TicketGeneratorWorker");
                    _stateService.SetError(WorkerName, ex.Message);
                }
            }

            await Task.Delay(TimeSpan.FromMinutes(intervalMinutes), stoppingToken);
        }
    }

    private async Task GenerateTickets(int minTickets, int maxTickets, bool stressTestMode)
    {
        var httpClient = _httpClientFactory.CreateClient("FabrikamApi");
        var random = new Random();

        // Get recent orders (last 90 days) to create realistic tickets
        var fromDate = DateTime.UtcNow.AddDays(-90).ToString("yyyy-MM-dd");
        var ordersResponse = await httpClient.GetAsync($"/api/orders?fromDate={fromDate}&pageSize=50");

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

        var ticketCount = random.Next(minTickets, maxTickets + 1);
        
        var mode = stressTestMode ? " [STRESS TEST]" : "";
        _logger.LogInformation("Generating {TicketCount} support tickets{Mode}", ticketCount, mode);

        for (int i = 0; i < ticketCount; i++)
        {
            // Pick a random order
            var order = orders[random.Next(orders.Count)];

            // Pick a scenario with weighted selection (85% AI-solvable, 15% escalation-required)
            // This reflects Fabrikam's high-quality homes - most issues are simple questions
            var useEscalationScenario = random.Next(100) < 15; // 15% chance
            var scenario = useEscalationScenario
                ? _escalationScenarios[random.Next(_escalationScenarios.Length)]
                : _aiSolvableScenarios[random.Next(_aiSolvableScenarios.Length)];

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
                var response = await httpClient.PostAsJsonAsync("/api/supporttickets", newTicket);

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
