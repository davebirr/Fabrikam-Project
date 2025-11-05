# 🟡 Intermediate Challenge: Multi-Agent Orchestration

**Level Up with Specialist Agents** | 90 minutes | Self-Directed

---

## 🎯 Challenge Overview

You've built a solid foundation agent. Now it's time to scale! Real customer service organizations have **specialists** for different domains. Your challenge: build a multi-agent system where an orchestrator routes customers to the right specialist.

**The Evolution**:
- **Beginner**: One agent does everything
- **Intermediate**: Orchestrator + specialist agents working together
- **Advanced**: Production-grade enterprise system

---

## 💡 **Starting with Intermediate? Get a Quick Foundation!**

**Jumping straight to intermediate?** Smart move! Here's how to get oriented quickly using beginner challenge resources:

### **Option 1: Use the Beginner Full Solution as a Starting Point** ⭐ RECOMMENDED

The beginner challenge has a complete, tested system prompt and agent setup that gives you one specialist "for free":

1. **Open Beginner Full Solution**: [View Full Solution](../01-beginner/full-solution.md)
2. **Copy the system prompt** - It's already refined through testing
3. **Create "Fabrikam Technical Specialist"** in Copilot Studio using that prompt
4. **Connect the 4 MCP tools** (get_orders, get_products, get_customers, create_support_ticket)
5. **Test with a quick order lookup** to verify MCP tools work
6. **Now proceed with your multi-agent challenge!**

**Time Investment**: 5-10 minutes  
**Value**: Verified MCP connection, working base agent, understanding of the business

### **Option 2: Start Fresh (The Hard Way)**

Prefer to figure everything out yourself? Go for it! Just know:
- ❌ You'll need to figure out MCP tool connections
- ❌ You'll need to discover business rules (30-day production timeline, ticket categories)
- ❌ You'll need to test conversation flows from scratch
- ⚠️ **Budget extra time** for this exploration!

### **Either Way: The Technical Specialist is Your "Free" Agent**

The multi-agent architecture uses 4 specialists. **Good news**: The Technical Specialist uses the same tools and logic as the beginner challenge!

- If you used Option 1: Just rename your beginner agent to "Technical Specialist" ✅
- If you used Option 2: Use [beginner system prompt](../01-beginner/full-solution.md) as your Technical Specialist template

**Result**: You start with 1 specialist and only need to build 3 more + orchestrator! 🚀

---

## 🎪 Choose Your Path

Pick the challenge that excites you most, or tackle multiple if you're ambitious!

### **🌟 Option A: Multi-Agent Orchestration** (Recommended)
Build an orchestrator that routes to specialist agents

**Difficulty**: ⭐⭐⭐  
**Time Estimate**: 75-90 minutes  
**Coolness Factor**: 🔥🔥🔥

### **🖼️ Option B: Vision Integration**
Add image analysis for damage assessment

**Difficulty**: ⭐⭐  
**Time Estimate**: 60-75 minutes  
**Coolness Factor**: 🔥🔥

### **📄 Option C: Invoice Processing Pipeline**
Build an agent that processes supplier invoices automatically

**Difficulty**: ⭐⭐⭐  
**Time Estimate**: 75-90 minutes  
**Coolness Factor**: 🔥🔥🔥🔥

---

## 🌟 Option A: Multi-Agent Orchestration (Primary Challenge)

### **The Scenario**

Fabrikam is growing fast! They now have specialized departments:
- **Sales Team**: Product recommendations, pricing, customization
- **Technical Team**: Installation, repairs, warranty claims
- **Billing Team**: Payments, refunds, financing options
- **Escalation Team**: Complaints, legal issues, executive review

**Your Mission**: Build an **Orchestrator Agent** that intelligently routes customers to the right specialist, maintains context, and delivers seamless experiences.

---

### **Architecture**

