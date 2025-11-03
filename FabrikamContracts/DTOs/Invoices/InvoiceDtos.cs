namespace FabrikamContracts.DTOs.Invoices;

/// <summary>
/// Invoice information structure for API responses
/// Avoids EF circular references by flattening the navigation properties
/// </summary>
public class InvoiceDto
{
    /// <summary>
    /// Invoice ID
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Auto-generated invoice number (e.g., INV-2025-001234)
    /// </summary>
    public string InvoiceNumber { get; set; } = string.Empty;

    /// <summary>
    /// Vendor/supplier name
    /// </summary>
    public string Vendor { get; set; } = string.Empty;

    /// <summary>
    /// Vendor address
    /// </summary>
    public string? VendorAddress { get; set; }

    /// <summary>
    /// Date invoice was issued
    /// </summary>
    public DateTime InvoiceDate { get; set; }

    /// <summary>
    /// Payment due date
    /// </summary>
    public DateTime DueDate { get; set; }

    /// <summary>
    /// Vendor's invoice number (from their system)
    /// </summary>
    public string? VendorInvoiceNumber { get; set; }

    /// <summary>
    /// Purchase order number
    /// </summary>
    public string? PurchaseOrderNumber { get; set; }

    /// <summary>
    /// Sum of all line items before tax
    /// </summary>
    public decimal SubtotalAmount { get; set; }

    /// <summary>
    /// Tax amount
    /// </summary>
    public decimal TaxAmount { get; set; }

    /// <summary>
    /// Shipping/delivery charges
    /// </summary>
    public decimal ShippingAmount { get; set; }

    /// <summary>
    /// Total amount due
    /// </summary>
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Current status
    /// </summary>
    public string Status { get; set; } = "Pending";

    /// <summary>
    /// Who/what submitted this invoice
    /// </summary>
    public string CreatedBy { get; set; } = "Manual Entry";

    /// <summary>
    /// When invoice was entered into system
    /// </summary>
    public DateTime CreatedDate { get; set; }

    /// <summary>
    /// Processing notes
    /// </summary>
    public string? ProcessingNotes { get; set; }

    /// <summary>
    /// Invoice category
    /// </summary>
    public string? Category { get; set; }

    /// <summary>
    /// Line items (flattened to avoid circular references)
    /// </summary>
    public List<InvoiceLineItemDto> LineItems { get; set; } = new();
}

/// <summary>
/// Invoice line item structure for API responses
/// </summary>
public class InvoiceLineItemDto
{
    /// <summary>
    /// Line item ID
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Description of product/service
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Quantity ordered
    /// </summary>
    public int Quantity { get; set; }

    /// <summary>
    /// Unit of measure
    /// </summary>
    public string? Unit { get; set; }

    /// <summary>
    /// Price per unit
    /// </summary>
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// Total for this line
    /// </summary>
    public decimal Amount { get; set; }

    /// <summary>
    /// Product/part number
    /// </summary>
    public string? ProductCode { get; set; }
}

/// <summary>
/// Request to create a new invoice
/// </summary>
public class CreateInvoiceRequest
{
    public required string Vendor { get; set; }
    public string? VendorAddress { get; set; }
    public DateTime InvoiceDate { get; set; }
    public DateTime DueDate { get; set; }
    public string? VendorInvoiceNumber { get; set; }
    public string? PurchaseOrderNumber { get; set; }
    public decimal SubtotalAmount { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal? ShippingAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public string? ProcessingNotes { get; set; }
    public string? Category { get; set; }
    public string? CreatedBy { get; set; }
    public required List<CreateInvoiceLineItemRequest> LineItems { get; set; }
}

/// <summary>
/// Line item in invoice creation request
/// </summary>
public class CreateInvoiceLineItemRequest
{
    public required string Description { get; set; }
    public int Quantity { get; set; }
    public string? Unit { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal Amount { get; set; }
    public string? ProductCode { get; set; }
}

/// <summary>
/// Request to update an existing invoice
/// </summary>
public class UpdateInvoiceRequest
{
    public string? Status { get; set; }
    public string? ProcessingNotes { get; set; }
}

/// <summary>
/// Invoice statistics response
/// </summary>
public class InvoiceStatsDto
{
    public int TotalInvoices { get; set; }
    public int PendingInvoices { get; set; }
    public int ApprovedInvoices { get; set; }
    public int PaidInvoices { get; set; }
    public int RejectedInvoices { get; set; }
    public int DuplicateInvoices { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal PendingAmount { get; set; }
    public List<VendorStatsDto> TopVendors { get; set; } = new();
}

/// <summary>
/// Vendor statistics
/// </summary>
public class VendorStatsDto
{
    public string Vendor { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal TotalAmount { get; set; }
}
