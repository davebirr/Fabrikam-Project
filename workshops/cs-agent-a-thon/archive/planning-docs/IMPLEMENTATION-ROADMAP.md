# 🏗️ Implementation Roadmap - Business Simulator Enhancement
**Building on Existing Foundation for cs-agent-a-thon Workshop**

---

## 🎯 **Strategic Overview**

We're building on the excellent foundation already established:
- **Detailed Requirements** - `docs/future-features/BUSINESS-SIMULATOR-REQUIREMENTS.md` (GitHub Issue #9)
- **Data Seeding** - Robust `DataSeedService` with realistic business patterns
- **API Foundation** - Comprehensive REST API with proper DTOs and error handling
- **Testing Framework** - Comprehensive test coverage for validation

**Goal**: Transform from static demonstration → dynamic business simulation for 70-80 workshop participants

---

## 📋 **Phase 1: Foundation (Week 1) - CRITICAL PATH**

### **1.1 Implement Core Business Simulator Service**

**New File**: `FabrikamApi/src/Services/BusinessSimulatorService.cs`

```csharp
using FabrikamApi.Models;
using FabrikamApi.Services;
using Microsoft.Extensions.Options;

namespace FabrikamApi.Services;

public class BusinessSimulatorService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<BusinessSimulatorService> _logger;
    private readonly IOptions<BusinessSimulatorConfig> _config;
    private readonly SemaphoreSlim _simulationSemaphore = new(1, 1);
    
    // Workshop management
    private bool _workshopModeActive = false;
    private DateTime _lastOrderGenerated = DateTime.MinValue;
    private DateTime _lastTicketGenerated = DateTime.MinValue;
    
    public BusinessSimulatorService(
        IServiceScopeFactory scopeFactory,
        ILogger<BusinessSimulatorService> logger,
        IOptions<BusinessSimulatorConfig> config)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _config = config;
    }
    
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Business Simulator Service started");
        
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await _simulationSemaphore.WaitAsync(stoppingToken);
                
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<FabrikamDbContext>();
                
                // Generate orders based on workshop vs normal mode
                if (ShouldGenerateOrder())
                {
                    await GenerateRealisticOrderAsync(context);
                    _lastOrderGenerated = DateTime.UtcNow;
                }
                
                // Generate support tickets
                if (ShouldGenerateTicket())
                {
                    await GenerateRealisticTicketAsync(context);
                    _lastTicketGenerated = DateTime.UtcNow;
                }
                
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in business simulation cycle");
            }
            finally
            {
                _simulationSemaphore.Release();
            }
            
            // Workshop mode: faster cycles (2-3 minutes)
            // Normal mode: realistic cycles (15-30 minutes)
            var delay = _workshopModeActive ? 
                TimeSpan.FromMinutes(Random.Shared.Next(2, 4)) :
                TimeSpan.FromMinutes(Random.Shared.Next(15, 31));
                
            await Task.Delay(delay, stoppingToken);
        }
    }
    
    private bool ShouldGenerateOrder()
    {
        if (_workshopModeActive)
        {
            // Workshop: 1 order every 3-5 minutes average
            return DateTime.UtcNow - _lastOrderGenerated > TimeSpan.FromMinutes(3);
        }
        
        // Normal: 6-7 orders per business day (every 1-2 hours during business hours)
        return DateTime.UtcNow - _lastOrderGenerated > TimeSpan.FromHours(1) &&
               DateTime.UtcNow.Hour >= 8 && DateTime.UtcNow.Hour <= 17;
    }
    
    private bool ShouldGenerateTicket()
    {
        if (_workshopModeActive)
        {
            // Workshop: More frequent tickets for participant engagement
            return DateTime.UtcNow - _lastTicketGenerated > TimeSpan.FromMinutes(5);
        }
        
        // Normal: 1-2 tickets per 10 orders (realistic business rate)
        return DateTime.UtcNow - _lastTicketGenerated > TimeSpan.FromMinutes(30);
    }
    
    // Public methods for workshop control
    public async Task StartWorkshopModeAsync()
    {
        _workshopModeActive = true;
        _logger.LogInformation("Workshop mode activated - increased simulation rate");
    }
    
    public async Task StopWorkshopModeAsync()
    {
        _workshopModeActive = false;
        _logger.LogInformation("Workshop mode deactivated - normal simulation rate");
    }
}
```

### **1.2 Order Generation Engine**

**New File**: `FabrikamApi/src/Services/OrderGenerationEngine.cs`

```csharp
using FabrikamApi.Models;
using FabrikamApi.Data;
using Microsoft.EntityFrameworkCore;

namespace FabrikamApi.Services;

public class OrderGenerationEngine
{
    private readonly FabrikamDbContext _context;
    private readonly ILogger<OrderGenerationEngine> _logger;
    private readonly Random _random = new();
    
    // Regional preferences (from existing requirements doc)
    private readonly Dictionary<string, RegionalPreferences> _regionalPreferences = new()
    {
        ["Midwest"] = new RegionalPreferences
        {
            States = ["IL", "OH", "MI", "IN", "WI"],
            MarketShare = 0.25m,
            AvgOrderValue = 195000,
            PreferredProducts = ["FamilyHaven", "CozyCotagge"],
            GrowthRate = 1.05m
        },
        ["Southeast"] = new RegionalPreferences
        {
            States = ["FL", "GA", "NC", "SC", "TN"],
            MarketShare = 0.30m,
            AvgOrderValue = 185000,
            PreferredProducts = ["BackyardStudio", "RetailFlex"],
            GrowthRate = 1.12m
        },
        // Add other regions from requirements doc...
    };
    
    public OrderGenerationEngine(FabrikamDbContext context, ILogger<OrderGenerationEngine> logger)
    {
        _context = context;
        _logger = logger;
    }
    
    public async Task<Order> GenerateRealisticOrderAsync()
    {
        try
        {
            // 1. Select or create customer (70% new, 20% existing, 10% referral)
            var customer = await SelectOrCreateCustomerAsync();
            
            // 2. Determine regional preferences
            var region = GetCustomerRegion(customer);
            var preferences = _regionalPreferences[region];
            
            // 3. Select products based on regional preferences
            var products = await _context.Products.ToListAsync();
            var primaryProduct = SelectProductByPreferences(products, preferences);
            
            // 4. Generate realistic order
            var order = new Order
            {
                CustomerId = customer.Id,
                OrderNumber = GenerateOrderNumber(),
                Status = OrderStatus.Pending,
                OrderDate = DateTime.UtcNow,
                ShippingAddress = customer.Address,
                ShippingCity = customer.City,
                ShippingState = customer.State,
                ShippingZipCode = customer.ZipCode,
                Region = region,
                LastUpdated = DateTime.UtcNow,
                OrderItems = new List<OrderItem>()
            };
            
            // Add primary product
            var orderItem = new OrderItem
            {
                ProductId = primaryProduct.Id,
                Quantity = 1,
                UnitPrice = primaryProduct.Price,
                LineTotal = primaryProduct.Price
            };
            order.OrderItems.Add(orderItem);
            
            // Add components based on regional preferences (30-45% attach rate)
            await AddComponentsToOrderAsync(order, preferences);
            
            // Calculate totals
            CalculateOrderTotals(order);
            
            _context.Orders.Add(order);
            
            _logger.LogInformation("Generated realistic order {OrderNumber} for customer {CustomerName} in {Region}", 
                order.OrderNumber, $"{customer.FirstName} {customer.LastName}", region);
            
            return order;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating realistic order");
            throw;
        }
    }
    
    private async Task<Customer> SelectOrCreateCustomerAsync()
    {
        var customerType = _random.NextDouble();
        
        if (customerType <= 0.70) // 70% new customers
        {
            return await CreateNewCustomerAsync();
        }
        else if (customerType <= 0.90) // 20% existing customers
        {
            var existingCustomers = await _context.Customers.ToListAsync();
            return existingCustomers[_random.Next(existingCustomers.Count)];
        }
        else // 10% referral customers
        {
            return await CreateReferralCustomerAsync();
        }
    }
    
    private async Task<Customer> CreateNewCustomerAsync()
    {
        // Generate realistic customer data
        var firstNames = new[] { "John", "Sarah", "Michael", "Emily", "David", "Lisa", "Robert", "Ashley" };
        var lastNames = new[] { "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Wilson" };
        var companies = new[] { "ABC Construction", "Sunrise Developments", "Mountain View Builders", null, null, null }; // 50% business customers
        
        var region = SelectRandomRegion();
        var state = _regionalPreferences[region].States[_random.Next(_regionalPreferences[region].States.Length)];
        
        var customer = new Customer
        {
            FirstName = firstNames[_random.Next(firstNames.Length)],
            LastName = lastNames[_random.Next(lastNames.Length)],
            CompanyName = companies[_random.Next(companies.Length)],
            Email = $"customer{_random.Next(1000, 9999)}@email.com",
            Phone = $"({_random.Next(200, 999)}) {_random.Next(200, 999)}-{_random.Next(1000, 9999)}",
            Address = $"{_random.Next(100, 9999)} {new[] { "Main St", "Oak Ave", "Pine Rd", "Cedar Ln" }[_random.Next(4)]}",
            City = GetRandomCityForState(state),
            State = state,
            ZipCode = _random.Next(10000, 99999).ToString(),
            Region = region,
            CustomerType = string.IsNullOrEmpty(companies[companies.Length - 1]) ? CustomerType.Individual : CustomerType.Business,
            CreatedDate = DateTime.UtcNow
        };
        
        _context.Customers.Add(customer);
        return customer;
    }
    
    private string GenerateOrderNumber()
    {
        var date = DateTime.UtcNow;
        var sequence = _random.Next(1000, 9999);
        return $"ORD{date:yyyyMMdd}{sequence}";
    }
    
    // Helper methods for realistic data generation...
    private string SelectRandomRegion()
    {
        var regions = _regionalPreferences.Keys.ToArray();
        var weights = _regionalPreferences.Values.Select(r => (double)r.MarketShare).ToArray();
        
        // Weighted random selection
        var totalWeight = weights.Sum();
        var randomValue = _random.NextDouble() * totalWeight;
        
        double currentWeight = 0;
        for (int i = 0; i < regions.Length; i++)
        {
            currentWeight += weights[i];
            if (randomValue <= currentWeight)
                return regions[i];
        }
        
        return regions[0]; // Fallback
    }
}

public class RegionalPreferences
{
    public string[] States { get; set; } = Array.Empty<string>();
    public decimal MarketShare { get; set; }
    public decimal AvgOrderValue { get; set; }
    public string[] PreferredProducts { get; set; } = Array.Empty<string>();
    public decimal GrowthRate { get; set; }
}
```

### **1.3 Configuration System**

**New File**: `FabrikamApi/src/Configuration/BusinessSimulatorConfig.cs`

```csharp
namespace FabrikamApi.Configuration;

public class BusinessSimulatorConfig
{
    public const string SectionName = "BusinessSimulator";
    
    public bool Enabled { get; set; } = false;
    public WorkshopModeConfig WorkshopMode { get; set; } = new();
    public NormalModeConfig NormalMode { get; set; } = new();
    public WarrantyDepartmentConfig WarrantyDepartment { get; set; } = new();
}

public class WorkshopModeConfig
{
    public bool Enabled { get; set; } = false;
    public int OrderGenerationIntervalMinutes { get; set; } = 3;
    public int TicketGenerationIntervalMinutes { get; set; } = 5;
    public int MaxConcurrentTickets { get; set; } = 15;
    public int ParticipantCapacity { get; set; } = 80;
    public bool AutoScaleEnabled { get; set; } = true;
}

public class NormalModeConfig
{
    public int OrderGenerationIntervalMinutes { get; set; } = 240; // 4 hours
    public int TicketGenerationIntervalMinutes { get; set; } = 30;
    public decimal TicketProbabilityPerOrder { get; set; } = 0.15m; // 15% of orders generate tickets
}

public class WarrantyDepartmentConfig
{
    public bool Enabled { get; set; } = true;
    public decimal TicketProbability { get; set; } = 0.15m;
    public int ResponseTimeTargetHours { get; set; } = 2;
    public int EscalationThresholdHours { get; set; } = 4;
}
```

### **1.4 Workshop Management API**

**New File**: `FabrikamApi/src/Controllers/WorkshopController.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using FabrikamApi.Services;

namespace FabrikamApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WorkshopController : ControllerBase
{
    private readonly BusinessSimulatorService _simulatorService;
    private readonly ILogger<WorkshopController> _logger;
    
    public WorkshopController(
        BusinessSimulatorService simulatorService,
        ILogger<WorkshopController> logger)
    {
        _simulatorService = simulatorService;
        _logger = logger;
    }
    
    [HttpPost("start")]
    public async Task<IActionResult> StartWorkshop([FromBody] StartWorkshopRequest request)
    {
        try
        {
            await _simulatorService.StartWorkshopModeAsync();
            
            _logger.LogInformation("Workshop started with {ParticipantCount} participants", request.ParticipantCount);
            
            return Ok(new
            {
                Status = "Workshop Started",
                ParticipantCount = request.ParticipantCount,
                EstimatedOrderRate = "1 every 3-5 minutes",
                EstimatedTicketRate = "1 every 5-7 minutes",
                Message = "Business simulation accelerated for workshop"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting workshop");
            return StatusCode(500, "Error starting workshop");
        }
    }
    
    [HttpPost("stop")]
    public async Task<IActionResult> StopWorkshop()
    {
        try
        {
            await _simulatorService.StopWorkshopModeAsync();
            
            _logger.LogInformation("Workshop stopped, returning to normal simulation rate");
            
            return Ok(new
            {
                Status = "Workshop Stopped",
                Message = "Business simulation returned to normal rate"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error stopping workshop");
            return StatusCode(500, "Error stopping workshop");
        }
    }
    
    [HttpGet("status")]
    public async Task<IActionResult> GetWorkshopStatus()
    {
        // Return current workshop metrics
        return Ok(new
        {
            IsWorkshopActive = true, // TODO: Get from service
            OrdersGeneratedToday = 42, // TODO: Get from database
            TicketsGeneratedToday = 18, // TODO: Get from database
            ActiveTickets = 12, // TODO: Get from database
            LastActivity = DateTime.UtcNow.AddMinutes(-3)
        });
    }
}

public class StartWorkshopRequest
{
    public int ParticipantCount { get; set; }
    public string WorkshopName { get; set; } = "";
    public TimeSpan Duration { get; set; } = TimeSpan.FromHours(2);
}
```

---

## 🎟️ **Phase 2: Dynamic Support Tickets (Week 2) - CRITICAL PATH**

### **2.1 Warranty Department Simulator**

**New File**: `FabrikamApi/src/Services/WarrantyDepartmentSimulator.cs`

```csharp
using FabrikamApi.Models;
using FabrikamApi.Data;
using Microsoft.EntityFrameworkCore;

namespace FabrikamApi.Services;

public class WarrantyDepartmentSimulator
{
    private readonly FabrikamDbContext _context;
    private readonly ILogger<WarrantyDepartmentSimulator> _logger;
    private readonly Random _random = new();
    
    private readonly WarrantyScenario[] _warrantyScenarios = new[]
    {
        new WarrantyScenario
        {
            Name = "Foundation Settling Issues",
            Description = "Customer reports cracks in foundation after recent settling. Requesting inspection and repair estimate.",
            Probability = 0.12m,
            Priority = Priority.High,
            Category = TicketCategory.WarrantyClaim,
            EstimatedCost = 2500m,
            ResponseRequired = "Schedule structural inspection within 48 hours"
        },
        
        new WarrantyScenario
        {
            Name = "HVAC System Malfunction",
            Description = "Heating/cooling system not working properly. Customer reporting inconsistent temperatures throughout the home.",
            Probability = 0.08m,
            Priority = Priority.High,
            Category = TicketCategory.WarrantyClaim,
            EstimatedCost = 1800m,
            ResponseRequired = "Emergency HVAC technician dispatch"
        },
        
        new WarrantyScenario
        {
            Name = "Electrical Outlet Not Working",
            Description = "Multiple electrical outlets in kitchen not functioning. Possible wiring issue during installation.",
            Probability = 0.15m,
            Priority = Priority.Medium,
            Category = TicketCategory.WarrantyClaim,
            EstimatedCost = 400m,
            ResponseRequired = "Electrician visit within 24 hours"
        },
        
        new WarrantyScenario
        {
            Name = "Paint Touch-up Request",
            Description = "Minor paint chips and scuffs from delivery/installation. Customer requesting warranty touch-up service.",
            Probability = 0.20m,
            Priority = Priority.Low,
            Category = TicketCategory.Maintenance,
            EstimatedCost = 150m,
            ResponseRequired = "Schedule cosmetic repair within 1 week"
        },
        
        new WarrantyScenario
        {
            Name = "Window Seal Failure",
            Description = "Condensation between window panes indicating seal failure. Warranty replacement needed.",
            Probability = 0.10m,
            Priority = Priority.Medium,
            Category = TicketCategory.WarrantyClaim,
            EstimatedCost = 650m,
            ResponseRequired = "Window inspection and replacement quote"
        },
        
        new WarrantyScenario
        {
            Name = "Flooring Gap Issues",
            Description = "Gaps appearing between flooring planks. Possible installation issue or material defect.",
            Probability = 0.18m,
            Priority = Priority.Medium,
            Category = TicketCategory.WarrantyClaim,
            EstimatedCost = 800m,
            ResponseRequired = "Flooring contractor assessment"
        }
    };
    
    public WarrantyDepartmentSimulator(FabrikamDbContext context, ILogger<WarrantyDepartmentSimulator> logger)
    {
        _context = context;
        _logger = logger;
    }
    
    public async Task<SupportTicket?> GenerateWarrantyTicketAsync()
    {
        try
        {
            // Find delivered orders from 30-365 days ago (warranty period)
            var warrantyEligibleOrders = await _context.Orders
                .Include(o => o.Customer)
                .Where(o => o.Status == OrderStatus.Delivered &&
                           o.DeliveryDate.HasValue &&
                           o.DeliveryDate.Value >= DateTime.UtcNow.AddDays(-365) &&
                           o.DeliveryDate.Value <= DateTime.UtcNow.AddDays(-30))
                .ToListAsync();
            
            if (!warrantyEligibleOrders.Any())
            {
                _logger.LogDebug("No warranty-eligible orders found");
                return null;
            }
            
            // Select random order
            var order = warrantyEligibleOrders[_random.Next(warrantyEligibleOrders.Count)];
            
            // Select warranty scenario based on probability
            var scenario = SelectWarrantyScenarioByProbability();
            
            var ticket = new SupportTicket
            {
                TicketNumber = GenerateTicketNumber(),
                CustomerId = order.CustomerId,
                OrderId = order.Id,
                Subject = scenario.Name,
                Description = $"Order #{order.OrderNumber}: {scenario.Description}",
                Status = TicketStatus.Open,
                Priority = scenario.Priority,
                Category = scenario.Category,
                CreatedDate = DateTime.UtcNow,
                LastUpdated = DateTime.UtcNow,
                EstimatedResolutionDate = DateTime.UtcNow.AddDays(GetResolutionDays(scenario.Priority)),
                InternalNotes = $"Warranty claim - Estimated cost: ${scenario.EstimatedCost:N0}. Action: {scenario.ResponseRequired}"
            };
            
            _context.SupportTickets.Add(ticket);
            
            _logger.LogInformation("Generated warranty ticket {TicketNumber} for order {OrderNumber}: {Subject}",
                ticket.TicketNumber, order.OrderNumber, ticket.Subject);
            
            return ticket;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating warranty ticket");
            return null;
        }
    }
    
    private WarrantyScenario SelectWarrantyScenarioByProbability()
    {
        var totalProbability = _warrantyScenarios.Sum(s => s.Probability);
        var randomValue = (decimal)_random.NextDouble() * totalProbability;
        
        decimal currentProbability = 0;
        foreach (var scenario in _warrantyScenarios)
        {
            currentProbability += scenario.Probability;
            if (randomValue <= currentProbability)
                return scenario;
        }
        
        return _warrantyScenarios[0]; // Fallback
    }
    
    private string GenerateTicketNumber()
    {
        var date = DateTime.UtcNow;
        var sequence = _random.Next(1000, 9999);
        return $"WTY{date:yyyyMMdd}{sequence}";
    }
    
    private int GetResolutionDays(Priority priority)
    {
        return priority switch
        {
            Priority.Critical => 1,
            Priority.High => 2,
            Priority.Medium => 5,
            Priority.Low => 7,
            _ => 3
        };
    }
}

public class WarrantyScenario
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public decimal Probability { get; set; }
    public Priority Priority { get; set; }
    public TicketCategory Category { get; set; }
    public decimal EstimatedCost { get; set; }
    public string ResponseRequired { get; set; } = "";
}
```

### **2.2 Enhanced Ticket Generation**

**Update**: `FabrikamApi/src/Services/BusinessSimulatorService.cs` (add to existing file)

```csharp
// Add to BusinessSimulatorService class

private readonly WarrantyDepartmentSimulator _warrantySimulator;
private readonly CustomerServiceScenarioEngine _customerServiceEngine;

private async Task GenerateRealisticTicketAsync(FabrikamDbContext context)
{
    try
    {
        SupportTicket? ticket = null;
        
        // 30% chance of warranty ticket, 70% general customer service
        if (_random.NextDouble() <= 0.30)
        {
            ticket = await _warrantySimulator.GenerateWarrantyTicketAsync();
        }
        else
        {
            ticket = await _customerServiceEngine.GenerateCustomerServiceTicketAsync();
        }
        
        if (ticket != null)
        {
            _logger.LogInformation("Generated support ticket {TicketNumber}: {Subject}",
                ticket.TicketNumber, ticket.Subject);
        }
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error generating realistic ticket");
    }
}
```

---

## 🚀 **Phase 3: Service Registration & Integration (Week 2)**

### **3.1 Update Program.cs**

**Update**: `FabrikamApi/src/Program.cs`

```csharp
// Add to existing Program.cs

// Configuration
builder.Services.Configure<BusinessSimulatorConfig>(
    builder.Configuration.GetSection(BusinessSimulatorConfig.SectionName));

// Register new services
builder.Services.AddScoped<OrderGenerationEngine>();
builder.Services.AddScoped<WarrantyDepartmentSimulator>();
builder.Services.AddScoped<CustomerServiceScenarioEngine>();

// Register background service
builder.Services.AddHostedService<BusinessSimulatorService>();

// Add workshop controller
builder.Services.AddControllers(); // This should already exist
```

### **3.2 Update appsettings.json**

**Update**: `FabrikamApi/src/appsettings.json`

```json
{
  "BusinessSimulator": {
    "Enabled": true,
    "WorkshopMode": {
      "Enabled": false,
      "OrderGenerationIntervalMinutes": 3,
      "TicketGenerationIntervalMinutes": 5,
      "MaxConcurrentTickets": 15,
      "ParticipantCapacity": 80,
      "AutoScaleEnabled": true
    },
    "NormalMode": {
      "OrderGenerationIntervalMinutes": 240,
      "TicketGenerationIntervalMinutes": 30,
      "TicketProbabilityPerOrder": 0.15
    },
    "WarrantyDepartment": {
      "Enabled": true,
      "TicketProbability": 0.15,
      "ResponseTimeTargetHours": 2,
      "EscalationThresholdHours": 4
    }
  }
}
```

---

## 🧪 **Phase 4: Testing & Validation (Week 3)**

### **4.1 Unit Tests for Simulator**

**New File**: `FabrikamTests/Unit/Services/BusinessSimulatorServiceTests.cs`

```csharp
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using FabrikamApi.Services;
using FabrikamApi.Configuration;
using Xunit;

namespace FabrikamTests.Unit.Services;

public class BusinessSimulatorServiceTests
{
    private readonly Mock<IServiceScopeFactory> _mockScopeFactory;
    private readonly Mock<ILogger<BusinessSimulatorService>> _mockLogger;
    private readonly BusinessSimulatorConfig _config;
    
    public BusinessSimulatorServiceTests()
    {
        _mockScopeFactory = new Mock<IServiceScopeFactory>();
        _mockLogger = new Mock<ILogger<BusinessSimulatorService>>();
        _config = new BusinessSimulatorConfig { Enabled = true };
    }
    
    [Fact]
    public async Task StartWorkshopModeAsync_ShouldActivateWorkshopMode()
    {
        // Arrange
        var options = Options.Create(_config);
        var service = new BusinessSimulatorService(_mockScopeFactory.Object, _mockLogger.Object, options);
        
        // Act
        await service.StartWorkshopModeAsync();
        
        // Assert
        // TODO: Add assertions to verify workshop mode is active
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Information,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Workshop mode activated")),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
            Times.Once);
    }
}
```

### **4.2 Integration Tests**

**New File**: `FabrikamTests/Integration/WorkshopIntegrationTests.cs`

```csharp
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using System.Net.Http.Json;
using Xunit;
using FabrikamApi;

namespace FabrikamTests.Integration;

public class WorkshopIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;
    
    public WorkshopIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
    }
    
    [Fact]
    public async Task StartWorkshop_ShouldReturnSuccess()
    {
        // Arrange
        var request = new
        {
            ParticipantCount = 50,
            WorkshopName = "Test Workshop",
            Duration = TimeSpan.FromHours(2)
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/workshop/start", request);
        
        // Assert
        Assert.True(response.IsSuccessStatusCode);
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Workshop Started", content);
    }
    
    [Fact]
    public async Task GetWorkshopStatus_ShouldReturnStatus()
    {
        // Act
        var response = await _client.GetAsync("/api/workshop/status");
        
        // Assert
        Assert.True(response.IsSuccessStatusCode);
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("OrdersGeneratedToday", content);
    }
}
```

---

## 📊 **Phase 5: Documentation & Workshop Integration (Week 4)**

### **5.1 Update Workshop Documentation**

**Update**: `workshops/cs-agent-a-thon/README.md` (add section)

```markdown
## 🔄 **Live Business Simulation**

Your workshop includes a **real-time business simulator** that creates authentic scenarios:

### **What to Expect**
- **Fresh Orders**: New customer orders appear every 3-5 minutes
- **Support Tickets**: Customer service issues arrive throughout the session  
- **Warranty Claims**: Post-delivery issues requiring immediate attention
- **Realistic Patterns**: Seasonal trends, regional preferences, and customer behaviors

### **For Participants**
The simulator ensures you always have meaningful scenarios to work with:
- **Customer Service Agents**: Active ticket queue with varied priorities
- **Sales Intelligence**: Live order data for trend analysis  
- **Executive Assistants**: Real-time business operations to monitor

### **For Facilitators**
Control the simulation to enhance learning:
```bash
# Start workshop mode (accelerated simulation)
curl -X POST https://your-api/api/workshop/start \
  -H "Content-Type: application/json" \
  -d '{"participantCount": 75, "workshopName": "cs-agent-a-thon"}'

# Check simulation status
curl https://your-api/api/workshop/status

# Stop workshop mode (return to normal rate)  
curl -X POST https://your-api/api/workshop/stop
```

This transforms static demos into dynamic, engaging experiences that showcase real AI agent capabilities! 🚀
```

### **5.2 Facilitator Guide**

**New File**: `workshops/cs-agent-a-thon/facilitator/SIMULATION-GUIDE.md`

```markdown
# 🎮 Workshop Simulation Management Guide
**For cs-agent-a-thon Facilitators**

## 🚀 **Pre-Workshop Setup**

### **1. Start Workshop Mode**
15 minutes before participants arrive:

```bash
# Activate accelerated simulation
curl -X POST https://fabrikam-api.azurewebsites.net/api/workshop/start \
  -H "Content-Type: application/json" \
  -d '{
    "participantCount": 75,
    "workshopName": "cs-agent-a-thon-oct2025",
    "duration": "02:00:00"
  }'
