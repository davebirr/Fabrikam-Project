# 💡 Hints: Multi-Agent Orchestration

**Smart hints without spoilers!** Use these progressively as you build your solution.

---

## 🎯 General Strategy Hints

<details>
<summary><strong>Hint 1: Start with 2 Agents, Not 5</strong></summary>

Don't try to build all specialists at once! Follow this progression:

1. **First**: Build Orchestrator + ONE specialist (e.g., Sales)
   - Get the handoff working
   - Test context passing
   - Celebrate the routing! 🎉

2. **Second**: Add a second specialist (e.g., Technical)
   - Now you have real routing decisions
   - Test both paths

3. **Third**: Add remaining specialists
   - Billing
   - Escalation

4. **Finally**: Polish and enhance
   - Better routing logic
   - Context summarization
   - Multi-specialist flows

**Why**: Early success builds confidence and helps you understand the handoff mechanism.

</details>

<details>
<summary><strong>Hint 2: Routing is About Intent Detection</strong></summary>

The orchestrator's job is to classify customer intent:

**Sales Intent Keywords**:
- Product names (Family Haven, Executive Manor)
- "buy", "purchase", "financing", "pricing", "cost"
- "customize", "options", "features"

**Technical Intent Keywords**:
- "order", "delivery", "delayed", "damaged", "broken"
- "installation", "repair", "warranty"
- Order numbers (FAB-2025-XXX)

**Billing Intent Keywords**:
- "refund", "payment", "invoice", "charge"
- "financing", "loan", "credit"

**Escalation Intent Keywords**:
- "manager", "supervisor", "complaint"
- "ridiculous", "frustrated", "angry"
- "third time", "still waiting"

**Tip**: Use these as examples in your orchestrator's system prompt!

</details>

<details>
<summary><strong>Hint 3: Context is King</strong></summary>

When handing off, pass critical context:

**Minimum Context**:
- Customer request/question
- Intent classification (why routing here)

**Good Context**:
- Previous specialist consultations
- Key data collected (order numbers, product names)
- Customer sentiment

**Excellent Context**:
- Conversation summary
- Urgency level
- Special handling needed

**Example**:
```
Routing to Technical Specialist:
Context: Customer reports delayed order FAB-2025-042.
Sentiment: Frustrated (mentioned "third time").
Action needed: Check order status, create priority ticket.
```

</details>

---

## 🔧 Technology-Specific Hints

### Copilot Studio Approach

<details>
<summary><strong>Hint CS-1: Using Topics for Specialists</strong></summary>

**Simplest approach**: One agent with multiple Topics acting as specialists

**Setup**:
1. Create main agent: "Fabrikam Customer Service"
2. Create Topics:
   - **Orchestration Topic** (default, highest priority)
   - **Sales Topic** (trigger phrases: "buy", "product", "pricing")
   - **Technical Topic** (trigger phrases: "order", "delivery", "repair")
   - **Billing Topic** (trigger phrases: "refund", "payment")
   - **Escalation Topic** (trigger phrases: "manager", "complaint")

**Handoff Method**:
```
Orchestrator Topic:
- Analyzes customer request
- Uses "Redirect to another topic" node
- Selects appropriate specialist topic
- Topic handles the request
```

**Pros**: Easy setup, single agent, shared context
**Cons**: All logic in one agent (can get complex)

</details>

<details>
<summary><strong>Hint CS-2: Using Multiple Agents</strong></summary>

**More realistic approach**: Separate agents for orchestrator and specialists

**Setup**:
1. Create 5 agents:
   - Fabrikam Orchestrator
   - Fabrikam Sales Specialist
   - Fabrikam Technical Specialist
   - Fabrikam Billing Specialist
   - Fabrikam Escalation Specialist

2. Connect orchestrator to specialists using **Transfer to Agent** action

**Handoff Method**:
```
In Orchestrator:
1. Add Generative Answers node
2. Use system prompt to classify intent
3. Based on classification, use "Transfer conversation" action
4. Select target specialist agent
```

**Pros**: Clean separation, specialists can be developed independently
**Cons**: Context passing requires explicit configuration

</details>

<details>
<summary><strong>Hint CS-3: System Prompts for Each Specialist</strong></summary>

Give each specialist a clear identity and capabilities:

**Sales Specialist**:
```
You are a Fabrikam Sales Specialist.

YOUR ROLE:
- Help customers explore modular home products
- Provide pricing and financing information
- Explain customization options
- Guide product selection

AVAILABLE TOOLS:
- get_products: Get product catalog
- create_support_ticket: For complex custom requests

TONE: Enthusiastic, helpful, consultative
```

