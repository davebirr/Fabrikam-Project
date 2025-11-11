using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.DTOs.Customers;
using FabrikamContracts.Enums;
using Microsoft.AspNetCore.Authorization;

namespace FabrikamApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "ApiAccess")] // SECURITY: Environment-aware authentication for all customer endpoints
public class CustomersController : ControllerBase
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<CustomersController> _logger;

    public CustomersController(FabrikamIdentityDbContext context, ILogger<CustomersController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all customers with optional filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CustomerListItemDto>>> GetCustomers(
        string? region = null,
        int page = 1,
        int pageSize = 20)
    {
        try
        {
            var query = _context.Customers.AsQueryable();

            // Apply region filter
            if (!string.IsNullOrEmpty(region))
            {
                query = query.Where(c => c.Region == region);
            }

            // Get total count for pagination
            var totalCount = await query.CountAsync();

            // Apply pagination
            var customers = await query
                .OrderBy(c => c.LastName)
                .ThenBy(c => c.FirstName)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new CustomerListItemDto
                {
                    Id = c.Id,
                    Name = $"{c.FirstName} {c.LastName}",
                    Email = c.Email!,
                    Phone = c.Phone!,
                    City = c.City!,
                    State = c.State!,
                    Region = c.Region!,
                    CreatedDate = c.CreatedDate,
                    OrderCount = c.Orders.Count(),
                    TotalSpent = c.Orders.Sum(o => o.Total)
                })
                .ToListAsync();

            // Add total count to response headers
            Response.Headers.Append("X-Total-Count", totalCount.ToString());

            return Ok(customers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving customers");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get a specific customer by ID with detailed information
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<object>> GetCustomer(int id)
    {
        try
        {
            var customer = await _context.Customers
                .Include(c => c.Orders)
                    .ThenInclude(o => o.OrderItems)
                        .ThenInclude(oi => oi.Product)
                .Include(c => c.SupportTickets)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (customer == null)
            {
                return NotFound($"Customer with ID {id} not found");
            }

            var result = new
            {
                customer.Id,
                Name = $"{customer.FirstName} {customer.LastName}",
                customer.Email,
                customer.Phone,
                Address = new
                {
                    customer.Address,
                    customer.City,
                    customer.State,
                    customer.ZipCode
                },
                customer.Region,
                customer.CreatedDate,
                OrderSummary = new
                {
                    TotalOrders = customer.Orders.Count,
                    TotalSpent = customer.Orders.Sum(o => o.Total),
                    LastOrderDate = customer.Orders.Any() ? customer.Orders.Max(o => o.OrderDate) : (DateTime?)null
                },
                RecentOrders = customer.Orders
                    .OrderByDescending(o => o.OrderDate)
                    .Take(5)
                    .Select(o => new
                    {
                        o.Id,
                        o.OrderNumber,
                        Status = o.Status.ToString(),
                        o.OrderDate,
                        o.Total,
                        ItemCount = o.OrderItems.Count
                    }),
                SupportTicketSummary = new
                {
                    TotalTickets = customer.SupportTickets.Count,
                    OpenTickets = customer.SupportTickets.Count(t => t.Status == TicketStatus.Open),
                    RecentTickets = customer.SupportTickets
                        .OrderByDescending(t => t.CreatedDate)
                        .Take(3)
                        .Select(t => new
                        {
                            t.Id,
                            t.Subject,
                            Status = t.Status.ToString(),
                            Priority = t.Priority.ToString(),
                            t.CreatedDate
                        })
                }
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving customer {CustomerId}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get customer analytics and summary data
    /// </summary>
    [HttpGet("analytics")]
    public async Task<ActionResult<CustomerAnalyticsDto>> GetCustomersAnalytics(
        string? region = null,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        try
        {
            var query = _context.Customers.AsQueryable();

            // Apply region filter
            if (!string.IsNullOrEmpty(region))
            {
                query = query.Where(c => c.Region == region);
            }

            // Apply date filters
            if (startDate.HasValue)
            {
                query = query.Where(c => c.CreatedDate >= startDate.Value);
            }
            if (endDate.HasValue)
            {
                query = query.Where(c => c.CreatedDate <= endDate.Value);
            }

            var customers = await query
                .Include(c => c.Orders)
                .ToListAsync();

            // Calculate active customers (those with orders)
            var activeCustomers = customers.Count(c => c.Orders.Any());

            var analytics = new CustomerAnalyticsDto
            {
                TotalCustomers = customers.Count,
                ActiveCustomers = activeCustomers,
                TotalRevenue = customers.SelectMany(c => c.Orders).Sum(o => o.Total),
                AverageOrderValue = customers.SelectMany(c => c.Orders).Any() 
                    ? customers.SelectMany(c => c.Orders).Average(o => o.Total) 
                    : 0,
                RegionalBreakdown = customers
                    .GroupBy(c => c.Region ?? "Unknown")
                    .Select(g => new CustomerRegionalBreakdownDto
                    {
                        Region = g.Key,
                        CustomerCount = g.Count(),
                        Revenue = g.SelectMany(c => c.Orders).Sum(o => o.Total)
                    })
                    .OrderByDescending(x => x.Revenue)
                    .ToList(),
                TopCustomers = customers
                    .Select(c => new TopCustomerDto
                    {
                        Id = c.Id,
                        Name = $"{c.FirstName} {c.LastName}",
                        Email = c.Email,
                        Region = c.Region ?? "Unknown",
                        TotalSpent = c.Orders.Sum(o => o.Total),
                        OrderCount = c.Orders.Count
                    })
                    .Where(c => c.TotalSpent > 0)
                    .OrderByDescending(c => c.TotalSpent)
                    .Take(10)
                    .ToList()
            };

            return Ok(analytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving customer analytics");
            return StatusCode(500, "Internal server error");
        }
    }
}