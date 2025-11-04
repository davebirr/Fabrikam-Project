# 💡 Hints: Invoice Processing Pipeline

**Smart hints without spoilers!** Use these progressively as you build your solution.

---

## 🎯 General Strategy Hints

<details>
<summary><strong>Hint 1: Start Simple, Then Expand</strong></summary>

Don't try to build the perfect solution immediately! Follow this progression:

1. **First**: Get ONE simple invoice processed end-to-end
   - Extract vendor and total manually if needed
   - Submit to API
   - Celebrate success! 🎉

2. **Second**: Add more field extraction
   - Invoice number, dates
   - Line items (even if just one)

3. **Third**: Add validation
   - Required fields check
   - Basic math validation

4. **Finally**: Polish and enhance
   - Duplicate detection
   - Error handling
   - Batch processing

**Why**: Early success builds momentum and helps you understand the flow.

</details>

<details>
<summary><strong>Hint 2: Choose the Right Approach for Your Skills</strong></summary>

Match your approach to your experience level:

| Your Background | Best Approach | Why |
|----------------|---------------|-----|
| Low-code/Power Platform | M365 + Power Automate | Familiar tools, drag-and-drop |
| Cloud/Azure focus | Azure AI Foundry + Document Intelligence | Production-ready, highest accuracy |
| Curious about Computer Use | Copilot Studio | Newest capabilities, exciting demos |
| Developer mindset | Agent Framework + MCP | Full control, custom logic |

**Tip**: Don't switch approaches mid-challenge. Commit to one and see it through!

</details>

<details>
<summary><strong>Hint 3: Test with Easy Invoices First</strong></summary>

Process these invoices in order of increasing complexity:

1. **Start**: `006-ecopanel-systems-simple.md` (simplest)
2. **Next**: `001-premium-lumber-supply.md` (standard format)
3. **Then**: `003-transmodular-logistics.md` (service invoice)
4. **Challenge**: `007-solaredge-solutions-complex.md` (most complex)
5. **Finally**: `008-duplicate-test-invoice.md` (tests duplicate detection)

**Why**: Build confidence with easy wins before tackling complex scenarios.

</details>

---

## 🔧 Technology-Specific Hints

### Copilot Studio + Computer Use

<details>
<summary><strong>Hint CS-1: Setting Up Computer Use</strong></summary>

Computer Use provides a hosted browser for AI-driven web automation:

**Setup Steps**:
1. In Copilot Studio, click **Tools** in the left sidebar
2. Select **Computer Use** from the tools list
3. Click **+ Add to agent** and choose your agent
4. In the **New Computer Use** dialog:
   - **Instructions**: Provide guidance for what the AI should do
     - Example: `"Open https://example.com, Go to add invoice, fill in the provided details, Select submit invoice"`
   - **Prompt Templates** (optional): Choose from:
     - Invoice processing
     - Data Entry  
     - Data Extraction
   - **Use Hosted Browser**: Keep checked (default)
     - This provides a ready-to-use machine for web automation
     - Supports public-facing websites (not custom desktop apps or internal sites)