```
Customer Request
      ↓
┌─────────────────────┐
│  Orchestrator Agent │  ← Main entry point
│  "Customer Service  │
│       Hub"          │
└─────────────────────┘
      ↓ Routes to
      ├─→ 🛒 Sales Specialist Agent
      ├─→ 🔧 Technical Specialist Agent (your beginner agent!)
      ├─→ 💰 Billing Specialist Agent
      └─→ 🚨 Escalation Specialist Agent
```

**The Smart Part:** Your beginner "Fabrikam Customer Service" agent already has the tools and logic for Technical Specialist! Just rename and refocus it, then build 3 new specialists around it.

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Orchestrator correctly identifies which specialist to route to
- ✅ **Technical Specialist refined** from beginner agent (or created fresh)
- ✅ **At least 1 additional specialist** working (Sales, Billing, OR Escalation)
- ✅ Basic context passed between agents
- ✅ Customer can complete simple requests

#### **Good Success (60 points)**
- ✅ **All 4 specialist agents implemented** (Technical + 3 new specialists)
- ✅ Seamless handoffs with full context
- ✅ Multi-turn conversations within specialists
- ✅ Natural transitions ("Let me connect you to...")
- ✅ Orchestrator can route to multiple specialists in sequence

#### **Excellent Success (100 points)**
- ✅ Intelligent intent classification (handles ambiguous requests)
- ✅ Context summarization between handoffs
- ✅ Specialists can escalate back to orchestrator
- ✅ Conversation history maintained across specialists
- ✅ Orchestrator makes smart routing decisions based on conversation flow
- ✅ Professional handoff language and experience

#### **Bonus Features (up to 20 points)**
- 🌟 Parallel specialist consultation (orchestrator asks multiple specialists)
- 🌟 Learning from past routing decisions
- 🌟 Sentiment-based routing (frustrated customers go to escalation)
- 🌟 Conversation summarization at end
- 🌟 Proactive specialist suggestions

---

### **🧪 Test Scenarios**

#### **Scenario 1: Simple Single-Specialist Routing**
```
Customer: "I want to buy the Family Haven 1800. What financing do you offer?"

Expected Flow:
1. Orchestrator: Identifies "buy" + "financing", then routes to Sales
2. Sales Agent: Provides product info + financing options
3. Sales Agent: Can answer follow-up questions
```

#### **Scenario 2: Multi-Specialist Complex Request**
```
Customer: "My order is delayed and I want a refund"

Expected Flow:
1. Orchestrator: Identifies "order delayed" + "refund"
2. Orchestrator: Routes to Technical (check order status first)
3. Technical: Looks up order, confirms delay, creates ticket
4. Technical: Hands off to Billing
5. Billing: Explains refund policy, processes request
6. Orchestrator: Confirms resolution with customer
```

#### **Scenario 3: Ambiguous Intent Clarification**
```
Customer: "I have a problem with my home"

Expected Flow:
1. Orchestrator: Recognizes ambiguity
2. Orchestrator: Asks clarifying questions
   - "Can you describe the issue? Is it structural, billing, or delivery-related?"
3. Customer: "The walls are cracking"
4. Orchestrator: Routes to Technical (structural issue)
```

#### **Scenario 4: Escalation Path**
```
Customer: "This is the third time I've called! I want to speak to a manager!"

Expected Flow:
1. Orchestrator: Detects frustration + "manager"
2. Orchestrator: Immediately routes to Escalation
3. Escalation: Empathetic acknowledgment, gathers history
4. Escalation: Creates high-priority ticket with manager assignment
```

---

### **🏗️ Implementation Approaches**

#### **Approach 1: Multiple Copilot Studio Agents** (Easiest)
Create 5 separate agents in Copilot Studio:
- Orchestrator Agent (main entry point)
- Sales Specialist Agent
- Technical Specialist Agent
- Billing Specialist Agent
- Escalation Specialist Agent

**Handoff Method**: Use Copilot Studio's built-in handoff features or topics that redirect

