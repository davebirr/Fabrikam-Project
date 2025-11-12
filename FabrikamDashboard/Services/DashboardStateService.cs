using FabrikamDashboard.Models;

namespace FabrikamDashboard.Services;

/// <summary>
/// Singleton service that holds the current dashboard state
/// and notifies subscribers when data changes
/// </summary>
public class DashboardStateService
{
    private DashboardDataDto? _currentData;
    private string _currentTimeframe = "365days"; // Default to match MCP tool
    private readonly object _lock = new();
    
    public event Action? OnDataChanged;
    public event Action? OnTimeframeChanged;

    public DashboardDataDto? CurrentData
    {
        get
        {
            lock (_lock)
            {
                return _currentData;
            }
        }
    }

    public string CurrentTimeframe
    {
        get
        {
            lock (_lock)
            {
                return _currentTimeframe;
            }
        }
    }

    public void UpdateData(DashboardDataDto newData)
    {
        lock (_lock)
        {
            _currentData = newData;
        }
        
        // Notify all subscribers on the UI thread
        OnDataChanged?.Invoke();
    }

    public void UpdateTimeframe(string timeframe)
    {
        lock (_lock)
        {
            _currentTimeframe = timeframe;
        }
        
        // Notify all subscribers
        OnTimeframeChanged?.Invoke();
    }
}
