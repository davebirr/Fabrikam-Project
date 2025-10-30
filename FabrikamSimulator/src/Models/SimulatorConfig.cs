namespace FabrikamSimulator.Models;

public class SimulatorConfig
{
    public OrderProgressionConfig OrderProgression { get; set; } = new();
    public OrderGeneratorConfig OrderGenerator { get; set; } = new();
    public TicketGeneratorConfig TicketGenerator { get; set; } = new();
}

public class OrderProgressionConfig
{
    public bool Enabled { get; set; } = true;
    public int IntervalMinutes { get; set; } = 5;
    public int PendingToProductionDays { get; set; } = 3;
    public int ProductionToShippedDays { get; set; } = 30;
    public int ShippedToDeliveredDays { get; set; } = 10;
    public int RandomVariationDays { get; set; } = 2;
    public bool BlockProgressionWithOpenTickets { get; set; } = true;
}

public class OrderGeneratorConfig
{
    public bool Enabled { get; set; } = true;
    public int IntervalMinutes { get; set; } = 60;
    public int MinOrdersPerInterval { get; set; } = 1;
    public int MaxOrdersPerInterval { get; set; } = 3;
}

public class TicketGeneratorConfig
{
    public bool Enabled { get; set; } = true;
    public int IntervalMinutes { get; set; } = 60;
    public int MinTicketsPerInterval { get; set; } = 1;
    public int MaxTicketsPerInterval { get; set; } = 2;
}

public class SimulatorStatus
{
    public WorkerStatus OrderProgression { get; set; } = new();
    public WorkerStatus OrderGenerator { get; set; } = new();
    public WorkerStatus TicketGenerator { get; set; } = new();
}

public class WorkerStatus
{
    public bool Enabled { get; set; }
    public DateTime? LastRun { get; set; }
    public DateTime? NextRun { get; set; }
    public int RunCount { get; set; }
    public string? LastError { get; set; }
}