```

Expected response:
```json
{
  "status": "Workshop Started",
  "participantCount": 75,
  "estimatedOrderRate": "1 every 3-5 minutes",
  "estimatedTicketRate": "1 every 5-7 minutes",
  "message": "Business simulation accelerated for workshop"
}
```

### **2. Verify Simulation Status**
```bash
curl https://fabrikam-api.azurewebsites.net/api/workshop/status
```

Should show:
- Active ticket queue (5-15 tickets)
- Recent order activity
- Normal simulation timing

## 🎯 **During Workshop Management**

### **Monitoring Simulation Health**
Check every 30 minutes:
```bash
# Quick status check
curl https://fabrikam-api.azurewebsites.net/api/workshop/status | jq .

# Expected healthy metrics:
# - OrdersGeneratedToday: 15-25
# - TicketsGeneratedToday: 20-35  
# - ActiveTickets: 8-15
# - LastActivity: <5 minutes ago
```

### **Troubleshooting Common Issues**

**Problem**: "No new tickets appearing"
```bash
# Check if simulation is still active
curl https://fabrikam-api.azurewebsites.net/api/workshop/status

# If needed, restart workshop mode
curl -X POST https://fabrikam-api.azurewebsites.net/api/workshop/start \
  -H "Content-Type: application/json" \
  -d '{"participantCount": 75}'
