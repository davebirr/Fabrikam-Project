# ⚠️ Partial Solution: Multi-Agent Orchestration

**Architecture & Patterns Without Full Code**

This guide provides architectural guidance and key patterns for building a multi-agent orchestration system. Use this when you want direction without seeing complete implementations.

---

## 🏗️ Architecture Overview

### **Recommended Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                     Customer Interface                       │
│            (Copilot Studio / Web UI / Chat)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  ORCHESTRATOR AGENT                          │
│                                                              │
│  Responsibilities:                                           │
│  • Classify customer intent                                  │
│  • Route to appropriate specialist                           │
│  • Maintain conversation context                            │
│  • Handle ambiguous requests with clarification              │
│  • Coordinate multi-specialist workflows                     │
└───────┬──────────┬────────────┬──────────────┬──────────────┘
        │          │            │              │
        ▼          ▼            ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐
│  SALES   │ │TECHNICAL │ │ BILLING  │ │ ESCALATION  │
│SPECIALIST│ │SPECIALIST│ │SPECIALIST│ │ SPECIALIST  │
└──────────┘ └──────────┘ └──────────┘ └─────────────┘
     │            │            │              │
     └────────────┴────────────┴──────────────┘
                  │
                  ▼
        ┌──────────────────┐
        │  Fabrikam MCP    │
        │  Tools (shared)  │
        │                  │
        │ • get_products   │
        │ • get_orders     │
        │ • get_customers  │
        │ • create_ticket  │
        └──────────────────┘
```

---

## 🎯 Intent Classification Pattern

### **Approach 1: Keyword-Based Classification** (Simpler, faster)

**Pattern**:
```
Define keyword sets for each specialist:
- Sales: ["buy", "purchase", "product", "pricing", "financing", "customize"]
- Technical: ["order", "delivery", "fab-", "damaged", "repair", "warranty", "delayed"]
- Billing: ["refund", "payment", "invoice", "charge", "bill", "account"]
- Escalation: ["manager", "supervisor", "complaint", "frustrated", "ridiculous"]

Algorithm:
1. Convert message to lowercase
2. Check for keyword matches in each category
3. Return category with most matches
4. If no matches or tie → ask for clarification
```

**Pros**: Fast, deterministic, easy to debug
**Cons**: Can't handle nuanced language, synonyms require manual addition

### **Approach 2: LLM-Based Classification** (More flexible)

**Pattern**:
```
System Prompt:
"You are an intent classifier for Fabrikam customer service.
Classify messages into: SALES, TECHNICAL, BILLING, ESCALATION, or UNCLEAR.

Examples:
- 'I want to buy a home' → SALES
- 'Where is my order FAB-2025-047?' → TECHNICAL
- 'I need a refund' → BILLING
- 'This is ridiculous, get me a manager!' → ESCALATION
- 'I have a problem' → UNCLEAR

Message: {customerMessage}
Classification:"

Parse single-word response (SALES, TECHNICAL, etc.)
```

**Pros**: Handles nuanced language, understands context
**Cons**: Slower, costs per classification, requires parsing

### **Approach 3: Hybrid** (Recommended for production)

```
1. Try keyword matching first (fast path)
2. If confident match (>70% keywords hit) → route immediately
3. If uncertain or no match → use LLM classification
4. If LLM returns UNCLEAR → ask clarifying question
```

---

## 🔄 Context Handoff Patterns

### **Pattern 1: Minimal Context** (Good for simple routing)

**Data Structure**:
```json
{
  "customerMessage": "My order is delayed and I want a refund",
  "intent": "Technical + Billing",
  "timestamp": "2025-11-04T10:30:00Z"
}
```

**Use when**: Single-specialist routing, simple requests

### **Pattern 2: Rich Context** (Better for complex flows)

**Data Structure**:
```json
{
  "customerId": 17,
  "customerName": "Diego Siciliani",
  "originalMessage": "My order is delayed and I want a refund",
  "intent": "Technical + Billing",
  "extractedData": {
    "orderId": "FAB-2025-042",
    "issueType": "Delivery delay",
    "requestedAction": "Refund"
  },
  "sentiment": "Frustrated",
  "routingHistory": ["Orchestrator", "Technical"],
  "conversationSummary": "Customer order 55 days in production, 25 days overdue. Ticket TKT-123 created.",
  "timestamp": "2025-11-04T10:30:00Z"
}
```

**Use when**: Multi-specialist workflows, complex requests, escalations

### **Pattern 3: Incremental Context Building**

```
Start with minimal context
↓
Specialist 1 adds data they discover
↓
Pass enriched context to Specialist 2
↓
Each specialist contributes what they learned
↓
Final context is comprehensive
```

**Example Flow**:
```
Orchestrator: {message, intent}
→ Technical: Adds {orderId, delayDays, ticketNumber}
→ Billing: Adds {refundAmount, processingTime}
→ Orchestrator: Final summary with all data
```

---

## 🧠 Specialist System Prompt Patterns

### **Sales Specialist Prompt Template**

```markdown
# ROLE
You are a Fabrikam Sales Specialist. You help customers explore modular home products, understand pricing, and make purchase decisions.