**Technical Specialist**:
```
You are a Fabrikam Technical Support Specialist.

YOUR ROLE:
- Check order status and delivery tracking
- Handle damage reports and warranty claims
- Create support tickets for production issues
- Provide installation guidance

AVAILABLE TOOLS:
- get_orders: Look up order details
- create_support_ticket: For delays, damage, defects

TONE: Professional, empathetic, solution-focused
```

**Why**: Clear roles prevent specialist confusion and improve responses.

</details>

---

### Power Automate / Low-Code Approach

<details>
<summary><strong>Hint PA-1: Using Cloud Flows for Orchestration</strong></summary>

Build orchestration logic in Power Automate:

**Flow Structure**:
1. **Trigger**: When customer message received (Power Virtual Agents)
2. **AI Builder - Analyze Text**: Classify intent
3. **Switch/Condition**: Route based on classification
4. **Branch 1 - Sales**: Call Sales specialist flow
5. **Branch 2 - Technical**: Call Technical specialist flow
6. **Branch 3 - Billing**: Call Billing specialist flow
7. **Branch 4 - Escalation**: Call Escalation specialist flow
8. **Return**: Send specialist response to customer

**Specialist Flows**:
- Each specialist is a separate flow
- Takes customer message + context as input
- Calls appropriate MCP tools (get_orders, get_products, etc.)
- Returns formatted response

**Tip**: Use flow variables to maintain context across handoffs.

</details>

<details>
<summary><strong>Hint PA-2: AI Builder for Intent Classification</strong></summary>

Use AI Builder's **Category Classification** model:

**Setup**:
1. In AI Builder, create new model: "Intent Classifier"
2. Define categories:
   - Sales (products, pricing, financing)
   - Technical (orders, delivery, repairs)
   - Billing (payments, refunds)
   - Escalation (complaints, manager requests)
3. Train with sample phrases (20+ per category)
4. Test and publish

**In Flow**:
```
Action: AI Builder - Predict (Category Classification)
Input: Customer message
Output: Intent category + confidence score

If confidence < 0.7:
  Ask clarifying question
Else:
  Route to specialist
```

**Why**: Pre-trained classification is faster than custom LLM prompting.

</details>

---

### Azure AI Foundry / Agent Framework Approach

<details>
<summary><strong>Hint AF-1: Agent Framework Multi-Agent Pattern</strong></summary>

Use Agent Framework's built-in orchestration capabilities:

**Architecture**:
```csharp
// Main orchestrator agent
var orchestrator = new AgentBuilder()
    .WithName("Fabrikam Orchestrator")
    .WithInstructions("Route customers to appropriate specialist...")
    .WithAgentTools(new[] {
        salesSpecialist,
        technicalSpecialist,
        billingSpecialist,
        escalationSpecialist
    })
    .Build();

// Specialist agents
var salesSpecialist = new AgentBuilder()
    .WithName("Sales Specialist")
    .WithInstructions("Help with products and pricing...")
    .WithTools(new[] { getProducts, createTicket })
    .Build();
```

**Orchestration Logic**:
- Orchestrator analyzes customer message
- Decides which specialist agent to invoke
- Calls specialist as a tool
- Returns specialist response to customer

**Why**: Agent Framework handles context and conversation threading automatically.

</details>

<details>
<summary><strong>Hint AF-2: Custom MCP Tools as Specialists</strong></summary>

Create each specialist as an MCP tool:

```csharp
[McpServerTool, Description("Sales specialist for product recommendations")]
public async Task<object> ConsultSalesSpecialist(
    string customerRequest,
    string? context = null)
{
    var systemPrompt = @"You are a Fabrikam Sales Specialist.
        Help customers explore products, pricing, and financing.";
    
    var chatPrompt = $@"Customer Request: {customerRequest}
        Context: {context ?? "None"}
        
        Provide helpful sales assistance.";
    
    // Call LLM with specialist prompt
    var response = await CallLLM(systemPrompt, chatPrompt);
    
    // Optionally call tools (get_products, etc.)
    if (NeedsProductData(response))
    {
        var products = await GetProducts();
        response = await EnrichWithProducts(response, products);
    }
    
    return new { specialist = "Sales", response = response };
}
```

**Orchestrator calls appropriate specialist**:
```csharp
var intent = await ClassifyIntent(userMessage);

return intent switch
{
    "Sales" => await ConsultSalesSpecialist(userMessage, context),
    "Technical" => await ConsultTechnicalSpecialist(userMessage, context),
    "Billing" => await ConsultBillingSpecialist(userMessage, context),
    _ => await ConsultEscalationSpecialist(userMessage, context)
};
```

