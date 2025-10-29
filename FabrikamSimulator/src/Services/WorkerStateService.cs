using FabrikamSimulator.Models;

namespace FabrikamSimulator.Services;

public class WorkerStateService
{
    private readonly Dictionary<string, WorkerStatus> _workerStatuses = new();
    private readonly object _lock = new();

    public WorkerStatus GetStatus(string workerName)
    {
        lock (_lock)
        {
            if (!_workerStatuses.ContainsKey(workerName))
            {
                _workerStatuses[workerName] = new WorkerStatus();
            }
            return _workerStatuses[workerName];
        }
    }

    public void SetEnabled(string workerName, bool enabled)
    {
        lock (_lock)
        {
            var status = GetStatus(workerName);
            status.Enabled = enabled;
        }
    }

    public void UpdateLastRun(string workerName, DateTime? nextRun = null)
    {
        lock (_lock)
        {
            var status = GetStatus(workerName);
            status.LastRun = DateTime.UtcNow;
            status.NextRun = nextRun;
            status.RunCount++;
            status.LastError = null;
        }
    }

    public void SetError(string workerName, string error)
    {
        lock (_lock)
        {
            var status = GetStatus(workerName);
            status.LastError = error;
        }
    }

    public SimulatorStatus GetAllStatuses()
    {
        lock (_lock)
        {
            return new SimulatorStatus
            {
                OrderProgression = GetStatus("OrderProgression"),
                OrderGenerator = GetStatus("OrderGenerator"),
                TicketGenerator = GetStatus("TicketGenerator")
            };
        }
    }
}