# CAPABILITIES
You have access to these tools:
- get_products(): Retrieve product catalog with specs and pricing
- create_support_ticket(): For custom requests beyond standard products

# YOUR RESPONSIBILITIES
✅ Help customers find the right home for their needs
✅ Explain product features, sizes, and customization options
✅ Provide pricing and financing information
✅ Guide through selection process
✅ Create tickets for custom design requests

❌ DO NOT handle:
- Order status (Technical Specialist)
- Billing/refunds (Billing Specialist)
- Complaints (Escalation Specialist)

# TONE
Enthusiastic, consultative, helpful. You're excited about helping customers find their perfect home!

# HANDOFF PROTOCOL
If customer asks about topics outside your scope:
"That's handled by our {Specialist} team. Let me connect you with them."

# CONTEXT PROVIDED
You receive:
- Customer's original request
- Routing reason
- Any data collected so far

Use this context to provide seamless service without asking customers to repeat information.
```

### **Technical Specialist Prompt Template**

```markdown
# ROLE
You are a Fabrikam Technical Support Specialist. You handle order status, delivery issues, damage reports, and warranty claims.

# CAPABILITIES
- get_orders(orderId): Look up order details and status
- get_customers(customerId): Retrieve customer information
- create_support_ticket(): Create tickets for production issues, delays, damage

# YOUR RESPONSIBILITIES
✅ Check order status and delivery tracking
✅ Investigate delivery delays
✅ Handle damage reports and warranty claims
✅ Create support tickets for production issues
✅ Provide installation guidance

❌ DO NOT handle:
- Product sales (Sales Specialist)
- Refund processing (Billing Specialist)
- Formal complaints (Escalation Specialist)

# DELAY DETECTION
Orders > 30 days in production are delayed.
Calculate: (Current Date - Order Date) - 30 = Days Overdue
If > 0 days overdue → Create high-priority ticket

# TONE
Professional, empathetic, solution-focused. Acknowledge frustration, provide clear next steps.

# HANDOFF PROTOCOL
For refund requests → Hand to Billing Specialist
For angry customers → Hand to Escalation Specialist
For product questions → Hand to Sales Specialist
```

### **Billing Specialist Prompt Template**

```markdown
# ROLE
You are a Fabrikam Billing Specialist. You handle payment questions, invoices, refunds, and financing.

# CAPABILITIES
- get_customers(customerId): Retrieve account and payment information
- create_support_ticket(): For refund processing, billing disputes

# YOUR RESPONSIBILITIES
✅ Explain billing and payment policies
✅ Process refund requests
✅ Answer invoice questions
✅ Provide financing information
✅ Handle billing discrepancies

❌ DO NOT handle:
- Product information (Sales Specialist)
- Order status (Technical Specialist)
- Complaints requiring escalation (Escalation Specialist)

# REFUND POLICY
- Pre-production: Full refund available
- In production: Partial refund, case-by-case
- Delivered: Refund only for defects (requires inspection)

# TONE
Professional, clear, policy-focused. Be empathetic but firm about policies.
```

### **Escalation Specialist Prompt Template**

```markdown
# ROLE
You are a Fabrikam Escalation Specialist. You handle customer complaints, formal escalations, and situations requiring management intervention.

# CAPABILITIES
- get_customers(customerId): Full customer history
- get_orders(orderId): Order details for context
- create_support_ticket(): HIGH-PRIORITY tickets with manager assignment

# YOUR RESPONSIBILITIES
✅ Handle frustrated/angry customers with empathy
✅ Acknowledge past service failures
✅ Create executive-level escalation tickets
✅ Provide timeline for resolution
✅ De-escalate situations when possible

# TONE
Calm, empathetic, professional. Acknowledge emotions, apologize for failures, focus on resolution.

# ESCALATION PATTERN
1. Acknowledge customer's frustration empathetically
2. Apologize for the service failure
3. Gather full context (what happened, when, how many times)
4. Create high-priority ticket with detailed notes
5. Set clear expectations for follow-up timing
6. Offer direct contact information if appropriate