```

**Problem**: "Too many tickets, participants overwhelmed"
```bash
# This is handled automatically by the simulator
# It maintains 5-15 active tickets maximum
# New tickets won't generate if queue is full
```

**Problem**: "Participants want more challenging scenarios"
```bash
# Manual scenario triggers (if implemented):
curl -X POST https://fabrikam-api.azurewebsites.net/api/workshop/scenario/rush-orders
curl -X POST https://fabrikam-api.azurewebsites.net/api/workshop/scenario/service-crisis
```

## 🏁 **Post-Workshop Cleanup**

### **1. Stop Workshop Mode**
```bash
curl -X POST https://fabrikam-api.azurewebsites.net/api/workshop/stop
```

### **2. Generate Workshop Report**
```bash
# Get final metrics
curl https://fabrikam-api.azurewebsites.net/api/workshop/status > workshop-metrics.json

# Check total activity
curl https://fabrikam-api.azurewebsites.net/api/orders/analytics?period=today
curl https://fabrikam-api.azurewebsites.net/api/support/analytics?period=today
```

## 📊 **Expected Workshop Metrics**

For a successful 2-hour workshop with 75 participants:

| Metric | Expected Range | Notes |
|--------|----------------|--------|
| **Orders Generated** | 25-40 | 1 every 3-5 minutes |
| **Support Tickets** | 35-50 | 1 every 2-4 minutes |
| **Warranty Claims** | 10-15 | 30% of tickets |
| **Active Tickets** | 8-15 | Auto-maintained queue |
| **Participant Engagement** | 80%+ | Based on agent interactions |

## 🎯 **Success Indicators**

**Healthy Simulation:**
- ✅ Consistent new activity every 3-5 minutes
- ✅ Mix of order types and priorities
- ✅ Ticket queue maintained at 8-15 active
- ✅ No errors in simulation logs

**Participant Engagement:**
- ✅ Agents handling 2-4 tickets per session
- ✅ Mix of beginner and advanced scenarios
- ✅ Real business context driving conversations
- ✅ Workshop objectives met within timeframe

The simulation creates the perfect environment for authentic AI agent development! 🚀
```

