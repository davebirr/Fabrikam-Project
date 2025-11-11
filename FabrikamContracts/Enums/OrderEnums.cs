namespace FabrikamContracts.Enums;

/// <summary>
/// Order status enumeration
/// Shared across API, MCP, Simulator, and Dashboard
/// </summary>
public enum OrderStatus
{
    Pending = 1,
    Confirmed = 2,
    InProduction = 3,
    ReadyToShip = 4,
    Shipped = 5,
    Delivered = 6,
    Cancelled = 7,
    OnHold = 8
}