# PHRASES TO USE
- "I sincerely apologize for this experience"
- "I understand this has been frustrating"
- "Let me ensure this gets the attention it deserves"
- "I'm escalating this to our management team"
- "You can expect contact within {timeframe}"
```

---

## 🔀 Multi-Specialist Workflow Patterns

### **Sequential Handoff Pattern**

```
Use when: Request requires multiple specialists in sequence

Example: "My order is delayed and I want a refund"

Flow:
1. Orchestrator classifies → Technical + Billing needed
2. Route to Technical first
   - Technical checks order
   - Confirms delay
   - Creates ticket
   - Gathers refund-relevant data
3. Technical hands to Billing with context
   - Billing sees: order delayed, ticket created, customer wants refund
   - Billing processes refund request
4. Billing confirms with customer
5. Returns to Orchestrator or ends conversation

Context Passed:
{
  "orderId": "FAB-2025-042",
  "delayDays": 25,
  "ticketNumber": "TKT-20251104-0042",
  "technicalSummary": "Order confirmed delayed, ticket created",
  "requestedAction": "Refund"
}
```

### **Parallel Consultation Pattern**

```
Use when: Orchestrator needs input from multiple specialists simultaneously

Example: "What's the best option for a 2,000 sq ft home with solar panels?"

Flow:
1. Orchestrator identifies need for Sales + potentially Technical
2. Orchestrator calls Sales specialist as tool
   - Sales returns: Product recommendations
3. Orchestrator synthesizes response
4. Provides comprehensive answer to customer

Implementation:
- Specialists are called as tools, don't interact directly with customer
- Orchestrator combines their responses
- Customer sees single coherent answer
```

### **Escalation with History Pattern**

```
Use when: Customer is frustrated after previous interactions

Example: "Third time calling! Nobody has fixed my issue!"

Flow:
1. Orchestrator detects frustration keywords
2. Immediately routes to Escalation (skip clarification)
3. Escalation Specialist:
   - Reviews customer history (previous tickets, conversations)
   - Acknowledges past failures
   - Creates executive escalation
   - Provides direct timeline and contact
4. Does NOT hand back to original specialist (fresh ownership)

Context Passed:
{
  "customerId": 17,
  "previousTickets": ["TKT-001", "TKT-045"],
  "conversationCount": 3,
  "sentiment": "Very Frustrated",
  "urgency": "High",
  "issue": "Unresolved delivery delay"
}
```

---

## 🛠️ Implementation Approaches

### **Approach A: Copilot Studio with Topics** (Easiest)

**Architecture**:
```
One Agent: "Fabrikam Customer Service"
├── Orchestration Topic (default topic)
│   ├── Classify intent
│   ├── Redirect to specialist topic
│   └── Handle multi-turn conversations
├── Sales Topic
│   ├── Trigger: Sales keywords
│   ├── System Message: Sales specialist prompt
│   └── Generative Answers with get_products access
├── Technical Topic
│   ├── Trigger: Technical keywords
│   ├── System Message: Technical specialist prompt
│   └── Generative Answers with get_orders, create_ticket access
├── Billing Topic
│   └── [Similar structure]
└── Escalation Topic
    └── [Similar structure]
```

**Pros**:
- Single agent, easy to manage
- Built-in topic routing
- Shared conversation history
- No complex handoff mechanics

**Cons**:
- Can become complex with many topics
- All logic in one agent
- Harder to test specialists independently

### **Approach B: Multiple Copilot Studio Agents** (More Realistic)

**Architecture**:
```
Fabrikam Orchestrator Agent
├── Uses "Transfer to Agent" action
├── Routes to:
│   ├── Fabrikam Sales Agent
│   ├── Fabrikam Technical Agent
│   ├── Fabrikam Billing Agent
│   └── Fabrikam Escalation Agent
```

**Handoff Implementation**:
```
In Orchestrator:
1. Generative Answers node classifies intent
2. Based on classification, use "Transfer conversation to agent" action
3. Select target specialist agent
4. Pass context variables to specialist

In Specialist:
1. Receive context from orchestrator
2. Handle customer request
3. When done, optionally transfer back to orchestrator
```

**Pros**:
- Clean separation of concerns
- Specialists can be developed independently
- Realistic enterprise pattern
- Easy to test each agent

**Cons**:
- Requires explicit context passing configuration
- More agents to manage
- Transfer mechanics can be complex

### **Approach C: Agent Framework with MCP Tools** (Most Flexible)

**Architecture**:
```csharp
// Orchestrator agent
var orchestrator = new ChatCompletionsAgent
{
    Name = "Fabrikam Orchestrator",
    Instructions = orchestratorPrompt,
    Tools = {
        salesSpecialistTool,
        technicalSpecialistTool,
        billingSpecialistTool,
        escalationSpecialistTool
    }
};