#### **Approach 2: Single Agent with Specialized Topics** (Simpler Setup)
One agent with different Topics acting as "specialists":
- Main Topic: Orchestration and routing
- Sales Topic: Product and pricing
- Technical Topic: Orders and support
- Billing Topic: Payments and refunds
- Escalation Topic: Complaints

**Handoff Method**: Topic transitions within same agent

#### **Approach 3: Agent + Functions** (Most Flexible)
Orchestrator agent that calls specialist "functions" (tools):
- Each specialist is a custom MCP tool
- Orchestrator decides which tool to call
- Tools return specialized responses

---

### **💡 Hints & Tips**

**Available Without Spoilers!** [View Hints](./hints-multi-agent.md)

---

### **⚠️ Partial Solution**

**Architecture & Patterns** [View Partial Solution](./partial-solution-multi-agent.md)

---

### **🚨 SPOILER ALERT - Full Solution**

**Complete Implementation** [View Full Solution](./full-solution-multi-agent.md)

---

## 🖼️ Option B: Vision Integration

### **The Scenario**

Customers often send photos of damage, installation issues, or questions about their homes. Your beginner agent can't see images—time to add vision!

**Your Mission**: Enhance your customer service agent to accept and analyze photos, automatically assessing damage severity and creating detailed tickets.

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Agent accepts image uploads
- ✅ Uses GPT-4 Vision to analyze images
- ✅ Provides basic description of what's in the image
- ✅ Creates support ticket with image analysis

#### **Good Success (60 points)**
- ✅ Categorizes damage severity (Minor/Major/Critical)
- ✅ Identifies specific issue types (cracks, water damage, defects)
- ✅ Suggests immediate actions for safety issues
- ✅ Generates detailed ticket descriptions from images
- ✅ Handles non-damage images gracefully

#### **Excellent Success (100 points)**
- ✅ Estimates repair costs based on visual assessment
- ✅ Compares to similar past issues
- ✅ Asks clarifying questions about the image
- ✅ Provides step-by-step safety instructions for critical issues
- ✅ Multi-image analysis (before/after, multiple angles)

---

### **🧪 Test Scenarios**

#### **Scenario 1: Cracked Wall Analysis**
```
Customer: "There are cracks in my wall" [uploads photo]

Expected Behavior:
✅ Analyze image
✅ Identify crack type (horizontal/vertical, length, location)
✅ Assess severity (Major - spans 3ft, structural concern)
✅ Create ticket with detailed description
✅ Provide safety guidance if needed
✅ Estimate: $2,500-$4,000 repair cost
```

#### **Scenario 2: Water Damage Detection**
```
Customer: [uploads photo of ceiling stain]

Expected Behavior:
✅ Identify water damage
✅ Assess severity (size, color, location)
✅ Ask about water source (roof leak, plumbing, etc.)
✅ Create CRITICAL ticket if active leak detected
✅ Provide immediate action steps (turn off water, place bucket)
```

---

### **💡 Hints & Tips**

[View Vision Hints](./hints-vision.md)

---

### **⚠️ Partial Solution**

[View Partial Solution](./partial-solution-vision.md)

---

### **🚨 SPOILER ALERT - Full Solution**

[View Full Solution](./full-solution-vision.md)

---

## 📄 Option C: Invoice Processing Pipeline

### **The Scenario**

Fabrikam receives 50+ supplier invoices every week—lumber, glass, HVAC systems, solar panels, logistics, and more. Currently, staff manually review each invoice, checking for errors, duplicates, and math mistakes before entering data into the accounting system. **This takes 15-20 minutes per invoice!**

**Your Mission**: Build an **Invoice Processing Agent** that can:
1. **Extract** data from invoice documents (PDFs)
2. **Validate** the extracted data (math, duplicates, required fields)
3. **Submit** to the Fabrikam Invoice API
4. **Report** results and handle errors gracefully

---

### **Architecture**

