using System.ComponentModel.DataAnnotations;
using FabrikamContracts.Enums;

namespace FabrikamApi.Models;

/// <summary>
/// Represents an invoice received from suppliers, logistics vendors, and service providers
/// </summary>
public class Invoice
{
    public int Id { get; set; }
    
    /// <summary>
    /// Auto-generated invoice number (e.g., INV-2025-001234)
    /// </summary>
    [Required]
    [StringLength(50)]
    public string InvoiceNumber { get; set; } = string.Empty;
    
    /// <summary>
    /// Vendor/supplier name
    /// </summary>
    [Required]
    [StringLength(200)]
    public string Vendor { get; set; } = string.Empty;
    
    /// <summary>
    /// Vendor address for payment processing
    /// </summary>
    [StringLength(500)]
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
    [StringLength(100)]
    public string? VendorInvoiceNumber { get; set; }
    
    /// <summary>
    /// Purchase order number (if applicable)
    /// </summary>
    [StringLength(100)]
    public string? PurchaseOrderNumber { get; set; }
    
    /// <summary>
    /// Sum of all line items before tax
    /// </summary>
    public decimal SubtotalAmount { get; set; }
    
    /// <summary>
    /// Tax amount (typically 8.5% WA sales tax for materials)
    /// </summary>
    public decimal TaxAmount { get; set; }
    
    /// <summary>
    /// Shipping/delivery charges
    /// </summary>
    public decimal ShippingAmount { get; set; }
    
    /// <summary>
    /// Total amount due (subtotal + tax + shipping)
    /// </summary>
    public decimal TotalAmount { get; set; }
    
    /// <summary>
    /// Current status of invoice processing
    /// </summary>
    public InvoiceStatus Status { get; set; } = InvoiceStatus.Pending;
    
    /// <summary>
    /// Who/what submitted this invoice (agent name, user, system)
    /// </summary>
    [StringLength(200)]
    public string CreatedBy { get; set; } = "Manual Entry";
    
    /// <summary>
    /// When invoice was entered into system
    /// </summary>
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    /// <summary>
    /// Notes from automated processing or manual review
    /// </summary>
    [StringLength(2000)]
    public string? ProcessingNotes { get; set; }
    
    /// <summary>
    /// Category of invoice for reporting
    /// </summary>
    [StringLength(100)]
    public string? Category { get; set; }
    
    // Navigation properties
    public virtual ICollection<InvoiceLineItem> LineItems { get; set; } = new List<InvoiceLineItem>();
}

/// <summary>
/// Individual line items on an invoice
/// </summary>
public class InvoiceLineItem
{
    public int Id { get; set; }
    
    public int InvoiceId { get; set; }
    
    /// <summary>
    /// Description of product/service
    /// </summary>
    [Required]
    [StringLength(500)]
    public string Description { get; set; } = string.Empty;
    
    /// <summary>
    /// Quantity ordered
    /// </summary>
    public int Quantity { get; set; }
    
    /// <summary>
    /// Unit of measure (ea, ft, sqft, ton, etc.)
    /// </summary>
    [StringLength(20)]
    public string? Unit { get; set; }
    
    /// <summary>
    /// Price per unit
    /// </summary>
    public decimal UnitPrice { get; set; }
    
    /// <summary>
    /// Total for this line (quantity × unit price)
    /// </summary>
    public decimal Amount { get; set; }
    
    /// <summary>
    /// Product/part number if applicable
    /// </summary>
    [StringLength(100)]
    public string? ProductCode { get; set; }
    
    // Navigation property
    public virtual Invoice Invoice { get; set; } = null!;
}
