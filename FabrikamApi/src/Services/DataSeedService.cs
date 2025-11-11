using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.Enums;
using Microsoft.EntityFrameworkCore;

namespace FabrikamApi.Services;

public class DataSeedService : ISeedService
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<DataSeedService> _logger;

    public DataSeedService(FabrikamIdentityDbContext context, ILogger<DataSeedService> logger)
    {
        _context = context;
        _logger = logger;
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

            _logger.LogInformation("Starting database seed...");

            SeedProducts();
            SeedCustomers();
            await SeedOrders();
            await SeedSupportTickets();

            await _context.SaveChangesAsync();
            _logger.LogInformation("Database seeding completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during database seeding");
            throw;
        }
    }

    public async Task ForceReseedAsync()
    {
        try
        {
            _logger.LogInformation("Starting force re-seed of database...");

            // Clear existing data
            _context.Orders.RemoveRange(_context.Orders);
            _context.Customers.RemoveRange(_context.Customers);
            _context.Products.RemoveRange(_context.Products);
            _context.SupportTickets.RemoveRange(_context.SupportTickets);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Cleared existing data, now re-seeding...");

            SeedProducts();
            SeedCustomers();
            await SeedOrders();
            await SeedSupportTickets();

            await _context.SaveChangesAsync();
            _logger.LogInformation("Force re-seed completed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during force re-seed");
            throw;
        }
    }

    private void SeedProducts()
    {
        var products = new List<Product>
        {
            // ===== SINGLE FAMILY HOMES =====
            
            // Starter Series - First-time buyers
            new Product
            {
                Name = "Cozy Cottage 1200",
                Description = "A charming 1,200 sq ft single-family modular home perfect for first-time buyers. Features open-concept living, energy-efficient windows, and modern finishes.",
                ModelNumber = "CC-1200",
                Category = ProductCategory.SingleFamily,
                Price = 89500,
                StockQuantity = 25,
                ReorderLevel = 5,
                Dimensions = "40x30",
                SquareFeet = 1200,
                Bedrooms = 2,
                Bathrooms = 2,
                DeliveryDaysEstimate = 45,
                IsActive = true
            },
            new Product
            {
                Name = "Urban Studio 950",
                Description = "Compact 950 sq ft modern home optimized for urban lots. Perfect for minimalist living with smart storage solutions.",
                ModelNumber = "US-950",
                Category = ProductCategory.SingleFamily,
                Price = 75000,
                StockQuantity = 30,
                ReorderLevel = 8,
                Dimensions = "38x25",
                SquareFeet = 950,
                Bedrooms = 2,
                Bathrooms = 1,
                DeliveryDaysEstimate = 35,
                IsActive = true
            },
            new Product
            {
                Name = "Starter Haven 1400",
                Description = "Affordable 1,400 sq ft family home with traditional layout. Great first home with room to grow.",
                ModelNumber = "SH-1400",
                Category = ProductCategory.SingleFamily,
                Price = 98000,
                StockQuantity = 20,
                ReorderLevel = 4,
                Dimensions = "40x35",
                SquareFeet = 1400,
                Bedrooms = 3,
                Bathrooms = 2,
                DeliveryDaysEstimate = 50,
                IsActive = true
            },

            // Family Series - Growing families
            new Product
            {
                Name = "Family Haven 1800",
                Description = "Spacious 1,800 sq ft family home with open concept living, large kitchen island, and dedicated kids' playroom.",
                ModelNumber = "FH-1800",
                Category = ProductCategory.SingleFamily,
                Price = 145000,
                StockQuantity = 18,
                ReorderLevel = 3,
                Dimensions = "45x40",
                SquareFeet = 1800,
                Bedrooms = 3,
                Bathrooms = 2,
                DeliveryDaysEstimate = 60,
                IsActive = true
            },
            new Product
            {
                Name = "Suburban Dream 2200",
                Description = "Classic 2,200 sq ft home with formal dining, family room, and master suite. Perfect for suburban neighborhoods.",
                ModelNumber = "SD-2200",
                Category = ProductCategory.SingleFamily,
                Price = 178000,
                StockQuantity = 12,
                ReorderLevel = 3,
                Dimensions = "50x44",
                SquareFeet = 2200,
                Bedrooms = 4,
                Bathrooms = 3,
                DeliveryDaysEstimate = 65,
                IsActive = true
            },
            new Product
            {
                Name = "Ranch Royale 2000",
                Description = "Single-story 2,000 sq ft ranch with wheelchair accessibility and aging-in-place features.",
                ModelNumber = "RR-2000",
                Category = ProductCategory.SingleFamily,
                Price = 165000,
                StockQuantity = 15,
                ReorderLevel = 3,
                Dimensions = "50x40",
                SquareFeet = 2000,
                Bedrooms = 3,
                Bathrooms = 2,
                DeliveryDaysEstimate = 55,
                IsActive = true
            },

            // Executive Series - Luxury homes
            new Product
            {
                Name = "Executive Manor 2500",
                Description = "Luxury 2,500 sq ft executive home with premium finishes, home office, and gourmet kitchen.",
                ModelNumber = "EM-2500",
                Category = ProductCategory.SingleFamily,
                Price = 225000,
                StockQuantity = 8,
                ReorderLevel = 2,
                Dimensions = "50x50",
                SquareFeet = 2500,
                Bedrooms = 4,
                Bathrooms = 3,
                DeliveryDaysEstimate = 75,
                IsActive = true
            },
            new Product
            {
                Name = "Presidential Estate 3200",
                Description = "Premium 3,200 sq ft estate home with grand foyer, chef's kitchen, and luxury master retreat.",
                ModelNumber = "PE-3200",
                Category = ProductCategory.SingleFamily,
                Price = 295000,
                StockQuantity = 5,
                ReorderLevel = 1,
                Dimensions = "60x53",
                SquareFeet = 3200,
                Bedrooms = 5,
                Bathrooms = 4,
                DeliveryDaysEstimate = 90,
                IsActive = true
            },
            new Product
            {
                Name = "Modern Masterpiece 2800",
                Description = "Contemporary 2,800 sq ft home with floor-to-ceiling windows, smart home integration, and energy-efficient design.",
                ModelNumber = "MM-2800",
                Category = ProductCategory.SingleFamily,
                Price = 265000,
                StockQuantity = 6,
                ReorderLevel = 2,
                Dimensions = "56x50",
                SquareFeet = 2800,
                Bedrooms = 4,
                Bathrooms = 3,
                DeliveryDaysEstimate = 80,
                IsActive = true
            },

            // ===== DUPLEX & MULTI-FAMILY =====
            
            new Product
            {
                Name = "Twin Vista Duplex",
                Description = "Modern duplex with two 1,000 sq ft units. Perfect for rental income or multi-generational living.",
                ModelNumber = "TVD-2000",
                Category = ProductCategory.Duplex,
                Price = 175000,
                StockQuantity = 12,
                ReorderLevel = 2,
                Dimensions = "40x50",
                SquareFeet = 2000,
                Bedrooms = 4,
                Bathrooms = 4,
                DeliveryDaysEstimate = 65,
                IsActive = true
            },
            new Product
            {
                Name = "Investor Plus Duplex",
                Description = "High-yield duplex with two 1,200 sq ft units designed for maximum rental income.",
                ModelNumber = "IPD-2400",
                Category = ProductCategory.Duplex,
                Price = 195000,
                StockQuantity = 8,
                ReorderLevel = 2,
                Dimensions = "48x50",
                SquareFeet = 2400,
                Bedrooms = 6,
                Bathrooms = 4,
                DeliveryDaysEstimate = 70,
                IsActive = true
            },
            new Product
            {
                Name = "Tri-Crown Triplex",
                Description = "Premium triplex with three 900 sq ft units. Excellent for urban infill development.",
                ModelNumber = "TCT-2700",
                Category = ProductCategory.Triplex,
                Price = 245000,
                StockQuantity = 4,
                ReorderLevel = 1,
                Dimensions = "45x60",
                SquareFeet = 2700,
                Bedrooms = 9,
                Bathrooms = 6,
                DeliveryDaysEstimate = 85,
                IsActive = true
            },

            // ===== ACCESSORY DWELLING UNITS (ADUs) =====
            
            new Product
            {
                Name = "Backyard Studio 400",
                Description = "Perfect ADU for rental income or home office. Complete with kitchenette and full bath.",
                ModelNumber = "BS-400",
                Category = ProductCategory.Accessory,
                Price = 45000,
                StockQuantity = 35,
                ReorderLevel = 10,
                Dimensions = "20x20",
                SquareFeet = 400,
                Bedrooms = 1,
                Bathrooms = 1,
                DeliveryDaysEstimate = 30,
                IsActive = true
            },
            new Product
            {
                Name = "Terrazia ADU 650",
                Description = "Spacious 650 sq ft accessory unit with full kitchen and separate entrance. Perfect for aging parents.",
                ModelNumber = "TA-650",
                Category = ProductCategory.Accessory,
                Price = 65000,
                StockQuantity = 25,
                ReorderLevel = 8,
                Dimensions = "26x25",
                SquareFeet = 650,
                Bedrooms = 1,
                Bathrooms = 1,
                DeliveryDaysEstimate = 35,
                IsActive = true
            },
            new Product
            {
                Name = "Casita Grande 800",
                Description = "Luxury 800 sq ft guest house with vaulted ceilings and premium finishes.",
                ModelNumber = "CG-800",
                Category = ProductCategory.Accessory,
                Price = 78000,
                StockQuantity = 18,
                ReorderLevel = 5,
                Dimensions = "32x25",
                SquareFeet = 800,
                Bedrooms = 2,
                Bathrooms = 1,
                DeliveryDaysEstimate = 40,
                IsActive = true
            },
            new Product
            {
                Name = "Micro Loft 320",
                Description = "Ultra-compact 320 sq ft ADU perfect for urban lots. Features Murphy bed and efficient design.",
                ModelNumber = "ML-320",
                Category = ProductCategory.Accessory,
                Price = 38000,
                StockQuantity = 40,
                ReorderLevel = 12,
                Dimensions = "16x20",
                SquareFeet = 320,
                Bedrooms = 1,
                Bathrooms = 1,
                DeliveryDaysEstimate = 25,
                IsActive = true
            },

            // ===== COMMERCIAL UNITS =====
            
            new Product
            {
                Name = "Retail Flex 1500",
                Description = "Flexible retail/office space with storefront design and ADA compliance.",
                ModelNumber = "RF-1500",
                Category = ProductCategory.Commercial,
                Price = 125000,
                StockQuantity = 6,
                ReorderLevel = 1,
                Dimensions = "30x50",
                SquareFeet = 1500,
                DeliveryDaysEstimate = 90,
                IsActive = true
            },
            new Product
            {
                Name = "Office Plaza 2000",
                Description = "Professional office building with conference rooms and executive suites.",
                ModelNumber = "OP-2000",
                Category = ProductCategory.Commercial,
                Price = 165000,
                StockQuantity = 4,
                ReorderLevel = 1,
                Dimensions = "40x50",
                SquareFeet = 2000,
                DeliveryDaysEstimate = 95,
                IsActive = true
            },
            new Product
            {
                Name = "Warehouse Pro 3000",
                Description = "Industrial warehouse with loading dock and office space. Perfect for distribution.",
                ModelNumber = "WP-3000",
                Category = ProductCategory.Commercial,
                Price = 185000,
                StockQuantity = 3,
                ReorderLevel = 1,
                Dimensions = "50x60",
                SquareFeet = 3000,
                DeliveryDaysEstimate = 100,
                IsActive = true
            },

            // ===== COMPONENTS & UPGRADES =====
            
            new Product
            {
                Name = "Premium Kitchen Package",
                Description = "Upgraded kitchen with granite countertops, stainless appliances, and custom cabinetry.",
                ModelNumber = "PKP-001",
                Category = ProductCategory.Components,
                Price = 15000,
                StockQuantity = 50,
                ReorderLevel = 15,
                DeliveryDaysEstimate = 14,
                IsActive = true
            },
            new Product
            {
                Name = "Luxury Bath Suite",
                Description = "Spa-like bathroom upgrade with marble tiles, rainfall shower, and dual vanities.",
                ModelNumber = "LBS-001",
                Category = ProductCategory.Components,
                Price = 12000,
                StockQuantity = 35,
                ReorderLevel = 10,
                DeliveryDaysEstimate = 18,
                IsActive = true
            },
            new Product
            {
                Name = "Solar Power System",
                Description = "Complete solar installation with 20-year warranty. 8.5kW system with battery backup.",
                ModelNumber = "SPS-001",
                Category = ProductCategory.Components,
                Price = 25000,
                StockQuantity = 20,
                ReorderLevel = 5,
                DeliveryDaysEstimate = 21,
                IsActive = true
            },
            new Product
            {
                Name = "Smart Home Package",
                Description = "Complete home automation system with security, lighting, and climate control.",
                ModelNumber = "SHP-001",
                Category = ProductCategory.Components,
                Price = 8500,
                StockQuantity = 30,
                ReorderLevel = 8,
                DeliveryDaysEstimate = 10,
                IsActive = true
            },
            new Product
            {
                Name = "Hardwood Flooring Upgrade",
                Description = "Premium engineered hardwood flooring throughout main living areas.",
                ModelNumber = "HFU-001",
                Category = ProductCategory.Components,
                Price = 6500,
                StockQuantity = 45,
                ReorderLevel = 12,
                DeliveryDaysEstimate = 12,
                IsActive = true
            },
            new Product
            {
                Name = "Energy Efficiency Package",
                Description = "Complete energy upgrade with spray foam insulation, LED lighting, and Energy Star appliances.",
                ModelNumber = "EEP-001",
                Category = ProductCategory.Components,
                Price = 9500,
                StockQuantity = 25,
                ReorderLevel = 6,
                DeliveryDaysEstimate = 16,
                IsActive = true
            }
        };

        _context.Products.AddRange(products);
        _logger.LogInformation("Added {Count} products to seed data", products.Count);
    }

    private void SeedCustomers()
    {
        var customers = new List<Customer>
        {
            // ===== YOUNG PROFESSIONALS =====
            
            new Customer
            {
                FirstName = "Sarah",
                LastName = "Johnson",
                Email = "sarah.johnson@email.com",
                Phone = "(555) 123-4567",
                Address = "123 Maple Street",
                City = "Seattle",
                State = "WA",
                ZipCode = "98101",
                Region = "Pacific Northwest"
            },
            new Customer
            {
                FirstName = "Michael",
                LastName = "Chen",
                Email = "michael.chen@email.com",
                Phone = "(555) 234-5678",
                Address = "456 Oak Avenue",
                City = "Portland",
                State = "OR",
                ZipCode = "97201",
                Region = "Pacific Northwest"
            },
            new Customer
            {
                FirstName = "Alex",
                LastName = "Thompson",
                Email = "alex.thompson@techcorp.com",
                Phone = "(555) 456-7890",
                Address = "789 Innovation Drive",
                City = "Austin",
                State = "TX",
                ZipCode = "78701",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Priya",
                LastName = "Patel",
                Email = "priya.patel@startup.io",
                Phone = "(555) 321-7654",
                Address = "2134 Tech Row",
                City = "San Francisco",
                State = "CA",
                ZipCode = "94102",
                Region = "West Coast"
            },
            new Customer
            {
                FirstName = "Jordan",
                LastName = "Kim",
                Email = "jordan.kim@consulting.com",
                Phone = "(555) 654-3210",
                Address = "567 Finance Plaza",
                City = "New York",
                State = "NY",
                ZipCode = "10001",
                Region = "Northeast"
            },

            // ===== GROWING FAMILIES =====
            
            new Customer
            {
                FirstName = "Emily",
                LastName = "Davis",
                Email = "emily.davis@email.com",
                Phone = "(555) 345-6789",
                Address = "789 Pine Road",
                City = "Austin",
                State = "TX",
                ZipCode = "73301",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "David",
                LastName = "Rodriguez",
                Email = "david.rodriguez@email.com",
                Phone = "(555) 456-7890",
                Address = "321 Cedar Lane",
                City = "Denver",
                State = "CO",
                ZipCode = "80201",
                Region = "Mountain West"
            },
            new Customer
            {
                FirstName = "Jennifer",
                LastName = "Wilson",
                Email = "jennifer.wilson@email.com",
                Phone = "(555) 567-8901",
                Address = "654 Birch Court",
                City = "Atlanta",
                State = "GA",
                ZipCode = "30301",
                Region = "Southeast"
            },
            new Customer
            {
                FirstName = "Marcus",
                LastName = "Williams",
                Email = "marcus.williams@family.net",
                Phone = "(555) 432-1098",
                Address = "1456 Suburban Drive",
                City = "Columbus",
                State = "OH",
                ZipCode = "43201",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Amanda",
                LastName = "Foster",
                Email = "amanda.foster@household.com",
                Phone = "(555) 765-4321",
                Address = "2987 Family Circle",
                City = "Charlotte",
                State = "NC",
                ZipCode = "28201",
                Region = "Southeast"
            },

            // ===== EMPTY NESTERS & RETIREES =====
            
            new Customer
            {
                FirstName = "Robert",
                LastName = "Anderson",
                Email = "robert.anderson@email.com",
                Phone = "(555) 678-9012",
                Address = "987 Elm Street",
                City = "Chicago",
                State = "IL",
                ZipCode = "60601",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Margaret",
                LastName = "O'Connor",
                Email = "margaret.oconnor@retirement.net",
                Phone = "(555) 234-9876",
                Address = "3456 Golden Years Boulevard",
                City = "Phoenix",
                State = "AZ",
                ZipCode = "85001",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Charles",
                LastName = "Hoffman",
                Email = "charles.hoffman@leisure.com",
                Phone = "(555) 876-5432",
                Address = "1234 Sunset Lane",
                City = "Sarasota",
                State = "FL",
                ZipCode = "34236",
                Region = "Southeast"
            },
            new Customer
            {
                FirstName = "Dorothy",
                LastName = "Martinez",
                Email = "dorothy.martinez@senior.org",
                Phone = "(555) 345-2109",
                Address = "5678 Retirement Row",
                City = "Tucson",
                State = "AZ",
                ZipCode = "85701",
                Region = "Southwest"
            },

            // ===== REAL ESTATE INVESTORS =====
            
            new Customer
            {
                FirstName = "Lisa",
                LastName = "Thompson",
                Email = "lisa.thompson@email.com",
                Phone = "(555) 789-0123",
                Address = "147 Willow Drive",
                City = "Phoenix",
                State = "AZ",
                ZipCode = "85001",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "James",
                LastName = "Martinez",
                Email = "james.martinez@email.com",
                Phone = "(555) 890-1234",
                Address = "258 Spruce Avenue",
                City = "Miami",
                State = "FL",
                ZipCode = "33101",
                Region = "Southeast"
            },
            new Customer
            {
                FirstName = "Patricia",
                LastName = "White",
                Email = "patricia.white@realtyinvest.com",
                Phone = "(555) 567-2341",
                Address = "4567 Investment Way",
                City = "Las Vegas",
                State = "NV",
                ZipCode = "89101",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Kevin",
                LastName = "Brooks",
                Email = "kevin.brooks@portfoliomgmt.net",
                Phone = "(555) 432-8765",
                Address = "7890 Capital Circle",
                City = "Dallas",
                State = "TX",
                ZipCode = "75201",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Diana",
                LastName = "Chang",
                Email = "diana.chang@propertygroup.com",
                Phone = "(555) 654-0987",
                Address = "3210 Development Drive",
                City = "Atlanta",
                State = "GA",
                ZipCode = "30309",
                Region = "Southeast"
            },

            // ===== BUSINESS OWNERS =====
            
            new Customer
            {
                FirstName = "Thomas",
                LastName = "Campbell",
                Email = "thomas.campbell@bizowner.com",
                Phone = "(555) 123-8765",
                Address = "1111 Commerce Street",
                City = "Indianapolis",
                State = "IN",
                ZipCode = "46201",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Rebecca",
                LastName = "Garcia",
                Email = "rebecca.garcia@entrepreneur.net",
                Phone = "(555) 765-4380",
                Address = "2222 Business Park",
                City = "Tampa",
                State = "FL",
                ZipCode = "33601",
                Region = "Southeast"
            },
            new Customer
            {
                FirstName = "Daniel",
                LastName = "Lee",
                Email = "daniel.lee@smallbiz.com",
                Phone = "(555) 987-6543",
                Address = "3333 Enterprise Lane",
                City = "Nashville",
                State = "TN",
                ZipCode = "37201",
                Region = "Southeast"
            },

            // ===== RURAL & AGRICULTURAL =====
            
            new Customer
            {
                FirstName = "Mary",
                LastName = "Johnson",
                Email = "mary.johnson@ranch.com",
                Phone = "(555) 234-5432",
                Address = "4444 County Road 15",
                City = "Bozeman",
                State = "MT",
                ZipCode = "59715",
                Region = "Mountain West"
            },
            new Customer
            {
                FirstName = "William",
                LastName = "Smith",
                Email = "william.smith@farmland.net",
                Phone = "(555) 876-5439",
                Address = "5555 Agricultural Way",
                City = "Des Moines",
                State = "IA",
                ZipCode = "50301",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Susan",
                LastName = "Brown",
                Email = "susan.brown@rural.org",
                Phone = "(555) 345-7654",
                Address = "6666 Farm to Market Road",
                City = "Waco",
                State = "TX",
                ZipCode = "76701",
                Region = "Southwest"
            },

            // ===== URBAN PROFESSIONALS =====
            
            new Customer
            {
                FirstName = "Christopher",
                LastName = "Taylor",
                Email = "christopher.taylor@citylife.com",
                Phone = "(555) 123-4567",
                Address = "7777 Metropolitan Avenue",
                City = "Boston",
                State = "MA",
                ZipCode = "02101",
                Region = "Northeast"
            },
            new Customer
            {
                FirstName = "Nicole",
                LastName = "Evans",
                Email = "nicole.evans@urbanpro.net",
                Phone = "(555) 987-1234",
                Address = "8888 Downtown Plaza",
                City = "Minneapolis",
                State = "MN",
                ZipCode = "55401",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Anthony",
                LastName = "Miller",
                Email = "anthony.miller@metro.com",
                Phone = "(555) 456-7891",
                Address = "9999 City Center",
                City = "Portland",
                State = "OR",
                ZipCode = "97204",
                Region = "Pacific Northwest"
            },

            // ===== INTERNATIONAL PROFESSIONALS =====
            
            new Customer
            {
                FirstName = "Elena",
                LastName = "Kowalski",
                Email = "elena.kowalski@global.com",
                Phone = "(555) 234-8901",
                Address = "1010 International Way",
                City = "San Jose",
                State = "CA",
                ZipCode = "95101",
                Region = "West Coast"
            },
            new Customer
            {
                FirstName = "Raj",
                LastName = "Sharma",
                Email = "raj.sharma@techgiant.com",
                Phone = "(555) 567-3456",
                Address = "1212 Silicon Valley Drive",
                City = "Palo Alto",
                State = "CA",
                ZipCode = "94301",
                Region = "West Coast"
            },
            new Customer
            {
                FirstName = "Yuki",
                LastName = "Tanaka",
                Email = "yuki.tanaka@innovation.jp",
                Phone = "(555) 890-7654",
                Address = "1313 Tech Campus",
                City = "Bellevue",
                State = "WA",
                ZipCode = "98004",
                Region = "Pacific Northwest"
            },

            // ===== MILITARY & VETERANS =====
            
            new Customer
            {
                FirstName = "Colonel Sarah",
                LastName = "Mitchell",
                Email = "sarah.mitchell@military.mil",
                Phone = "(555) 345-6789",
                Address = "1414 Base Housing Road",
                City = "Norfolk",
                State = "VA",
                ZipCode = "23501",
                Region = "Southeast"
            },
            new Customer
            {
                FirstName = "Sergeant First Class Mike",
                LastName = "Roberts",
                Email = "mike.roberts@veteran.org",
                Phone = "(555) 678-9012",
                Address = "1515 Veterans Way",
                City = "San Antonio",
                State = "TX",
                ZipCode = "78201",
                Region = "Southwest"
            },

            // ===== FIRST RESPONDERS =====
            
            new Customer
            {
                FirstName = "Captain Lisa",
                LastName = "Murphy",
                Email = "lisa.murphy@firerescue.gov",
                Phone = "(555) 234-5678",
                Address = "1616 First Responder Lane",
                City = "Phoenix",
                State = "AZ",
                ZipCode = "85003",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Detective John",
                LastName = "Harrison",
                Email = "john.harrison@police.gov",
                Phone = "(555) 567-8901",
                Address = "1717 Public Safety Street",
                City = "Milwaukee",
                State = "WI",
                ZipCode = "53201",
                Region = "Midwest"
            },

            // ===== HEALTHCARE PROFESSIONALS =====
            
            new Customer
            {
                FirstName = "Dr. Maria",
                LastName = "Fernandez",
                Email = "maria.fernandez@hospital.org",
                Phone = "(555) 890-1234",
                Address = "1818 Medical Center Drive",
                City = "Houston",
                State = "TX",
                ZipCode = "77001",
                Region = "Southwest"
            },
            new Customer
            {
                FirstName = "Nurse Jennifer",
                LastName = "Adams",
                Email = "jennifer.adams@healthcare.net",
                Phone = "(555) 432-1098",
                Address = "1919 Healthcare Plaza",
                City = "Cleveland",
                State = "OH",
                ZipCode = "44101",
                Region = "Midwest"
            },

            // ===== EDUCATORS =====
            
            new Customer
            {
                FirstName = "Professor David",
                LastName = "Nelson",
                Email = "david.nelson@university.edu",
                Phone = "(555) 765-4321",
                Address = "2020 Academic Circle",
                City = "Ann Arbor",
                State = "MI",
                ZipCode = "48101",
                Region = "Midwest"
            },
            new Customer
            {
                FirstName = "Principal Karen",
                LastName = "Wright",
                Email = "karen.wright@schools.edu",
                Phone = "(555) 123-9876",
                Address = "2121 Education Way",
                City = "Raleigh",
                State = "NC",
                ZipCode = "27601",
                Region = "Southeast"
            }
        };

        _context.Customers.AddRange(customers);
        _logger.LogInformation("Added {Count} customers to seed data", customers.Count);
    }

    private async Task SeedOrders()
    {
        await _context.SaveChangesAsync(); // Save customers and products first

        var customers = await _context.Customers.ToListAsync();
        var products = await _context.Products.ToListAsync();

        var orders = new List<Order>();
        var random = new Random();

        // Define realistic order scenarios based on customer types
        var orderScenarios = new[]
        {
            // Young Professional Scenarios
            ("Urban Studio + Smart Home", new[] { "US-950", "SHP-001" }, 1, 3),
            ("Starter Home + Solar", new[] { "SH-1400", "SPS-001" }, 1, 1),
            ("ADU for Parents", new[] { "TA-650", "PKP-001" }, 1, 1),
            
            // Growing Family Scenarios  
            ("Family Home + Upgrades", new[] { "FH-1800", "PKP-001", "LBS-001" }, 1, 1),
            ("Suburban Dream Package", new[] { "SD-2200", "HFU-001", "EEP-001" }, 1, 1),
            ("Ranch with Accessibility", new[] { "RR-2000", "LBS-001" }, 1, 1),
            
            // Executive Scenarios
            ("Executive Estate", new[] { "EM-2500", "PKP-001", "LBS-001", "SPS-001" }, 1, 1),
            ("Presidential Home", new[] { "PE-3200", "PKP-001", "LBS-001", "SHP-001", "HFU-001" }, 1, 1),
            ("Modern Luxury", new[] { "MM-2800", "SPS-001", "SHP-001", "EEP-001" }, 1, 1),
            
            // Investor Scenarios
            ("Duplex Investment", new[] { "TVD-2000" }, 1, 1),
            ("High-Yield Duplex", new[] { "IPD-2400", "PKP-001" }, 1, 1),
            ("Triplex Development", new[] { "TCT-2700" }, 1, 1),
            ("ADU Portfolio", new[] { "BS-400", "TA-650", "CG-800" }, 1, 1),
            ("Multi-ADU Project", new[] { "ML-320" }, 5, 8),
            
            // Business Scenarios
            ("Commercial Retail", new[] { "RF-1500" }, 1, 1),
            ("Professional Office", new[] { "OP-2000", "SHP-001" }, 1, 1),
            ("Warehouse Facility", new[] { "WP-3000" }, 1, 1),
            
            // Component-Only Orders
            ("Kitchen Renovation", new[] { "PKP-001" }, 1, 3),
            ("Luxury Bath Upgrade", new[] { "LBS-001" }, 1, 2),
            ("Solar Installation", new[] { "SPS-001" }, 1, 1),
            ("Smart Home Retrofit", new[] { "SHP-001" }, 1, 1),
            ("Flooring Upgrade", new[] { "HFU-001" }, 1, 1),
            ("Energy Package", new[] { "EEP-001" }, 1, 1),
        };

        // Create 75 realistic orders over the past 12 months
        for (int i = 0; i < 75; i++)
        {
            var customer = customers[random.Next(customers.Count)];
            var scenario = orderScenarios[random.Next(orderScenarios.Length)];
            
            // Weighted date distribution (more recent orders more likely)
            var daysAgo = random.NextDouble() switch
            {
                < 0.3 => random.Next(1, 30),     // 30% in last month
                < 0.6 => random.Next(30, 90),    // 30% in last 3 months
                < 0.8 => random.Next(90, 180),   // 20% in last 6 months  
                _ => random.Next(180, 365)        // 20% older than 6 months
            };
            
            var orderDate = DateTime.UtcNow.AddDays(-daysAgo);

            var order = new Order
            {
                CustomerId = customer.Id,
                OrderNumber = $"ORD{orderDate:yyyyMMdd}{(i + 1):D4}",
                Status = DetermineOrderStatus(daysAgo, random),
                OrderDate = orderDate,
                ShippingAddress = customer.Address,
                ShippingCity = customer.City,
                ShippingState = customer.State,
                ShippingZipCode = customer.ZipCode,
                Region = customer.Region,
                LastUpdated = orderDate
            };

            // Add items based on scenario
            var orderItems = new List<OrderItem>();
            decimal subtotal = 0;

            foreach (var modelNumber in scenario.Item2)
            {
                var product = products.FirstOrDefault(p => p.ModelNumber == modelNumber);
                if (product != null)
                {
                    var quantity = random.Next(scenario.Item3, scenario.Item4 + 1);
                    
                    var orderItem = new OrderItem
                    {
                        ProductId = product.Id,
                        Quantity = quantity,
                        UnitPrice = product.Price,
                        LineTotal = product.Price * quantity
                    };

                    orderItems.Add(orderItem);
                    subtotal += orderItem.LineTotal;
                }
            }

            // Sometimes add random components to main orders
            if (scenario.Item2.Any(m => !m.Contains("-001")) && random.NextDouble() < 0.3)
            {
                var componentProducts = products.Where(p => p.Category == ProductCategory.Components).ToList();
                var componentProduct = componentProducts[random.Next(componentProducts.Count)];
                
                var orderItem = new OrderItem
                {
                    ProductId = componentProduct.Id,
                    Quantity = 1,
                    UnitPrice = componentProduct.Price,
                    LineTotal = componentProduct.Price
                };

                orderItems.Add(orderItem);
                subtotal += orderItem.LineTotal;
            }

            order.OrderItems = orderItems;
            order.Subtotal = subtotal;
            
            // Progressive tax rates by state/region
            order.Tax = customer.State switch
            {
                "OR" => 0,                    // No sales tax
                "MT" => 0,                    // No sales tax
                "CA" => subtotal * 0.0975m,   // High tax state
                "NY" => subtotal * 0.085m,    // High tax state
                "TX" => subtotal * 0.0625m,   // Mid tax state
                "FL" => subtotal * 0.06m,     // Mid tax state
                _ => subtotal * 0.075m        // Average
            };
            
            // Shipping logic
            order.Shipping = subtotal switch
            {
                >= 150000 => 0,              // Free shipping for luxury homes
                >= 50000 => 500,             // Reduced shipping for homes
                >= 10000 => 100,             // Standard shipping for components
                _ => 50                      // Small item shipping
            };
            
            order.Total = order.Subtotal + order.Tax + order.Shipping;

            // Set realistic delivery dates based on order status
            if (order.Status >= OrderStatus.Shipped)
            {
                var estimatedDays = orderItems.Max(oi => 
                    products.First(p => p.Id == oi.ProductId).DeliveryDaysEstimate);
                var actualDays = random.Next(Math.Max(1, estimatedDays - 7), estimatedDays + 14);
                order.ShippedDate = orderDate.AddDays(actualDays);
                
                if (order.Status == OrderStatus.Delivered)
                {
                    order.DeliveredDate = order.ShippedDate?.AddDays(random.Next(1, 14));
                    if (order.DeliveredDate.HasValue)
                    {
                        order.LastUpdated = order.DeliveredDate.Value;
                    }
                }
                else
                {
                    if (order.ShippedDate.HasValue)
                    {
                        order.LastUpdated = order.ShippedDate.Value;
                    }
                }
            }

            orders.Add(order);
        }

        _context.Orders.AddRange(orders);
        _logger.LogInformation("Added {Count} orders to seed data", orders.Count);
    }

    private static OrderStatus DetermineOrderStatus(int daysAgo, Random random)
    {
        return daysAgo switch
        {
            <= 7 => random.NextDouble() switch    // Last week - mostly early stages
            {
                < 0.4 => OrderStatus.Pending,
                < 0.7 => OrderStatus.Confirmed,
                < 0.9 => OrderStatus.InProduction,
                _ => OrderStatus.Shipped
            },
            <= 30 => random.NextDouble() switch   // Last month - mixed stages
            {
                < 0.2 => OrderStatus.Pending,
                < 0.3 => OrderStatus.Confirmed,
                < 0.5 => OrderStatus.InProduction,
                < 0.8 => OrderStatus.Shipped,
                _ => OrderStatus.Delivered
            },
            <= 90 => random.NextDouble() switch   // Last 3 months - mostly completed
            {
                < 0.1 => OrderStatus.InProduction,
                < 0.3 => OrderStatus.Shipped,
                < 0.9 => OrderStatus.Delivered,
                _ => OrderStatus.Cancelled
            },
            _ => random.NextDouble() switch        // Older orders - completed or cancelled
            {
                < 0.85 => OrderStatus.Delivered,
                _ => OrderStatus.Cancelled
            }
        };
    }

    private async Task SeedSupportTickets()
    {
        await _context.SaveChangesAsync(); // Save orders first

        var customers = await _context.Customers.ToListAsync();
        var orders = await _context.Orders.ToListAsync();

        var tickets = new List<SupportTicket>();
        var random = new Random();

        // Enhanced realistic support scenarios organized by category
        var supportScenarios = new Dictionary<TicketCategory, (string Subject, string Description, TicketPriority Priority)[]>
        {
            [TicketCategory.DeliveryIssue] = new[]
            {
                ("Delivery Delay - Order Not Received", "My order #ORD20241015001 was supposed to arrive last week but I haven't received any updates. The tracking shows it left the facility but no delivery confirmation.", TicketPriority.High),
                ("Damaged During Shipping", "The modular panels arrived with visible damage to the exterior siding. There are several cracks and dents that occurred during transport.", TicketPriority.High),
                ("Incorrect Delivery Address", "The delivery crew went to my old address instead of my new construction site. We need to coordinate a new delivery time.", TicketPriority.Medium),
                ("Missing Components", "My Terrazia ADU order arrived but we're missing the kitchen cabinet package that was included in the order.", TicketPriority.High),
                ("Access Issues at Site", "The delivery truck can't access our building site due to narrow roads. We need to discuss alternative delivery methods.", TicketPriority.Medium),
                ("Delivery Window Change", "We need to reschedule our delivery from next Tuesday to the following Monday due to foundation delays.", TicketPriority.Low),
                ("Foundation Requirements", "What are the exact foundation specifications for the Executive Manor 2500? Our contractor needs detailed requirements.", TicketPriority.Medium),
                ("Delivery Crew Contact", "Can you provide direct contact info for the delivery crew? We have specific site access instructions.", TicketPriority.Low)
            },
            
            [TicketCategory.ProductDefect] = new[]
            {
                ("Wall Panel Crack", "Found a crack in one of the wall panels upon delivery inspection. It appears to be a manufacturing defect.", TicketPriority.High),
                ("Window Installation Issue", "The windows in my Family Haven 1800 don't close properly. There seems to be a frame alignment problem.", TicketPriority.High),
                ("Electrical System Malfunction", "The smart home package has several outlets that aren't working. Need an electrician to inspect.", TicketPriority.High),
                ("Roof Leak During Rain", "We're experiencing water intrusion in the master bedroom during heavy rain. The roof seam may be compromised.", TicketPriority.Critical),
                ("Door Alignment Problem", "The front door doesn't close flush and has gaps around the frame letting in cold air.", TicketPriority.Medium),
                ("Plumbing Leak", "There's a leak under the kitchen sink in our new Urban Studio. Water is pooling under the cabinet.", TicketPriority.High),
                ("HVAC Performance Issues", "The heating system isn't maintaining consistent temperature throughout the home.", TicketPriority.Medium),
                ("Insulation Gaps", "We can feel cold air coming through the walls in several areas. Insulation may not be properly installed.", TicketPriority.Medium)
            },
            
            [TicketCategory.Installation] = new[]
            {
                ("Foundation Requirements", "Need detailed foundation specifications for my Suburban Dream 2200. Our contractor needs exact measurements.", TicketPriority.Medium),
                ("Electrical Hookup Questions", "What electrical connections are needed before delivery? Our electrician needs the requirements.", TicketPriority.Medium),
                ("Plumbing Preparation", "How should we prepare the plumbing connections for the Casita Grande ADU?", TicketPriority.Medium),
                ("Site Preparation Checklist", "Can you provide a complete site preparation checklist for our modular home delivery?", TicketPriority.Low),
                ("Crane Access Requirements", "Our lot has limited space. What are the minimum clearances needed for the installation crane?", TicketPriority.Medium),
                ("Assembly Time Estimate", "How long should we expect the on-site assembly to take for our duplex order?", TicketPriority.Low),
                ("Utility Connection Timing", "When in the process should we schedule utility connections for power, water, and sewer?", TicketPriority.Medium),
                ("Final Inspection Process", "What inspections are required after installation is complete?", TicketPriority.Low)
            },
            
            [TicketCategory.OrderInquiry] = new[]
            {
                ("Order Status Update", "Can you provide an update on order #ORD20241201002? It's been 3 weeks since order confirmation.", TicketPriority.Low),
                ("Customization Request", "Is it possible to upgrade the kitchen package on my existing order before production starts?", TicketPriority.Medium),
                ("Delivery Date Change", "We need to move our delivery date back by 2 weeks due to permit delays.", TicketPriority.Medium),
                ("Order Modification", "Can we add the solar power system to our existing Family Haven order?", TicketPriority.Medium),
                ("Cancellation Request", "Due to financing issues, we may need to cancel our order. What is the cancellation policy?", TicketPriority.High),
                ("Rush Order Request", "Is it possible to expedite our ADU order? We have a tenant moving in sooner than expected.", TicketPriority.High),
                ("Duplicate Order Issue", "I think I may have accidentally placed the same order twice. Can you check order #ORD20241205001?", TicketPriority.Medium),
                ("Order Details Confirmation", "Can you confirm all the specifications included in our Presidential Estate order?", TicketPriority.Low)
            },
            
            [TicketCategory.Billing] = new[]
            {
                ("Duplicate Charge", "I was charged twice for my recent Backyard Studio order. Please reverse the duplicate transaction.", TicketPriority.High),
                ("Payment Plan Options", "Are payment plans available for large orders? I'm interested in the Executive Manor.", TicketPriority.Medium),
                ("Invoice Discrepancy", "The invoice amount doesn't match the quote I received. There's a $5,000 difference.", TicketPriority.High),
                ("Refund Request", "We canceled our order within the allowed timeframe. When can we expect our deposit refund?", TicketPriority.Medium),
                ("Tax Calculation Question", "The tax amount seems high on our commercial order. Can you verify the calculation?", TicketPriority.Medium),
                ("Credit Card Update", "I need to update the credit card on file for my upcoming payment.", TicketPriority.Low),
                ("Financing Options", "What financing options are available for first-time buyers?", TicketPriority.Low),
                ("Payment Receipt", "I haven't received an email receipt for my recent payment. Can you resend it?", TicketPriority.Low)
            },
            
            [TicketCategory.General] = new[]
            {
                ("Warranty Information", "What warranty coverage is included with my modular home purchase?", TicketPriority.Low),
                ("Product Catalog Request", "Can you send me a complete catalog of available floor plans and options?", TicketPriority.Low),
                ("Reference Request", "Can you provide references from other customers who purchased the same model?", TicketPriority.Low),
                ("Site Visit Request", "Can a representative visit our site to assess feasibility for modular home placement?", TicketPriority.Medium),
                ("Customization Possibilities", "What customization options are available for the Ranch Royale model?", TicketPriority.Low),
                ("Maintenance Guidelines", "Can you provide maintenance guidelines for our new modular home?", TicketPriority.Low),
                ("Insurance Requirements", "What information do I need to provide to my insurance company?", TicketPriority.Low),
                ("Future Expansion Options", "Can modular homes be expanded or additional units added later?", TicketPriority.Low)
            }
        };

        var supportAgents = new[] 
        { 
            "Sarah Mitchell", "David Rodriguez", "Emily Parker", "Michael Chang", 
            "Jennifer Brooks", "Alex Thompson", "Maria Gonzalez", "Robert Kim",
            "Lisa Chen", "James Wilson"
        };

        // Create 60 realistic support tickets over the past 6 months
        for (int i = 0; i < 60; i++)
        {
            var customer = customers[random.Next(customers.Count)];
            
            // 70% chance of being related to an order
            Order? relatedOrder = null;
            if (random.NextDouble() < 0.7 && orders.Any())
            {
                relatedOrder = orders[random.Next(orders.Count)];
            }
            
            // Weight ticket creation toward more recent dates
            var daysAgo = random.NextDouble() switch
            {
                < 0.4 => random.Next(1, 30),     // 40% in last month
                < 0.7 => random.Next(30, 90),    // 30% in last 3 months
                _ => random.Next(90, 180)         // 30% older than 3 months
            };
            
            var createdDate = DateTime.UtcNow.AddDays(-daysAgo);
            
            // Select random category and scenario
            var categories = supportScenarios.Keys.ToArray();
            var selectedCategory = categories[random.Next(categories.Length)];
            var scenarios = supportScenarios[selectedCategory];
            var scenario = scenarios[random.Next(scenarios.Length)];

            var ticket = new SupportTicket
            {
                TicketNumber = $"TKT{createdDate:yyyyMMdd}{(i + 1):D4}",
                CustomerId = customer.Id,
                OrderId = relatedOrder?.Id,
                Subject = scenario.Subject,
                Description = scenario.Description + (relatedOrder != null ? $" (Order: {relatedOrder.OrderNumber})" : ""),
                Status = DetermineTicketStatus(daysAgo, random),
                Priority = scenario.Priority,
                Category = selectedCategory,
                Region = customer.Region,
                CreatedDate = createdDate,
                LastUpdated = createdDate
            };

            // Assign tickets (80% assigned rate)
            if (random.NextDouble() < 0.8)
            {
                ticket.AssignedTo = supportAgents[random.Next(supportAgents.Length)];
            }

            // Set resolved date for resolved/closed tickets
            if (ticket.Status == TicketStatus.Resolved || ticket.Status == TicketStatus.Closed)
            {
                var resolutionDays = ticket.Priority switch
                {
                    TicketPriority.Critical => random.Next(1, 2),    // Same or next day
                    TicketPriority.High => random.Next(1, 3),        // 1-3 days
                    TicketPriority.Medium => random.Next(2, 7),      // 2-7 days
                    TicketPriority.Low => random.Next(3, 14),        // 3-14 days
                    _ => random.Next(1, 7)
                };
                
                ticket.ResolvedDate = createdDate.AddDays(resolutionDays);
                ticket.LastUpdated = ticket.ResolvedDate.Value;
            }

            tickets.Add(ticket);
        }

        _context.SupportTickets.AddRange(tickets);
        _logger.LogInformation("Added {Count} support tickets to seed data", tickets.Count);

        // Add realistic notes to 40% of tickets
        await _context.SaveChangesAsync(); // Save tickets first

        var ticketNotes = new List<TicketNote>();
        var ticketsForNotes = tickets.Where(t => random.NextDouble() < 0.4).ToList();
        
        foreach (var ticket in ticketsForNotes)
        {
            var noteCount = random.Next(1, 5); // 1-4 notes per ticket
            
            for (int i = 0; i < noteCount; i++)
            {
                var noteDate = ticket.CreatedDate.AddHours(random.Next(1, 
                    (int)(DateTime.UtcNow - ticket.CreatedDate).TotalHours));
                var isInternal = random.NextDouble() < 0.3; // 30% internal notes

                var publicNotes = new[]
                {
                    "Thank you for contacting Fabrikam Homes. We're looking into this issue and will get back to you within 24 hours.",
                    "I've forwarded your request to our technical team for review. You should hear back from us by tomorrow.",
                    "We've scheduled a site inspection for next Tuesday. Our field technician will contact you to confirm the time.",
                    "Your replacement parts have been ordered and should arrive within 3-5 business days.",
                    "I've escalated your case to our senior support team. A specialist will contact you today.",
                    "We've processed your refund request. You should see the credit on your account within 5-7 business days.",
                    "Thank you for your patience. We've identified the issue and are working on a resolution.",
                    "I've updated your delivery schedule. Your new delivery date is confirmed for next Friday.",
                    "Our quality control team is investigating this matter. We take product quality very seriously.",
                    "I've contacted our logistics partner to track down your missing shipment."
                };

                var internalNotes = new[]
                {
                    "Customer called for status update - following up with production team",
                    "Escalated to field services - potential warranty claim",
                    "Reviewed order details - customer may need upgrade consultation",
                    "Coordinating with delivery team for redelivery",
                    "QC team reviewing photos provided by customer",
                    "Legal reviewing warranty terms for this situation",
                    "Production manager confirms this is a known issue with batch #2024-15",
                    "Customer very upset - manager needs to call back today",
                    "Similar issue reported by 3 other customers this week",
                    "Approved expedited shipping at no charge to customer"
                };

                var note = new TicketNote
                {
                    TicketId = ticket.Id,
                    Note = isInternal ? 
                        internalNotes[random.Next(internalNotes.Length)] : 
                        publicNotes[random.Next(publicNotes.Length)],
                    CreatedBy = ticket.AssignedTo ?? "Support Team",
                    IsInternal = isInternal,
                    CreatedDate = noteDate
                };

                ticketNotes.Add(note);
            }
        }

        _context.TicketNotes.AddRange(ticketNotes);
        _logger.LogInformation("Added {Count} ticket notes to seed data", ticketNotes.Count);
    }

    private static TicketStatus DetermineTicketStatus(int daysAgo, Random random)
    {
        return daysAgo switch
        {
            <= 7 => random.NextDouble() switch      // Last week - mostly active
            {
                < 0.3 => TicketStatus.Open,
                < 0.6 => TicketStatus.InProgress,
                < 0.8 => TicketStatus.PendingCustomer,
                _ => TicketStatus.Resolved
            },
            <= 30 => random.NextDouble() switch     // Last month - mixed
            {
                < 0.2 => TicketStatus.Open,
                < 0.4 => TicketStatus.InProgress,
                < 0.5 => TicketStatus.PendingCustomer,
                < 0.8 => TicketStatus.Resolved,
                _ => TicketStatus.Closed
            },
            _ => random.NextDouble() switch          // Older - mostly resolved
            {
                < 0.1 => TicketStatus.InProgress,
                < 0.8 => TicketStatus.Resolved,
                _ => TicketStatus.Closed
            }
        };
    }
}
