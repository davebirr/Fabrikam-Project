namespace FabrikamSimulator.Services;

/// <summary>
/// Service for managing runtime configuration overrides
/// </summary>
public class RuntimeConfigService
{
    private bool? _stressTestModeOverride = null;
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
}
