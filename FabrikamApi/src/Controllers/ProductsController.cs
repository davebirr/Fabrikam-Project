using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.DTOs.Products;
using FabrikamContracts.Enums;
using Microsoft.AspNetCore.Authorization;

namespace FabrikamApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "ApiAccess")] // SECURITY: Environment-aware authentication for all product endpoints
public class ProductsController : ControllerBase
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(FabrikamIdentityDbContext context, ILogger<ProductsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all products with optional filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProducts(
        string? category = null,
        bool? inStock = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        int page = 1,
        int pageSize = 20)
    {
        try
        {
            var query = _context.Products.AsQueryable();

            // Apply filters
            if (!string.IsNullOrEmpty(category))
            {
                if (Enum.TryParse<ProductCategory>(category, true, out var categoryEnum))
                {
                    query = query.Where(p => p.Category == categoryEnum);
                }
                else
                {
                    // If category is invalid, return empty result
                    return Ok(new List<object>());
                }
            }

            if (inStock.HasValue)
            {
                query = inStock.Value
                    ? query.Where(p => p.StockQuantity > 0)
                    : query.Where(p => p.StockQuantity == 0);
            }

            if (minPrice.HasValue)
            {
                query = query.Where(p => p.Price >= minPrice.Value);
            }

            if (maxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= maxPrice.Value);
            }

            // Only show active products
            query = query.Where(p => p.IsActive);

            // Get total count for pagination
            var totalCount = await query.CountAsync();

            // Apply pagination
            var products = await query
                .OrderBy(p => p.Category)
                .ThenBy(p => p.Name)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(p => new ProductDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    ModelNumber = p.ModelNumber,
                    Category = p.Category.ToString(),
                    Price = p.Price,
                    StockQuantity = p.StockQuantity,
                    ReorderLevel = p.ReorderLevel,
                    StockStatus = p.StockQuantity > p.ReorderLevel ? "In Stock" :
                                 p.StockQuantity > 0 ? "Low Stock" : "Out of Stock",
                    Dimensions = p.Dimensions,
                    SquareFeet = p.SquareFeet.HasValue ? (int?)p.SquareFeet.Value : null,
                    Bedrooms = p.Bedrooms.HasValue ? (int?)p.Bedrooms.Value : null,
                    Bathrooms = p.Bathrooms.HasValue ? (int?)p.Bathrooms.Value : null,
                    DeliveryDaysEstimate = p.DeliveryDaysEstimate
                })
                .ToListAsync();

            // Add total count to response headers
            Response.Headers.Append("X-Total-Count", totalCount.ToString());

            return Ok(products);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving products");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get a specific product by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<object>> GetProduct(int id)
    {
        try
        {
            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.Id == id && p.IsActive);

            if (product == null)
            {
                return NotFound($"Product with ID {id} not found");
            }

            var result = new
            {
                product.Id,
                product.Name,
                product.Description,
                product.ModelNumber,
                Category = product.Category.ToString(),
                product.Price,
                product.StockQuantity,
                product.ReorderLevel,
                StockStatus = product.StockQuantity > product.ReorderLevel ? "In Stock" :
                             product.StockQuantity > 0 ? "Low Stock" : "Out of Stock",
                product.Dimensions,
                product.SquareFeet,
                product.Bedrooms,
                product.Bathrooms,
                product.DeliveryDaysEstimate,
                product.CreatedDate
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving product {ProductId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get products that are low stock or out of stock
    /// </summary>
    [HttpGet("low-stock")]
    public async Task<ActionResult<IEnumerable<object>>> GetLowStockProducts()
    {
        try
        {
            var lowStockProducts = await _context.Products
                .Where(p => p.IsActive && p.StockQuantity <= p.ReorderLevel)
                .OrderBy(p => p.StockQuantity)
                .ThenBy(p => p.Name)
                .Select(p => new
                {
                    p.Id,
                    p.Name,
                    p.ModelNumber,
                    Category = p.Category.ToString(),
                    p.StockQuantity,
                    p.ReorderLevel,
                    StockStatus = p.StockQuantity == 0 ? "Out of Stock" : "Low Stock",
                    p.Price
                })
                .ToListAsync();

            return Ok(lowStockProducts);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving low stock products");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get inventory summary and analytics
    /// </summary>
    [HttpGet("inventory")]
    public async Task<ActionResult<object>> GetInventory()
    {
        try
        {
            var products = await _context.Products
                .Where(p => p.IsActive)
                .ToListAsync();

            var totalProducts = products.Count;
            var inStockProducts = products.Count(p => p.StockQuantity > p.ReorderLevel);
            var lowStockProducts = products.Count(p => p.StockQuantity > 0 && p.StockQuantity <= p.ReorderLevel);
            var outOfStockProducts = products.Count(p => p.StockQuantity == 0);

            var inventory = new
            {
                Summary = new
                {
                    TotalProducts = totalProducts,
                    InStockProducts = inStockProducts,
                    LowStockProducts = lowStockProducts,
                    OutOfStockProducts = outOfStockProducts,
                    TotalInventoryValue = products.Sum(p => p.Price * p.StockQuantity)
                },
                ByCategory = products
                    .GroupBy(p => p.Category)
                    .Select(g => new
                    {
                        Category = g.Key.ToString(),
                        TotalProducts = g.Count(),
                        InStock = g.Count(p => p.StockQuantity > p.ReorderLevel),
                        LowStock = g.Count(p => p.StockQuantity > 0 && p.StockQuantity <= p.ReorderLevel),
                        OutOfStock = g.Count(p => p.StockQuantity == 0),
                        InventoryValue = g.Sum(p => p.Price * p.StockQuantity)
                    })
                    .OrderBy(x => x.Category),
                LowStockItems = products
                    .Where(p => p.StockQuantity <= p.ReorderLevel)
                    .OrderBy(p => p.StockQuantity)
                    .Select(p => new
                    {
                        p.Id,
                        p.Name,
                        Category = p.Category.ToString(),
                        p.StockQuantity,
                        p.ReorderLevel,
                        Status = p.StockQuantity == 0 ? "Out of Stock" : "Low Stock"
                    })
                    .Take(10) // Top 10 items needing attention
            };

            return Ok(inventory);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory summary");
            return StatusCode(500, "Internal server error");
        }
    }
}