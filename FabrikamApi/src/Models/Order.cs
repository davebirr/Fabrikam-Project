using System.ComponentModel.DataAnnotations;
using FabrikamContracts.Enums;

namespace FabrikamApi.Models;

public class Order
{
    public int Id { get; set; }
    
    [Required]
    public int CustomerId { get; set; }
    
    [Required]
    [StringLength(20)]
    public string OrderNumber { get; set; } = string.Empty;
    
    [Required]
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    
    [Required]
    public DateTime OrderDate { get; set; } = DateTime.UtcNow;
    
    public DateTime? ShippedDate { get; set; }
    
    public DateTime? DeliveredDate { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal Subtotal { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal Tax { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal Shipping { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal Total { get; set; }
    
    [StringLength(200)]
    public string? ShippingAddress { get; set; }
    
    [StringLength(100)]
    public string? ShippingCity { get; set; }
    
    [StringLength(10)]
    public string? ShippingState { get; set; }
    
    [StringLength(20)]
    public string? ShippingZipCode { get; set; }
    
    [StringLength(50)]
    public string? Region { get; set; }
    
    [StringLength(500)]
    public string? Notes { get; set; }
    
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Customer Customer { get; set; } = null!;
    public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
}

public class OrderItem
{
    public int Id { get; set; }
    
    [Required]
    public int OrderId { get; set; }
    
    [Required]
    public int ProductId { get; set; }
    
    [Required]
    [Range(1, int.MaxValue)]
    public int Quantity { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal UnitPrice { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal LineTotal { get; set; }
    
    [StringLength(200)]
    public string? CustomOptions { get; set; }
    
    // Navigation properties
    public virtual Order Order { get; set; } = null!;
    public virtual Product Product { get; set; } = null!;
}