---

## ✅ **Implementation Checklist**

### **Week 1: Foundation**
- [ ] Create `BusinessSimulatorService` background service
- [ ] Implement `OrderGenerationEngine` with regional preferences  
- [ ] Build `WarrantyDepartmentSimulator` with realistic scenarios
- [ ] Add `WorkshopController` for session management
- [ ] Configure business simulator settings
- [ ] Test basic order and ticket generation

### **Week 2: Enhancement** 
- [ ] Add `CustomerServiceScenarioEngine` for diverse tickets
- [ ] Implement workshop mode activation/deactivation
- [ ] Build ticket queue management (5-15 active tickets)
- [ ] Add performance optimizations for 70-80 participants
- [ ] Test workshop start/stop functionality
- [ ] Validate realistic business patterns

### **Week 3: Testing**
- [ ] Comprehensive unit tests for all new services
- [ ] Integration tests for workshop management API
- [ ] Load testing with simulated 80 participants
- [ ] Performance monitoring and optimization
- [ ] Error handling and logging validation
- [ ] Documentation updates

### **Week 4: Deployment**
- [ ] Azure deployment with new configuration
- [ ] Workshop facilitator training materials
- [ ] Participant onboarding automation
- [ ] Final performance tuning
- [ ] Backup and recovery procedures
- [ ] Workshop success metrics tracking

---

**This roadmap builds directly on your existing excellent foundation while adding the dynamic, real-time simulation capabilities needed for an engaging 70-80 participant workshop experience! 🎯**