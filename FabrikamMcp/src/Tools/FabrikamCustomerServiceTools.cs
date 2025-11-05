using System.ComponentModel;
using System.Net.Http.Json;
using System.Text.Json;
using FabrikamMcp.Services;
using ModelContextProtocol.Server;

namespace FabrikamMcp.Tools;

[McpServerToolType]
public class FabrikamCustomerServiceTools : AuthenticatedMcpToolBase
{
    public FabrikamCustomerServiceTools(
        HttpClient httpClient, 
        IConfiguration configuration,
        IAuthenticationService authService,
        ILogger<FabrikamCustomerServiceTools> logger,
        IHttpContextAccessor httpContextAccessor) 
        : base(httpClient, configuration, authService, logger, httpContextAccessor)
    {
    }

    [McpServerTool, Description("Get support tickets with optional filtering by status, priority, category, region, assigned agent, or specific ticket ID. Use ticketId for detailed ticket info with full conversation history. Use filters (status, priority, category, region, assignedTo, urgent) for ticket lists. When called without parameters, returns ALL tickets (paginated). No default filters - agent determines what data is needed.")]
    public async Task<object> GetSupportTickets(
        string? userGuid = null,
        int? ticketId = null,
        string? status = null,
        string? priority = null,
        string? category = null,
        string? region = null,
        string? assignedTo = null,
        bool urgent = false,
        int page = 1,
        int pageSize = 20)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(GetSupportTickets)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(GetSupportTickets));
        }

        try
        {
            var baseUrl = GetApiBaseUrl();
            
            // If ticketId is provided, get specific ticket details
            if (ticketId.HasValue)
            {
                var ticketResponse = await _httpClient.GetAsync($"{baseUrl}/api/supporttickets/{ticketId.Value}");
                
                if (ticketResponse.IsSuccessStatusCode)
                {
                    var ticketJson = await ticketResponse.Content.ReadAsStringAsync();
                    using var document = JsonDocument.Parse(ticketJson);
                    var ticket = document.RootElement;

                    var ticketText = FormatTicketDetailText(ticket);

                    return new
                    {
                        content = new object[]
                        {
                            new { type = "text", text = ticketText }
                        },
                        data = ticketJson
                    };
                }
                
                if (ticketResponse.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return new
                    {
                        content = new object[]
                        {
                            new { type = "text", text = $"❌ Support ticket with ID {ticketId.Value} not found" }
                        }
                    };
                }
                
                return new
                {
                    error = new
                    {
                        code = (int)ticketResponse.StatusCode,
                        message = $"Error retrieving support ticket {ticketId.Value}: {ticketResponse.StatusCode} - {ticketResponse.ReasonPhrase}"
                    }
                };
            }
            
            // Build query parameters for ticket list
            var queryParams = new List<string>();
            
            // No default filters - let the AI agent determine what tickets are needed
            // The tool provides ALL tickets unless filters are explicitly specified
            
            if (!string.IsNullOrEmpty(status)) queryParams.Add($"status={Uri.EscapeDataString(status)}");
            if (!string.IsNullOrEmpty(priority)) queryParams.Add($"priority={Uri.EscapeDataString(priority)}");
            if (!string.IsNullOrEmpty(category)) queryParams.Add($"category={Uri.EscapeDataString(category)}");
            if (!string.IsNullOrEmpty(region)) queryParams.Add($"region={Uri.EscapeDataString(region)}");
            if (!string.IsNullOrEmpty(assignedTo)) queryParams.Add($"assignedTo={Uri.EscapeDataString(assignedTo)}");
            
            // Handle urgent tickets filter
            if (urgent)
            {
                queryParams.Add("urgent=true");
            }
            
            queryParams.Add($"page={page}");
            queryParams.Add($"pageSize={pageSize}");

            var queryString = "?" + string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"{baseUrl}/api/supporttickets{queryString}");
            
            if (response.IsSuccessStatusCode)
            {
                var ticketsJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(ticketsJson);
                var ticketsArray = document.RootElement;

                var totalCount = response.Headers.FirstOrDefault(h => h.Key == "X-Total-Count").Value?.FirstOrDefault();
                var ticketText = FormatTicketListText(ticketsArray, totalCount, page, status, priority, urgent);
                
                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = ticketText }
                    },
                    data = ticketsJson,
                    pagination = new
                    {
                        page,
                        pageSize,
                        totalCount
                    }
                };
            }
            
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error retrieving support tickets: {response.StatusCode} - {response.ReasonPhrase}"
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
                    message = $"Error retrieving support tickets: {ex.Message}"
                }
            };
        }
    }

    [McpServerTool, Description("Create a new support ticket for customer service escalation. IMPORTANT: You must provide customerId - get it from the order data by calling get_orders first. Use orderId if the ticket is related to a specific order.")]
    public async Task<object> CreateSupportTicket(
        string? userGuid = null,
        [Description("REQUIRED: Customer ID from the order data (use get_orders to retrieve it first)")] int customerId = 0,
        [Description("Optional: Order ID if this ticket is related to a specific order")] int? orderId = null,
        [Description("Brief summary of the issue (e.g., 'Production Delay - Order FAB-2025-047')")] string subject = "",
        [Description("Detailed description of the issue including timeline and customer impact")] string description = "",
        [Description("Priority level: Low, Medium, High, or Critical (use High for delays, Critical for damage)")] string priority = "Medium",
        [Description("Category: OrderInquiry, DeliveryIssue, ProductDefect, Installation, Billing, Technical, General, or Complaint")] string category = "General")
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(CreateSupportTicket)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(CreateSupportTicket));
        }

        try
        {
            var baseUrl = GetApiBaseUrl();
            
            // If customerId is missing but orderId is provided, look up the customer from the order
            if (customerId == 0 && orderId.HasValue && orderId.Value > 0)
            {
                var orderResponse = await _httpClient.GetAsync($"{baseUrl}/api/orders/{orderId.Value}");
                
                if (orderResponse.IsSuccessStatusCode)
                {
                    var orderJson = await orderResponse.Content.ReadAsStringAsync();
                    using var orderDoc = JsonDocument.Parse(orderJson);
                    var orderRoot = orderDoc.RootElement;
                    
                    if (orderRoot.TryGetProperty("customerId", out var customerIdProp))
                    {
                        customerId = customerIdProp.GetInt32();
                    }
                }
            }

            // Validate we have a customerId
            if (customerId == 0)
            {
                return new
                {
                    error = new
                    {
                        code = 400,
                        message = "Customer ID is required. Either provide customerId directly, or provide orderId so we can look up the customer from the order."
                    }
                };
            }

            var ticketData = new
            {
                customerId,
                orderId,
                subject,
                description,
                priority,
                category
            };

            var response = await _httpClient.PostAsJsonAsync($"{baseUrl}/api/supporttickets", ticketData);
            
            if (response.IsSuccessStatusCode)
            {
                var resultJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(resultJson);
                var result = document.RootElement;

                var ticketNumber = GetJsonValue(result, "ticketNumber");
                var ticketId = GetJsonValue(result, "id");
                var ticketStatus = GetJsonValue(result, "status");
                var message = GetJsonValue(result, "message");

                var resultText = $"""
                    ✅ **Support Ticket Created Successfully**
                    
                    🎫 **Ticket Number:** {ticketNumber}
                    🆔 **Ticket ID:** {ticketId}
                    📋 **Subject:** {subject}
                    📝 **Description:** {description}
                    ⚡ **Priority:** {GetPriorityEmoji(priority)} {priority}
                    📂 **Category:** {category}
                    🔓 **Status:** {ticketStatus}
                    
                    {message}
                    """;

                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = resultText }
                    },
                    data = resultJson
                };
            }
            
            var errorContent = await response.Content.ReadAsStringAsync();
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error creating support ticket: {response.StatusCode} - {errorContent}"
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
                    message = $"Error creating support ticket: {ex.Message}"
                }
            };
        }
    }

    [McpServerTool, Description("Update a support ticket's status, priority, and/or assignment. Available statuses: Open, InProgress, PendingCustomer, Resolved, Closed, Cancelled")]
    public async Task<object> UpdateTicketStatus(
        string? userGuid = null,
        int ticketId = 0,
        string? status = null,
        string? priority = null,
        string? assignedTo = null)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(UpdateTicketStatus)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(UpdateTicketStatus));
        }

        try
        {
            var baseUrl = GetApiBaseUrl();
            var updateData = new
            {
                status,
                priority,
                assignedTo
            };

            var response = await _httpClient.PatchAsJsonAsync($"{baseUrl}/api/supporttickets/{ticketId}/status", updateData);
            
            if (response.IsSuccessStatusCode)
            {
                var resultJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(resultJson);
                var result = document.RootElement;

                var details = new List<string>();
                if (!string.IsNullOrEmpty(status)) details.Add($"📊 **Status:** {status}");
                if (!string.IsNullOrEmpty(priority)) details.Add($"⚡ **Priority:** {GetPriorityEmoji(priority)} {priority}");
                if (!string.IsNullOrEmpty(assignedTo)) details.Add($"👤 **Assigned To:** {assignedTo}");

                var resultText = $"""
                    ✅ **Support Ticket Updated Successfully**
                    
                    🎫 **Ticket #{ticketId}**
                    {string.Join("\n", details)}
                    
                    {GetJsonValue(result, "message")}
                    """;

                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = resultText }
                    },
                    data = resultJson
                };
            }
            
            var errorContent = await response.Content.ReadAsStringAsync();
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error updating ticket {ticketId}: {response.StatusCode} - {errorContent}"
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
                    message = $"Error updating ticket {ticketId}: {ex.Message}"
                }
            };
        }
    }

    [McpServerTool, Description("Add a note to an existing support ticket. Specify if the note is internal (visible only to staff) or external (visible to customer).")]
    public async Task<object> AddTicketNote(
        string? userGuid = null,
        int ticketId = 0,
        string note = "",
        string createdBy = "",
        bool isInternal = false)
    {
        // Validate GUID requirement based on authentication mode
        if (!ValidateGuidRequirement(userGuid, nameof(AddTicketNote)))
        {
            return CreateGuidValidationErrorResponse(userGuid, nameof(AddTicketNote));
        }

        try
        {
            var baseUrl = GetApiBaseUrl();
            var noteData = new
            {
                note,
                createdBy,
                isInternal
            };

            var response = await _httpClient.PostAsJsonAsync($"{baseUrl}/api/supporttickets/{ticketId}/notes", noteData);
            
            if (response.IsSuccessStatusCode)
            {
                var resultJson = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(resultJson);
                var result = document.RootElement;

                var noteType = isInternal ? "Internal" : "External";
                var resultText = $"""
                    ✅ **{noteType} Note Added Successfully**
                    
                    🎫 **Ticket #{ticketId}**
                    📝 **Note:** {note}
                    👤 **Created By:** {createdBy}
                    🔒 **Visibility:** {noteType}
                    
                    {GetJsonValue(result, "message")}
                    """;

                return new
                {
                    content = new object[]
                    {
                        new { type = "text", text = resultText }
                    },
                    data = resultJson
                };
            }
            
            var errorContent = await response.Content.ReadAsStringAsync();
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Error adding note to ticket {ticketId}: {response.StatusCode} - {errorContent}"
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
                    message = $"Error adding note to ticket {ticketId}: {ex.Message}"
                }
            };
        }
    }

    private static string FormatTicketDetailText(JsonElement ticket)
    {
        var id = GetJsonValue(ticket, "id");
        var ticketNumber = GetJsonValue(ticket, "ticketNumber");
        var subject = GetJsonValue(ticket, "subject");
        var description = GetJsonValue(ticket, "description");
        var status = GetJsonValue(ticket, "status");
        var priority = GetJsonValue(ticket, "priority");
        var category = GetJsonValue(ticket, "category");
        var assignedTo = GetJsonValue(ticket, "assignedTo");
        var region = GetJsonValue(ticket, "region");

        var customerName = "";
        var customerEmail = "";
        var customerPhone = "";
        var customerRegion = "";

        if (ticket.TryGetProperty("customer", out var customer))
        {
            customerName = GetJsonValue(customer, "name");
            customerEmail = GetJsonValue(customer, "email");
            customerPhone = GetJsonValue(customer, "phone");
            customerRegion = GetJsonValue(customer, "region");
        }

        var relatedOrder = "";
        if (ticket.TryGetProperty("relatedOrder", out var order))
        {
            var orderNumber = GetJsonValue(order, "orderNumber");
            var orderStatus = GetJsonValue(order, "status");
            if (!string.IsNullOrEmpty(orderNumber))
            {
                relatedOrder = $"""
                    
                    🔗 **Related Order**
                    • Order: {orderNumber}
                    • Status: {orderStatus}
                    """;
            }
        }

        var createdDate = GetJsonValue(ticket, "createdDate");
        var lastUpdated = GetJsonValue(ticket, "lastUpdated");
        var resolvedDate = GetJsonValue(ticket, "resolvedDate");

        return $"""
            🎫 **SUPPORT TICKET DETAILS**
            
            🆔 **Ticket Information**
            • ID: {id}
            • Ticket Number: {ticketNumber}
            • Status: {GetTicketStatusEmoji(status)} {status}
            • Priority: {GetPriorityEmoji(priority)} {priority}
            • Category: {category}
            • Region: {region ?? "N/A"}
            • Assigned To: {assignedTo ?? "Unassigned"}
            • Created: {createdDate}
            {(!string.IsNullOrEmpty(lastUpdated) ? $"• Last Updated: {lastUpdated}" : "")}
            {(!string.IsNullOrEmpty(resolvedDate) ? $"• Resolved: {resolvedDate}" : "")}
            
            👤 **Customer**
            • Name: {customerName}
            • Email: {customerEmail}
            {(!string.IsNullOrEmpty(customerPhone) ? $"• Phone: {customerPhone}" : "")}
            • Region: {customerRegion}
            
            📋 **Issue Details**
            • Subject: {subject}
            • Description: {description}{relatedOrder}
            """;
    }

    private static string FormatTicketListText(JsonElement ticketsArray, string? totalCount, int page, string? status, string? priority, bool urgent)
    {
        var ticketsList = new List<(string id, string ticketNumber, string subject, string status, string priority, string category)>();
        
        foreach (var ticket in ticketsArray.EnumerateArray())
        {
            ticketsList.Add((
                GetJsonValue(ticket, "id"),
                GetJsonValue(ticket, "ticketNumber"),
                GetJsonValue(ticket, "subject"),
                GetJsonValue(ticket, "status"),
                GetJsonValue(ticket, "priority"),
                GetJsonValue(ticket, "category")
            ));
        }

        if (ticketsList.Count == 0)
        {
            return "📭 **No support tickets found matching the specified criteria.**";
        }

        var text = $"""
            🎫 **FABRIKAM SUPPORT TICKETS**
            
            📊 **Summary**
            • Total Tickets: {totalCount ?? "N/A"}
            • Page: {page}
            • Showing: {ticketsList.Count} tickets
            """;

        // Add filter info if applied
        var filters = new List<string>();
        if (!string.IsNullOrEmpty(status)) filters.Add($"• Status: {status}");
        if (!string.IsNullOrEmpty(priority)) filters.Add($"• Priority: {priority}");
        if (urgent) filters.Add("• Urgent tickets only");

        if (filters.Any())
        {
            text += $"\n\n🔍 **Applied Filters:**\n{string.Join("\n", filters)}";
        }

        // Group by priority
        var byPriority = ticketsList.GroupBy(t => t.priority)
            .Select(g => new { Priority = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count);

        if (byPriority.Any())
        {
            text += "\n\n⚡ **By Priority:**";
            foreach (var group in byPriority)
            {
                text += $"\n• {GetPriorityEmoji(group.Priority)} {group.Priority}: {group.Count} tickets";
            }
        }

        // Show recent tickets
        text += "\n\n🕒 **Recent Tickets:**";
        foreach (var ticket in ticketsList.Take(10))
        {
            var statusEmoji = GetTicketStatusEmoji(ticket.status);
            var priorityEmoji = GetPriorityEmoji(ticket.priority);
            text += $"\n• **{ticket.ticketNumber}**: {ticket.subject} {statusEmoji} {priorityEmoji}";
        }

        if (ticketsList.Count > 10)
        {
            text += $"\n\n💡 *... and {ticketsList.Count - 10} more tickets. Use pagination to see more.*";
        }

        return text;
    }

    private static string GetTicketStatusEmoji(string status)
    {
        return status.ToLower() switch
        {
            "open" => "🔓",
            "in progress" => "⚙️",
            "inprogress" => "⚙️",
            "pendingcustomer" => "⏳",
            "resolved" => "✅",
            "closed" => "🔒",
            "cancelled" => "❌",
            _ => "🎫"
        };
    }

    private static string GetPriorityEmoji(string priority)
    {
        return priority.ToLower() switch
        {
            "critical" => "🔥",
            "high" => "🔴",
            "medium" => "🟡",
            "low" => "🟢",
            _ => "⚪"
        };
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
