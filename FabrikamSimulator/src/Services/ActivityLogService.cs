using System.Collections.Concurrent;

namespace FabrikamSimulator.Services;

public class ActivityLogService
{
    private readonly ConcurrentQueue<ActivityLogEntry> _logs = new();
    private const int MaxLogEntries = 500; // Keep last 500 entries

    public void LogActivity(string workerName, string action, string details, bool isError = false)
    {
        var entry = new ActivityLogEntry
        {
            Timestamp = DateTime.UtcNow,
            WorkerName = workerName,
            Action = action,
            Details = details,
            IsError = isError
        };

        _logs.Enqueue(entry);

        // Trim old entries if needed
        while (_logs.Count > MaxLogEntries)
        {
            _logs.TryDequeue(out _);
        }
    }

    public IEnumerable<ActivityLogEntry> GetRecentLogs(int count = 100)
    {
        return _logs.TakeLast(count).OrderByDescending(l => l.Timestamp);
    }

    public IEnumerable<ActivityLogEntry> GetLogsByWorker(string workerName, int count = 100)
    {
        return _logs
            .Where(l => l.WorkerName.Equals(workerName, StringComparison.OrdinalIgnoreCase))
            .TakeLast(count)
            .OrderByDescending(l => l.Timestamp);
    }

    public void ClearLogs()
    {
        _logs.Clear();
    }
}

public class ActivityLogEntry
{
    public DateTime Timestamp { get; set; }
    public string WorkerName { get; set; } = "";
    public string Action { get; set; } = "";
    public string Details { get; set; } = "";
    public bool IsError { get; set; }
}