</details>

---

## 🧩 Routing Strategy Hints

<details>
<summary><strong>Hint R-1: Simple Keyword Matching (Good Enough!)</strong></summary>

Don't overcomplicate routing! Simple keyword matching works well:

```csharp
string[] salesKeywords = { "buy", "purchase", "product", "pricing", "family haven", "executive manor" };
string[] technicalKeywords = { "order", "delivery", "fab-2025", "damaged", "repair", "warranty" };
string[] billingKeywords = { "refund", "payment", "invoice", "charge", "financing" };
string[] escalationKeywords = { "manager", "supervisor", "complaint", "frustrated", "ridiculous" };

var lowerMessage = customerMessage.ToLower();

if (salesKeywords.Any(k => lowerMessage.Contains(k)))
    return "Sales";
if (technicalKeywords.Any(k => lowerMessage.Contains(k)))
    return "Technical";
if (billingKeywords.Any(k => lowerMessage.Contains(k)))
    return "Billing";
if (escalationKeywords.Any(k => lowerMessage.Contains(k)))
    return "Escalation";

return "Clarification"; // Ask what they need
```

**Why**: 80% of requests have clear keywords. Save complexity for edge cases!

</details>

<details>
<summary><strong>Hint R-2: LLM-Based Intent Classification</strong></summary>

For more nuanced routing, use an LLM:

```
System Prompt:
You are an intent classifier for Fabrikam customer service.

Classify customer messages into ONE of these categories:
- SALES: Product questions, pricing, purchasing, customization
- TECHNICAL: Order status, delivery, repairs, damage, installation
- BILLING: Payments, refunds, invoices, financing
- ESCALATION: Complaints, manager requests, legal issues
- UNCLEAR: Ambiguous requests that need clarification

User Message: {customerMessage}

Respond with ONLY the category name (SALES, TECHNICAL, BILLING, ESCALATION, or UNCLEAR).
```

**Parse response**:
```csharp
var intent = await CallLLM(classificationPrompt);
var category = intent.Trim().ToUpper();

if (category == "UNCLEAR")
{
    return await AskClarifyingQuestion();
}

return RouteToSpecialist(category);
```

**Why**: Handles complex/ambiguous requests better than keywords.

</details>

<details>
<summary><strong>Hint R-3: Multi-Step Routing with Clarification</strong></summary>

Handle ambiguous requests gracefully:

```
Customer: "I have a problem with my home"

Orchestrator Response:
"I'd be happy to help! To connect you with the right specialist, could you tell me more about the problem?

- Is it related to an order or delivery?
- Is it a structural or quality issue?
- Is it about payment or billing?"

Customer: "The walls are cracking"

Orchestrator: [Routes to Technical Specialist]
```

**Implementation**:
```csharp
if (intent == "UNCLEAR")
{
    var clarification = await AskClarifyingQuestion(customerMessage);
    
    // Store in conversation context
    context.Add("needs_clarification", clarification);
    
    return clarification;
}

// On next turn, re-classify with additional context
if (context.ContainsKey("needs_clarification"))
{
    var combinedMessage = $"{context["previous_message"]} {customerMessage}";
    intent = await ClassifyIntent(combinedMessage);
}
```

**Why**: Better UX than guessing wrong specialist!

</details>

---

## 🔄 Context Handoff Hints

<details>
<summary><strong>Hint CH-1: Minimum Viable Context</strong></summary>

At minimum, pass these to specialists:

```json
{
  "customerMessage": "My order FAB-2025-042 is delayed and I want a refund",
  "intent": "Technical + Billing",
  "routingReason": "Order delay + refund request"
}
```

**Specialist uses this**:
- Knows why they were called
- Has customer's original request
- Can provide targeted help

</details>

<details>
<summary><strong>Hint CH-2: Rich Context Passing</strong></summary>

For better specialist responses, pass rich context:

```json
{
  "customerMessage": "My order FAB-2025-042 is delayed and I want a refund",
  "intent": "Technical + Billing",
  "routingReason": "Order delay + refund request",
  "extractedData": {
    "orderId": "FAB-2025-042",
    "issueType": "Delivery delay",
    "requestedAction": "Refund"
  },
  "sentiment": "Frustrated",
  "conversationHistory": [
    { "speaker": "Customer", "message": "My order is delayed" },
    { "speaker": "Orchestrator", "message": "Let me check on that..." }
  ]
}
```

