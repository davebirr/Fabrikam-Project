using System.ComponentModel;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using FabrikamMcp.Attributes;
using FabrikamMcp.Services;
using FabrikamContracts.DTOs.Invoices;
using ModelContextProtocol.Server;

namespace FabrikamMcp.Tools;

/// <summary>
/// MCP tools for invoice processing and management
/// </summary>
[McpServerToolType]
public class FabrikamInvoiceTools : AuthenticatedMcpToolBase
{
    public FabrikamInvoiceTools(
        HttpClient httpClient,
        IConfiguration configuration,
        IAuthenticationService authService,
        ILogger<FabrikamInvoiceTools> logger,
        IHttpContextAccessor httpContextAccessor)
        : base(httpClient, configuration, authService, logger, httpContextAccessor)
    {
    }

    /// <summary>
    /// Get invoices with optional filtering for duplicate detection and validation
    /// </summary>
    [McpServerTool, Description("Get invoices with optional filtering by invoice number, vendor, status, date range, or category. Use invoiceNumber for duplicate detection before submission. Use filters (vendor, status, fromDate, toDate, category) for invoice lists. Supports pagination. Returns invoice details including line items for validation.")]
    [McpAuthorize(McpRoles.Admin, McpRoles.Sales)]
    public async Task<object> get_invoices(
        string? userGuid = null,
        string? invoiceNumber = null,
        string? vendor = null,
        string? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        string? category = null,
        int? page = null,
        int? pageSize = null)
    {
        try
        {
            var baseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
            var queryParams = new List<string>();

            if (!string.IsNullOrEmpty(invoiceNumber))
            {
                queryParams.Add($"invoiceNumber={Uri.EscapeDataString(invoiceNumber)}");
            }

            if (!string.IsNullOrEmpty(vendor))
            {
                queryParams.Add($"vendor={Uri.EscapeDataString(vendor)}");
            }

            if (!string.IsNullOrEmpty(status))
            {
                queryParams.Add($"status={Uri.EscapeDataString(status)}");
            }

            if (fromDate.HasValue)
            {
                queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
            }

            if (toDate.HasValue)
            {
                queryParams.Add($"toDate={toDate.Value:yyyy-MM-dd}");
            }

            if (!string.IsNullOrEmpty(category))
            {
                queryParams.Add($"category={Uri.EscapeDataString(category)}");
            }

            if (page.HasValue)
            {
                queryParams.Add($"page={page.Value}");
            }

            if (pageSize.HasValue)
            {
                queryParams.Add($"pageSize={pageSize.Value}");
            }

            var queryString = queryParams.Count > 0 ? "?" + string.Join("&", queryParams) : "";
            var url = $"{baseUrl}/api/invoices{queryString}";

            _logger.LogInformation("Fetching invoices from {Url}", url);

            var response = await _httpClient.GetAsync(url);

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Successfully retrieved invoices");
                
                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = FormatInvoicesResponse(content, invoiceNumber)
                        }
                    },
                    data = content
                };
            }

            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = !string.IsNullOrEmpty(invoiceNumber)
                                ? $"No invoice found with number '{invoiceNumber}'. This invoice number is available for use."
                                : "No invoices found matching the specified criteria."
                        }
                    }
                };
            }

            _logger.LogWarning("Failed to retrieve invoices: {StatusCode}", response.StatusCode);
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Failed to retrieve invoices: {response.StatusCode}"
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving invoices");
            return new
            {
                error = new { message = $"Error retrieving invoices: {ex.Message}" }
            };
        }
    }

    /// <summary>
    /// Submit a new invoice to the Fabrikam invoice system with validation
    /// </summary>
    [McpServerTool, Description("Submit a new invoice to Fabrikam's invoice processing system. IMPORTANT: Include all required fields (invoiceNumber, vendor, invoiceDate, dueDate, subtotal, tax, total, category, lineItems). The API performs validation including math checks, duplicate detection, and date validation. Returns the created invoice with ID on success, or detailed validation errors if submission fails.")]
    [McpAuthorize(McpRoles.Admin, McpRoles.Sales)]
    public async Task<object> submit_invoice(
        string? userGuid = null,
        [Description("REQUIRED: Unique invoice number from the invoice document")] string invoiceNumber = "",
        [Description("REQUIRED: Vendor/supplier name")] string vendor = "",
        [Description("REQUIRED: Invoice date (YYYY-MM-DD format)")] DateTime? invoiceDate = null,
        [Description("REQUIRED: Payment due date (YYYY-MM-DD format)")] DateTime? dueDate = null,
        [Description("REQUIRED: Subtotal amount before tax")] decimal subtotal = 0,
        [Description("REQUIRED: Tax amount")] decimal tax = 0,
        [Description("REQUIRED: Total amount (subtotal + tax)")] decimal total = 0,
        [Description("REQUIRED: Category (Materials, Services, Equipment, Logistics, or Utilities)")] string category = "",
        [Description("Optional: Line items with description, quantity, unitPrice, and amount")] List<CreateInvoiceLineItemRequest>? lineItems = null,
        [Description("Optional: Additional notes or comments")] string? notes = null,
        [Description("Optional: Purchase order number if applicable")] string? purchaseOrderNumber = null)
    {
        try
        {
            var baseUrl = _configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
            var url = $"{baseUrl}/api/invoices";

            // Construct the invoice request
            var invoiceRequest = new
            {
                invoiceNumber,
                vendor,
                invoiceDate = invoiceDate?.ToString("yyyy-MM-dd") ?? DateTime.Today.ToString("yyyy-MM-dd"),
                dueDate = dueDate?.ToString("yyyy-MM-dd") ?? DateTime.Today.AddDays(30).ToString("yyyy-MM-dd"),
                subtotal,
                tax,
                total,
                category,
                lineItems = lineItems ?? new List<CreateInvoiceLineItemRequest>(),
                notes,
                purchaseOrderNumber
            };

            var jsonContent = JsonSerializer.Serialize(invoiceRequest);
            var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

            _logger.LogInformation("Submitting invoice {InvoiceNumber} from vendor {Vendor}", 
                invoiceNumber, vendor);

            var response = await _httpClient.PostAsync(url, content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Successfully submitted invoice {InvoiceNumber}", invoiceNumber);
                
                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = FormatInvoiceSubmissionSuccess(responseContent, invoiceNumber, vendor, total)
                        }
                    },
                    data = responseContent
                };
            }

            if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
            {
                _logger.LogWarning("Invoice validation failed for {InvoiceNumber}: {Error}", 
                    invoiceNumber, responseContent);
                
                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = FormatInvoiceValidationError(responseContent, invoiceNumber)
                        }
                    },
                    error = new
                    {
                        code = 400,
                        message = "Invoice validation failed",
                        details = responseContent
                    }
                };
            }

            if (response.StatusCode == System.Net.HttpStatusCode.Conflict)
            {
                _logger.LogWarning("Duplicate invoice detected: {InvoiceNumber}", invoiceNumber);
                
                return new
                {
                    content = new object[]
                    {
                        new
                        {
                            type = "text",
                            text = $"❌ DUPLICATE INVOICE DETECTED\n\nInvoice number '{invoiceNumber}' already exists in the system.\n\n" +
                                   $"Action Required:\n" +
                                   $"1. Verify this is not a duplicate submission\n" +
                                   $"2. Use get_invoices with invoiceNumber='{invoiceNumber}' to see existing invoice\n" +
                                   $"3. If this is a different invoice, use a unique invoice number"
                        }
                    },
                    error = new
                    {
                        code = 409,
                        message = "Duplicate invoice number",
                        details = responseContent
                    }
                };
            }

            _logger.LogError("Failed to submit invoice {InvoiceNumber}: {StatusCode}", 
                invoiceNumber, response.StatusCode);
            
            return new
            {
                error = new
                {
                    code = (int)response.StatusCode,
                    message = $"Failed to submit invoice: {response.StatusCode}",
                    details = responseContent
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error submitting invoice {InvoiceNumber}", invoiceNumber);
            return new
            {
                error = new { message = $"Error submitting invoice: {ex.Message}" }
            };
        }
    }

    private string FormatInvoicesResponse(string jsonContent, string? invoiceNumber)
    {
        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            
            // Try to parse as array first (list of invoices)
            if (jsonContent.TrimStart().StartsWith("["))
            {
                var invoices = JsonSerializer.Deserialize<List<JsonElement>>(jsonContent, options);
                if (invoices == null || invoices.Count == 0)
                {
                    return "No invoices found.";
                }

                var sb = new StringBuilder();
                sb.AppendLine($"📄 INVOICE LIST ({invoices.Count} invoice{(invoices.Count == 1 ? "" : "s")})\n");

                foreach (var invoice in invoices)
                {
                    var number = invoice.GetProperty("invoiceNumber").GetString();
                    var vendor = invoice.GetProperty("vendor").GetString();
                    var total = invoice.GetProperty("total").GetDecimal();
                    var status = invoice.GetProperty("status").GetString();
                    var date = invoice.GetProperty("invoiceDate").GetDateTime();

                    sb.AppendLine($"Invoice: {number}");
                    sb.AppendLine($"  Vendor: {vendor}");
                    sb.AppendLine($"  Date: {date:yyyy-MM-dd}");
                    sb.AppendLine($"  Total: ${total:N2}");
                    sb.AppendLine($"  Status: {status}");
                    sb.AppendLine();
                }

                return sb.ToString();
            }
            else
            {
                // Single invoice
                var invoice = JsonSerializer.Deserialize<JsonElement>(jsonContent, options);
                var sb = new StringBuilder();
                
                sb.AppendLine($"📄 INVOICE DETAILS\n");
                sb.AppendLine($"Invoice Number: {invoice.GetProperty("invoiceNumber").GetString()}");
                sb.AppendLine($"Vendor: {invoice.GetProperty("vendor").GetString()}");
                sb.AppendLine($"Date: {invoice.GetProperty("invoiceDate").GetDateTime():yyyy-MM-dd}");
                sb.AppendLine($"Due Date: {invoice.GetProperty("dueDate").GetDateTime():yyyy-MM-dd}");
                sb.AppendLine($"Category: {invoice.GetProperty("category").GetString()}");
                sb.AppendLine($"Status: {invoice.GetProperty("status").GetString()}");
                sb.AppendLine();
                sb.AppendLine($"Subtotal: ${invoice.GetProperty("subtotal").GetDecimal():N2}");
                sb.AppendLine($"Tax: ${invoice.GetProperty("tax").GetDecimal():N2}");
                sb.AppendLine($"TOTAL: ${invoice.GetProperty("total").GetDecimal():N2}");

                if (invoice.TryGetProperty("lineItems", out var lineItems) && lineItems.ValueKind == JsonValueKind.Array)
                {
                    var items = lineItems.EnumerateArray().ToList();
                    if (items.Count > 0)
                    {
                        sb.AppendLine($"\nLine Items ({items.Count}):");
                        foreach (var item in items)
                        {
                            var desc = item.GetProperty("description").GetString();
                            var qty = item.GetProperty("quantity").GetDecimal();
                            var price = item.GetProperty("unitPrice").GetDecimal();
                            var amount = item.GetProperty("amount").GetDecimal();
                            sb.AppendLine($"  - {desc}: {qty} × ${price:N2} = ${amount:N2}");
                        }
                    }
                }

                return sb.ToString();
            }
        }
        catch
        {
            return jsonContent; // Fallback to raw JSON
        }
    }

    private string FormatInvoiceSubmissionSuccess(string jsonContent, string invoiceNumber, string vendor, decimal total)
    {
        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var invoice = JsonSerializer.Deserialize<JsonElement>(jsonContent, options);
            
            var id = invoice.GetProperty("id").GetInt32();
            var status = invoice.GetProperty("status").GetString();

            return $"✅ INVOICE SUBMITTED SUCCESSFULLY\n\n" +
                   $"Invoice Number: {invoiceNumber}\n" +
                   $"Vendor: {vendor}\n" +
                   $"Total: ${total:N2}\n" +
                   $"System ID: {id}\n" +
                   $"Status: {status}\n\n" +
                   $"The invoice has been validated and added to the Fabrikam invoice processing system.";
        }
        catch
        {
            return $"✅ Invoice {invoiceNumber} submitted successfully.";
        }
    }

    private string FormatInvoiceValidationError(string errorContent, string invoiceNumber)
    {
        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var error = JsonSerializer.Deserialize<JsonElement>(errorContent, options);
            
            var sb = new StringBuilder();
            sb.AppendLine($"❌ INVOICE VALIDATION FAILED: {invoiceNumber}\n");
            
            if (error.TryGetProperty("errors", out var errors))
            {
                sb.AppendLine("Validation Errors:");
                foreach (var prop in errors.EnumerateObject())
                {
                    var fieldName = prop.Name;
                    var messages = prop.Value.EnumerateArray().Select(e => e.GetString()).ToList();
                    foreach (var msg in messages)
                    {
                        sb.AppendLine($"  • {fieldName}: {msg}");
                    }
                }
            }
            else if (error.TryGetProperty("title", out var title))
            {
                sb.AppendLine($"Error: {title.GetString()}");
                if (error.TryGetProperty("detail", out var detail))
                {
                    sb.AppendLine($"Details: {detail.GetString()}");
                }
            }
            else
            {
                sb.AppendLine(errorContent);
            }

            sb.AppendLine("\nPlease correct the errors and resubmit.");
            return sb.ToString();
        }
        catch
        {
            return $"❌ Invoice validation failed for {invoiceNumber}. Please check all required fields and amounts.";
        }
    }
}