**Learn More**: [Computer Use Documentation](https://go.microsoft.com/fwlink/?linkid=2328405)

**Key Insight**: Computer Use treats the browser like a human would—it "sees" the page visually and can interact with forms, buttons, and content.

</details>

<details>
<summary><strong>Hint CS-2: Extraction Strategy</strong></summary>

For invoice data extraction via Computer Use:

1. **Upload** invoice PDF to a temporary viewing page
2. **Instruct AI** to read invoice fields visually:
   ```
   "Look at the invoice displayed. Find and extract:
   - Vendor name (usually at top)
   - Invoice number (look for 'Invoice #' or similar)
   - Total amount (often at bottom, may say 'Total Due' or 'Amount Due')
   - Line items table (description, quantity, price, amount)"
   ```

3. **Ask AI to return structured data**:
   ```
   "Return this as JSON with fields: vendor, invoiceNumber, totalAmount, lineItems"
   ```

**Why**: Visual extraction works well but needs clear instructions about where to look.

</details>

<details>
<summary><strong>Hint CS-3: API Integration</strong></summary>

After extracting data, call the Fabrikam Invoice API:

1. Add a **Power Automate flow** action to your Copilot
2. In the flow, use **HTTP** action
3. Configure:
   - Method: `POST`
   - URL: `https://localhost:7297/api/invoices`
   - Headers: `Content-Type: application/json`
   - Body: Pass the extracted JSON from Computer Use

**Alternative**: Use Copilot Studio's built-in HTTP connector if available.

</details>

---

### Azure AI Foundry + Document Intelligence

<details>
<summary><strong>Hint AI-1: Document Intelligence Setup</strong></summary>

Azure AI Document Intelligence has a **prebuilt invoice model**:

1. Create an Azure AI Services resource (or use existing)
2. Get your endpoint and API key
3. Use the **prebuilt-invoice** model (no training needed!)

**Endpoint pattern**:
```
https://<your-resource>.cognitiveservices.azure.com/formrecognizer/documentModels/prebuilt-invoice:analyze?api-version=2023-07-31
```

**Why**: Microsoft's prebuilt model is trained on thousands of invoice formats.

</details>

<details>
<summary><strong>Hint AI-2: Calling Document Intelligence</strong></summary>

Submit your PDF to Document Intelligence:

```http
POST https://<resource>.cognitiveservices.azure.com/formrecognizer/documentModels/prebuilt-invoice:analyze?api-version=2023-07-31
Ocp-Apim-Subscription-Key: <your-key>
Content-Type: application/pdf

<PDF binary data>
```

**Response includes**:
- Vendor name
- Invoice number/ID
- Invoice date, due date
- Total amount, tax amount
- Line items with descriptions and amounts
- **Confidence scores** for each field!

**Pro Tip**: Check confidence scores. If < 0.7, flag for manual review.

</details>

<details>
<summary><strong>Hint AI-3: Mapping to Fabrikam API</strong></summary>

Document Intelligence fields → Fabrikam API fields:

| Document Intelligence | Fabrikam API |
|----------------------|--------------|
| `VendorName` | `vendor` |
| `InvoiceId` | `invoiceNumber` |
| `InvoiceDate` | `invoiceDate` |
| `DueDate` | `dueDate` |
| `SubTotal` | `subtotalAmount` |
| `TotalTax` | `taxAmount` |
| `InvoiceTotal` | `totalAmount` |
| `Items` array | `lineItems` array |

**Watch out**: Some field names are slightly different! Map them carefully.

</details>

---

### M365 Copilot + Power Automate

<details>
<summary><strong>Hint M365-1: Flow Structure</strong></summary>

Build your Power Automate flow with these steps:

1. **Trigger**: Manual trigger or file upload trigger
2. **Get file content**: Read the invoice PDF
3. **AI Builder - Extract invoice**: Use AI Builder's invoice processing
4. **Parse JSON**: Extract fields from AI Builder response
5. **HTTP - POST**: Submit to Fabrikam Invoice API
6. **Compose**: Create success/error message

**Tip**: Test each step individually before connecting them all.

</details>

<details>
<summary><strong>Hint M365-2: AI Builder Invoice Processing</strong></summary>

AI Builder has a prebuilt **Invoice Processing** model:

1. In your flow, add **AI Builder** action
2. Choose **Extract information from invoices**
3. Pass your PDF file content
4. AI Builder returns JSON with invoice fields

**Output includes**:
- Vendor/Supplier name
- Invoice number
- Dates
- Total amount
- Line items

**Pro Tip**: The output is already structured JSON—easy to map to API!

</details>

<details>
<summary><strong>Hint M365-3: Validation in Power Automate</strong></summary>

Add validation steps before submitting:

1. **Condition**: Check if `TotalAmount` is not null
2. **Condition**: Check if `VendorName` is not empty
3. **Compose** action: Calculate line items sum
4. **Condition**: Compare sum to subtotal (should match within $0.01)

If validation fails:
- **Yes branch**: Submit to API
- **No branch**: Send error notification

**Why**: Catch bad data before it reaches the API.

</details>

---

### Agent Framework + Custom MCP

<details>
<summary><strong>Hint MCP-1: OCR Library Selection</strong></summary>

For custom extraction, you'll need an OCR library:

**Python Options**:
- `pytesseract` (free, good for text-heavy PDFs)
- `pdf2image` + `Pillow` (convert PDF to images first)
- `PyPDF2` (for text-based PDFs, no OCR needed)

**C# Options**:
- `IronOCR` (commercial, very accurate)
- `Tesseract` NuGet package (free, requires setup)
- `Azure.AI.FormRecognizer` SDK (uses Document Intelligence)

**Quick Win**: Use `PyPDF2` or similar if your PDFs have selectable text!

</details>

<details>
<summary><strong>Hint MCP-2: MCP Tool Structure</strong></summary>

Create an MCP tool for invoice processing:

```csharp
[McpServerTool, Description("Process invoice PDF and submit to Fabrikam API")]
public async Task<object> ProcessInvoice(string filePath)
{
    // 1. Extract text from PDF
    var invoiceText = ExtractTextFromPdf(filePath);
    
    // 2. Use LLM to parse invoice text into structured data
    var extractedData = await ParseInvoiceWithLLM(invoiceText);
    
    // 3. Validate the extracted data
    var validationResult = ValidateInvoice(extractedData);
    
    if (!validationResult.IsValid)
    {
        return new { error = validationResult.Errors };
    }
    
    // 4. Submit to Fabrikam Invoice API
    var apiResponse = await SubmitToInvoiceApi(extractedData);
    
    return new { success = true, invoiceNumber = apiResponse.InvoiceNumber };
}
```

**Why**: Breaking into clear steps makes debugging easier.

</details>

<details>
<summary><strong>Hint MCP-3: Using LLM for Parsing</strong></summary>

After OCR extraction, use an LLM to structure the data:

```csharp
var prompt = $@"Parse this invoice text and return JSON with these fields:
- vendor (string)
- invoiceNumber (string)
- invoiceDate (YYYY-MM-DD)
- dueDate (YYYY-MM-DD)
- subtotalAmount (decimal)
- taxAmount (decimal)
- totalAmount (decimal)
- lineItems (array of: description, quantity, unitPrice, amount)

Invoice text:
{invoiceText}

Return only valid JSON, no explanation.";

var response = await CallLLM(prompt);
var invoice = JsonSerializer.Deserialize<InvoiceDto>(response);
```

**Why**: LLMs are excellent at extracting structured data from unstructured text!

</details>

---

## ✅ Validation Hints

<details>
<summary><strong>Hint V-1: Math Validation Strategy</strong></summary>

The API validates math, but you should too (to give better errors):

**Check 1: Line Items Sum**
```
lineItemsSum = sum(each lineItem.amount)
if (abs(lineItemsSum - invoice.subtotalAmount) > 0.01):
    error("Line items sum to {lineItemsSum} but subtotal is {subtotalAmount}")
```

**Check 2: Total Calculation**
```
calculatedTotal = subtotalAmount + taxAmount + shippingAmount
if (abs(calculatedTotal - totalAmount) > 0.01):
    error("Calculated total {calculatedTotal} doesn't match invoice total {totalAmount}")
```

**Check 3: Line Item Math**
```
for each lineItem:
    calculatedAmount = quantity * unitPrice
    if (abs(calculatedAmount - lineItem.amount) > 0.01):
        error("Line item {description} math is wrong")
```

**Tip**: Use $0.01 tolerance for rounding differences.

</details>

<details>
<summary><strong>Hint V-2: Duplicate Detection</strong></summary>

Before submitting, check for duplicates:

```http
GET /api/invoices/check-duplicates?vendor={vendor}&totalAmount={total}&invoiceDate={date}
```

**The API looks for**:
- Same vendor name
- Same total amount
- Invoice date within ±30 days

**Your options**:
1. **Auto-skip**: Don't submit if duplicate found
2. **Warn user**: "Potential duplicate found, proceed anyway? (Y/N)"
3. **Flag for review**: Submit with special note

**Why**: Prevents double-paying suppliers!

</details>

<details>
<summary><strong>Hint V-3: Date Validation</strong></summary>

Check dates before submission:

```csharp
// Invoice date should not be future-dated
if (invoice.InvoiceDate > DateTime.Now)
{
    return "Error: Invoice date cannot be in the future";
}

// Due date should be >= invoice date
if (invoice.DueDate < invoice.InvoiceDate)
{
    return "Error: Due date must be on or after invoice date";
}

// Reasonable date range (e.g., within 2 years)
if (invoice.InvoiceDate < DateTime.Now.AddYears(-2))
{
    return "Warning: Invoice is more than 2 years old";
}
```

**Why**: Catches data extraction errors early.

</details>

---

## 🎯 Workflow Hints

<details>
<summary><strong>Hint W-1: Batch Processing Pattern</strong></summary>

To process multiple invoices efficiently:

1. **Collect all invoice files** in a directory
2. **Loop through each file**:
   ```
   for each file in invoiceDirectory:
       result = ProcessInvoice(file)
       
       if result.success:
           successCount++
           Log "✅ {file} - Invoice {result.invoiceNumber}"
       else:
           failureCount++
           Log "❌ {file} - Error: {result.error}"
   ```

3. **Generate summary report**:
   ```
   Processed: {totalCount} invoices
   Successful: {successCount}
   Failed: {failureCount}
   Total Amount: ${sumOfSuccessfulInvoices}
   ```

**Tip**: Keep going even if one invoice fails!

</details>

<details>
<summary><strong>Hint W-2: Error Handling Strategy</strong></summary>

Handle different error types appropriately:

| Error Type | What to Do |
|------------|-----------|
| **OCR failed** | Log error, skip invoice, report "unreadable" |
| **Validation failed** | Show specific validation errors, don't submit |
| **Duplicate found** | Ask user or auto-skip, don't fail completely |
| **API error (400)** | Show API error message (bad request) |
| **API error (500)** | Retry once, then log and continue |
| **Network error** | Retry 3 times with delay, then fail gracefully |

**Why**: Different errors need different recovery strategies.

</details>

<details>
<summary><strong>Hint W-3: User Experience Tips</strong></summary>

Make your solution user-friendly:

**Good Progress Updates**:
```
Processing invoice 1 of 8...
✅ Premium Lumber Supply - $80,433.30 - Success
Processing invoice 2 of 8...
⚠️  SmartGlass Tech - Potential duplicate detected
Processing invoice 3 of 8...
❌ Malformed invoice - Math validation failed
...
```

**Clear Error Messages**:
```
❌ Invoice 005-climatecontrol.pdf failed validation:
   - Line items sum to $102,450 but subtotal is $103,200
   - Difference: $750.00
   - Suggestion: Check if discount was applied but not listed
```

**Helpful Summaries**:
```
📊 Processing Complete!
✅ Successfully submitted: 6 invoices ($862,345.09)
⚠️  Skipped duplicates: 1 invoice
❌ Failed validation: 1 invoice

Next steps:
- Review failed invoice: 005-climatecontrol.pdf
- Check duplicate: 008-duplicate-test.pdf
```

**Why**: Users appreciate knowing what happened and what to do next!

</details>

---

## 🚀 Quick Wins

<details>
<summary><strong>Quick Win 1: Manual Extraction Test</strong></summary>

Before automating extraction, manually create one invoice submission:

1. Open `001-premium-lumber-supply.md`
2. Copy the data into a JSON structure
3. Use Postman/curl to POST to the API
4. Verify it works!

**Why**: Proves your API connection works before building extraction logic.

</details>

<details>
<summary><strong>Quick Win 2: Stats API for Verification</strong></summary>

After submitting invoices, check stats:

```http
GET /api/invoices/stats
```

**Shows you**:
- Total invoices submitted
- Total dollar amount
- Count by status (pending/approved/paid)
- Top vendors

**Why**: Quick way to verify your invoices were actually created!

</details>

<details>
<summary><strong>Quick Win 3: Start with JSON Instead of PDF</strong></summary>

If PDF extraction is taking too long:

1. Manually type invoice data into JSON
2. Build validation and submission logic first
3. Add PDF extraction later

**Example**:
```json
{
  "vendor": "Premium Lumber Supply Co.",
  "invoiceNumber": "PLS-2025-10847",
  "invoiceDate": "2025-01-15",
  "totalAmount": 80433.30
}
```

**Why**: Validates your approach works before tackling OCR complexity.

</details>

---

## 🤔 Common Pitfalls

<details>
<summary><strong>Pitfall 1: Decimal Precision Issues</strong></summary>

**Problem**: `80433.3` vs `80433.30` causes validation failures

**Solution**: Always format decimals to 2 places:
```csharp
decimal amount = 80433.3m;
string formatted = amount.ToString("F2"); // "80433.30"
```

**Why**: Financial calculations require consistent precision.

</details>

<details>
<summary><strong>Pitfall 2: Date Format Confusion</strong></summary>

**Problem**: API expects `YYYY-MM-DD` but you send `MM/DD/YYYY`

**Solution**: Always format dates consistently:
```csharp
DateTime invoiceDate = new DateTime(2025, 1, 15);
string formatted = invoiceDate.ToString("yyyy-MM-dd"); // "2025-01-15"
```

**Why**: ISO 8601 format (YYYY-MM-DD) is unambiguous and API-standard.

</details>

<details>
<summary><strong>Pitfall 3: Missing Line Items</strong></summary>

**Problem**: Submit invoice without line items, validation fails

**API Requirement**: At least 1 line item must be provided

**Solution**: Always include line items array:
```json
{
  "vendor": "Test Vendor",
  "lineItems": [
    {
      "description": "Product ABC",
      "quantity": 1,
      "unitPrice": 100.00,
      "amount": 100.00
    }
  ]
}
```

**Why**: Invoice without line items isn't useful for accounting.

</details>

---

## 📚 Additional Resources

- **Sample Invoices README**: Detailed extraction guide and API documentation
- **Fabrikam Invoice API**: Test with `/api/invoices/stats` to verify connection
- **API Testing**: Use `curl` or Postman to manually test endpoints first

---

**Remember**: These hints are here to help when you're stuck. Try solving challenges yourself first—that's where the learning happens! 🧠

**Need more help?** Check the [Partial Solution](./partial-solution-invoice-processing.md) for architecture guidance.

**Ready to peek?** See the [Full Solution](./full-solution-invoice-processing.md) for complete implementations. (But try on your own first!)
