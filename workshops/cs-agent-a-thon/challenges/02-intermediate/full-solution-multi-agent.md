# 🚨 Full Solution: Multi-Agent Orchestration

**Complete Implementation Guide**

---

## ⚠️ Important Note

This full solution provides a comprehensive reference implementation. The complexity and depth depend on your chosen approach. We'll cover all three primary approaches:

1. **Copilot Studio with Topics** (No-code)
2. **Multiple Copilot Studio Agents** (Low-code)
3. **Agent Framework with MCP Tools** (Code-based)

---

## 📋 Solution Overview

This solution demonstrates a complete multi-agent orchestration system where:
- An **Orchestrator Agent** classifies customer intent
- **Specialist Agents** handle specific domains (Sales, Technical, Billing, Escalation)
- **Context** is maintained across handoffs
- **Multi-specialist workflows** coordinate seamlessly
- **Professional handoff language** creates a great experience

---

## 🎯 Approach 1: Copilot Studio with Topics

### **Architecture**

```
Fabrikam Customer Service Agent
├── Orchestration Topic (Conversational boosting, fallback)
├── Sales Topic
├── Technical Topic  
├── Billing Topic
└── Escalation Topic
```

### **Setup Steps**

**Step 1: Create the Agent**

1. Go to Copilot Studio (https://copilotstudio.microsoft.com)
2. Create new agent: "Fabrikam Customer Service"
3. Set description: "Multi-specialist customer service for Fabrikam Modular Homes"

**Step 2: Configure MCP Integration**

1. In agent settings → **Actions**
2. Add MCP server connection to Fabrikam MCP (from beginner challenge)
3. Ensure these tools are available:
   - get_products
   - get_orders
   - get_customers
   - create_support_ticket

**Step 3: Create Sales Topic**

1. Create new Topic: "Sales Specialist"
2. **Trigger phrases**:
   ```
   - buy a home
   - purchase
   - pricing
   - how much
   - financing
   - family haven
   - executive manor
   - products
   - customize
   ```

3. **Topic flow**:
   ```
   1. Message node: "Great! I'm your Fabrikam Sales Specialist. I'd love to help you find the perfect modular home!"
   
   2. Generative answers node:
      - Data sources: MCP tools (get_products)
      - System prompt: [See Sales Specialist Prompt below]
      
   3. Question node: "Is there anything else about our products I can help with?"
      - Yes → Loop back to generative answers
      - No → "Wonderful! Feel free to reach out anytime."
   ```

**Sales Specialist System Prompt**:
```markdown
You are a Fabrikam Sales Specialist with expertise in modular homes.

YOUR ROLE:
- Help customers explore our product line (Family Haven, Executive Manor, etc.)
- Provide detailed pricing and specifications
- Explain financing options
- Guide customers through customization choices
- Answer questions about delivery timelines and processes

AVAILABLE TOOLS:
- get_products: Retrieve our complete product catalog
- create_support_ticket: For custom design requests beyond standard offerings

YOUR APPROACH:
- Be enthusiastic and consultative
- Ask questions to understand customer needs (size, budget, location)
- Provide specific product recommendations with reasoning
- Explain value propositions clearly
- Offer to connect with financing or technical specialists if needed

OUT OF SCOPE (refer to other specialists):
- Order status and delivery (Technical Specialist)
- Billing and refunds (Billing Specialist)
- Complaints and escalations (Escalation Specialist)

TONE: Friendly, enthusiastic, consultative, helpful
```

**Step 4: Create Technical Topic**

1. Create new Topic: "Technical Specialist"
2. **Trigger phrases**:
   ```
   - my order
   - where is my order
   - delivery
   - delayed
   - FAB-2025
   - damaged
   - broken
   - repair
   - warranty
   - installation
   ```

3. **Topic flow**:
   ```
   1. Message node: "I'm your Fabrikam Technical Support Specialist. Let me help you with your order or technical issue."
   
   2. Generative answers node:
      - Data sources: MCP tools (get_orders, create_support_ticket)
      - System prompt: [See Technical Specialist Prompt below]
      
   3. Question node: "Have I resolved your technical concern?"
      - Yes → "Great! Reach out if you need anything else."
      - No → Loop back or escalate
   ```

**Technical Specialist System Prompt**:
```markdown
You are a Fabrikam Technical Support Specialist.

YOUR ROLE:
- Check order status and delivery tracking
- Investigate delivery delays
- Handle damage reports and warranty claims
- Create support tickets for production issues
- Provide installation guidance

AVAILABLE TOOLS:
- get_orders(orderId): Look up order details
- get_customers(customerId): Retrieve customer information
- create_support_ticket: Create tickets for delays, damage, defects

DELAY DETECTION:
Standard production time is 30 days. Check:
- Order date → production days = (today - orderDate) days
- If > 30 days: Calculate overdue = productionDays - 30
- If overdue > 0: Customer order is delayed

TICKET CREATION FOR DELAYS:
When order is delayed:
1. Acknowledge the delay empathetically
2. Calculate exact delay (X days beyond 30-day standard)
3. ASK: "Would you like me to create a high-priority support ticket?"
4. WAIT for customer approval
5. When approved, create ticket with:
   - Priority: High
   - Category: DeliveryDelay
   - Subject: "Order [orderId] - Production Delay ([X] days overdue)"
   - Description: Include order details, delay amount, customer concern

CUSTOMER NAME USAGE:
ALWAYS use the customer name from the ORDER DATA, not the logged-in user's name.
- Call get_customers or get_orders to get the actual customer name
- Use that name when addressing the customer

OUT OF SCOPE:
- Product sales (Sales Specialist)
- Refund processing (Billing Specialist)
- Formal complaints (Escalation Specialist)

TONE: Professional, empathetic, solution-focused
```

**Step 5: Create Billing Topic**

1. Create new Topic: "Billing Specialist"
2. **Trigger phrases**:
   ```
   - refund
   - payment
   - invoice
   - charge
   - bill
   - account
   - financing
   - loan
   ```

3. **System Prompt**:
```markdown
You are a Fabrikam Billing Specialist.

YOUR ROLE:
- Explain billing and payment policies
- Process refund requests
- Answer invoice questions
- Provide financing information
- Handle billing discrepancies

AVAILABLE TOOLS:
- get_customers(customerId): Account and payment info
- create_support_ticket: For refund processing, billing disputes

REFUND POLICY:
- Pre-production orders: Full refund available
- In-production orders: Partial refund, case-by-case basis
- Delivered orders: Refund only for defects (requires inspection)

WHEN CUSTOMER REQUESTS REFUND:
1. Understand the reason (delay, defect, changed circumstances)
2. Check order status (pre-production, in-production, delivered)
3. Explain applicable refund policy
4. If eligible, create support ticket for refund processing
5. Set expectations for processing time (5-7 business days)

OUT OF SCOPE:
- Product information (Sales Specialist)
- Order status (Technical Specialist)  
- Complaint escalation (Escalation Specialist)

TONE: Professional, clear, policy-focused but empathetic
```

**Step 6: Create Escalation Topic**

1. Create new Topic: "Escalation Specialist"
2. **Trigger phrases**:
   ```
   - manager
   - supervisor
   - complaint
   - ridiculous
   - frustrated
   - angry
   - third time
   - unacceptable
   ```

3. **System Prompt**:
```markdown
You are a Fabrikam Escalation Specialist handling high-priority customer concerns.

YOUR ROLE:
- Handle frustrated or angry customers with maximum empathy
- Acknowledge past service failures
- Create executive-level escalation tickets
- Provide clear timelines for resolution
- De-escalate when possible

AVAILABLE TOOLS:
- get_customers(customerId): Full customer history
- get_orders(orderId): Order details for context
- create_support_ticket: HIGH-PRIORITY tickets with manager assignment

ESCALATION APPROACH:
1. ACKNOWLEDGE EMOTIONS:
   "I sincerely apologize for this experience. I understand how frustrating this must be."

2. LISTEN AND VALIDATE:
   Let customer express concerns fully, don't interrupt

3. GATHER CONTEXT:
   - What happened?
   - When did it start?
   - How many times have they contacted us?
   - What resolutions were attempted?

4. CREATE HIGH-PRIORITY TICKET:
   - Priority: Critical
   - Category: CustomerComplaint
   - Subject: "[Escalation] {brief issue description}"
   - Description: Full context, previous attempts, customer sentiment
   - Request manager assignment

5. SET CLEAR EXPECTATIONS:
   "I've escalated this to our management team with CRITICAL priority. 
   A manager will personally contact you within 24 hours to resolve this."

6. PROVIDE DIRECT CONTACT (if appropriate):
   Ticket number, direct phone line if available

TONE: Calm, deeply empathetic, professional, solution-committed
```

**Step 7: Configure Orchestration (Fallback)**

The default **Conversational boosting** handles orchestration automatically:
- Analyzes customer messages
- Routes to appropriate topic based on trigger phrases
- If no topic matches → uses generative answers to respond or ask clarifying questions

Enhance fallback orchestration:

1. Go to Settings → **Generative AI** → **Generative answers** (fallback)
2. Add system message:

```markdown
You are the Fabrikam Customer Service Orchestrator.

When customers ask questions:
1. Determine which specialist can best help:
   - SALES: Product questions, pricing, purchasing, customization
   - TECHNICAL: Order status, delivery, damage, repairs, installation
   - BILLING: Refunds, payments, invoices, financing
   - ESCALATION: Complaints, manager requests, frustration

2. If topic is clear, hand off naturally:
   "Let me connect you with our [Sales/Technical/Billing] team who can help with that."
   [Topics will auto-trigger on next turn]

3. If ambiguous, ask clarifying question:
   "I'd be happy to help! To connect you with the right specialist:
   - Is this about a product you're interested in?
   - An existing order?
   - A billing question?
   - Or a concern you'd like escalated?"

4. For out-of-scope requests:
   "I specialize in Fabrikam modular homes assistance. For [other topic], 
   I recommend [appropriate resource]."

Be friendly, helpful, and ensure customers reach the right specialist.
```

---

### **Testing Your Copilot Studio Solution**

**Test 1: Direct Routing**
```
User: "I want to buy the Family Haven 1800"
Expected: Sales Topic triggers
✅ Agent: "Great! I'm your Fabrikam Sales Specialist..."
```

**Test 2: Order Status**
```
User: "Where is my order FAB-2025-047?"
Expected: Technical Topic triggers
✅ Agent: "I'm your Fabrikam Technical Support Specialist..."
```

**Test 3: Refund Request**
```
User: "I need a refund"
Expected: Billing Topic triggers
✅ Agent: "I'm your Fabrikam Billing Specialist..."
```

**Test 4: Escalation**
```
User: "This is ridiculous! I want a manager!"
Expected: Escalation Topic triggers immediately
✅ Agent: "I sincerely apologize for this experience..."
```

**Test 5: Ambiguous Request**
```
User: "I have a problem with my home"
Expected: Orchestrator asks clarifying question
✅ Agent: "I'd be happy to help! To connect you with the right specialist..."
```

---

## 🎯 Approach 2: Multiple Copilot Studio Agents

This approach creates separate agents for orchestrator and specialists, providing cleaner separation.

### **Setup Steps**

**Step 1: Create 5 Separate Agents**

1. **Fabrikam Orchestrator**
2. **Fabrikam Sales Specialist**
3. **Fabrikam Technical Specialist**
4. **Fabrikam Billing Specialist**
5. **Fabrikam Escalation Specialist**

**Step 2: Configure Each Specialist Agent**

Each specialist agent configuration:
- Connect to Fabrikam MCP server
- Add appropriate system prompt (use prompts from Approach 1)
- Configure generative answers with MCP tools

**Step 3: Configure Orchestrator Agent**

1. System prompt:

```markdown
You are the Fabrikam Customer Service Orchestrator.

Your job is to understand customer needs and connect them with the right specialist.

SPECIALIST CAPABILITIES:
- SALES: Products, pricing, purchasing, customization
- TECHNICAL: Orders, delivery, damage, repairs, warranties
- BILLING: Refunds, payments, invoices, financing
- ESCALATION: Complaints, frustrated customers, manager requests

ROUTING LOGIC:
1. Analyze customer message for intent
2. Classify as: SALES | TECHNICAL | BILLING | ESCALATION | UNCLEAR

3. If UNCLEAR, ask clarifying questions:
   "To connect you with the right specialist, could you tell me if this is about:
   - A product you're interested in purchasing?
   - An existing order or delivery?
   - A billing or payment question?
   - A concern you'd like escalated?"

4. When intent is clear, use "Transfer to Agent" action to route to specialist

TRANSFER PROCESS:
- Provide brief handoff message
- Use "Transfer conversation to agent" action
- Select appropriate specialist agent
- Pass context: customer message, intent, any extracted data
```

2. Add **Transfer to Agent** actions for each specialist
3. Use conditions or LLM classification to decide which agent to transfer to

**Example Flow**:
```
1. User message input
↓
2. Generative answers node (classifies intent)
↓
3. Condition branches:
   - If contains "buy" OR "product" → Transfer to Sales Agent
   - If contains "order" OR "delivery" → Transfer to Technical Agent
   - If contains "refund" OR "payment" → Transfer to Billing Agent
   - If contains "manager" OR "complaint" → Transfer to Escalation Agent
   - Else → Ask clarifying question
```

---

## 🎯 Approach 3: Agent Framework with MCP Tools

*Note: This is the most advanced approach requiring C# coding*

### **Full Implementation**

**Project Structure**:
```
FabrikamOrchestratorMcp/
├── FabrikamOrchestratorMcp.csproj
├── Program.cs (MCP server setup)
├── Tools/
│   ├── OrchestratorTool.cs
│   ├── SalesSpecialistTool.cs
│   ├── TechnicalSpecialistTool.cs
│   ├── BillingSpecialistTool.cs
│   └── EscalationSpecialistTool.cs
└── Services/
    ├── IntentClassifier.cs
    └── ContextManager.cs
```

**Key Implementation Code** (abbreviated for space):

```csharp
// OrchestratorTool.cs
[McpServerTool, Description("Main orchestrator for routing customer requests")]
public class OrchestratorTool
{
    private readonly SalesSpecialistTool _salesSpecialist;
    private readonly TechnicalSpecialistTool _technicalSpecialist;
    private readonly BillingSpecialistTool _billingSpecialist;
    private readonly EscalationSpecialistTool _escalationSpecialist;
    private readonly IntentClassifier _classifier;

    public async Task<object> RouteCustomerRequest(
        string customerMessage,
        int? customerId = null,
        string? conversationContext = null)
    {
        // Classify intent
        var intent = await _classifier.ClassifyIntent(customerMessage);
        
        // Route to appropriate specialist
        return intent switch
        {
            "Sales" => await _salesSpecialist.ConsultSales(customerMessage, conversationContext),
            "Technical" => await _technicalSpecialist.HandleTechnical(customerMessage, customerId, conversationContext),
            "Billing" => await _billingSpecialist.HandleBilling(customerMessage, customerId, conversationContext),
            "Escalation" => await _escalationSpecialist.HandleEscalation(customerMessage, customerId, conversationContext),
            _ => await AskClarification(customerMessage)
        };
    }
}

// SalesSpecialistTool.cs
[McpServerTool, Description("Sales specialist for product recommendations")]
public class SalesSpecialistTool
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    public async Task<object> ConsultSales(
        string customerRequest,
        string? context = null)
    {
        var systemPrompt = @"You are a Fabrikam Sales Specialist...";
        
        // Get products
        var products = await GetProducts();
        
        // Use LLM to generate response
        var response = await GenerateResponse(
            systemPrompt,
            customerRequest,
            products,
            context);
        
        return new
        {
            specialist = "Sales",
            response = response,
            tools_used = new[] { "get_products" }
        };
    }

    private async Task<string> GetProducts()
    {
        var baseUrl = _configuration["FabrikamApi:BaseUrl"];
        var response = await _httpClient.GetAsync($"{baseUrl}/api/products");
        return await response.Content.ReadAsStringAsync();
    }
}
```

**For complete Agent Framework implementation**, see the Fabrikam MCP server code in the beginner challenge and extend with the orchestration patterns shown above.

---

## 🎯 Testing the Complete Solution

### **Test Suite**

**1. Single-Specialist Routing**
```
✅ "I want to buy a home" → Sales
✅ "My order is delayed" → Technical
✅ "I need a refund" → Billing
✅ "Get me a manager" → Escalation
```

**2. Multi-Turn Conversations**
```
✅ Sales: "Tell me about the Family Haven" → "What's the price?" → "Do you offer financing?"
   Specialist maintains context across turns
```

**3. Multi-Specialist Workflows**
```
✅ "My order FAB-2025-042 is delayed and I want a refund"
   Technical → Checks order, confirms delay, creates ticket
   → Billing → Processes refund request
   Context preserved throughout
```

**4. Escalation Paths**
```
✅ "Third time calling and nothing is fixed!"
   Immediate route to Escalation (no clarification needed)
   Escalation reviews history, creates critical ticket
```

**5. Edge Cases**
```
✅ Ambiguous: "I have a problem" → Orchestrator asks clarifying questions
✅ Out of scope: "What's the weather?" → Polite decline, redirect
✅ Context loss: Multi-specialist handoff → Each specialist has full context
```

---

## 📊 Success Metrics Achieved

With this complete solution, you should achieve:

✅ **Basic** (30/100):
- Routing works for clear requests
- 2+ specialists functional
- Basic context passing

✅ **Good** (60/100):
- All 4 specialists working
- Multi-specialist workflows
- Clarification for ambiguous requests
- Natural handoff language

✅ **Excellent** (100/100):
- Intelligent intent classification
- Context preserved across all handoffs
- Conversation summaries
- Escalation paths working
- Professional customer experience

✅ **Bonus** (+20):
- Parallel specialist consultation
- Sentiment-based routing
- Conversation summarization
- Learning from routing history

---

## 🚀 Deployment & Next Steps

1. **Test thoroughly** with all scenarios
2. **Monitor routing accuracy** - adjust trigger phrases/classification
3. **Gather feedback** - refine specialist prompts
4. **Add metrics** - track routing success, specialist performance
5. **Scale up** - add more specialists as needed (Warranty, Customization, etc.)

---

**Congratulations!** You've built a production-ready multi-agent orchestration system! 🎉

This solution demonstrates enterprise-grade patterns:
- Intelligent routing
- Context preservation
- Specialist separation of concerns
- Professional customer experience
- Scalable architecture

**Next challenge**: Apply these patterns to your real-world scenarios or proceed to the [Advanced Challenge](../../03-advanced/README.md) for Agent Framework deep-dive!
