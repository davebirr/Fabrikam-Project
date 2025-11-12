namespace FabrikamDashboard.Models;

/// <summary>
/// DTO representing the status of all simulator workers
/// </summary>
public class SimulatorStatusDto
{
    public WorkerStatusDto OrderProgression { get; set; } = new();
    public WorkerStatusDto OrderGenerator { get; set; } = new();
    public WorkerStatusDto TicketGenerator { get; set; } = new();
}

/// <summary>
/// DTO representing the status of a single worker
/// </summary>
public class WorkerStatusDto
{
    public bool Enabled { get; set; }
    public DateTime? LastRun { get; set; }
    public DateTime? NextRun { get; set; }
    public int RunCount { get; set; }
    public string? LastError { get; set; }
}

/// <summary>
/// Dashboard data snapshot for real-time updates
/// </summary>
public class DashboardDataDto
{
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public int TotalOrders { get; set; }
    public int OpenTickets { get; set; }
    public int TotalInvoices { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AverageOrderValue { get; set; }
    public Dictionary<string, int> OrdersByStatus { get; set; } = new();
    public Dictionary<string, int> OrdersByRegion { get; set; } = new();
    public SimulatorStatusDto? SimulatorStatus { get; set; }
}