**Benefits**:
- Specialist doesn't have to re-extract data
- Can adjust tone based on sentiment
- Has full context for better decisions

</details>

<details>
<summary><strong>Hint CH-3: Conversation Summarization</strong></summary>

For multi-specialist handoffs, summarize between agents:

```
Customer talks to Technical → Technical finds delay → Needs to hand to Billing

Technical creates summary:
"Order FAB-2025-042 confirmed delayed by 25 days (55 days in production, 
30-day standard). Customer Diego Siciliani is requesting refund. 
Support ticket TKT-20251104-0042 created for production team. 
Handing to Billing for refund processing."

Billing receives:
- Summary (above)
- Customer's original request
- Data: orderId, customerId, ticketNumber
```

**Implementation**:
```csharp
var summary = await LLM.Summarize($@"
    Summarize this customer service interaction for handoff:
    {conversationHistory}
    
    Focus on:
    - Key issue identified
    - Actions taken
    - What the next specialist needs to know");

context.Add("handoff_summary", summary);
```

</details>

---

## 🎭 Specialist Behavior Hints

<details>
<summary><strong>Hint SB-1: Specialist Acknowledgment Pattern</strong></summary>

Specialists should acknowledge the handoff:

**Good Pattern**:
```
Technical Specialist:
"Hi Diego! I've reviewed your case from our orchestrator. I can see you're 
concerned about order FAB-2025-042 taking longer than expected. Let me check 
the current status for you..."

[Calls get_orders tool]

"I found the issue - your order has been in production for 55 days, which is 
25 days beyond our standard 30-day timeline..."
```

**Why**: Shows seamless coordination, builds trust.

</details>

<details>
<summary><strong>Hint SB-2: Specialist Can Escalate Back</strong></summary>

Specialists should know when to escalate back to orchestrator:

**Scenarios to escalate back**:
- Request outside specialist's scope
- Needs multiple specialists (technical + billing)
- Customer requests manager

**Pattern**:
```
Billing Specialist:
"I understand you'd also like to check on the delivery timeline. Let me 
connect you back to our main support to coordinate with our technical team 
about the delivery status."

[Hands back to Orchestrator with context]

Orchestrator:
"Thank you for working with our billing team. Now let me check with our 
technical specialist about your delivery..."

[Routes to Technical]
```

</details>

<details>
<summary><strong>Hint SB-3: Specialist Completion Signals</strong></summary>

Specialists should signal when they're done:

```
Sales Specialist (after answering product questions):
"Is there anything else I can help you with regarding our products, or 
would you like to move forward with an order?"

If customer says "No, that's all":
  "Great! If you have any other questions in the future, feel free to reach out."
  [End conversation or return to orchestrator]

If customer brings up different topic:
  "That sounds like a question for our [X] team. Let me connect you..."
  [Return to orchestrator for re-routing]
```

</details>

---

## 🧪 Testing Hints

<details>
<summary><strong>Hint T-1: Test Routing First, Then Responses</strong></summary>

**Phase 1: Test Routing**
```
Input: "I want to buy the Family Haven"
Expected: Routes to Sales ✅

Input: "My order is delayed"
Expected: Routes to Technical ✅

Input: "I want a refund"
Expected: Routes to Billing ✅

Input: "This is ridiculous! I want to speak to a manager!"
Expected: Routes to Escalation ✅
```

**Phase 2: Test Specialist Responses**
```
Sales: Can provide product details, pricing, financing ✅
Technical: Can look up orders, create tickets ✅
Billing: Can explain refund policies ✅
Escalation: Can empathize, create high-priority tickets ✅
```

**Why**: Routing is foundational - get it right first!

</details>

<details>
<summary><strong>Hint T-2: Test Multi-Specialist Flows</strong></summary>

Test scenarios that require multiple specialists:

**Test Case 1: Technical → Billing**
```
Customer: "Order delayed, want refund"
Expected:
1. Routes to Technical
2. Technical confirms delay, creates ticket
3. Technical hands to Billing
4. Billing processes refund
✅ Smooth handoff, context maintained
```

**Test Case 2: Sales → Technical**
```
Customer: "I bought the Family Haven 1800, when will it arrive?"
Expected:
1. Routes to Sales
2. Sales: "Great choice! Let me check your order status..."
3. Sales hands to Technical OR Sales has access to get_orders
✅ Doesn't lose customer in handoff
```

</details>

<details>
<summary><strong>Hint T-3: Test Edge Cases</strong></summary>

**Ambiguous requests**:
```
Input: "I have a problem"
Expected: Orchestrator asks clarifying questions ✅
```

