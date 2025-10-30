using FabrikamSimulator.Models;
using FabrikamSimulator.Services;
using Microsoft.AspNetCore.Mvc;

namespace FabrikamSimulator.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SimulatorController : ControllerBase
{
    private readonly WorkerStateService _stateService;
    private readonly ActivityLogService _activityLog;
    private readonly RuntimeConfigService _runtimeConfig;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SimulatorController> _logger;

    public SimulatorController(
        WorkerStateService stateService,
        ActivityLogService activityLog,
        RuntimeConfigService runtimeConfig,
        IConfiguration configuration,
        ILogger<SimulatorController> logger)
    {
        _stateService = stateService;
        _activityLog = activityLog;
        _runtimeConfig = runtimeConfig;
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
                logs = "GET /api/simulator/logs",
                startOrderProgression = "POST /api/simulator/orders/progression/start",
                stopOrderProgression = "POST /api/simulator/orders/progression/stop",
                startOrderGenerator = "POST /api/simulator/orders/generator/start",
                stopOrderGenerator = "POST /api/simulator/orders/generator/stop",
                startTicketGenerator = "POST /api/simulator/tickets/start",
                stopTicketGenerator = "POST /api/simulator/tickets/stop",
                stressTestStatus = "GET /api/simulator/stresstest/status",
                stressTestEnable = "POST /api/simulator/stresstest/enable",
                stressTestDisable = "POST /api/simulator/stresstest/disable",
                stressTestReset = "POST /api/simulator/stresstest/reset"
            }
        });
    }

    /// <summary>
    /// Get recent activity logs from all simulators
    /// </summary>
    [HttpGet("logs")]
    public ActionResult GetLogs([FromQuery] int count = 100, [FromQuery] string? worker = null)
    {
        var logs = string.IsNullOrEmpty(worker)
            ? _activityLog.GetRecentLogs(count)
            : _activityLog.GetLogsByWorker(worker, count);

        return Ok(new
        {
            count = logs.Count(),
            logs = logs.Select(l => new
            {
                timestamp = l.Timestamp,
                worker = l.WorkerName,
                action = l.Action,
                details = l.Details,
                isError = l.IsError
            })
        });
    }

    /// <summary>
    /// Clear all activity logs
    /// </summary>
    [HttpDelete("logs")]
    public IActionResult ClearLogs()
    {
        _activityLog.ClearLogs();
        return Ok(new { message = "Activity logs cleared" });
    }

    /// <summary>
    /// Get stress test mode status
    /// </summary>
    [HttpGet("stresstest/status")]
    public ActionResult GetStressTestStatus()
    {
        var isEnabled = _runtimeConfig.IsStressTestModeEnabled(_configuration);
        var stressTestConfig = _configuration.GetSection("SimulatorSettings:StressTest").Get<StressTestConfig>() ?? new StressTestConfig();
        var normalConfig = _configuration.GetSection("SimulatorSettings:TicketGenerator").Get<TicketGeneratorConfig>() ?? new TicketGeneratorConfig();

        return Ok(new
        {
            stressTestMode = isEnabled,
            source = _runtimeConfig.GetStressTestModeOverride() == null ? "configuration" : "runtime-override",
            currentSettings = isEnabled
                ? new
                {
                    mode = "STRESS TEST",
                    ticketIntervalMinutes = stressTestConfig.TicketIntervalMinutes,
                    minTicketsPerInterval = stressTestConfig.MinTicketsPerInterval,
                    maxTicketsPerInterval = stressTestConfig.MaxTicketsPerInterval,
                    estimatedTicketsPerDay = $"{(1440 / stressTestConfig.TicketIntervalMinutes) * stressTestConfig.MinTicketsPerInterval}-{(1440 / stressTestConfig.TicketIntervalMinutes) * stressTestConfig.MaxTicketsPerInterval}"
                }
                : new
                {
                    mode = "NORMAL",
                    ticketIntervalMinutes = normalConfig.IntervalMinutes,
                    minTicketsPerInterval = normalConfig.MinTicketsPerInterval,
                    maxTicketsPerInterval = normalConfig.MaxTicketsPerInterval,
                    estimatedTicketsPerDay = $"{(1440 / normalConfig.IntervalMinutes) * normalConfig.MinTicketsPerInterval}-{(1440 / normalConfig.IntervalMinutes) * normalConfig.MaxTicketsPerInterval}"
                }
        });
    }

    /// <summary>
    /// Enable stress test mode (150+ tickets/day for workshop demos)
    /// </summary>
    [HttpPost("stresstest/enable")]
    public IActionResult EnableStressTest()
    {
        _runtimeConfig.EnableStressTestMode();
        _logger.LogWarning("⚠️  STRESS TEST MODE ENABLED - High volume ticket generation activated");
        _activityLog.LogActivity("StressTestMode", "Enabled", "Stress test mode activated via API - expect 150+ tickets/day", false);

        return Ok(new
        {
            message = "Stress test mode enabled",
            status = "active",
            warning = "High volume ticket generation is now active (150+ tickets/day)",
            note = "This setting will persist until disabled or service restarts. To make permanent, update appsettings.json"
        });
    }

    /// <summary>
    /// Disable stress test mode (return to normal operation)
    /// </summary>
    [HttpPost("stresstest/disable")]
    public IActionResult DisableStressTest()
    {
        _runtimeConfig.DisableStressTestMode();
        _logger.LogInformation("Stress test mode disabled - returning to normal operation");
        _activityLog.LogActivity("StressTestMode", "Disabled", "Stress test mode deactivated via API - returning to normal ticket generation", false);

        return Ok(new
        {
            message = "Stress test mode disabled",
            status = "inactive",
            note = "Normal ticket generation resumed (~24-48 tickets/day)"
        });
    }

    /// <summary>
    /// Clear stress test mode override and use configuration file setting
    /// </summary>
    [HttpPost("stresstest/reset")]
    public IActionResult ResetStressTest()
    {
        _runtimeConfig.ClearOverride();
        var isEnabled = _runtimeConfig.IsStressTestModeEnabled(_configuration);
        _logger.LogInformation("Stress test mode override cleared - using configuration file setting: {IsEnabled}", isEnabled);
        _activityLog.LogActivity("StressTestMode", "Reset", $"Runtime override cleared - using configuration file setting (StressTestMode={isEnabled})", false);

        return Ok(new
        {
            message = "Stress test mode override cleared",
            status = isEnabled ? "active" : "inactive",
            source = "configuration file",
            note = "Now using StressTestMode setting from appsettings.json"
        });
    }
}
