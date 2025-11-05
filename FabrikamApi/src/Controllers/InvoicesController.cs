using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FabrikamApi.Data;
using FabrikamApi.Models;
using FabrikamContracts.DTOs.Invoices;
using System.Text.RegularExpressions;

namespace FabrikamApi.Controllers;

/// <summary>
/// Manages invoices from suppliers, logistics vendors, and service providers
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class InvoicesController : ControllerBase
{
    private readonly FabrikamIdentityDbContext _context;
    private readonly ILogger<InvoicesController> _logger;

    public InvoicesController(FabrikamIdentityDbContext context, ILogger<InvoicesController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all invoices with optional filtering
    /// </summary>
    /// <param name="vendor">Filter by vendor name (partial match)</param>
    /// <param name="status">Filter by invoice status</param>
    /// <param name="fromDate">Filter invoices from this date onwards</param>
    /// <param name="toDate">Filter invoices up to this date</param>
    /// <param name="category">Filter by category</param>
    /// <param name="page">Page number (1-based)</param>
    /// <param name="pageSize">Number of items per page (max 100)</param>
    /// <returns>Paginated list of invoices</returns>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<InvoiceDto>), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<IEnumerable<InvoiceDto>>> GetInvoices(
        [FromQuery] string? vendor = null,
        [FromQuery] InvoiceStatus? status = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null,
        [FromQuery] string? category = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        try
        {
            if (page < 1)
            {
                return BadRequest("Page number must be 1 or greater");
            }

            if (pageSize < 1 || pageSize > 100)
            {
                return BadRequest("Page size must be between 1 and 100");
            }

            var query = _context.Invoices
                .Include(i => i.LineItems)
                .AsQueryable();

            // Apply filters
            if (!string.IsNullOrWhiteSpace(vendor))
            {
                query = query.Where(i => i.Vendor.Contains(vendor));
            }

            if (status.HasValue)
            {
                query = query.Where(i => i.Status == status.Value);
            }

            if (fromDate.HasValue)
            {
                query = query.Where(i => i.InvoiceDate >= fromDate.Value);
            }

            if (toDate.HasValue)
            {
                query = query.Where(i => i.InvoiceDate <= toDate.Value);
            }

            if (!string.IsNullOrWhiteSpace(category))
            {
                query = query.Where(i => i.Category == category);
            }

            // Get total count for pagination
            var totalCount = await query.CountAsync();

            // Apply pagination
            var invoices = await query
                .OrderByDescending(i => i.CreatedDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            // Map to DTOs
            var dtos = invoices.Select(MapToDto).ToList();

            // Add pagination headers
            Response.Headers.Append("X-Total-Count", totalCount.ToString());
            Response.Headers.Append("X-Page", page.ToString());
            Response.Headers.Append("X-Page-Size", pageSize.ToString());
            Response.Headers.Append("X-Total-Pages", ((int)Math.Ceiling(totalCount / (double)pageSize)).ToString());

            _logger.LogInformation("Retrieved {Count} invoices (page {Page} of {PageSize})", 
                invoices.Count, page, pageSize);

            return Ok(dtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving invoices");
            return StatusCode(500, "An error occurred while retrieving invoices");
        }
    }

    /// <summary>
    /// Get a specific invoice by ID
    /// </summary>
    /// <param name="id">Invoice ID</param>
    /// <returns>Invoice details with line items</returns>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(InvoiceDto), 200)]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<InvoiceDto>> GetInvoice(int id)
    {
        try
        {
            var invoice = await _context.Invoices
                .Include(i => i.LineItems)
                .FirstOrDefaultAsync(i => i.Id == id);

            if (invoice == null)
            {
                return NotFound($"Invoice with ID {id} not found");
            }

            return Ok(MapToDto(invoice));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving invoice {InvoiceId}", id);
            return StatusCode(500, "An error occurred while retrieving the invoice");
        }
    }

    /// <summary>
    /// Get invoice by invoice number
    /// </summary>
    /// <param name="invoiceNumber">Invoice number (e.g., INV-2025-001234)</param>
    /// <returns>Invoice details</returns>
    [HttpGet("by-number/{invoiceNumber}")]
    [ProducesResponseType(typeof(InvoiceDto), 200)]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<InvoiceDto>> GetInvoiceByNumber(string invoiceNumber)
    {
        try
        {
            var invoice = await _context.Invoices
                .Include(i => i.LineItems)
                .FirstOrDefaultAsync(i => i.InvoiceNumber == invoiceNumber);

            if (invoice == null)
            {
                return NotFound($"Invoice with number {invoiceNumber} not found");
            }

            return Ok(MapToDto(invoice));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving invoice {InvoiceNumber}", invoiceNumber);
            return StatusCode(500, "An error occurred while retrieving the invoice");
        }
    }

    /// <summary>
    /// Check for potential duplicate invoices before submission
    /// </summary>
    /// <param name="vendor">Vendor name</param>
    /// <param name="totalAmount">Total amount</param>
    /// <param name="invoiceDate">Invoice date</param>
    /// <param name="toleranceDays">Number of days to check for duplicates (default 30)</param>
    /// <returns>List of potential duplicate invoices</returns>
    [HttpGet("check-duplicates")]
    [ProducesResponseType(typeof(IEnumerable<InvoiceDto>), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<IEnumerable<InvoiceDto>>> CheckDuplicates(
        [FromQuery] string vendor,
        [FromQuery] decimal totalAmount,
        [FromQuery] DateTime invoiceDate,
        [FromQuery] int toleranceDays = 30)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(vendor))
            {
                return BadRequest("Vendor name is required");
            }

            if (totalAmount <= 0)
            {
                return BadRequest("Total amount must be greater than zero");
            }

            var startDate = invoiceDate.AddDays(-toleranceDays);
            var endDate = invoiceDate.AddDays(toleranceDays);

            var duplicates = await _context.Invoices
                .Include(i => i.LineItems)
                .Where(i => i.Vendor == vendor
                    && i.TotalAmount == totalAmount
                    && i.InvoiceDate >= startDate
                    && i.InvoiceDate <= endDate)
                .OrderByDescending(i => i.CreatedDate)
                .ToListAsync();

            _logger.LogInformation("Found {Count} potential duplicate invoices for {Vendor} with amount {Amount}", 
                duplicates.Count, vendor, totalAmount);

            var dtos = duplicates.Select(MapToDto).ToList();
            return Ok(dtos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking for duplicate invoices");
            return StatusCode(500, "An error occurred while checking for duplicates");
        }
    }

    /// <summary>
    /// Submit a new invoice
    /// </summary>
    /// <param name="request">Invoice submission request</param>
    /// <returns>Created invoice with generated invoice number</returns>
    [HttpPost]
    [ProducesResponseType(typeof(InvoiceDto), 201)]
    [ProducesResponseType(400)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<InvoiceDto>> CreateInvoice([FromBody] CreateInvoiceRequest request)
    {
        try
        {
            // Validate request
            var validationError = ValidateInvoiceRequest(request);
            if (validationError != null)
            {
                return BadRequest(validationError);
            }

            // Check for duplicates
            var duplicates = await _context.Invoices
                .Where(i => i.Vendor == request.Vendor
                    && i.TotalAmount == request.TotalAmount
                    && i.InvoiceDate >= request.InvoiceDate.AddDays(-30)
                    && i.InvoiceDate <= request.InvoiceDate.AddDays(30))
                .ToListAsync();

            if (duplicates.Any())
            {
                var duplicateIds = string.Join(", ", duplicates.Select(d => d.InvoiceNumber));
                _logger.LogWarning("Potential duplicate invoice detected: {Vendor} ${Amount} on {Date}. Existing: {Duplicates}",
                    request.Vendor, request.TotalAmount, request.InvoiceDate, duplicateIds);

                return BadRequest(new
                {
                    error = "Potential duplicate invoice detected",
                    message = $"Found existing invoice(s) with same vendor, amount, and date: {duplicateIds}",
                    duplicates = duplicates.Select(d => new { d.Id, d.InvoiceNumber, d.CreatedDate })
                });
            }

            // Generate invoice number
            var invoiceNumber = await GenerateInvoiceNumber();

            // Create invoice
            var invoice = new Invoice
            {
                InvoiceNumber = invoiceNumber,
                Vendor = request.Vendor,
                VendorAddress = request.VendorAddress,
                InvoiceDate = request.InvoiceDate,
                DueDate = request.DueDate,
                VendorInvoiceNumber = request.VendorInvoiceNumber,
                PurchaseOrderNumber = request.PurchaseOrderNumber,
                SubtotalAmount = request.SubtotalAmount,
                TaxAmount = request.TaxAmount,
                ShippingAmount = request.ShippingAmount ?? 0,
                TotalAmount = request.TotalAmount,
                Status = InvoiceStatus.Pending,
                CreatedBy = request.CreatedBy ?? "AI Agent",
                CreatedDate = DateTime.UtcNow,
                ProcessingNotes = request.ProcessingNotes,
                Category = request.Category,
                LineItems = request.LineItems.Select(li => new InvoiceLineItem
                {
                    Description = li.Description,
                    Quantity = li.Quantity,
                    Unit = li.Unit,
                    UnitPrice = li.UnitPrice,
                    Amount = li.Amount,
                    ProductCode = li.ProductCode
                }).ToList()
            };

            _context.Invoices.Add(invoice);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created invoice {InvoiceNumber} for {Vendor} - ${Amount}",
                invoice.InvoiceNumber, invoice.Vendor, invoice.TotalAmount);

            var dto = MapToDto(invoice);
            return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating invoice for {Vendor}", request?.Vendor ?? "unknown");
            return StatusCode(500, "An error occurred while creating the invoice");
        }
    }

    /// <summary>
    /// Update an existing invoice
    /// </summary>
    /// <param name="id">Invoice ID</param>
    /// <param name="request">Updated invoice data</param>
    /// <returns>Updated invoice</returns>
    [HttpPut("{id}")]
    [ProducesResponseType(typeof(InvoiceDto), 200)]
    [ProducesResponseType(400)]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<InvoiceDto>> UpdateInvoice(int id, [FromBody] UpdateInvoiceRequest request)
    {
        try
        {
            var invoice = await _context.Invoices
                .Include(i => i.LineItems)
                .FirstOrDefaultAsync(i => i.Id == id);

            if (invoice == null)
            {
                return NotFound($"Invoice with ID {id} not found");
            }

            // Only allow updating status and processing notes
            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                if (Enum.TryParse<InvoiceStatus>(request.Status, true, out var status))
                {
                    invoice.Status = status;
                }
            }

            if (request.ProcessingNotes != null)
            {
                invoice.ProcessingNotes = string.IsNullOrWhiteSpace(invoice.ProcessingNotes)
                    ? request.ProcessingNotes
                    : $"{invoice.ProcessingNotes}\n{request.ProcessingNotes}";
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Updated invoice {InvoiceNumber} - Status: {Status}",
                invoice.InvoiceNumber, invoice.Status);

            return Ok(MapToDto(invoice));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating invoice {InvoiceId}", id);
            return StatusCode(500, "An error occurred while updating the invoice");
        }
    }

    /// <summary>
    /// Delete an invoice (for testing/cleanup only)
    /// </summary>
    /// <param name="id">Invoice ID</param>
    /// <returns>No content on success</returns>
    [HttpDelete("{id}")]
    [ProducesResponseType(204)]
    [ProducesResponseType(404)]
    [ProducesResponseType(500)]
    public async Task<IActionResult> DeleteInvoice(int id)
    {
        try
        {
            var invoice = await _context.Invoices.FindAsync(id);

            if (invoice == null)
            {
                return NotFound($"Invoice with ID {id} not found");
            }

            _context.Invoices.Remove(invoice);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Deleted invoice {InvoiceNumber}", invoice.InvoiceNumber);

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting invoice {InvoiceId}", id);
            return StatusCode(500, "An error occurred while deleting the invoice");
        }
    }

    /// <summary>
    /// Get invoice statistics
    /// </summary>
    /// <returns>Summary statistics for invoices</returns>
    [HttpGet("stats")]
    [ProducesResponseType(typeof(InvoiceStatsDto), 200)]
    [ProducesResponseType(500)]
    public async Task<ActionResult<InvoiceStatsDto>> GetInvoiceStats()
    {
        try
        {
            var topVendors = await _context.Invoices
                .GroupBy(i => i.Vendor)
                .Select(g => new VendorStatsDto
                {
                    Vendor = g.Key,
                    Count = g.Count(),
                    TotalAmount = g.Sum(i => i.TotalAmount)
                })
                .OrderByDescending(v => v.TotalAmount)
                .Take(10)
                .ToListAsync();

            var stats = new InvoiceStatsDto
            {
                TotalInvoices = await _context.Invoices.CountAsync(),
                PendingInvoices = await _context.Invoices.CountAsync(i => i.Status == InvoiceStatus.Pending),
                ApprovedInvoices = await _context.Invoices.CountAsync(i => i.Status == InvoiceStatus.Approved),
                PaidInvoices = await _context.Invoices.CountAsync(i => i.Status == InvoiceStatus.Paid),
                RejectedInvoices = await _context.Invoices.CountAsync(i => i.Status == InvoiceStatus.Rejected),
                DuplicateInvoices = await _context.Invoices.CountAsync(i => i.Status == InvoiceStatus.Duplicate),
                TotalAmount = await _context.Invoices.SumAsync(i => (decimal?)i.TotalAmount) ?? 0,
                PendingAmount = await _context.Invoices
                    .Where(i => i.Status == InvoiceStatus.Pending)
                    .SumAsync(i => (decimal?)i.TotalAmount) ?? 0,
                TopVendors = topVendors
            };

            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving invoice statistics");
            return StatusCode(500, "An error occurred while retrieving statistics");
        }
    }

    #region Helper Methods

    private string? ValidateInvoiceRequest(CreateInvoiceRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Vendor))
        {
            return "Vendor name is required";
        }

        if (request.InvoiceDate > DateTime.UtcNow.AddDays(1))
        {
            return "Invoice date cannot be in the future";
        }

        if (request.DueDate < request.InvoiceDate)
        {
            return "Due date must be on or after invoice date";
        }

        if (request.SubtotalAmount < 0)
        {
            return "Subtotal amount cannot be negative";
        }

        if (request.TaxAmount < 0)
        {
            return "Tax amount cannot be negative";
        }

        if (request.TotalAmount <= 0)
        {
            return "Total amount must be greater than zero";
        }

        // Validate math: subtotal + tax + shipping should equal total (within rounding tolerance)
        var calculatedTotal = request.SubtotalAmount + request.TaxAmount + (request.ShippingAmount ?? 0);
        if (Math.Abs(calculatedTotal - request.TotalAmount) > 0.01m)
        {
            return $"Total amount mismatch. Expected {calculatedTotal:C2}, got {request.TotalAmount:C2}";
        }

        if (request.LineItems == null || !request.LineItems.Any())
        {
            return "At least one line item is required";
        }

        // Validate line items sum to subtotal (within rounding tolerance)
        var lineItemsSum = request.LineItems.Sum(li => li.Amount);
        if (Math.Abs(lineItemsSum - request.SubtotalAmount) > 0.01m)
        {
            return $"Line items sum mismatch. Expected {lineItemsSum:C2}, got {request.SubtotalAmount:C2}";
        }

        // Validate each line item math
        foreach (var lineItem in request.LineItems)
        {
            if (lineItem.Quantity <= 0)
            {
                return $"Line item '{lineItem.Description}' has invalid quantity";
            }

            if (lineItem.UnitPrice < 0)
            {
                return $"Line item '{lineItem.Description}' has negative unit price";
            }

            var calculatedAmount = lineItem.Quantity * lineItem.UnitPrice;
            if (Math.Abs(calculatedAmount - lineItem.Amount) > 0.01m)
            {
                return $"Line item '{lineItem.Description}' amount mismatch. Expected {calculatedAmount:C2}, got {lineItem.Amount:C2}";
            }
        }

        return null; // No errors
    }

    private async Task<string> GenerateInvoiceNumber()
    {
        var year = DateTime.UtcNow.Year;
        var prefix = $"INV-{year}-";

        // Get the last invoice number for this year
        var lastInvoice = await _context.Invoices
            .Where(i => i.InvoiceNumber.StartsWith(prefix))
            .OrderByDescending(i => i.InvoiceNumber)
            .FirstOrDefaultAsync();

        int nextNumber = 1;
        if (lastInvoice != null)
        {
            // Extract the number part and increment
            var numberPart = lastInvoice.InvoiceNumber.Substring(prefix.Length);
            if (int.TryParse(numberPart, out int lastNumber))
            {
                nextNumber = lastNumber + 1;
            }
        }

        return $"{prefix}{nextNumber:D6}";
    }

    private static InvoiceDto MapToDto(Invoice invoice)
    {
        return new InvoiceDto
        {
            Id = invoice.Id,
            InvoiceNumber = invoice.InvoiceNumber,
            Vendor = invoice.Vendor,
            VendorAddress = invoice.VendorAddress,
            InvoiceDate = invoice.InvoiceDate,
            DueDate = invoice.DueDate,
            VendorInvoiceNumber = invoice.VendorInvoiceNumber,
            PurchaseOrderNumber = invoice.PurchaseOrderNumber,
            SubtotalAmount = invoice.SubtotalAmount,
            TaxAmount = invoice.TaxAmount,
            ShippingAmount = invoice.ShippingAmount,
            TotalAmount = invoice.TotalAmount,
            Status = invoice.Status.ToString(),
            CreatedBy = invoice.CreatedBy,
            CreatedDate = invoice.CreatedDate,
            ProcessingNotes = invoice.ProcessingNotes,
            Category = invoice.Category,
            LineItems = invoice.LineItems.Select(li => new InvoiceLineItemDto
            {
                Id = li.Id,
                Description = li.Description,
                Quantity = li.Quantity,
                Unit = li.Unit,
                UnitPrice = li.UnitPrice,
                Amount = li.Amount,
                ProductCode = li.ProductCode
            }).ToList()
        };
    }

    #endregion
}
