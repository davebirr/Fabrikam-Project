# Sample Invoice Documentation

This directory contains realistic supplier invoices that Fabrikam Modular Homes receives from various vendors. These invoices are designed for testing your automated invoice processing solution.

## Invoice Collection Overview

| Invoice | Vendor | Amount | Complexity | Purpose |
|---------|--------|--------|------------|---------|
| **001** | Premium Lumber Supply | $80,433.30 | ⭐⭐ Medium | Standard multi-line invoice |
| **002** | SmartGlass Technologies | $228,454.05 | ⭐⭐⭐ Complex | Rich formatting, volume discount |
| **003** | TransModular Logistics | $13,320.00 | ⭐⭐ Medium | Service invoice, no tax |
| **004** | ModularTech Appliances | $168,895.56 | ⭐⭐⭐ Complex | Package pricing, volume discount |
| **005** | ClimateControl HVAC | $115,658.80 | ⭐⭐⭐⭐ Very Complex | Equipment + services, split tax |
| **006** | EcoPanel Systems | $35,101.33 | ⭐ Simple | Handwritten-style, basic format |
| **007** | SolarEdge Solutions | $220,480.85 | ⭐⭐⭐⭐⭐ Extremely Complex | Multi-system, financing options |
| **008** | Premium Lumber (Duplicate) | $80,433.30 | ⭐ Test Case | **Duplicate detection test** |

## Fabrikam's Supplier Ecosystem

### **Core Materials & Components**
- **Premium Lumber Supply Co.** - Engineered lumber, sustainable timber
- **SmartGlass Technologies** - Energy-efficient windows with IoT sensors
- **ModularTech Appliances** - Smart home appliance packages
- **EcoPanel Systems** - Structural insulated panels (SIPs)

### **Technology & Systems**
- **HomeAI Integration** - Smart home automation (not included yet)
- **SolarEdge Solutions** - Solar panel arrays and battery storage
- **ClimateControl HVAC** - High-efficiency heating/cooling systems
- **SecureHome Systems** - Advanced security (not included yet)

### **Logistics & Services**
- **TransModular Logistics** - Specialized modular transport
- **CraneTech Services** - Heavy lifting and placement (not included yet)
- **SitePrep Excavation** - Foundation preparation (not included yet)
- **QualityPro Inspections** - Third-party certifications (not included yet)

## Data Extraction Guide

### **Required Fields**
Your invoice processing automation should extract:

1. **Vendor Information**
   - Vendor name
   - Vendor address
   - Contact information
   - Tax ID (if present)

2. **Invoice Details**
   - Invoice number
   - Vendor's invoice number (if different)
   - Invoice date
   - Due date
   - Purchase order number

3. **Financial Data**
   - Subtotal amount
   - Tax amount (including rate if stated)
   - Shipping/freight charges
   - **Total amount**

4. **Line Items** (for each item)
   - Description
   - Quantity
   - Unit of measure
   - Unit price
   - Line total

### **Validation Rules**

Your solution should validate:

✅ **Math Accuracy**
- Line items sum to subtotal
- Subtotal + tax + shipping = total
- Quantity × unit price = line total

✅ **Data Completeness**
- Vendor name is present
- Invoice date is valid (not future-dated)
- Due date ≥ invoice date
- Total amount > 0

✅ **Duplicate Detection**
- Check for invoices with same vendor, amount, and date (±30 days)
- Invoice #008 should trigger duplicate alert (matches #001)

✅ **Business Rules**
- Tax rate is reasonable (WA sales tax is 8.5% in these examples)
- Dates are in valid format
- All required fields present

## API Endpoints

Once extracted and validated, submit invoices to:

### **Create Invoice**
```http
POST https://localhost:7297/api/invoices
Content-Type: application/json

{
  "vendor": "Premium Lumber Supply Co.",
  "vendorAddress": "2847 Forest Drive, Tacoma, WA 98402",
  "invoiceDate": "2025-01-15",
  "dueDate": "2025-02-14",
  "vendorInvoiceNumber": "PLS-2025-10847",
  "purchaseOrderNumber": "FAB-PO-25-0089",
  "subtotalAmount": 72980.00,
  "taxAmount": 6203.30,
  "shippingAmount": 1250.00,
  "totalAmount": 80433.30,
  "category": "Materials",
  "createdBy": "YourAgentName",
  "processingNotes": "Extracted from PDF via [Your Method]",
  "lineItems": [
    {
      "description": "Glulam Beams - 24ft Engineered",
      "quantity": 48,
      "unit": "ea",
      "unitPrice": 385.00,
      "amount": 18480.00,
      "productCode": "EW-2024-GL"
    },
    // ... more line items
  ]
}
```

