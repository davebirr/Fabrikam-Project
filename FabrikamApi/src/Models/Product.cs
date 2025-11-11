using System.ComponentModel.DataAnnotations;
using FabrikamContracts.Enums;

namespace FabrikamApi.Models;

public class Product
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    [Required]
    [StringLength(50)]
    public string ModelNumber { get; set; } = string.Empty;
    
    [Required]
    public ProductCategory Category { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }
    
    [Range(0, int.MaxValue)]
    public int StockQuantity { get; set; }
    
    [Range(0, int.MaxValue)]
    public int ReorderLevel { get; set; } = 10;
    
    [StringLength(50)]
    public string? Dimensions { get; set; }
    
    [Range(0, double.MaxValue)]
    public double? SquareFeet { get; set; }
    
    [Range(1, 10)]
    public int? Bedrooms { get; set; }
    
    [Range(1, 10)]
    public int? Bathrooms { get; set; }
    
    [Range(1, 365)]
    public int DeliveryDaysEstimate { get; set; } = 30;
    
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
}
