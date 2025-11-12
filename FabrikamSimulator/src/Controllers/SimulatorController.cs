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

    /// <summary>
    /// Update order generator configuration at runtime
    /// </summary>
    [HttpPost("config/orders")]
    public IActionResult UpdateOrderConfig([FromBody] OrderConfigRequest request)
    {
        // Validate interval
        if (request.IntervalMinutes < 1 || request.IntervalMinutes > 1440)
        {
            return BadRequest(new { error = "Interval must be between 1 and 1440 minutes (24 hours)" });
        }

        // Validate volumes
        if (request.MinOrdersPerInterval < 0 || request.MinOrdersPerInterval > 50)
        {
            return BadRequest(new { error = "MinOrdersPerInterval must be between 0 and 50" });
        }

        if (request.MaxOrdersPerInterval < 1 || request.MaxOrdersPerInterval > 50)
        {
            return BadRequest(new { error = "MaxOrdersPerInterval must be between 1 and 50" });
        }

        if (request.MinOrdersPerInterval > request.MaxOrdersPerInterval)
        {
            return BadRequest(new { error = "MinOrdersPerInterval cannot exceed MaxOrdersPerInterval" });
        }

        // Apply configuration
        _runtimeConfig.SetOrderGeneratorConfig(request.IntervalMinutes, request.MinOrdersPerInterval, request.MaxOrdersPerInterval);

        // Calculate estimated throughput
        var intervalsPerDay = 1440 / request.IntervalMinutes;
        var avgOrdersPerInterval = (request.MinOrdersPerInterval + request.MaxOrdersPerInterval) / 2.0;
        var estimatedPerDay = (int)(intervalsPerDay * avgOrdersPerInterval);

        _logger.LogInformation("Order generator configuration updated via API: Interval={Interval}min, Min={Min}, Max={Max}, Estimated={Estimated}/day",
            request.IntervalMinutes, request.MinOrdersPerInterval, request.MaxOrdersPerInterval, estimatedPerDay);

        _activityLog.LogActivity("OrderGenerator", "ConfigUpdated",
            $"Runtime config: {request.MinOrdersPerInterval}-{request.MaxOrdersPerInterval} orders every {request.IntervalMinutes} minutes (~{estimatedPerDay}/day)",
            false);

        return Ok(new
        {
            message = "Order generator configuration updated",
            intervalMinutes = request.IntervalMinutes,
            minOrdersPerInterval = request.MinOrdersPerInterval,
            maxOrdersPerInterval = request.MaxOrdersPerInterval,
            estimatedOrdersPerDay = estimatedPerDay,
            note = "Configuration is runtime-only and will reset on service restart. To make permanent, update appsettings.json"
        });
    }

    /// <summary>
    /// Update ticket generator configuration at runtime
    /// </summary>
    [HttpPost("config/tickets")]
    public IActionResult UpdateTicketConfig([FromBody] TicketConfigRequest request)
    {
        // Validate interval
        if (request.IntervalMinutes < 1 || request.IntervalMinutes > 1440)
        {
            return BadRequest(new { error = "Interval must be between 1 and 1440 minutes (24 hours)" });
        }

        // Validate volumes
        if (request.MinTicketsPerInterval < 0 || request.MinTicketsPerInterval > 50)
        {
            return BadRequest(new { error = "MinTicketsPerInterval must be between 0 and 50" });
        }

        if (request.MaxTicketsPerInterval < 1 || request.MaxTicketsPerInterval > 50)
        {
            return BadRequest(new { error = "MaxTicketsPerInterval must be between 1 and 50" });
        }

        if (request.MinTicketsPerInterval > request.MaxTicketsPerInterval)
        {
            return BadRequest(new { error = "MinTicketsPerInterval cannot exceed MaxTicketsPerInterval" });
        }

        // Apply configuration
        _runtimeConfig.SetTicketGeneratorConfig(request.IntervalMinutes, request.MinTicketsPerInterval, request.MaxTicketsPerInterval);

        // Calculate estimated throughput
        var intervalsPerDay = 1440 / request.IntervalMinutes;
        var avgTicketsPerInterval = (request.MinTicketsPerInterval + request.MaxTicketsPerInterval) / 2.0;
        var estimatedPerDay = (int)(intervalsPerDay * avgTicketsPerInterval);

        _logger.LogInformation("Ticket generator configuration updated via API: Interval={Interval}min, Min={Min}, Max={Max}, Estimated={Estimated}/day",
            request.IntervalMinutes, request.MinTicketsPerInterval, request.MaxTicketsPerInterval, estimatedPerDay);

        _activityLog.LogActivity("TicketGenerator", "ConfigUpdated",
            $"Runtime config: {request.MinTicketsPerInterval}-{request.MaxTicketsPerInterval} tickets every {request.IntervalMinutes} minutes (~{estimatedPerDay}/day)",
            false);

        return Ok(new
        {
            message = "Ticket generator configuration updated",
            intervalMinutes = request.IntervalMinutes,
            minTicketsPerInterval = request.MinTicketsPerInterval,
            maxTicketsPerInterval = request.MaxTicketsPerInterval,
            estimatedTicketsPerDay = estimatedPerDay,
            note = "Configuration is runtime-only and will reset on service restart. To make permanent, update appsettings.json"
        });
    }

    /// <summary>
    /// Reset order generator configuration to appsettings.json defaults
    /// </summary>
    [HttpPost("config/orders/reset")]
    public IActionResult ResetOrderConfig()
    {
        _runtimeConfig.ClearOrderGeneratorOverride();
        var config = _runtimeConfig.GetOrderGeneratorConfig(_configuration);

        _logger.LogInformation("Order generator configuration reset to defaults: Interval={Interval}min, Min={Min}, Max={Max}",
            config.intervalMinutes, config.minOrders, config.maxOrders);

        _activityLog.LogActivity("OrderGenerator", "ConfigReset", "Runtime override cleared - using appsettings.json defaults", false);

        return Ok(new
        {
            message = "Order generator configuration reset to defaults",
            intervalMinutes = config.intervalMinutes,
            minOrdersPerInterval = config.minOrders,
            maxOrdersPerInterval = config.maxOrders,
            source = "appsettings.json"
        });
    }

    /// <summary>
    /// Reset ticket generator configuration to appsettings.json defaults
    /// </summary>
    [HttpPost("config/tickets/reset")]
    public IActionResult ResetTicketConfig()
    {
        _runtimeConfig.ClearTicketGeneratorOverride();
        var config = _runtimeConfig.GetTicketGeneratorConfig(_configuration);

        _logger.LogInformation("Ticket generator configuration reset to defaults: Interval={Interval}min, Min={Min}, Max={Max}",
            config.intervalMinutes, config.minTickets, config.maxTickets);

        _activityLog.LogActivity("TicketGenerator", "ConfigReset", "Runtime override cleared - using appsettings.json defaults", false);

        return Ok(new
        {
            message = "Ticket generator configuration reset to defaults",
            intervalMinutes = config.intervalMinutes,
            minTicketsPerInterval = config.minTickets,
            maxTicketsPerInterval = config.maxTickets,
            source = "appsettings.json"
        });
    }
}

public class OrderConfigRequest
{
    public int IntervalMinutes { get; set; }
    public int MinOrdersPerInterval { get; set; }
    public int MaxOrdersPerInterval { get; set; }
}

public class TicketConfigRequest
{
    public int IntervalMinutes { get; set; }
    public int MinTicketsPerInterval { get; set; }
    public int MaxTicketsPerInterval { get; set; }
}
