using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.DTOs.Orders;
using FabrikamContracts.Enums;
using Microsoft.AspNetCore.Authorization;

namespace FabrikamApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "ApiAccess")] // SECURITY: Environment-aware authentication for all order endpoints
public class OrdersController : ControllerBase
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(FabrikamIdentityDbContext context, ILogger<OrdersController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all orders with optional filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrders(
        string? status = null,
        string? region = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        try
        {
            // Allow unlimited results for dashboards/MCP tools
            // pageSize=0 or pageSize > 10000 means "get all records"
            const int MaxPageSize = 10000;
            var isUnlimited = pageSize == 0 || pageSize > MaxPageSize;
            var effectivePageSize = isUnlimited ? int.MaxValue : Math.Min(pageSize, MaxPageSize);

            var query = _context.Orders
                .Include(o => o.Customer)
                .AsQueryable();

            // Apply filters
            if (!string.IsNullOrEmpty(status))
            {
                if (Enum.TryParse<OrderStatus>(status, true, out var statusEnum))
                {
                    query = query.Where(o => o.Status == statusEnum);
                }
            }

            if (!string.IsNullOrEmpty(region))
            {
                query = query.Where(o => o.Customer.Region == region);
            }

            if (fromDate.HasValue)
            {
                query = query.Where(o => o.OrderDate >= fromDate.Value);
            }

            if (toDate.HasValue)
            {
                query = query.Where(o => o.OrderDate <= toDate.Value);
            }

            // Get total count for pagination
            var totalCount = await query.CountAsync();

            // Apply pagination and map to DTO
            var orders = await query
                .OrderByDescending(o => o.OrderDate)
                .Skip((page - 1) * effectivePageSize)
                .Take(effectivePageSize)
                .Select(o => new OrderDto
                {
                    Id = o.Id,
                    OrderNumber = o.OrderNumber,
                    Status = o.Status.ToString(),
                    OrderDate = o.OrderDate,
                    Total = o.Total,
                    Customer = new OrderCustomerDto
                    {
                        Id = o.Customer!.Id,
                        Name = $"{o.Customer.FirstName} {o.Customer.LastName}",
                        Region = o.Customer.Region!
                    }
                })
                .ToListAsync();

            // Add total count to response headers
            Response.Headers.Append("X-Total-Count", totalCount.ToString());

            return Ok(orders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving orders");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get a specific order by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDetailDto>> GetOrder(int id)
    {
        try
        {
            var order = await _context.Orders
                .Include(o => o.Customer)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
            {
                return NotFound($"Order with ID {id} not found");
            }

            var result = new OrderDetailDto
            {
                Id = order.Id,
                OrderNumber = order.OrderNumber,
                Status = order.Status.ToString(),
                OrderDate = order.OrderDate,
                ShippedDate = order.ShippedDate,
                DeliveredDate = order.DeliveredDate,
                Subtotal = order.Subtotal,
                Tax = order.Tax,
                Shipping = order.Shipping,
                Total = order.Total,
                Customer = new OrderCustomerDto
                {
                    Id = order.Customer!.Id,
                    Name = $"{order.Customer.FirstName} {order.Customer.LastName}",
                    Email = order.Customer.Email,
                    Phone = order.Customer.Phone!,
                    Region = order.Customer.Region!
                },
                Items = order.OrderItems!.Select(oi => new OrderItemDetailDto
                {
                    Id = oi.Id,
                    Product = new OrderItemProductDto
                    {
                        Id = oi.Product!.Id,
                        Name = oi.Product.Name,
                        Category = oi.Product.Category.ToString()
                    },
                    Quantity = oi.Quantity,
                    UnitPrice = oi.UnitPrice,
                    LineTotal = oi.LineTotal,
                    CustomOptions = oi.CustomOptions
                }).ToList()
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving order {OrderId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get sales analytics and summary data
    /// </summary>
    [HttpGet("analytics")]
    public async Task<ActionResult<SalesAnalyticsDto>> GetSalesAnalytics(
        DateTime? fromDate = null,
        DateTime? toDate = null)
    {
        try
        {
            // Default to last 30 days if no dates provided
            if (!fromDate.HasValue && !toDate.HasValue)
            {
                fromDate = DateTime.UtcNow.AddDays(-30);
                toDate = DateTime.UtcNow;
            }
            else if (!fromDate.HasValue && toDate.HasValue)
            {
                fromDate = toDate.Value.AddDays(-30);
            }
            else if (!toDate.HasValue)
            {
                toDate = DateTime.UtcNow;
            }

            var query = _context.Orders
                .Include(o => o.Customer)
                .Where(o => o.OrderDate >= fromDate && o.OrderDate <= toDate);

            var orders = await query.ToListAsync();

            var analytics = new SalesAnalyticsDto
            {
                Summary = new SalesSummaryDto
                {
                    TotalOrders = orders.Count,
                    TotalRevenue = orders.Sum(o => o.Total),
                    AverageOrderValue = orders.Any() ? orders.Average(o => o.Total) : 0,
                    Period = new SalesPeriodDto
                    {
                        FromDate = fromDate!.Value.ToString("yyyy-MM-dd"),
                        ToDate = toDate!.Value.ToString("yyyy-MM-dd")
                    }
                },
                ByStatus = orders
                    .GroupBy(o => o.Status)
                    .Select(g => new SalesByStatusDto
                    {
                        Status = g.Key.ToString(),
                        Count = g.Count(),
                        Revenue = g.Sum(o => o.Total)
                    })
                    .OrderByDescending(x => x.Count)
                    .ToList(),
                ByRegion = orders
                    .GroupBy(o => o.Customer.Region)
                    .Select(g => new SalesByRegionDto
                    {
                        Region = g.Key ?? "Unknown",
                        Count = g.Count(),
                        Revenue = g.Sum(o => o.Total)
                    })
                    .OrderByDescending(x => x.Revenue)
                    .ToList(),
                RecentTrends = orders
                    .GroupBy(o => o.OrderDate.Date)
                    .Select(g => new SalesTrendDto
                    {
                        Date = g.Key.ToString("yyyy-MM-dd"),
                        Orders = g.Count(),
                        Revenue = g.Sum(o => o.Total)
                    })
                    .OrderBy(x => x.Date)
                    .ToList()
            };

            return Ok(analytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving sales analytics");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Update order status and related dates (for simulator use)
    /// </summary>
    [HttpPatch("{id}/status")]
    public async Task<ActionResult> UpdateOrderStatus(
        int id,
        [FromBody] UpdateOrderStatusRequest request)
    {
        try
        {
            var order = await _context.Orders.FindAsync(id);

            if (order == null)
            {
                return NotFound($"Order with ID {id} not found");
            }

            // Update status if provided
            if (!string.IsNullOrEmpty(request.Status))
            {
                if (Enum.TryParse<OrderStatus>(request.Status, true, out var statusEnum))
                {
                    order.Status = statusEnum;
                    _logger.LogInformation("Updated order {OrderId} status to {Status}", id, request.Status);
                }
                else
                {
                    return BadRequest($"Invalid status: {request.Status}");
                }
            }

            // Update shipped date if provided
            if (request.ShippedDate.HasValue)
            {
                order.ShippedDate = request.ShippedDate.Value;
                _logger.LogInformation("Updated order {OrderId} shipped date to {ShippedDate}", id, request.ShippedDate);
            }

            // Update delivered date if provided
            if (request.DeliveredDate.HasValue)
            {
                order.DeliveredDate = request.DeliveredDate.Value;
                _logger.LogInformation("Updated order {OrderId} delivered date to {DeliveredDate}", id, request.DeliveredDate);
            }

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = $"Order {order.OrderNumber} updated successfully",
                orderId = id,
                status = order.Status.ToString(),
                shippedDate = order.ShippedDate,
                deliveredDate = order.DeliveredDate
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order {OrderId} status", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Create a new order (for simulator use)
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<OrderDetailDto>> CreateOrder([FromBody] CreateOrderRequest request)
    {
        try
        {
            // Validate customer exists
            var customer = await _context.Customers.FindAsync(request.CustomerId);
            if (customer == null)
            {
                return BadRequest($"Customer with ID {request.CustomerId} not found");
            }

            // Generate order number
            var lastOrder = await _context.Orders
                .OrderByDescending(o => o.Id)
                .FirstOrDefaultAsync();
            
            var year = DateTime.UtcNow.Year;
            var nextNumber = lastOrder != null ? 
                int.Parse(lastOrder.OrderNumber.Split('-').Last()) + 1 : 1;
            var orderNumber = $"FAB-{year}-{nextNumber:D3}";

            // Create order
            var order = new Order
            {
                OrderNumber = orderNumber,
                CustomerId = request.CustomerId,
                OrderDate = request.OrderDate ?? DateTime.UtcNow,
                Status = string.IsNullOrEmpty(request.Status) ? OrderStatus.Pending :
                         Enum.Parse<OrderStatus>(request.Status, true),
                OrderItems = new List<OrderItem>()
            };

            // Add order items if provided
            if (request.Items != null && request.Items.Any())
            {
                foreach (var itemRequest in request.Items)
                {
                    var product = await _context.Products.FindAsync(itemRequest.ProductId);
                    if (product != null)
                    {
                        order.OrderItems.Add(new OrderItem
                        {
                            ProductId = itemRequest.ProductId,
                            Quantity = itemRequest.Quantity,
                            UnitPrice = itemRequest.UnitPrice ?? product.Price
                        });
                    }
                }
            }

            // Calculate total
            order.Total = order.OrderItems.Sum(i => i.Quantity * i.UnitPrice);

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created new order {OrderNumber} for customer {CustomerId}", 
                orderNumber, request.CustomerId);

            // Return created order
            var createdOrder = await _context.Orders
                .Include(o => o.Customer)
                .Include(o => o.OrderItems)
                    .ThenInclude(i => i.Product)
                .FirstAsync(o => o.Id == order.Id);

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, new
            {
                id = createdOrder.Id,
                orderNumber = createdOrder.OrderNumber,
                customerId = createdOrder.CustomerId,
                customer = new
                {
                    id = createdOrder.Customer.Id,
                    name = $"{createdOrder.Customer.FirstName} {createdOrder.Customer.LastName}",
                    email = createdOrder.Customer.Email
                },
                orderDate = createdOrder.OrderDate,
                status = createdOrder.Status.ToString(),
                total = createdOrder.Total,
                items = createdOrder.OrderItems.Select(i => new
                {
                    productId = i.ProductId,
                    productName = i.Product?.Name,
                    quantity = i.Quantity,
                    unitPrice = i.UnitPrice,
                    lineTotal = i.Quantity * i.UnitPrice
                })
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order for customer {CustomerId}", request.CustomerId);
            return StatusCode(500, "Internal server error");
        }
    }
}

// Request models for new endpoints
public record UpdateOrderStatusRequest(
    string? Status = null,
    DateTime? ShippedDate = null,
    DateTime? DeliveredDate = null);

public record CreateOrderRequest(
    int CustomerId,
    DateTime? OrderDate = null,
    string? Status = null,
    List<CreateOrderItemRequest>? Items = null);

public record CreateOrderItemRequest(
    int ProductId,
    int Quantity,
    decimal? UnitPrice = null);