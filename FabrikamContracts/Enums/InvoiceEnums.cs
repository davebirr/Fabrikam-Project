namespace FabrikamContracts.Enums;

/// <summary>
/// Invoice processing status
/// </summary>
public enum InvoiceStatus
{
    /// <summary>
    /// Newly submitted, awaiting review
    /// </summary>
    Pending = 1,
    
    /// <summary>
    /// Validated and approved for payment
    /// </summary>
    Approved = 2,
    
    /// <summary>
    /// Duplicate invoice detected
    /// </summary>
    Duplicate = 3,
    
    /// <summary>
    /// Failed validation or manually rejected
    /// </summary>
    Rejected = 4,
    
    /// <summary>
    /// Payment has been processed
    /// </summary>
    Paid = 5,
    
    /// <summary>
    /// Cancelled before processing
    /// </summary>
    Cancelled = 6
}
