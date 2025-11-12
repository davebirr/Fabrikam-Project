namespace FabrikamSimulator.Services;

/// <summary>
/// Service for managing runtime configuration overrides
/// </summary>
public class RuntimeConfigService
{
    private bool? _stressTestModeOverride = null;
    private OrderGeneratorConfigOverride? _orderGeneratorOverride = null;
    private TicketGeneratorConfigOverride? _ticketGeneratorOverride = null;
    private readonly object _lock = new object();

    /// <summary>
    /// Get the current stress test mode setting
    /// </summary>
    public bool? GetStressTestModeOverride()
    {
        lock (_lock)
        {
            return _stressTestModeOverride;
        }
    }

    /// <summary>
    /// Enable stress test mode
    /// </summary>
    public void EnableStressTestMode()
    {
        lock (_lock)
        {
            _stressTestModeOverride = true;
        }
    }

    /// <summary>
    /// Disable stress test mode
    /// </summary>
    public void DisableStressTestMode()
    {
        lock (_lock)
        {
            _stressTestModeOverride = false;
        }
    }

    /// <summary>
    /// Clear the override and use configuration file setting
    /// </summary>
    public void ClearOverride()
    {
        lock (_lock)
        {
            _stressTestModeOverride = null;
        }
    }

    /// <summary>
    /// Check if stress test mode is enabled (considering override)
    /// </summary>
    public bool IsStressTestModeEnabled(IConfiguration configuration)
    {
        lock (_lock)
        {
            return _stressTestModeOverride ?? configuration.GetValue<bool>("SimulatorSettings:StressTestMode");
        }
    }

    /// <summary>
    /// Set order generator configuration override
    /// </summary>
    public void SetOrderGeneratorConfig(int intervalMinutes, int minOrders, int maxOrders)
    {
        lock (_lock)
        {
            _orderGeneratorOverride = new OrderGeneratorConfigOverride
            {
                IntervalMinutes = intervalMinutes,
                MinOrdersPerInterval = minOrders,
                MaxOrdersPerInterval = maxOrders
            };
        }
    }

    /// <summary>
    /// Get order generator configuration (with override if set)
    /// </summary>
    public (int intervalMinutes, int minOrders, int maxOrders) GetOrderGeneratorConfig(IConfiguration configuration)
    {
        lock (_lock)
        {
            if (_orderGeneratorOverride != null)
            {
                return (_orderGeneratorOverride.IntervalMinutes, _orderGeneratorOverride.MinOrdersPerInterval, _orderGeneratorOverride.MaxOrdersPerInterval);
            }

            var config = configuration.GetSection("SimulatorSettings:OrderGenerator");
            return (
                config.GetValue<int>("IntervalMinutes", 60),
                config.GetValue<int>("MinOrdersPerInterval", 1),
                config.GetValue<int>("MaxOrdersPerInterval", 3)
            );
        }
    }

    /// <summary>
    /// Clear order generator override
    /// </summary>
    public void ClearOrderGeneratorOverride()
    {
        lock (_lock)
        {
            _orderGeneratorOverride = null;
        }
    }

    /// <summary>
    /// Set ticket generator configuration override
    /// </summary>
    public void SetTicketGeneratorConfig(int intervalMinutes, int minTickets, int maxTickets)
    {
        lock (_lock)
        {
            _ticketGeneratorOverride = new TicketGeneratorConfigOverride
            {
                IntervalMinutes = intervalMinutes,
                MinTicketsPerInterval = minTickets,
                MaxTicketsPerInterval = maxTickets
            };
        }
    }

    /// <summary>
    /// Get ticket generator configuration (with override if set)
    /// </summary>
    public (int intervalMinutes, int minTickets, int maxTickets) GetTicketGeneratorConfig(IConfiguration configuration)
    {
        lock (_lock)
        {
            if (_ticketGeneratorOverride != null)
            {
                return (_ticketGeneratorOverride.IntervalMinutes, _ticketGeneratorOverride.MinTicketsPerInterval, _ticketGeneratorOverride.MaxTicketsPerInterval);
            }

            var config = configuration.GetSection("SimulatorSettings:TicketGenerator");
            return (
                config.GetValue<int>("IntervalMinutes", 60),
                config.GetValue<int>("MinTicketsPerInterval", 1),
                config.GetValue<int>("MaxTicketsPerInterval", 2)
            );
        }
    }

    /// <summary>
    /// Clear ticket generator override
    /// </summary>
    public void ClearTicketGeneratorOverride()
    {
        lock (_lock)
        {
            _ticketGeneratorOverride = null;
        }
    }

    /// <summary>
    /// Check if order generator has runtime override
    /// </summary>
    public bool HasOrderGeneratorOverride()
    {
        lock (_lock)
        {
            return _orderGeneratorOverride != null;
        }
    }

    /// <summary>
    /// Check if ticket generator has runtime override
    /// </summary>
    public bool HasTicketGeneratorOverride()
    {
        lock (_lock)
        {
            return _ticketGeneratorOverride != null;
        }
    }
}

public class OrderGeneratorConfigOverride
{
    public int IntervalMinutes { get; set; }
    public int MinOrdersPerInterval { get; set; }
    public int MaxOrdersPerInterval { get; set; }
}

public class TicketGeneratorConfigOverride
{
    public int IntervalMinutes { get; set; }
    public int MinTicketsPerInterval { get; set; }
    public int MaxTicketsPerInterval { get; set; }
}