```
Invoice Document (PDF)
      ↓
┌─────────────────────────────┐
│  Invoice Processing Agent   │
│                             │
│  1. Extract invoice data    │
│     (vendor, amounts, items)│
│                             │
│  2. Validate extracted data │
│     (math, duplicates, etc) │
│                             │
│  3. Submit to API           │
│     POST /api/invoices      │
│                             │
│  4. Report results          │
└─────────────────────────────┘
      ↓
Fabrikam Invoice API
```

---

### **🎯 Choose Your Approach**

The Fabrikam MCP server now includes invoice processing tools! You can choose your integration approach based on your learning goals:

#### **Approach 1: Using MCP Invoice Tools** ⭐ (Recommended for 90-minute timeline)

**What You Get**:
- `get_invoices` - Query invoices with filtering for duplicate detection
- `submit_invoice` - Validate and submit invoices with automatic validation

**Workflow**:
```
1. Extract invoice data from PDF (your code/AI)
2. Use get_invoices to check for duplicates
3. Use submit_invoice to validate and submit
4. Focus your time on document processing and business logic
```

**Why Choose This**:
- ✅ Faster implementation (focus on extraction logic)
- ✅ Built-in validation (math checks, duplicates, dates)
- ✅ Consistent with Options A & B (uses MCP tools)
- ✅ Demonstrates MCP integration patterns
- ✅ Better for the 60-90 minute timeline

**MCP Tools Available**:
- **get_invoices**(invoiceNumber, vendor, status, fromDate, toDate, category, page, pageSize)
  - Returns invoice list for duplicate checking
  - Filter by any field to find matching invoices
- **submit_invoice**(invoiceNumber, vendor, invoiceDate, dueDate, subtotal, tax, total, category, lineItems, notes, purchaseOrderNumber)
  - Validates all fields and math
  - Detects duplicates automatically
  - Returns detailed validation errors if submission fails

#### **Approach 2: Direct API Integration** 🚀 (For the ambitious!)

**What You Build**:
- Direct HTTP calls to `POST /api/invoices`
- Your own validation logic
- HTTP client and error handling

**Workflow**:
```
1. Extract invoice data from PDF (your code/AI)
2. Implement validation (math, duplicates, dates)
3. Make HTTP POST to /api/invoices endpoint
4. Handle API responses and errors
```

**Why Choose This**:
- ✅ Learn HTTP client patterns
- ✅ Understand API contracts directly
- ✅ More control over validation logic
- ✅ Production integration experience
- ⚠️ Requires more time (consider 90+ minutes)

**API Endpoints**:
- **GET** `/api/invoices` - List invoices (filter by vendor, status, dates, category)
- **GET** `/api/invoices/{id}` - Get specific invoice with line items
- **POST** `/api/invoices` - Submit new invoice
- Returns: 200 (success), 400 (validation failed), 409 (duplicate)

**💡 Tip**: You can mix approaches! Use MCP tools for duplicate checking but direct API for submission to learn both patterns.

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Successfully extracts key invoice data (vendor, total, invoice number)
- ✅ Submits at least 1 invoice successfully to the API
- ✅ Shows extracted data before submission
- ✅ Handles API errors gracefully

#### **Good Success (60 points)**
- ✅ Extracts all required fields (vendor, dates, amounts, line items)
- ✅ Performs basic validation (required fields present)
- ✅ Successfully processes 3+ different invoices
- ✅ Provides clear status updates during processing
- ✅ Handles malformed/incomplete invoices gracefully

#### **Excellent Success (100 points)**
- ✅ Full data extraction (all fields including line items)
- ✅ Comprehensive validation:
  - Math validation (line items sum to subtotal, totals match)
  - Date validation (not future-dated, due date >= invoice date)
  - Duplicate detection (checks API before submission)
- ✅ Processes batch of invoices (5+ invoices)
- ✅ Detailed reporting (success/failure counts, error details)
- ✅ Error recovery (retry failed submissions)

#### **Bonus Features (up to 20 points)**
- 🌟 Automatic PDF conversion (from Markdown samples)
- 🌟 Confidence scoring for extracted data
- 🌟 Interactive clarification (asks user when uncertain)
- 🌟 Invoice categorization (materials vs services vs equipment)
- 🌟 Cost analysis and reporting (vendor spending trends)