### **Check for Duplicates**
```http
GET https://localhost:7297/api/invoices/check-duplicates?vendor=Premium+Lumber+Supply+Co.&totalAmount=80433.30&invoiceDate=2025-01-15
```

### **List All Invoices**
```http
GET https://localhost:7297/api/invoices
```

### **Get Invoice Statistics**
```http
GET https://localhost:7297/api/invoices/stats
```

## Testing Strategy

### **Test 1: Simple Invoice (EcoPanel Systems)**
Start with invoice #006 - simple format, easy to parse
- **Expected outcome:** Successful extraction and submission
- **Validation:** Math checks pass, no duplicates

### **Test 2: Standard Invoice (Premium Lumber)**
Process invoice #001 - typical supplier invoice
- **Expected outcome:** Complete line item extraction
- **Validation:** 4 line items, tax calculation correct

### **Test 3: Complex Invoice (SmartGlass)**
Process invoice #002 - rich formatting, discount
- **Expected outcome:** Handle volume discount correctly
- **Validation:** Subtotal reflects discount, not just sum of line items

### **Test 4: Service Invoice (TransModular)**
Process invoice #003 - services (no sales tax on labor)
- **Expected outcome:** Recognize labor/services (different tax treatment)
- **Validation:** Tax = $0 (transportation exempt)

### **Test 5: Duplicate Detection**
Process invoice #008 after #001
- **Expected outcome:** API should reject as potential duplicate
- **Validation:** Error message with reference to existing invoice

### **Test 6: Extremely Complex (SolarEdge)**
Process invoice #007 - multiple sections, payment options
- **Expected outcome:** Extract despite complexity
- **Validation:** Handle equipment + installation split, correct totals

## Success Criteria

### **Basic (30 points)**
- Extract vendor name, invoice date, total amount
- Submit to API successfully
- Display confirmation message

### **Good (60 points)**
- Extract all required fields (vendor, dates, amounts, line items)
- Validate math (line items sum, tax calculation)
- Check for duplicates before submission
- Handle API errors gracefully

### **Excellent (100 points)**
- Process multiple invoices in batch
- Generate summary report (total invoices, total amount, by vendor)
- Create audit log of processing
- Handle different invoice formats automatically

### **Bonus (20 points)**
- Monitor a folder for new invoices and process automatically
- Send email notification after processing
- Create dashboard showing invoice statistics
- Implement retry logic for API failures

## Converting Markdown to PDF

These invoices are provided as Markdown files. Convert them to PDF using:

### **Option 1: Online Converter**
- https://www.markdowntopdf.com/
- Upload .md file, download PDF

### **Option 2: VS Code + Extension**
```bash
# Install Markdown PDF extension
code --install-extension yzane.markdown-pdf

# Right-click .md file > "Markdown PDF: Export (pdf)"
```

### **Option 3: Command Line (requires pandoc)**
```bash
pandoc 001-premium-lumber-supply.md -o 001-premium-lumber-supply.pdf
```

### **Option 4: Python Script**
```python
import markdown
from weasyprint import HTML

with open('001-premium-lumber-supply.md', 'r') as f:
    html = markdown.markdown(f.read())
    HTML(string=html).write_pdf('001-premium-lumber-supply.pdf')
```

## Tips for Implementation

### **For Copilot Studio (Computer Use)**
1. Upload PDF to accessible location
2. Use Computer Use to open PDF in browser
3. Extract text using vision capabilities
4. Parse data with pattern matching
5. Submit to API via HTTP action

### **For Azure AI Foundry (Document Intelligence)**
1. Use Document Intelligence prebuilt invoice model
2. Extract fields automatically
3. Map to API schema
4. Submit via custom action

### **For M365 Copilot (Power Automate)**
1. Trigger on file upload to SharePoint
2. Use AI Builder "Extract information from invoices"
3. Map fields to JSON
4. HTTP POST to Fabrikam API

### **For Agent Framework (Custom MCP)**
1. Create MCP tool for PDF processing
2. Use OCR library (pytesseract, pdf-lib)
3. Parse extracted text
4. Validate and submit

## Need Help?

Check these resources:
- **API Documentation:** Run API locally and visit `/swagger`
- **Hints File:** See `hints-invoice-processing.md` (if stuck)
- **Partial Solution:** See `partial-solution-invoice-processing.md` (architecture only)
- **Full Solution:** See `full-solution-invoice-processing.md` (complete implementation)

---

**Remember:** The goal is to demonstrate automated document processing, not just manual data entry. Show how your agent can intelligently extract, validate, and submit invoices with minimal human intervention!

Good luck! 🚀📄💡
