using System.ComponentModel;
using System.Net.Http.Json;
using System.Text.Json;
using FabrikamMcp.Attributes;
using FabrikamMcp.Services;
using ModelContextProtocol.Server;

namespace FabrikamMcp.Tools;

[McpServerToolType]
public class FabrikamSalesTools : AuthenticatedMcpToolBase
{
    public FabrikamSalesTools(
        HttpClient httpClient, 
        IConfiguration configuration,
        IAuthenticationService authService,
        ILogger<FabrikamSalesTools> logger,
        IHttpContextAccessor httpContextAccessor) 
        : base(httpClient, configuration, authService, logger, httpContextAccessor)
    {
    }

    [McpServerTool, Description("Get orders with optional filtering by status, region, date range, or specific order ID. Use orderId for detailed order info with full line items. Use filters (status, region, fromDate, toDate) for order lists. When called without parameters, returns ALL orders (paginated). For date filters, use YYYY-MM-DD format. Supports historical data queries - no date restrictions.")]
    [McpAuthorize(McpRoles.Admin, McpRoles.Sales, McpRoles.CustomerService)]
    public async Task<object> GetOrders(
        string? userGuid = null,
        int? orderId = null,
        string? status = null,
        string? region = null,
        string? fromDate = null,
        string? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetOrders)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetOrders));
        }

        // Validate authorization
        if (!ValidateAuthorization(nameof(GetOrders)))
        {
            return CreateAuthenticationErrorResponse(nameof(GetOrders));
        }

        // Log tool usage
        LogToolUsage(nameof(GetOrders), new { userGuid, orderId, status, region, fromDate, toDate, page, pageSize });

        try
        {
            var baseUrl = GetApiBaseUrl();

            // If orderId is provided, get specific order details
            if (orderId.HasValue)
            {
                var orderResponse = await SendAuthenticatedRequest($"{baseUrl}/api/orders/{orderId.Value}");

                if (orderResponse.IsSuccessStatusCode)
                {
                    var orderJson = await orderResponse.Content.ReadAsStringAsync();
                    // Parse as dynamic object since API returns anonymous object
                    using var document = JsonDocument.Parse(orderJson);
                    var orderElement = document.RootElement;

                    return new
                    {
                        content = new object[]
                        {
                            new
                            {
                                type = "resource",
                                resource = new
                                {
                                    uri = $"{baseUrl}/api/orders/{orderId.Value}",
                                    name = $"Order {orderElement.GetProperty("orderNumber").GetString()}",
                                    description = $"Order details for {orderElement.GetProperty("customer").GetProperty("name").GetString()}",
                                    mimeType = "application/json"
                                }
                            },
                            new
                            {
                                type = "text",
                                text = FormatOrderDetailText(orderElement)
                            }
                        },
                        orderData = JsonSerializer.Deserialize<object>(orderJson),
                        outputSchema = new
                        {
                            type = "object",
                            properties = new
                            {
                                id = new { type = "integer", description = "Order ID" },
                                orderNumber = new { type = "string", description = "Order number" },
                                customer = new { type = "object", description = "Customer information" },
                                status = new { type = "string", description = "Current order status" },
                                total = new { type = "number", description = "Order total amount" },
                                items = new { type = "array", description = "Order items and products" }
                            }
                        }
                    };
                }

                if (orderResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return new
                    {
                        error = new
                        {
                            code = 404,
                            message = $"Order with ID {orderId.Value} not found"
                        }
                    };
                }

                return new
                {
                    error = new
                    {
                        code = (int)orderResponse.StatusCode,
                        message = $"Error retrieving order {orderId.Value}: {orderResponse.StatusCode} - {orderResponse.ReasonPhrase}"
                    }
                };
            }

            // Build query parameters for order list
            var queryParams = new List<string>();

            if (!string.IsNullOrEmpty(status)) queryParams.Add($"status={Uri.EscapeDataString(status)}");
            if (!string.IsNullOrEmpty(region)) queryParams.Add($"region={Uri.EscapeDataString(region)}");
            if (!string.IsNullOrEmpty(fromDate)) queryParams.Add($"fromDate={Uri.EscapeDataString(fromDate)}");
            if (!string.IsNullOrEmpty(toDate)) queryParams.Add($"toDate={Uri.EscapeDataString(toDate)}");

            // Smart date validation and fallback logic
            var originalFromDate = fromDate;
            var originalToDate = toDate;
            bool dateFiltersProvided = !string.IsNullOrEmpty(fromDate) || !string.IsNullOrEmpty(toDate);

            // No default filters - let the AI agent determine what data is needed
            // The tool provides ALL orders unless filters are explicitly specified

            queryParams.Add($"page={page}");
            queryParams.Add($"pageSize={pageSize}");

            var queryString = "?" + string.Join("&", queryParams);
            var response = await SendAuthenticatedRequest($"{baseUrl}/api/orders{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var ordersJson = await response.Content.ReadAsStringAsync();
                // Parse as array since API returns array of anonymous objects
                using var document = JsonDocument.Parse(ordersJson);
                var ordersArray = document.RootElement;
                var totalCount = response.Headers.GetValues("X-Total-Count").FirstOrDefault();

                // If date filters were provided but no results found, try without date filters
                bool hasResults = ordersArray.GetArrayLength() > 0;
                if (!hasResults && dateFiltersProvided)
                {
                    // Try again without date filters to show available data
                    var fallbackParams = new List<string>();

                    if (!string.IsNullOrEmpty(status)) fallbackParams.Add($"status={Uri.EscapeDataString(status)}");
                    if (!string.IsNullOrEmpty(region)) fallbackParams.Add($"region={Uri.EscapeDataString(region)}");
                    fallbackParams.Add($"page={page}");
                    fallbackParams.Add($"pageSize={pageSize}");

                    var fallbackQueryString = "?" + string.Join("&", fallbackParams);
                    var fallbackResponse = await SendAuthenticatedRequest($"{baseUrl}/api/orders{fallbackQueryString}");

                    if (fallbackResponse.IsSuccessStatusCode)
                    {
                        var fallbackOrdersJson = await fallbackResponse.Content.ReadAsStringAsync();
                        using var fallbackDocument = JsonDocument.Parse(fallbackOrdersJson);
                        var fallbackOrdersArray = fallbackDocument.RootElement;
                        var fallbackTotalCount = fallbackResponse.Headers.GetValues("X-Total-Count").FirstOrDefault();

                        if (fallbackOrdersArray.GetArrayLength() > 0)
                        {
                            // Return fallback results with explanation
                            return new
                            {
                                content = new object[]
                                {
                                    new
                                    {
                                        type = "resource",
                                        resource = new
                                        {
                                            uri = $"{baseUrl}/api/orders{fallbackQueryString}",
                                            name = "Order List (Date Filter Adjusted)",
                                            description = $"No orders found for {originalFromDate} to {originalToDate}. Showing available orders instead.",
                                            mimeType = "application/json"
                                        }
                                    },
                                    new
                                    {
                                        type = "text",
                                        text = FormatOrderListText(fallbackOrdersArray, fallbackTotalCount, page, status, region, null, null)
                                    }
                                },
                                ordersData = JsonSerializer.Deserialize<object[]>(fallbackOrdersJson),
                                pagination = new
                                {
                                    page = page,
                                    pageSize = pageSize,
                                    totalCount = fallbackTotalCount ?? "0"
                                },
                                outputSchema = new
                                {
                                    type = "array",
                                    description = "List of orders",
                                    items = new
                                    {
                                        type = "object",
                                        properties = new
                                        {
                                            id = new { type = "integer", description = "Order ID" },
                                            orderNumber = new { type = "string", description = "Order number" },
                                            status = new { type = "string", description = "Order status" },
                                            total = new { type = "number", description = "Order total" },
                                            customer = new { type = "object", description = "Customer info" }
                                        }
                                    }
                                }
                            };
                        }
                    }
                }

                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "resource",
                            resource = new
                            {
                                uri = $"{baseUrl}/api/orders{queryString}",
                                name = "Order List",
                                description = GetOrderFilterDescription(status, region, fromDate, toDate),
                                mimeType = "application/json"
                            }
                        },
                        new
                        {
                            type = "text",
                            text = FormatOrderListText(ordersArray, totalCount, page, status, region, fromDate, toDate)
                        }
                    },
                    ordersData = JsonSerializer.Deserialize<object[]>(ordersJson),
                    pagination = new
                    {
                        page = page,
                        pageSize = pageSize,
                        totalCount = totalCount
                    },
                    outputSchema = new
                    {
                        type = "array",
                        description = "List of orders",
                        items = new
                        {
                            type = "object",
                            properties = new
                            {
                                id = new { type = "integer", description = "Order ID" },
                                orderNumber = new { type = "string", description = "Order number" },
                                status = new { type = "string", description = "Order status" },
                                total = new { type = "number", description = "Order total" },
                                customer = new { type = "object", description = "Customer info" }
                            }
                        }
                    }
                };
            }

            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving orders: {response.StatusCode} - {response.ReasonPhrase}"
                }
            };
        }
        catch (Exception ex)
        {
            return new
            {
                error = new
                {
                    code = 500,
                    message = $"Error retrieving orders: {ex.Message}"
                }
            };
        }
    }

    [McpServerTool, Description("Get sales analytics and summary data including total orders, revenue, average order value, and breakdowns by status and region.")]
    [McpAuthorize(McpRoles.Admin, McpRoles.Sales)]
    public async Task<object> GetSalesAnalytics(string? userGuid = null, string? fromDate = null, string? toDate = null)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetSalesAnalytics)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetSalesAnalytics));
        }

        // Validate authorization
        if (!ValidateAuthorization(nameof(GetSalesAnalytics)))
        {
            return CreateAuthenticationErrorResponse(nameof(GetSalesAnalytics));
        }

        // Log tool usage
        LogToolUsage(nameof(GetSalesAnalytics), new { fromDate, toDate });

        try
        {
            var baseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
            var queryParams = new List<string>();

            if (!string.IsNullOrEmpty(fromDate)) queryParams.Add($"fromDate={Uri.EscapeDataString(fromDate)}");
            if (!string.IsNullOrEmpty(toDate)) queryParams.Add($"toDate={Uri.EscapeDataString(toDate)}");

            var queryString = queryParams.Count > 0 ? "?" + string.Join("&", queryParams) : "";
            var response = await SendAuthenticatedRequest($"{baseUrl}/api/orders/analytics{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var analyticsJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(analyticsJson);
                var analyticsElement = document.RootElement;

                // Return structured content with both typed data and text fallback for MCP protocol compliance
                var result = new
                {
                    // MCP structured content
                    content = new object[]
                    {
                        new
                        {
                            type = "resource",
                            resource = new
                            {
                                uri = $"{baseUrl}/api/orders/analytics{queryString}",
                                name = "Sales Analytics Data",
                                description = "Comprehensive sales analytics and performance metrics",
                                mimeType = "application/json"
                            }
                        },
                        new
                        {
                            type = "text",
                            text = FormatSalesAnalyticsText(analyticsElement)
                        }
                    },
                    // Structured data for programmatic access
                    analyticsData = JsonSerializer.Deserialize<object>(analyticsJson),
                    // Schema information for validation
                    outputSchema = new
                    {
                        type = "object",
                        properties = new
                        {
                            summary = new { type = "object", description = "Overall sales summary metrics" },
                            byStatus = new { type = "array", description = "Sales breakdown by order status" },
                            byRegion = new { type = "array", description = "Sales breakdown by region" },
                            recentTrends = new { type = "array", description = "Recent sales trend data" }
                        }
                    }
                };

                return result;
            }

            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving sales analytics: {response.StatusCode} - {response.ReasonPhrase}"
                }
            };
        }
        catch (Exception ex)
        {
            return new
            {
                error = new
                {
                    code = 500,
                    message = $"Error retrieving sales analytics: {ex.Message}"
                }
            };
        }
    }

    private static string FormatSalesAnalyticsText(JsonElement analytics)
    {
        if (analytics.ValueKind == JsonValueKind.Null || analytics.ValueKind == JsonValueKind.Undefined)
            return "No sales analytics data available.";

        // Extract summary information
        var totalOrders = 0;
        var totalRevenue = 0m;
        var averageOrderValue = 0m;
        var fromDate = "N/A";
        var toDate = "N/A";

        if (analytics.TryGetProperty("summary", out var summaryProp))
        {
            if (summaryProp.TryGetProperty("totalOrders", out var totalOrdersProp))
                totalOrders = totalOrdersProp.GetInt32();
            if (summaryProp.TryGetProperty("totalRevenue", out var totalRevenueProp))
                totalRevenue = totalRevenueProp.GetDecimal();
            if (summaryProp.TryGetProperty("averageOrderValue", out var avgProp))
                averageOrderValue = avgProp.GetDecimal();

            if (summaryProp.TryGetProperty("period", out var periodProp))
            {
                if (periodProp.TryGetProperty("fromDate", out var fromDateProp))
                    fromDate = fromDateProp.GetString() ?? "N/A";
                if (periodProp.TryGetProperty("toDate", out var toDateProp))
                    toDate = toDateProp.GetString() ?? "N/A";
            }
        }

        var text = $"""
            📊 SALES ANALYTICS REPORT
            
            📈 Summary ({fromDate} to {toDate})
            • Total Orders: {totalOrders:N0}
            • Total Revenue: ${totalRevenue:N2}
            • Average Order Value: ${averageOrderValue:N2}
            
            📋 By Status:
            """;

        // Process byStatus array
        if (analytics.TryGetProperty("byStatus", out var byStatusProp) && byStatusProp.ValueKind == JsonValueKind.Array)
        {
            foreach (var status in byStatusProp.EnumerateArray())
            {
                var statusName = status.TryGetProperty("status", out var statusNameProp) ? statusNameProp.GetString() : "Unknown";
                var count = status.TryGetProperty("count", out var countProp) ? countProp.GetInt32() : 0;
                var revenue = status.TryGetProperty("revenue", out var revenueProp) ? revenueProp.GetDecimal() : 0;
                text += $"\n• {statusName}: {count:N0} orders (${revenue:N2})";
            }
        }

        text += "\n\n🗺️ By Region:";
        // Process byRegion array
        if (analytics.TryGetProperty("byRegion", out var byRegionProp) && byRegionProp.ValueKind == JsonValueKind.Array)
        {
            foreach (var region in byRegionProp.EnumerateArray())
            {
                var regionName = region.TryGetProperty("region", out var regionNameProp) ? regionNameProp.GetString() : "Unknown";
                var count = region.TryGetProperty("count", out var countProp) ? countProp.GetInt32() : 0;
                var revenue = region.TryGetProperty("revenue", out var revenueProp) ? revenueProp.GetDecimal() : 0;
                text += $"\n• {regionName}: {count:N0} orders (${revenue:N2})";
            }
        }

        // Process recentTrends array (note: API returns "recentTrends", not "dailyTrends")
        if (analytics.TryGetProperty("recentTrends", out var trendsProp) && trendsProp.ValueKind == JsonValueKind.Array)
        {
            text += "\n\n📅 Recent Daily Sales:";
            var count = 0;
            foreach (var daily in trendsProp.EnumerateArray())
            {
                if (count >= 7) break; // Limit to last 7 days
                var date = daily.TryGetProperty("date", out var dateProp) ? dateProp.GetString() : "N/A";
                var orders = daily.TryGetProperty("orders", out var ordersProp) ? ordersProp.GetInt32() : 0;
                var revenue = daily.TryGetProperty("revenue", out var revenueProp) ? revenueProp.GetDecimal() : 0;

                // Parse date for better formatting if possible
                if (DateTime.TryParse(date, out var parsedDate))
                    text += $"\n• {parsedDate:MM/dd}: {orders:N0} orders (${revenue:N2})";
                else
                    text += $"\n• {date}: {orders:N0} orders (${revenue:N2})";
                count++;
            }
        }

        return text;
    }

    [McpServerTool, Description("Get customers with optional filtering by region or specific customer ID. Use customerId for detailed customer info including order history and support tickets, or use region filter for customer lists. When called without parameters, returns all customers with pagination.")]
    [McpAuthorize(McpRoles.Admin, McpRoles.Sales, McpRoles.CustomerService)]
    public async Task<object> GetCustomers(string? userGuid = null, int? customerId = null, string? region = null, int page = 1, int pageSize = 20)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetCustomers)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetCustomers));
        }

        // Validate authorization
        if (!ValidateAuthorization(nameof(GetCustomers)))
        {
            return CreateAuthenticationErrorResponse(nameof(GetCustomers));
        }

        // Log tool usage
        LogToolUsage(nameof(GetCustomers), new { userGuid, customerId, region, page, pageSize });

        try
        {
            var baseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";

            // If customerId is provided, get specific customer details
            if (customerId.HasValue)
            {
                var customerResponse = await SendAuthenticatedRequest($"{baseUrl}/api/customers/{customerId.Value}");

                if (customerResponse.IsSuccessStatusCode)
                {
                    var customerJson = await customerResponse.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(customerJson);
                    var customerElement = document.RootElement;

                    // Extract customer name for resource description
                    var customerName = customerElement.TryGetProperty("name", out var nameProp) ? nameProp.GetString() : "Unknown Customer";

                    return new
                    {
                        content = new object[]
                        {
                            new
                            {
                                type = "resource",
                                resource = new
                                {
                                    uri = $"{baseUrl}/api/customers/{customerId.Value}",
                                    name = $"Customer {customerName}",
                                    description = "Detailed customer information with order history",
                                    mimeType = "application/json"
                                }
                            },
                            new
                            {
                                type = "text",
                                text = FormatCustomerDetailText(customerElement)
                            }
                        },
                        customerData = JsonSerializer.Deserialize<object>(customerJson),
                        outputSchema = new
                        {
                            type = "object",
                            properties = new
                            {
                                id = new { type = "integer", description = "Customer ID" },
                                name = new { type = "string", description = "Customer name" },
                                email = new { type = "string", description = "Customer email address" },
                                address = new { type = "object", description = "Customer address information" },
                                orderSummary = new { type = "object", description = "Customer purchase history summary" },
                                recentOrders = new { type = "array", description = "Recent customer orders" },
                                supportTicketSummary = new { type = "object", description = "Support ticket summary" }
                            }
                        }
                    };
                }

                if (customerResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return new
                    {
                        error = new
                        {
                            code = 404,
                            message = $"Customer with ID {customerId.Value} not found"
                        }
                    };
                }

                return new
                {
                    error = new
                    {
                        code = (int)customerResponse.StatusCode,
                        message = $"Error retrieving customer {customerId.Value}: {customerResponse.StatusCode} - {customerResponse.ReasonPhrase}"
                    }
                };
            }

            // Build query parameters for customer list
            var queryParams = new List<string>();

            if (!string.IsNullOrEmpty(region)) queryParams.Add($"region={Uri.EscapeDataString(region)}");

            // Always include pagination parameters for predictable results
            queryParams.Add($"page={page}");
            queryParams.Add($"pageSize={pageSize}");

            var queryString = "?" + string.Join("&", queryParams);
            var response = await SendAuthenticatedRequest($"{baseUrl}/api/customers{queryString}");

            if (response.IsSuccessStatusCode)
            {
                var customersJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(customersJson);
                var customersArray = document.RootElement;
                var totalCount = response.Headers.GetValues("X-Total-Count").FirstOrDefault();

                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "resource",
                            resource = new
                            {
                                uri = $"{baseUrl}/api/customers{queryString}",
                                name = "Customer Directory",
                                description = $"Customer list{(!string.IsNullOrEmpty(region) ? $" for {region} region" : "")}",
                                mimeType = "application/json"
                            }
                        },
                        new
                        {
                            type = "text",
                            text = FormatCustomerListText(customersArray, totalCount, page, region)
                        }
                    },
                    customersData = JsonSerializer.Deserialize<object[]>(customersJson),
                    pagination = new
                    {
                        page = page,
                        pageSize = pageSize,
                        totalCount = totalCount
                    },
                    outputSchema = new
                    {
                        type = "array",
                        description = "List of customers",
                        items = new
                        {
                            type = "object",
                            properties = new
                            {
                                id = new { type = "integer", description = "Customer ID" },
                                name = new { type = "string", description = "Customer name" },
                                email = new { type = "string", description = "Customer email" },
                                region = new { type = "string", description = "Customer region" },
                                orderCount = new { type = "integer", description = "Number of orders" },
                                totalSpent = new { type = "number", description = "Total amount spent" }
                            }
                        }
                    }
                };
            }

            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving customers: {response.StatusCode} - {response.ReasonPhrase}"
                }
            };
        }
        catch (Exception ex)
        {
            return new
            {
                error = new
                {
                    code = 500,
                    message = $"Error retrieving customers: {ex.Message}"
                }
            };
        }
    }

    private static string FormatCustomerDetailText(JsonElement customer)
    {
        if (customer.ValueKind == JsonValueKind.Null || customer.ValueKind == JsonValueKind.Undefined)
            return "No customer data available.";

        // Extract basic customer information
        var id = customer.TryGetProperty("id", out var idProp) ? idProp.GetInt32() : 0;
        var name = customer.TryGetProperty("name", out var nameProp) ? nameProp.GetString() : "Unknown";
        var email = customer.TryGetProperty("email", out var emailProp) ? emailProp.GetString() : "N/A";
        var phone = customer.TryGetProperty("phone", out var phoneProp) ? phoneProp.GetString() : "N/A";
        var region = customer.TryGetProperty("region", out var regionProp) ? regionProp.GetString() : "N/A";
        var createdDate = customer.TryGetProperty("createdDate", out var createdProp) ? createdProp.GetDateTime() : DateTime.MinValue;

        // Extract address information
        var addressText = "Address not available";
        if (customer.TryGetProperty("address", out var addressProp))
        {
            var street = addressProp.TryGetProperty("address", out var streetProp) ? streetProp.GetString() : "";
            var city = addressProp.TryGetProperty("city", out var cityProp) ? cityProp.GetString() : "";
            var state = addressProp.TryGetProperty("state", out var stateProp) ? stateProp.GetString() : "";
            var zipCode = addressProp.TryGetProperty("zipCode", out var zipProp) ? zipProp.GetString() : "";

            if (!string.IsNullOrEmpty(street) && !string.IsNullOrEmpty(city))
                addressText = $"{street}\n{city}, {state} {zipCode}";
        }

        // Extract order summary
        var totalOrders = 0;
        var totalSpent = 0m;
        var lastOrderDate = "None";
        if (customer.TryGetProperty("orderSummary", out var orderSummaryProp))
        {
            if (orderSummaryProp.TryGetProperty("totalOrders", out var totalOrdersProp))
                totalOrders = totalOrdersProp.GetInt32();
            if (orderSummaryProp.TryGetProperty("totalSpent", out var totalSpentProp))
                totalSpent = totalSpentProp.GetDecimal();
            if (orderSummaryProp.TryGetProperty("lastOrderDate", out var lastOrderProp))
                lastOrderDate = lastOrderProp.GetDateTime().ToString("yyyy-MM-dd");
        }

        // Extract recent orders
        var recentOrdersText = "No recent orders";
        if (customer.TryGetProperty("recentOrders", out var recentOrdersProp) && recentOrdersProp.ValueKind == JsonValueKind.Array)
        {
            var orders = new List<string>();
            foreach (var order in recentOrdersProp.EnumerateArray().Take(3))
            {
                var orderNumber = order.TryGetProperty("orderNumber", out var orderNumProp) ? orderNumProp.GetString() : "N/A";
                var status = order.TryGetProperty("status", out var statusProp) ? statusProp.GetString() : "Unknown";
                var total = order.TryGetProperty("total", out var totalProp) ? totalProp.GetDecimal() : 0;
                orders.Add($"#{orderNumber}: {status} - ${total:F2}");
            }
            if (orders.Any())
                recentOrdersText = string.Join("\n• ", orders);
        }

        // Extract support ticket summary
        var supportText = "";
        if (customer.TryGetProperty("supportTicketSummary", out var supportProp))
        {
            var totalTickets = supportProp.TryGetProperty("totalTickets", out var totalTicketsProp) ? totalTicketsProp.GetInt32() : 0;
            var openTickets = supportProp.TryGetProperty("openTickets", out var openTicketsProp) ? openTicketsProp.GetInt32() : 0;
            supportText = $"\n\n🎫 Support Summary\n• Total Tickets: {totalTickets}\n• Open Tickets: {openTickets}";
        }

        return $"""
            👤 CUSTOMER PROFILE
            
            📝 Contact Information
            • Name: {name}
            • Email: {email}
            • Phone: {phone}
            • Region: {region}
            • Registration Date: {(createdDate != DateTime.MinValue ? createdDate.ToString("yyyy-MM-dd") : "N/A")}
            
            📍 Address
            {addressText}
            
            🛒 Purchase History
            • Total Orders: {totalOrders:N0}
            • Lifetime Value: ${totalSpent:N2}
            • Last Purchase: {lastOrderDate}
            
            📦 Recent Orders
            • {recentOrdersText}{supportText}
            """;
    }

    private static string FormatCustomerListText(JsonElement customersArray, string? totalCount, int page, string? region)
    {
        if (customersArray.ValueKind != JsonValueKind.Array)
            return "No customer data available.";

        var customerCount = customersArray.GetArrayLength();
        var totalSpent = 0m;
        var activeCustomers = 0;

        var regionText = !string.IsNullOrEmpty(region) ? $" in {region} region" : "";
        var text = $"""
            👥 CUSTOMER DIRECTORY{regionText.ToUpper()}
            
            📊 Summary
            • Total Customers: {totalCount ?? customerCount.ToString()}
            • Page: {page}
            """;

        // Process customers and calculate summary
        var customers = new List<string>();
        foreach (var customer in customersArray.EnumerateArray().Take(10))
        {
            var name = customer.TryGetProperty("name", out var nameProp) ? nameProp.GetString() : "Unknown";
            var email = customer.TryGetProperty("email", out var emailProp) ? emailProp.GetString() : "N/A";
            var orderCount = customer.TryGetProperty("orderCount", out var orderCountProp) ? orderCountProp.GetInt32() : 0;
            var spent = customer.TryGetProperty("totalSpent", out var spentProp) ? spentProp.GetDecimal() : 0;
            var customerRegion = customer.TryGetProperty("region", out var regionProp) ? regionProp.GetString() : "Unknown";

            totalSpent += spent;
            if (orderCount > 0) activeCustomers++;

            customers.Add($"• {name} ({email}) - {orderCount} orders, ${spent:N2} total, {customerRegion}");
        }

        if (customerCount > 0)
        {
            var avgSpent = totalSpent / customerCount;
            text += $"\n• Active Customers: {activeCustomers}";
            text += $"\n• Average Customer Value: ${avgSpent:N2}";
        }

        text += "\n\n👤 Customers (Page " + page + "):";
        if (customers.Any())
        {
            text += "\n" + string.Join("\n", customers);
            if (customerCount > 10)
            {
                text += $"\n... and {customerCount - 10} more customers";
            }
        }
        else
        {
            text += "\nNo customers found for the specified criteria.";
        }

        return text;
    }

    private static string FormatOrderDetailText(JsonElement order)
    {
        if (order.ValueKind == JsonValueKind.Null || order.ValueKind == JsonValueKind.Undefined)
            return "Order details not available.";

        // Extract basic order information
        var id = order.TryGetProperty("id", out var idProp) ? idProp.GetInt32() : 0;
        var orderNumber = order.TryGetProperty("orderNumber", out var orderNumProp) ? orderNumProp.GetString() : "N/A";
        var status = order.TryGetProperty("status", out var statusProp) ? statusProp.GetString() : "Unknown";
        var orderDate = order.TryGetProperty("orderDate", out var orderDateProp) ? orderDateProp.GetDateTime() : DateTime.MinValue;
        var total = order.TryGetProperty("total", out var totalProp) ? totalProp.GetDecimal() : 0;

        // Extract customer information
        var customerName = "N/A";
        var customerEmail = "N/A";
        var customerPhone = "";
        if (order.TryGetProperty("customer", out var customerProp))
        {
            if (customerProp.TryGetProperty("name", out var nameProp))
                customerName = nameProp.GetString() ?? "N/A";
            if (customerProp.TryGetProperty("email", out var emailProp))
                customerEmail = emailProp.GetString() ?? "N/A";
            if (customerProp.TryGetProperty("phone", out var phoneProp))
                customerPhone = phoneProp.GetString() ?? "";
        }

        // Extract optional dates
        var shippedDate = order.TryGetProperty("shippedDate", out var shippedProp) &&
                          shippedProp.ValueKind != JsonValueKind.Null ? shippedProp.GetDateTime() : (DateTime?)null;
        var deliveredDate = order.TryGetProperty("deliveredDate", out var deliveredProp) &&
                            deliveredProp.ValueKind != JsonValueKind.Null ? deliveredProp.GetDateTime() : (DateTime?)null;

        // Count items if available
        var itemCount = 0;
        var itemsText = "Items not available";
        if (order.TryGetProperty("items", out var itemsProp) && itemsProp.ValueKind == JsonValueKind.Array)
        {
            itemCount = itemsProp.GetArrayLength();
            var itemsList = new List<string>();
            var count = 0;
            foreach (var item in itemsProp.EnumerateArray())
            {
                if (count >= 10) break;
                var productName = item.TryGetProperty("productName", out var prodNameProp) ? prodNameProp.GetString() : "Unknown Product";
                var quantity = item.TryGetProperty("quantity", out var qtyProp) ? qtyProp.GetInt32() : 0;
                var unitPrice = item.TryGetProperty("unitPrice", out var priceProp) ? priceProp.GetDecimal() : 0;
                var lineTotal = quantity * unitPrice;
                itemsList.Add($"• {productName}: {quantity} × ${unitPrice:F2} = ${lineTotal:F2}");
                count++;
            }
            itemsText = string.Join("\n", itemsList);
            if (itemCount > 10)
                itemsText += $"\n... and {itemCount - 10} more items";
        }

        return $"""
            📋 ORDER DETAILS
            
            🆔 Order Information
            • Order ID: {id}
            • Order Number: {orderNumber}
            • Status: {GetOrderStatusEmoji(status ?? "Unknown")} {status}
            • Order Date: {(orderDate != DateTime.MinValue ? orderDate.ToString("MMM dd, yyyy") : "N/A")}
            {(shippedDate.HasValue ? $"• Shipped: {shippedDate:MMM dd, yyyy}" : "")}
            {(deliveredDate.HasValue ? $"• Delivered: {deliveredDate:MMM dd, yyyy}" : "")}
            
            👤 Customer
            • Name: {customerName}
            • Email: {customerEmail}
            {(!string.IsNullOrEmpty(customerPhone) ? $"• Phone: {customerPhone}" : "")}
            
            � Financial Details
            • Total: ${total:F2}
            
            📦 Items ({itemCount})
            {itemsText}
            
            🕒 Order Details Retrieved: {DateTime.Now:MMM dd, yyyy HH:mm}
            """;
    }

    private static string FormatOrderListText(JsonElement ordersArray, string? totalCount, int page, string? status, string? region, string? fromDate, string? toDate)
    {
        if (ordersArray.ValueKind != JsonValueKind.Array)
            return "No orders found.";

        var orderCount = ordersArray.GetArrayLength();
        var totalRevenue = 0m;
        var ordersList = new List<string>();

        // Process orders and calculate summary
        var count = 0;
        foreach (var order in ordersArray.EnumerateArray())
        {
            if (count >= 8) break; // Limit display to 8 orders

            var orderNumber = order.TryGetProperty("orderNumber", out var orderNumProp) ? orderNumProp.GetString() : "N/A";
            var orderStatus = order.TryGetProperty("status", out var statusProp) ? statusProp.GetString() : "Unknown";
            var total = order.TryGetProperty("total", out var totalProp) ? totalProp.GetDecimal() : 0;
            totalRevenue += total;

            var customerName = "N/A";
            if (order.TryGetProperty("customer", out var customerProp) &&
                customerProp.TryGetProperty("name", out var nameProp))
            {
                customerName = nameProp.GetString() ?? "N/A";
            }

            var statusEmoji = GetOrderStatusEmoji(orderStatus ?? "Unknown");
            ordersList.Add($"• #{orderNumber}: {customerName} - ${total:F2} {statusEmoji}");
            count++;
        }

        var averageOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0;

        var text = $"""
            📋 FABRIKAM ORDERS
            
            � Summary
            • Total Orders: {totalCount ?? orderCount.ToString()}
            • Page: {page}
            • Total Revenue: ${totalRevenue:N2}
            • Average Order Value: ${averageOrderValue:F2}
            """;

        // Add filter info if applied
        var filters = GetAppliedFilters(status, region, fromDate, toDate);
        if (!string.IsNullOrEmpty(filters))
        {
            text += $"\n\n🔍 Applied Filters:\n{filters}";
        }

        // Show recent orders
        if (ordersList.Any())
        {
            text += "\n\n🕒 Recent Orders:";
            text += "\n" + string.Join("\n", ordersList);
            if (orderCount > 8)
            {
                text += $"\n... and {orderCount - 8} more orders";
            }
        }

        return text;
    }

    private static string GetOrderFilterDescription(string? status, string? region, string? fromDate, string? toDate)
    {
        var filters = new List<string>();

        if (!string.IsNullOrEmpty(status)) filters.Add($"Status: {status}");
        if (!string.IsNullOrEmpty(region)) filters.Add($"Region: {region}");
        if (!string.IsNullOrEmpty(fromDate)) filters.Add($"From: {fromDate}");
        if (!string.IsNullOrEmpty(toDate)) filters.Add($"To: {toDate}");

        return filters.Any() ? $"Filtered orders ({string.Join(", ", filters)})" : "Complete order list";
    }

    private static string GetAppliedFilters(string? status, string? region, string? fromDate, string? toDate)
    {
        var filters = new List<string>();

        if (!string.IsNullOrEmpty(status)) filters.Add($"• Status: {status}");
        if (!string.IsNullOrEmpty(region)) filters.Add($"• Region: {region}");
        if (!string.IsNullOrEmpty(fromDate)) filters.Add($"• From Date: {fromDate}");
        if (!string.IsNullOrEmpty(toDate)) filters.Add($"• To Date: {toDate}");

        return filters.Any() ? string.Join("\n", filters) : "";
    }

    private static string GetOrderStatusEmoji(string status)
    {
        return status.ToLower() switch
        {
            "pending" => "⏳",
            "confirmed" => "✅",
            "inproduction" => "🏭",
            "in production" => "🏭",
            "readytoship" => "📦",
            "ready to ship" => "📦",
            "shipped" => "🚚",
            "delivered" => "🎉",
            "cancelled" => "❌",
            "onhold" => "⏸️",
            "on hold" => "⏸️",
            _ => "📋"
        };
    }
}
