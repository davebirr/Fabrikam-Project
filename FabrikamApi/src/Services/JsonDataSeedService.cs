using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.Enums;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace FabrikamApi.Services;

public class JsonDataSeedService : ISeedService
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<JsonDataSeedService> _logger;
    private readonly IWebHostEnvironment _environment;

    public JsonDataSeedService(FabrikamIdentityDbContext context, ILogger<JsonDataSeedService> logger, IWebHostEnvironment environment)
    {
        _context = context;
        _logger = logger;
        _environment = environment;
    }

    public async Task SeedDataAsync()
    {
        try
        {
            // Ensure database is created
            await _context.Database.EnsureCreatedAsync();

            // Check if data already exists
            if (await _context.Customers.AnyAsync())
            {
                _logger.LogInformation("Database already contains data, skipping seed");
                return;
            }

            _logger.LogInformation("Starting JSON-based database seed...");

            await SeedProductsFromJson();
            await SeedCustomersFromJson();
            await SeedOrdersFromJson();
            await SeedSupportTicketsFromJson();

            _logger.LogInformation("JSON-based database seeding completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during JSON-based database seeding");
            throw;
        }
    }

    public async Task ForceReseedAsync()
    {
        try
        {
            _logger.LogInformation("Starting force re-seed of database...");

            // Clear existing data
            _context.SupportTickets.RemoveRange(_context.SupportTickets);
            _context.Orders.RemoveRange(_context.Orders);
            _context.Customers.RemoveRange(_context.Customers);
            _context.Products.RemoveRange(_context.Products);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Cleared existing data, now re-seeding...");

            await SeedProductsFromJson();
            await SeedCustomersFromJson();
            await SeedOrdersFromJson();
            await SeedSupportTicketsFromJson();

            _logger.LogInformation("Force re-seed completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during force re-seed");
            throw;
        }
    }

    private async Task SeedProductsFromJson()
    {
        var jsonPath = Path.Combine(_environment.ContentRootPath, "Data", "SeedData", "products.json");

        if (!File.Exists(jsonPath))
        {
            _logger.LogWarning("Products JSON file not found at {Path}", jsonPath);
            return;
        }

        var jsonContent = await File.ReadAllTextAsync(jsonPath);
        var productsData = JsonSerializer.Deserialize<List<ProductSeedData>>(jsonContent, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        if (productsData == null)
        {
            _logger.LogWarning("Failed to deserialize products data");
            return;
        }

        var products = productsData.Select(p => new Product
        {
            // Don't set Id - let database auto-generate
            Name = p.Name,
            Description = p.Description,
            ModelNumber = p.ModelNumber,
            Category = Enum.Parse<ProductCategory>(p.Category),
            Price = p.Price,
            StockQuantity = p.StockQuantity,
            ReorderLevel = p.ReorderLevel,
            Dimensions = p.Dimensions,
            SquareFeet = p.SquareFeet,
            Bedrooms = p.Bedrooms,
            Bathrooms = p.Bathrooms,
            DeliveryDaysEstimate = p.DeliveryDaysEstimate,
            IsActive = p.IsActive,
            CreatedDate = DateTime.UtcNow
        }).ToList();

        _context.Products.AddRange(products);
        await _context.SaveChangesAsync(); // Save to generate IDs
        _logger.LogInformation("Added {Count} products from JSON seed data", products.Count);
    }

    private async Task SeedCustomersFromJson()
    {
        var jsonPath = Path.Combine(_environment.ContentRootPath, "Data", "SeedData", "customers.json");

        if (!File.Exists(jsonPath))
        {
            _logger.LogWarning("Customers JSON file not found at {Path}", jsonPath);
            return;
        }

        var jsonContent = await File.ReadAllTextAsync(jsonPath);
        var customersData = JsonSerializer.Deserialize<List<CustomerSeedData>>(jsonContent, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        if (customersData == null)
        {
            _logger.LogWarning("Failed to deserialize customers data");
            return;
        }

        var customers = customersData.Select(c => new Customer
        {
            // Don't set Id - let database auto-generate
            FirstName = c.FirstName,
            LastName = c.LastName,
            Email = c.Email,
            Phone = c.Phone,
            Address = c.Address,
            City = c.City,
            State = c.State,
            ZipCode = c.ZipCode,
            Region = c.Region,
            CreatedDate = c.CreatedDate
        }).ToList();

        _context.Customers.AddRange(customers);
        await _context.SaveChangesAsync(); // Save to generate IDs
        _logger.LogInformation("Added {Count} customers from JSON seed data", customers.Count);
    }

    private async Task SeedOrdersFromJson()
    {
        var jsonPath = Path.Combine(_environment.ContentRootPath, "Data", "SeedData", "orders.json");

        if (!File.Exists(jsonPath))
        {
            _logger.LogWarning("Orders JSON file not found at {Path}", jsonPath);
            return;
        }

        var jsonContent = await File.ReadAllTextAsync(jsonPath);
        var ordersData = JsonSerializer.Deserialize<List<OrderSeedData>>(jsonContent, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        if (ordersData == null)
        {
            _logger.LogWarning("Failed to deserialize orders data");
            return;
        }

        // Get actual customers and products to map IDs
        var customers = await _context.Customers.ToListAsync();
        var products = await _context.Products.ToListAsync();

        var orders = new List<Order>();

        foreach (var orderData in ordersData)
        {
            // Map to actual customer ID (using index based on original seed order)
            var customerIndex = (orderData.CustomerId - 1) % customers.Count;
            var actualCustomerId = customers[customerIndex].Id;

            // Calculate subtotal from items
            var subtotal = orderData.Items.Sum(item => item.UnitPrice * item.Quantity);
            var tax = subtotal * 0.085m; // 8.5% tax
            var shipping = subtotal > 100000 ? 0 : 1000; // Free shipping over $100k
            var total = subtotal + tax + shipping;

            var order = new Order
            {
                // Don't set Id - let database auto-generate
                OrderNumber = orderData.OrderNumber,
                CustomerId = actualCustomerId,
                OrderDate = orderData.OrderDate,
                Status = Enum.Parse<OrderStatus>(orderData.Status),
                ShippingAddress = orderData.ShippingAddress,
                ShippingCity = orderData.ShippingCity,
                ShippingState = orderData.ShippingState,
                ShippingZipCode = orderData.ShippingZip,
                Region = customers[customerIndex].Region,
                Subtotal = subtotal,
                Tax = tax,
                Shipping = shipping,
                Total = total,
                LastUpdated = DateTime.UtcNow
            };

            orders.Add(order);
        }

        _context.Orders.AddRange(orders);
        await _context.SaveChangesAsync(); // Save to generate order IDs

        // Now add order items with correct order and product IDs
        var orderItems = new List<OrderItem>();
        var savedOrders = await _context.Orders.OrderBy(o => o.Id).ToListAsync();

        for (int orderIndex = 0; orderIndex < ordersData.Count && orderIndex < savedOrders.Count; orderIndex++)
        {
            var orderData = ordersData[orderIndex];
            var savedOrder = savedOrders[orderIndex];

            foreach (var itemData in orderData.Items)
            {
                // Map to actual product ID (using index based on original seed order)
                var productIndex = (itemData.ProductId - 1) % products.Count;
                var actualProductId = products[productIndex].Id;

                var orderItem = new OrderItem
                {
                    OrderId = savedOrder.Id,
                    ProductId = actualProductId,
                    Quantity = itemData.Quantity,
                    UnitPrice = itemData.UnitPrice,
                    LineTotal = itemData.UnitPrice * itemData.Quantity
                };
                orderItems.Add(orderItem);
            }
        }

        _context.OrderItems.AddRange(orderItems);
        await _context.SaveChangesAsync();
        _logger.LogInformation("Added {OrderCount} orders with {ItemCount} items from JSON seed data", orders.Count, orderItems.Count);
    }

    private async Task SeedSupportTicketsFromJson()
    {
        var jsonPath = Path.Combine(_environment.ContentRootPath, "Data", "SeedData", "supporttickets.json");

        if (!File.Exists(jsonPath))
        {
            _logger.LogWarning($"Support tickets JSON file not found at {jsonPath}");
            return;
        }

        var json = await File.ReadAllTextAsync(jsonPath);
        var supportTickets = JsonSerializer.Deserialize<List<SupportTicketSeedData>>(json, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        if (supportTickets == null || !supportTickets.Any())
        {
            _logger.LogWarning("No support tickets found in JSON file");
            return;
        }

        // Get actual customers and orders to map IDs
        var customers = await _context.Customers.ToListAsync();
        var orders = await _context.Orders.ToListAsync();

        foreach (var ticketData in supportTickets)
        {
            // Map to actual customer ID (using index based on original seed order)
            var customerIndex = (ticketData.CustomerId - 1) % customers.Count;
            var actualCustomerId = customers[customerIndex].Id;

            // Map to actual order ID if specified
            int? actualOrderId = null;
            if (ticketData.OrderId.HasValue && orders.Any())
            {
                var orderIndex = (ticketData.OrderId.Value - 1) % orders.Count;
                actualOrderId = orders[orderIndex].Id;
            }

            var supportTicket = new SupportTicket
            {
                // Don't set Id - let database auto-generate
                TicketNumber = ticketData.TicketNumber,
                CustomerId = actualCustomerId,
                OrderId = actualOrderId,
                Subject = ticketData.Subject,
                Description = ticketData.Description,
                Status = (TicketStatus)ticketData.Status,
                Priority = (TicketPriority)ticketData.Priority,
                Category = (TicketCategory)ticketData.Category,
                AssignedTo = ticketData.AssignedTo,
                CreatedDate = DateTime.Parse(ticketData.CreatedDate),
                ResolvedDate = !string.IsNullOrEmpty(ticketData.ResolvedDate) ? DateTime.Parse(ticketData.ResolvedDate) : null,
                LastUpdated = DateTime.Parse(ticketData.LastUpdated),
                Region = customers[customerIndex].Region
            };

            _context.SupportTickets.Add(supportTicket);
        }

        await _context.SaveChangesAsync();
        _logger.LogInformation($"Seeded {supportTickets.Count} support tickets");
    }
}

// Data transfer objects for JSON deserialization
public class ProductSeedData
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string ModelNumber { get; set; } = "";
    public string Category { get; set; } = "";
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public int ReorderLevel { get; set; }
    public string? Dimensions { get; set; }
    public int? SquareFeet { get; set; }
    public int? Bedrooms { get; set; }
    public int? Bathrooms { get; set; }
    public int DeliveryDaysEstimate { get; set; }
    public bool IsActive { get; set; }
}

public class CustomerSeedData
{
    public int Id { get; set; }
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public string Email { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Address { get; set; } = "";
    public string City { get; set; } = "";
    public string State { get; set; } = "";
    public string ZipCode { get; set; } = "";
    public string Region { get; set; } = "";
    public DateTime CreatedDate { get; set; }
}

public class OrderSeedData
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = "";
    public int CustomerId { get; set; }
    public DateTime OrderDate { get; set; }
    public string Status { get; set; } = "";
    public string ShippingAddress { get; set; } = "";
    public string ShippingCity { get; set; } = "";
    public string ShippingState { get; set; } = "";
    public string ShippingZip { get; set; } = "";
    public List<OrderItemSeedData> Items { get; set; } = new();
}

public class OrderItemSeedData
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class SupportTicketSeedData
{
    public int Id { get; set; }
    public string TicketNumber { get; set; } = "";
    public int CustomerId { get; set; }
    public int? OrderId { get; set; }
    public string Subject { get; set; } = "";
    public string Description { get; set; } = "";
    public int Status { get; set; }
    public int Priority { get; set; }
    public int Category { get; set; }
    public string? AssignedTo { get; set; }
    public string CreatedDate { get; set; } = "";
    public string? ResolvedDate { get; set; }
    public string LastUpdated { get; set; } = "";
    public string? Region { get; set; }
}