**Out-of-scope requests**:
```
Input: "What's the weather today?"
Expected: Politely decline, redirect to company topics ✅
```

**Frustrated escalation**:
```
Input: "Third time calling! Nothing is resolved!"
Expected: Immediately route to Escalation (skip clarification) ✅
```

**Context loss**:
```
Input: Multi-turn conversation across specialists
Expected: Each specialist has context from previous interactions ✅
```

</details>

---

## 🚀 Quick Wins

<details>
<summary><strong>Quick Win 1: Two-Agent MVP</strong></summary>

**Fastest path to success**:

1. **Orchestrator** (dumb router):
   ```
   If message contains "product" OR "buy" OR "pricing":
       Route to Sales
   Else:
       Route to Technical
   ```

2. **Sales Specialist**:
   - Calls `get_products()`
   - Provides product info

3. **Technical Specialist**:
   - Calls `get_orders(orderId)`
   - Creates support tickets

**Test**:
```
"Tell me about your products" → Sales ✅
"Where's my order FAB-2025-047?" → Technical ✅
```

**Why**: Proves the pattern works before adding complexity!

</details>

<details>
<summary><strong>Quick Win 2: Use Your Beginner Agent as a Specialist</strong></summary>

Your beginner challenge agent already does everything!

**Strategy**:
1. Keep beginner agent as "Technical Specialist"
2. Build new "Sales Specialist" for product questions
3. Build simple "Orchestrator" that routes between them

**Why**: Reuse existing work, focus on orchestration logic!

</details>

<details>
<summary><strong>Quick Win 3: Start with Topic Routing (Copilot Studio)</strong></summary>

**Easiest Copilot Studio approach**:

1. One agent: "Fabrikam Customer Service"
2. Create 3 Topics:
   - **Sales Topic**: Trigger = "product", "buy", "pricing"
   - **Technical Topic**: Trigger = "order", "delivery", "repair"
   - **Billing Topic**: Trigger = "refund", "payment"

3. Each topic has its own Generative Answers node with specialist system prompt

**Why**: No complex handoffs, Copilot Studio handles routing automatically!

</details>

---

## 🤔 Common Pitfalls

<details>
<summary><strong>Pitfall 1: Context Gets Lost in Handoffs</strong></summary>

**Problem**: Customer tells Technical about delay, Technical hands to Billing, Billing asks customer to repeat everything

**Solution**: Pass comprehensive context
```json
{
  "previous_specialist": "Technical",
  "summary": "Order FAB-2025-042 delayed 25 days, customer wants refund",
  "data_collected": {
    "orderId": "FAB-2025-042",
    "customerId": 17,
    "delayDays": 25
  }
}
```

**Why**: Seamless handoffs require context preservation.

</details>

<details>
<summary><strong>Pitfall 2: Infinite Routing Loops</strong></summary>

**Problem**: Orchestrator routes to Sales → Sales confused → Routes back to Orchestrator → Routes to Sales again...

**Solution**: Track routing history
```csharp
if (context.RoutingHistory.Count(r => r == "Sales") > 2)
{
    // Been to Sales 3 times already!
    return "I apologize, I'm having trouble with your request. Let me connect you to our escalation team.";
}
```

**Why**: Prevents customer frustration from endless loops.

</details>

<details>
<summary><strong>Pitfall 3: Specialists Don't Know Their Scope</strong></summary>

**Problem**: Sales specialist tries to process refunds, Technical specialist tries to quote prices

**Solution**: Clear scope in system prompts
```
Technical Specialist System Prompt:

YOUR RESPONSIBILITIES:
✅ Order status and tracking
✅ Delivery issues
✅ Product defects and damage
✅ Warranty claims
✅ Installation support

OUT OF SCOPE (refer back to orchestrator):
❌ Product pricing and sales
❌ Refund processing
❌ Account billing issues
❌ Legal complaints

If customer asks about out-of-scope topics, say:
"That's handled by our [Sales/Billing] team. Let me connect you..."
```

</details>

---

## 📚 Additional Resources

- **Beginner Challenge**: Your foundation agent can become a specialist!
- **Fabrikam MCP Tools**: Use the same tools across all specialists
- **Test Scenarios**: Full conversation flows in the README

---

**Remember**: Start simple (2 agents), then expand. Multi-agent orchestration is about **routing** and **context** - master those and the rest follows! 🧠

**Need more help?** Check the [Partial Solution](./partial-solution-multi-agent.md) for architecture guidance.

**Ready to peek?** See the [Full Solution](./full-solution-multi-agent.md) for complete implementations.
