namespace FabrikamContracts.Enums;

/// <summary>
/// Support ticket status enumeration
/// Shared across API, MCP, Simulator, and Dashboard
/// </summary>
public enum TicketStatus
{
    Open = 1,
    InProgress = 2,
    PendingCustomer = 3,
    Resolved = 4,
    Closed = 5,
    Cancelled = 6
}

/// <summary>
/// Support ticket priority enumeration
/// Shared across API, MCP, Simulator, and Dashboard
/// </summary>
public enum TicketPriority
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}

/// <summary>
/// Support ticket category enumeration
/// Shared across API, MCP, Simulator, and Dashboard
/// </summary>
public enum TicketCategory
{
    OrderInquiry = 1,
    DeliveryIssue = 2,
    ProductDefect = 3,
    Installation = 4,
    Billing = 5,
    Technical = 6,
    General = 7,
    Complaint = 8
}
