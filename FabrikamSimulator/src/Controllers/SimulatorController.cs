using FabrikamSimulator.Models;
using FabrikamSimulator.Services;
using Microsoft.AspNetCore.Mvc;

namespace FabrikamSimulator.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SimulatorController : ControllerBase
{
    private readonly WorkerStateService _stateService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SimulatorController> _logger;

    public SimulatorController(
        WorkerStateService stateService,
        IConfiguration configuration,
        ILogger<SimulatorController> logger)
    {
        _stateService = stateService;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Get status of all simulators
    /// </summary>
    [HttpGet("status")]
    public ActionResult<SimulatorStatus> GetStatus()
    {
        return Ok(_stateService.GetAllStatuses());
    }

    /// <summary>
    /// Start the order progression simulator
    /// </summary>
    [HttpPost("orders/progression/start")]
    public IActionResult StartOrderProgression()
    {
        _stateService.SetEnabled("OrderProgression", true);
        _logger.LogInformation("Order progression simulator started via API");
        return Ok(new { message = "Order progression simulator started", status = "enabled" });
    }

    /// <summary>
    /// Stop the order progression simulator
    /// </summary>
    [HttpPost("orders/progression/stop")]
    public IActionResult StopOrderProgression()
    {
        _stateService.SetEnabled("OrderProgression", false);
        _logger.LogInformation("Order progression simulator stopped via API");
        return Ok(new { message = "Order progression simulator stopped", status = "disabled" });
    }

    /// <summary>
    /// Start the order generator simulator
    /// </summary>
    [HttpPost("orders/generator/start")]
    public IActionResult StartOrderGenerator()
    {
        _stateService.SetEnabled("OrderGenerator", true);
        _logger.LogInformation("Order generator simulator started via API");
        return Ok(new { message = "Order generator simulator started", status = "enabled" });
    }

    /// <summary>
    /// Stop the order generator simulator
    /// </summary>
    [HttpPost("orders/generator/stop")]
    public IActionResult StopOrderGenerator()
    {
        _stateService.SetEnabled("OrderGenerator", false);
        _logger.LogInformation("Order generator simulator stopped via API");
        return Ok(new { message = "Order generator simulator stopped", status = "disabled" });
    }

    /// <summary>
    /// Start the ticket generator simulator
    /// </summary>
    [HttpPost("tickets/start")]
    public IActionResult StartTicketGenerator()
    {
        _stateService.SetEnabled("TicketGenerator", true);
        _logger.LogInformation("Ticket generator simulator started via API");
        return Ok(new { message = "Ticket generator simulator started", status = "enabled" });
    }

    /// <summary>
    /// Stop the ticket generator simulator
    /// </summary>
    [HttpPost("tickets/stop")]
    public IActionResult StopTicketGenerator()
    {
        _stateService.SetEnabled("TicketGenerator", false);
        _logger.LogInformation("Ticket generator simulator stopped via API");
        return Ok(new { message = "Ticket generator simulator stopped", status = "disabled" });
    }

    /// <summary>
    /// Get current simulator configuration
    /// </summary>
    [HttpGet("config")]
    public ActionResult<SimulatorConfig> GetConfig()
    {
        var config = _configuration.GetSection("SimulatorSettings").Get<SimulatorConfig>() ?? new SimulatorConfig();
        return Ok(config);
    }

    /// <summary>
    /// Get API information
    /// </summary>
    [HttpGet("info")]
    public IActionResult GetInfo()
    {
        return Ok(new
        {
            service = "Fabrikam Business Simulator",
            version = "1.0.0",
            description = "Automated business activity simulator for Fabrikam modular homes platform",
            simulators = new[]
            {
                new { name = "OrderProgression", description = "Moves orders through lifecycle stages" },
                new { name = "OrderGenerator", description = "Creates new customer orders" },
                new { name = "TicketGenerator", description = "Generates support tickets" }
            },
            endpoints = new
            {
                status = "GET /api/simulator/status",
                config = "GET /api/simulator/config",
                startOrderProgression = "POST /api/simulator/orders/progression/start",
                stopOrderProgression = "POST /api/simulator/orders/progression/stop",
                startOrderGenerator = "POST /api/simulator/orders/generator/start",
                stopOrderGenerator = "POST /api/simulator/orders/generator/stop",
                startTicketGenerator = "POST /api/simulator/tickets/start",
                stopTicketGenerator = "POST /api/simulator/tickets/stop"
            }
        });
    }
}
