using System.ComponentModel;
using System.Net.Http.Json;
using System.Text.Json;
using FabrikamMcp.Services;
using ModelContextProtocol.Server;

namespace FabrikamMcp.Tools;

[McpServerToolType]
public class FabrikamProductTools : AuthenticatedMcpToolBase
{
    public FabrikamProductTools(
        HttpClient httpClient, 
        IConfiguration configuration,
        IAuthenticationService authService,
        ILogger<FabrikamProductTools> logger,
        IHttpContextAccessor httpContextAccessor) 
        : base(httpClient, configuration, authService, logger, httpContextAccessor)
    {
    }

    [McpServerTool, Description("Get product catalog with optional filtering by category, price range, stock status, or specific product ID. Use productId for detailed product info, or use filters for product lists. When called without parameters, returns all active products.")]
    public async Task<object> GetProducts(
        string? userGuid = null,
        int? productId = null,
        string? category = null,
        bool? inStock = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        int page = 1,
        int pageSize = 20)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetProducts)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetProducts));
        }

        try
        {
            var baseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://fabrikam-api-dev.levelupcsp.com";

            // If productId is provided, get specific product details
            if (productId.HasValue)
            {
                var productResponse = await _httpClient.GetAsync($"{baseUrl}/api/products/{productId.Value}");

                if (productResponse.IsSuccessStatusCode)
                {
                    var productJson = await productResponse.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(productJson);
                    var productElement = document.RootElement;

                    var productDetails = $"""
                    📦 **Product Details**
                    
                    **{GetJsonValue(productElement, "name")}** (#{GetJsonValue(productElement, "modelNumber")})
                    📍 Category: {GetJsonValue(productElement, "category")}
                    💰 Price: ${GetJsonValue(productElement, "price"):N2}
                    📐 Dimensions: {GetJsonValue(productElement, "dimensions")}
                    🏠 {GetJsonValue(productElement, "squareFeet")} sq ft | {GetJsonValue(productElement, "bedrooms")} bed | {GetJsonValue(productElement, "bathrooms")} bath
                    
                    **Stock Information:**
                    📊 Current Stock: {GetJsonValue(productElement, "stockQuantity")} units
                    ⚠️ Reorder Level: {GetJsonValue(productElement, "reorderLevel")} units
                    📈 Stock Status: {GetJsonValue(productElement, "stockStatus")}
                    🚚 Delivery Estimate: {GetJsonValue(productElement, "deliveryDaysEstimate")} days
                    
                    **Description:**
                    {GetJsonValue(productElement, "description", "No description available")}
                    """;

                    return new
                    {
                        content = new object[]
                        {
                            new { type = "text", text = productDetails }
                        },
                        data = productJson
                    };
                }
                else if (productResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return new
                    {
                        content = new object[]
                        {
                            new { type = "text", text = $"❌ Product with ID {productId} not found." }
                        }
                    };
                }
                else
                {
                    return new
                    {
                        error = new
                        {
                            code = (int)productResponse.StatusCode,
                            message = $"Error retrieving product: {productResponse.StatusCode} - {productResponse.ReasonPhrase}"
                        }
                    };
                }
            }

            // Build query parameters for filtering
            var queryParams = new List<string>();

            if (!string.IsNullOrEmpty(category))
            {
                queryParams.Add($"category={Uri.EscapeDataString(category)}");
            }

            if (inStock.HasValue)
            {
                queryParams.Add($"inStock={inStock.Value.ToString().ToLower()}");
            }

            if (minPrice.HasValue)
            {
                queryParams.Add($"minPrice={minPrice.Value}");
            }

            if (maxPrice.HasValue)
            {
                queryParams.Add($"maxPrice={maxPrice.Value}");
            }

            queryParams.Add($"page={page}");
            queryParams.Add($"pageSize={pageSize}");

            var queryString = queryParams.Count > 0 ? "?" + string.Join("&", queryParams) : "";
            var response = await _httpClient.GetAsync($"{baseUrl}/api/products{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonContent = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(jsonContent);
                var productsArray = document.RootElement;

                var productsText = "📦 **Product Catalog**\n\n";

                // Add filter information
                var filters = new List<string>();
                if (!string.IsNullOrEmpty(category)) filters.Add($"Category: {category}");
                if (inStock.HasValue) filters.Add($"In Stock: {(inStock.Value ? "Yes" : "No")}");
                if (minPrice.HasValue) filters.Add($"Min Price: ${minPrice.Value:N2}");
                if (maxPrice.HasValue) filters.Add($"Max Price: ${maxPrice.Value:N2}");

                if (filters.Any())
                {
                    productsText += $"🔍 **Filters Applied:** {string.Join(", ", filters)}\n\n";
                }

                var productCount = 0;
                foreach (var product in productsArray.EnumerateArray())
                {
                    productCount++;
                    var name = GetJsonValue(product, "name");
                    var modelNumber = GetJsonValue(product, "modelNumber");
                    var categoryStr = GetJsonValue(product, "category");
                    var price = GetJsonValue(product, "price");
                    var stockQuantity = GetJsonValue(product, "stockQuantity");
                    var stockStatus = GetJsonValue(product, "stockStatus");
                    var squareFeet = GetJsonValue(product, "squareFeet");
                    var bedrooms = GetJsonValue(product, "bedrooms");
                    var bathrooms = GetJsonValue(product, "bathrooms");
                    var deliveryDays = GetJsonValue(product, "deliveryDaysEstimate");

                    var stockIcon = stockStatus switch
                    {
                        "In Stock" => "✅",
                        "Low Stock" => "⚠️",
                        "Out of Stock" => "❌",
                        _ => "📊"
                    };

                    productsText += $"""
                        **{name}** (#{modelNumber})
                        📍 {categoryStr} | 💰 ${price:N2} | 🏠 {squareFeet} sq ft | {bedrooms}bed/{bathrooms}bath
                        {stockIcon} {stockStatus} ({stockQuantity} units) | 🚚 {deliveryDays} days delivery
                        
                        """;
                }

                // Add pagination info
                var totalCountHeader = response.Headers.FirstOrDefault(h => h.Key == "X-Total-Count").Value?.FirstOrDefault();
                if (!string.IsNullOrEmpty(totalCountHeader) && int.TryParse(totalCountHeader, out var totalCount))
                {
                    var totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
                    productsText += $"\n📄 **Page {page} of {totalPages}** | Total Products: {totalCount}";

                    if (page < totalPages)
                    {
                        productsText += $"\n💡 Use page={page + 1} to see more products";
                    }
                }

                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = productsText }
                    },
                    data = jsonContent
                };
            }

            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving products: {response.StatusCode} - {response.ReasonPhrase}"
                }
            };
        }
        catch (HttpRequestException ex)
        {
            return new
            {
                error = new { message = $"Network error retrieving products: {ex.Message}" }
            };
        }
        catch (Exception ex)
        {
            return new
            {
                error = new { message = $"Error retrieving products: {ex.Message}" }
            };
        }
    }

    [McpServerTool, Description("Get product analytics including inventory levels, sales performance, and category breakdowns. Provides insights into product performance and stock management.")]
    public async Task<object> GetProductAnalytics(
        string? userGuid = null,
        string? category = null,
        bool includeOutOfStock = true)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetProductAnalytics)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetProductAnalytics));
        }

        try
        {
            var baseUrl = GetApiBaseUrl();

            // Get all products for analytics
            var queryParams = new List<string> { "pageSize=0" }; // Get all products

            if (!string.IsNullOrEmpty(category))
            {
                queryParams.Add($"category={Uri.EscapeDataString(category)}");
            }

            if (!includeOutOfStock)
            {
                queryParams.Add("inStock=true");
            }

            var queryString = "?" + string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"{baseUrl}/api/products{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var jsonContent = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(jsonContent);
                var productsArray = document.RootElement;

                var products = new List<(string name, string category, decimal price, int stock, string status, int bedrooms)>();

                foreach (var product in productsArray.EnumerateArray())
                {
                    products.Add((
                        GetJsonValue(product, "name"),
                        GetJsonValue(product, "category"),
                        decimal.TryParse(GetJsonValue(product, "price"), out var price) ? price : 0,
                        int.TryParse(GetJsonValue(product, "stockQuantity"), out var stock) ? stock : 0,
                        GetJsonValue(product, "stockStatus"),
                        int.TryParse(GetJsonValue(product, "bedrooms"), out var bedrooms) ? bedrooms : 0
                    ));
                }

                var analyticsText = "📊 **Product Analytics Dashboard**\n\n";

                if (!string.IsNullOrEmpty(category))
                {
                    analyticsText += $"🔍 **Category Filter:** {category}\n\n";
                }

                // Summary metrics
                var totalProducts = products.Count;
                var inStock = products.Count(p => p.status == "In Stock");
                var lowStock = products.Count(p => p.status == "Low Stock");
                var outOfStock = products.Count(p => p.status == "Out of Stock");
                var averagePrice = products.Where(p => p.price > 0).Average(p => p.price);
                var totalInventoryValue = products.Sum(p => p.price * p.stock);

                analyticsText += $"""
                    ## 📈 **Summary Metrics**
                    - **Total Products:** {totalProducts}
                    - **In Stock:** {inStock} ({(double)inStock / totalProducts * 100:F1}%)
                    - **Low Stock:** {lowStock} ({(double)lowStock / totalProducts * 100:F1}%)
                    - **Out of Stock:** {outOfStock} ({(double)outOfStock / totalProducts * 100:F1}%)
                    - **Average Price:** ${averagePrice:N2}
                    - **Total Inventory Value:** ${totalInventoryValue:N2}
                    
                    """;

                // Category breakdown
                var categoryBreakdown = products
                    .GroupBy(p => p.category)
                    .Select(g => new
                    {
                        Category = g.Key,
                        Count = g.Count(),
                        InStock = g.Count(p => p.status == "In Stock"),
                        AveragePrice = g.Average(p => p.price),
                        TotalValue = g.Sum(p => p.price * p.stock)
                    })
                    .OrderByDescending(x => x.Count);

                analyticsText += "## 📂 **By Category**\n";
                foreach (var cat in categoryBreakdown)
                {
                    analyticsText += $"**{cat.Category}:** {cat.Count} products | {cat.InStock} in stock | Avg: ${cat.AveragePrice:N2} | Value: ${cat.TotalValue:N2}\n";
                }

                // Price ranges
                analyticsText += "\n## 💰 **By Price Range**\n";
                var priceRanges = new[]
                {
                    ("Under $100K", products.Count(p => p.price < 100000)),
                    ("$100K - $200K", products.Count(p => p.price >= 100000 && p.price < 200000)),
                    ("$200K - $300K", products.Count(p => p.price >= 200000 && p.price < 300000)),
                    ("$300K+", products.Count(p => p.price >= 300000))
                };

                foreach (var (range, count) in priceRanges)
                {
                    analyticsText += $"**{range}:** {count} products ({(double)count / totalProducts * 100:F1}%)\n";
                }

                // Stock alerts
                if (lowStock > 0 || outOfStock > 0)
                {
                    analyticsText += "\n## ⚠️ **Stock Alerts**\n";

                    if (outOfStock > 0)
                    {
                        analyticsText += $"❌ **{outOfStock} products are out of stock**\n";
                        var outOfStockProducts = products.Where(p => p.status == "Out of Stock").Take(5);
                        foreach (var product in outOfStockProducts)
                        {
                            analyticsText += $"   • {product.name}\n";
                        }
                        if (outOfStock > 5) analyticsText += $"   • ... and {outOfStock - 5} more\n";
                    }

                    if (lowStock > 0)
                    {
                        analyticsText += $"⚠️ **{lowStock} products are low in stock**\n";
                        var lowStockProducts = products.Where(p => p.status == "Low Stock").Take(5);
                        foreach (var product in lowStockProducts)
                        {
                            analyticsText += $"   • {product.name} ({product.stock} units)\n";
                        }
                        if (lowStock > 5) analyticsText += $"   • ... and {lowStock - 5} more\n";
                    }
                }

                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = analyticsText }
                    },
                    data = new
                    {
                        totalProducts,
                        inStock,
                        lowStock,
                        outOfStock,
                        averagePrice,
                        totalInventoryValue,
                        categoryBreakdown,
                        priceRanges
                    }
                };
            }

            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving product analytics: {response.StatusCode} - {response.ReasonPhrase}"
                }
            };
        }
        catch (HttpRequestException ex)
        {
            return new
            {
                error = new { message = $"Network error retrieving product analytics: {ex.Message}" }
            };
        }
        catch (Exception ex)
        {
            return new
            {
                error = new { message = $"Error retrieving product analytics: {ex.Message}" }
            };
        }
    }

    private static string GetJsonValue(JsonElement element, string propertyName, string defaultValue = "")
    {
        if (element.TryGetProperty(propertyName, out var property))
        {
            return property.ValueKind switch
            {
                JsonValueKind.String => property.GetString() ?? defaultValue,
                JsonValueKind.Number => property.TryGetDecimal(out var dec) ? dec.ToString("F2") : property.GetRawText(),
                JsonValueKind.True => "true",
                JsonValueKind.False => "false",
                JsonValueKind.Null => defaultValue,
                _ => property.GetRawText()
            };
        }
        return defaultValue;
    }
}
