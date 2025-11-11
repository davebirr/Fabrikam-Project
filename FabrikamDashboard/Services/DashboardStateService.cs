using FabrikamDashboard.Models;

namespace FabrikamDashboard.Services;

/// <summary>
/// Singleton service that holds the current dashboard state
/// and notifies subscribers when data changes
/// </summary>
public class DashboardStateService
{
    private DashboardDataDto? _currentData;
    private readonly object _lock = new();
    
    public event Action? OnDataChanged;

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

    public void UpdateData(DashboardDataDto newData)
    {
        lock (_lock)
        {
            _currentData = newData;
        }
        
        // Notify all subscribers on the UI thread
        OnDataChanged?.Invoke();
    }
}