// Each specialist is an MCP tool
[McpServerTool]
public async Task<object> ConsultSalesSpecialist(
    string customerRequest,
    string context)
{
    // Sales specialist logic
    // Calls get_products, formats response
    return salesResponse;
}
```

**Orchestrator Decision Flow**:
```csharp
var messages = new List<ChatMessage> {
    new SystemChatMessage(orchestratorPrompt),
    new UserChatMessage(customerRequest)
};

var response = await orchestrator.GetChatCompletionsAsync(messages);

// Orchestrator decides to call specialist tool
// Agent Framework automatically routes to appropriate tool
// Tool returns specialist response
// Orchestrator formats for customer
```

**Pros**:
- Full control over routing logic
- Specialists are testable functions
- Easy to add new specialists
- Supports complex workflows

**Cons**:
- Requires coding
- Need to manage conversation state
- More complex setup

---

## 📊 Decision Matrix: Which Approach?

| Requirement | Copilot Topics | Multiple Agents | Agent Framework |
|-------------|----------------|-----------------|-----------------|
| **No coding required** | ✅ Best | ✅ Good | ❌ Requires code |
| **Quick setup** | ✅ Best | ⚠️ Medium | ❌ More complex |
| **Realistic enterprise pattern** | ⚠️ Simple | ✅ Best | ✅ Best |
| **Easy testing** | ⚠️ Medium | ✅ Best | ✅ Best |
| **Specialist independence** | ❌ Shared agent | ✅ Best | ✅ Best |
| **Complex routing logic** | ⚠️ Limited | ⚠️ Medium | ✅ Best |
| **Context management** | ✅ Auto | ⚠️ Manual config | ⚠️ Manual code |
| **Learning curve** | ✅ Low | ⚠️ Medium | ❌ High |

**Recommendation**:
- **Beginner/No-code**: Copilot Studio with Topics
- **Low-code/Enterprise realism**: Multiple Copilot Agents
- **Advanced/Full control**: Agent Framework with MCP tools

---

## 🧪 Testing Strategy

### **Phase 1: Individual Specialist Testing**

```
Test each specialist independently:

Sales Specialist:
✅ "Tell me about the Family Haven 1800"
✅ "What financing options do you offer?"
✅ "How much does customization cost?"

Technical Specialist:
✅ "Where is order FAB-2025-047?"
✅ "My home has water damage"
✅ "Installation isn't complete"

Billing Specialist:
✅ "I need a refund"
✅ "When is my payment due?"
✅ "I was charged twice"

Escalation Specialist:
✅ "This is ridiculous, get me a manager!"
✅ "I've called three times with no resolution!"
```

### **Phase 2: Orchestrator Routing Testing**

```
Test routing logic:

✅ "I want to buy a home" → Routes to Sales
✅ "My order is delayed" → Routes to Technical
✅ "I want a refund" → Routes to Billing
✅ "I want to speak to a manager" → Routes to Escalation
✅ "I have a problem" → Asks clarifying question
```

### **Phase 3: Multi-Specialist Flow Testing**

```
Test complex workflows:

✅ Delayed order + refund → Technical → Billing
✅ Product question + order status → Sales → Technical
✅ Frustrated customer → Immediate escalation
✅ Context maintained across handoffs
✅ Conversation summary at transitions
```

### **Phase 4: Edge Case Testing**

```
✅ Ambiguous requests ("I need help")
✅ Out-of-scope ("What's the weather?")
✅ Multiple issues in one message
✅ Changing topics mid-conversation
✅ Returning customers with history
```

---

## 🎯 Success Metrics

**Basic Success** (30 points):
- Routing works for clear requests
- At least 2 specialists functional
- Basic context passing

**Good Success** (60 points):
- All 4 specialists working
- Multi-specialist workflows
- Clarification for ambiguous requests
- Natural handoff language

**Excellent Success** (100 points):
- Intelligent intent classification
- Context preserved across all handoffs
- Conversation summaries
- Escalation paths working
- Professional experience

---

## 🚀 Next Steps

Ready to start building:

1. **Choose your implementation approach** (Topics, Multiple Agents, or Agent Framework)
2. **Build orchestrator + 1 specialist** (prove the pattern)
3. **Add remaining specialists** (expand coverage)
4. **Test workflows** (single and multi-specialist)
5. **Polish experience** (handoff language, context quality)

**Need more detail?** Check the [Full Solution](./full-solution-multi-agent.md) for complete code examples.

**Need clarification?** Review the [Hints](./hints-multi-agent.md) for specific implementation guidance.

---

**Remember**: Multi-agent orchestration is about **routing** (right specialist), **context** (seamless handoffs), and **experience** (natural transitions). Master these and you have a scalable customer service system! 🎯