---

### **🧪 Test Scenarios**

#### **Scenario 1: Simple Invoice Processing**
```
Invoice: Premium Lumber Supply Co. ($80,433.30)
- 4 line items
- Standard format
- All required fields present

Expected Flow:
1. Extract: vendor, invoice number, dates, amounts, line items
2. Validate: Math checks pass, no duplicates found
3. Submit: POST to /api/invoices
4. Report: "✅ Invoice INV-2025-000001 created successfully"
```

#### **Scenario 2: Complex Multi-Section Invoice**
```
Invoice: SolarEdge Solutions ($220,480.85)
- 17 line items across 4 sections (equipment, batteries, installation, permits)
- Volume discount applied
- Complex formatting

Expected Flow:
1. Extract: Handle multi-section layout
2. Validate: Line items sum to subtotal, discount calculated correctly
3. Submit: All line items properly structured
4. Report: "✅ Processed 6-system solar installation invoice"
```

#### **Scenario 3: Duplicate Detection**
```
Invoice: Premium Lumber Supply Co. ($80,433.30) - DUPLICATE
- Same vendor, amount, similar date as previously submitted invoice

Expected Flow:
1. Extract: Complete extraction successful
2. Validate: Call GET /api/invoices/check-duplicates
3. Detect: Finds matching invoice from 7 days ago
4. Report: "⚠️ Potential duplicate detected - Invoice #PLS-2025-10961 matches INV-2025-000001"
5. Action: Ask user whether to proceed or skip
```

#### **Scenario 4: Validation Failure**
```
Invoice: Malformed invoice with math errors
- Line items don't sum to subtotal
- Future-dated invoice date
- Missing required fields

Expected Flow:
1. Extract: Partial extraction (some fields missing)
2. Validate: Detect errors
3. Report: 
   - "❌ Math validation failed: Line items sum to $45,200 but subtotal is $48,000"
   - "❌ Invoice date is future-dated (2026-01-15)"
   - "❌ Missing required field: Vendor address"
4. Action: Do not submit, provide detailed error report
```

---

### **🏗️ Implementation Approaches**

#### **Approach 1: Copilot Studio with Computer Use** (Cutting Edge)
Use Copilot Studio's "Computer Use" feature to automate browser-based workflows:
- Upload invoice PDF to hosted browser
- Use AI to visually identify and extract data from invoice
- Validate extracted data
- Submit via API calls

**Best For**: Testing newest AI capabilities, UI automation scenarios

#### **Approach 2: Azure AI Foundry + Document Intelligence** (Recommended)
Use Azure's pre-built invoice analysis models:
- Azure AI Document Intelligence (prebuilt-invoice model)
- Automatic field extraction (vendor, dates, totals, line items)
- High accuracy with confidence scores
- REST API integration to Fabrikam Invoice API

**Best For**: Production-quality extraction, highest accuracy

#### **Approach 3: M365 Copilot + Power Automate** (Low-Code)
Build a Power Automate flow with AI Builder:
- AI Builder: Invoice processing model
- Parse invoice documents
- Use Copilot to validate and prepare data
- HTTP action to call Fabrikam Invoice API

**Best For**: Low-code approach, M365 ecosystem integration

#### **Approach 4: Agent Framework + OCR Library** (Custom MCP)
Build a custom MCP tool with OCR capabilities:
- Use Tesseract OCR or similar library
- Custom extraction logic with LLM assistance
- Validation rules in code
- API integration via HttpClient

**Best For**: Full control, custom validation logic, learning MCP development

---

### **📄 Sample Invoices**

We've provided 8 realistic supplier invoices in **both PDF and Markdown formats** in the `sample-invoices/` directory:

| Invoice | Vendor | Amount | Complexity | Purpose |
|---------|--------|--------|------------|---------|
| 001 | Premium Lumber Supply Co. | $80,433.30 | ⭐⭐ Medium | Standard multi-line invoice |
| 002 | SmartGlass Technologies | $228,454.05 | ⭐⭐⭐ Complex | Volume discount, rich formatting |
| 003 | TransModular Logistics | $13,320.00 | ⭐⭐ Medium | Service invoice (tax-exempt) |
| 004 | ModularTech Appliances | $168,895.56 | ⭐⭐⭐ Complex | Package pricing, 18 units |
| 005 | ClimateControl HVAC | $115,658.80 | ⭐⭐⭐⭐ Very Complex | Mixed tax treatment |
| 006 | EcoPanel Systems | $35,101.33 | ⭐ Simple | Basic handwritten-style |
| 007 | SolarEdge Solutions | $220,480.85 | ⭐⭐⭐⭐⭐ Extremely Complex | Multi-section, 17 items |
| 008 | Premium Lumber (Duplicate) | $80,433.30 | ⭐ Simple | Tests duplicate detection |

**File Formats:**
- 📄 **PDF files** (001-premium-lumber-supply.pdf, etc.) - Ready for OCR, Document Intelligence, or vision-based processing
- 📝 **Markdown files** (.md) - Human-readable source files

**See**: [sample-invoices/README.md](./sample-invoices/README.md) for complete details and API documentation

---

### **🌐 Fabrikam Invoice API**

Your agent will interact with the real Fabrikam Invoice API:

#### **Base URL**
```
https://localhost:7297/api/invoices
```

#### **Key Endpoints**

**Submit Invoice**
```http
POST /api/invoices
Content-Type: application/json

{
  "vendor": "Premium Lumber Supply Co.",
  "invoiceNumber": "PLS-2025-10847",
  "invoiceDate": "2025-01-15",
  "dueDate": "2025-02-14",
  "subtotalAmount": 72980.00,
  "taxAmount": 6203.30,
  "shippingAmount": 1250.00,
  "totalAmount": 80433.30,
  "category": "Materials",
  "lineItems": [
    {
      "description": "Glulam Beams 24' x 10.75\" x 5.125\"",
      "quantity": 45,
      "unitPrice": 875.00,
      "amount": 39375.00,
      "productCode": "GLB-24-10-5"
    },
    // ... more line items
  ]
}
```

**Check for Duplicates**
```http
GET /api/invoices/check-duplicates?vendor=Premium%20Lumber&totalAmount=80433.30&invoiceDate=2025-01-15
```

**Get Invoice Statistics**
```http
GET /api/invoices/stats
```

**Complete API documentation**: See [sample-invoices/README.md](./sample-invoices/README.md)

---

### **💡 Hints & Tips**

**Available Without Spoilers!** [View Hints](./hints-invoice-processing.md)

---

### **⚠️ Partial Solution**

**Architecture & Patterns** [View Partial Solution](./partial-solution-invoice-processing.md)

---

### **🚨 SPOILER ALERT - Full Solution**

**Complete Implementation** [View Full Solution](./full-solution-invoice-processing.md)

---

## 🎓 What You'll Learn

Across all options, you'll master:
- ✅ **Advanced agent patterns** - Orchestration, vision, automation
- ✅ **Multi-agent coordination** - Context handoff, routing, collaboration
- ✅ **Specialized capabilities** - Vision analysis, scheduled tasks
- ✅ **Production thinking** - Error handling, monitoring, reporting

---

## 📊 Evaluation

**Time Check**: You have 90 minutes!

- **60 points**: Good stopping point if time is short
- **80 points**: Solid intermediate-level achievement
- **100 points**: Excellent work!
- **100+ points**: Above and beyond!

---

## ⏭️ Next Steps

Ready for the ultimate challenge?

**Next:** [**Proceed to Advanced Challenge**](../03-advanced/README.md)

Build production-ready agents with code using Azure AI Agent Framework!

---

**Remember: You can choose any option or tackle multiple! Focus on learning, not perfection.** 🚀
