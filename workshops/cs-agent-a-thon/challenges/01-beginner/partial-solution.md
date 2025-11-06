# 🟢 Beginner Challenge: Partial Solution

**Architecture & Approach Guide** | No Complete Code Spoilers

---

## 🎯 Purpose of This Document

This partial solution shows you **HOW to think about the problem** without giving away the exact implementation. You'll learn:

- ✅ Overall architecture and component structure
- ✅ Key patterns and decision points
- ✅ When to use which MCP tools
- ✅ How to structure your instructions
- ✅ Critical logic for delay detection

**What this does NOT include:**
- ❌ Complete instructions text
- ❌ Exact conversation flows
- ❌ Word-for-word instructions

If you want the complete working solution, see [full-solution.md](./full-solution.md).

---

## 🏗️ Overall Architecture

### **The Three-Layer Pattern**

Your agent needs three distinct layers working together:

```
┌─────────────────────────────────────────────────┐
│         PERSONALITY & TONE LAYER                │
│  "How should I sound? When to be empathetic?"  │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         BUSINESS LOGIC LAYER                    │
│  "What are the rules? When to take action?"    │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         TOOL EXECUTION LAYER                    │
│  "Which MCP tools to call? What data to use?"  │
└─────────────────────────────────────────────────┘
```

**Why this matters:** Many beginners create agents that can use tools but don't know WHEN to use them or HOW to interpret the results. The business logic layer is what separates a chatbot from an intelligent agent.

---

## 📋 instructions Structure

Your instructions should have these distinct sections:

### **1. Role Definition** (~3-4 sentences)
- Who you are (customer service agent for Fabrikam)
- What you help with (orders, products, support)
- Your core mission (assist customers professionally)

### **2. Personality Guidelines** (~5-7 rules)
Key attributes to specify:
- Tone (warm, professional, empathetic)
- Language style (clear, specific, jargon-free)
- Ownership mentality (don't blame "the system")
- When to show empathy vs efficiency

**Pattern to use:**
```
PERSONALITY:
- [Attribute]: [How to demonstrate it]
- [Attribute]: [Specific examples]
```

### **3. Available Tools** (Critical section!)
List each MCP tool with:
- Tool name
- **What it does** (function)
- **When to use it** (trigger conditions)
- **What to do with results** (interpretation)

**Example structure:**
```
TOOLS:
- get_orders
  Purpose: [What it retrieves]
  Use when: [Customer mention triggers]
  After calling: [How to analyze the data]
```

### **4. Business Rules** (The secret sauce!)
This is where most beginners fall short. You need to explicitly teach your agent:

#### **Production Timeline Rules**
- Standard production time: **30 days**
- How to calculate if order is delayed
- What to do when delay is detected

**Pattern:**
```
PRODUCTION TIMELINES:
- Standard: [X days]
- Calculation: [How to compute delay]
- Action when delayed: [What to do immediately]
```

#### **Ticket Creation Rules**
Specify:
- When to create tickets (not just "for problems")
- What categories to use (exact values)
- How to set priority (criteria)
- What information to include

#### **Support Ticket Categories**
You must provide the **exact category names** the API expects:
- `OrderInquiry`
- `DeliveryIssue`
- `ProductDefect`
- `Installation`
- `Billing`
- `Technical`
- `General`
- `Complaint`

**Why exact names matter:** The API will reject tickets with incorrect categories. Your agent needs to know "use `OrderInquiry`, not 'Order Question'".

### **5. Conversation Flow** (~5-7 steps)
A simple numbered process:
1. Greet warmly
2. Understand need
3. Call appropriate tool(s)
4. Analyze results (not just repeat!)
5. Provide helpful response
6. Take action if needed
7. Offer next steps

### **6. Error Handling**
What to do when:
- Tool returns no results
- Customer provides invalid data
- System errors occur
- You don't have enough information

---

## 🎯 Critical Logic: Delay Detection

**This is the hardest part of the beginner challenge.** Here's how to think about it:

### **The Problem**
When a customer asks "Where is my order?", they want MORE than just what the database says. They want you to ANALYZE whether this is normal or a problem.

### **What NOT to do:**
```
❌ Customer: "Where is my order?"
❌ Agent: "Your order is in production since Jan 15."
   (Just repeating system data - not helpful!)
```

### **What TO do:**
```
✅ Customer: "Where is my order?"
✅ Agent: "I can see your order has been in production for 49 days, 
          which is longer than our standard 30-day timeline. This appears 
          to be delayed. I apologize for this! I've created a support 
          ticket (#12345) and our production team will contact you 
          within 24 hours."
   (Analyzing data + taking action - intelligent!)
```

### **The Algorithm**

Your agent needs to:

1. **Get current date** (the AI model knows today's date)
2. **Get order date** (from `get_orders` tool response)
3. **Calculate days elapsed**
4. **Compare to standard (30 days)**
5. **If delayed: TAKE ACTION**

### **Implementation Approaches**

#### **Approach 1: Explicit Calculation Instructions**
Tell your agent exactly how to do math:

```
When analyzing order timelines:
1. Note today's date
2. Note the order date from get_orders
3. Calculate: days_elapsed = today - order_date
4. If days_elapsed > 30 AND status is still "InProduction":
   - This is DELAYED
   - Immediately call create_support_ticket
   - Use category: "OrderInquiry"
   - Priority: "High"
```

#### **Approach 2: Business Rule Definition**
Define the rule and let the AI figure out the math:

```
PRODUCTION DELAYS:
- Standard production: 30 days
- If order is in production longer than 30 days, it is DELAYED
- ALWAYS create a support ticket for delayed orders
- Don't wait for customer to ask - be proactive!
```

#### **Approach 3: Example-Based Learning**
Provide an example in your prompt:

```
EXAMPLE: Delayed Order Detection
Order placed: January 15, 2025
Today's date: March 5, 2025
Days in production: 49 days
Standard timeline: 30 days
Status: InProduction

ANALYSIS: This order is 19 days overdue (49 - 30 = 19)
ACTION: Create ticket immediately with category "OrderInquiry", 
        priority "High", description explaining the delay
```

**Recommended:** Use a combination of Approach 1 (explicit) and Approach 3 (example).

---

## 🛠️ Tool Usage Patterns

### **get_orders**

**When to call:**
- Customer mentions order number (FAB-2025-XXX)
- Customer asks "where is my order"
- Customer provides email (call get_customers first, then get_orders)

**What to do with results:**
```json
{
  "id": 15,
  "orderNumber": "FAB-2025-015",
  "orderDate": "2024-11-12T00:00:00",
  "status": "InProduction",
  "productName": "Starter Studio 400"
}
```

**Analysis checklist:**
- ✅ Is this order delayed? (calculate days)
- ✅ What's the next expected milestone?
- ✅ Should I create a ticket?
- ✅ What can I tell the customer about timeline?

### **get_products**

**When to call:**
- Customer asks about home models
- Customer wants to compare products
- Customer asks "which home should I buy"
- During product recommendations

**What to do with results:**
Multiple products returned - you need to:
- Present information clearly (not just dump JSON)
- Highlight key differences (size, price, features)
- Ask clarifying questions (budget, needs)
- Remain neutral (help decide, don't push)

### **get_customers**

**When to call:**
- Customer provides email instead of order number
- You need to look up customer details
- Customer asks "show my orders"

**Use case pattern:**
```
1. Call get_customers with email
2. Get customer ID and name
3. Use customer info to call get_orders
4. Show all orders for that customer
```

### **create_support_ticket**

**When to call:**
- ✅ Delayed order detected (AUTOMATIC)
- ✅ Customer reports damage or defect
- ✅ Customer is frustrated or angry
- ✅ Issue beyond your capabilities
- ✅ Customer explicitly requests escalation

**What NOT to do:**
- ❌ Say "I'll create a ticket" but never actually call the tool
- ❌ Create tickets for simple questions you can answer
- ❌ Create tickets without gathering information first

**Required parameters:**
```javascript
{
  customerId: number,        // From get_customers or get_orders
  subject: string,           // Clear, specific (not "Help")
  description: string,       // Detailed context
  category: string,          // EXACT category from approved list
  priority: string          // Critical|High|Medium|Low
}
```

**Best practice structure:**
```
Subject: "[Category] - [Specific Issue]"
Example: "Order Delay - FAB-2025-015 exceeded 30-day production timeline"

Description: 
- Customer: [Name]
- Order: [Order number]
- Issue: [What's wrong]
- Timeline: [Relevant dates]
- Customer sentiment: [Frustrated/Calm/Urgent]
- Action needed: [What should support team do]
```

---

## 💡 Key Decision Points

### **Decision 1: When to be proactive vs reactive?**

**Reactive (wait for customer to complain):**
```
Customer: "My order is taking forever!"
Agent: "Let me look that up..." [then discovers delay]
```

**Proactive (detect and act immediately):**
```
Customer: "What's my order status?"
Agent: [Calls get_orders, calculates days, detects delay]
        "I can see your order has been delayed. I apologize! 
         I've already created a support ticket..."
```

**Guideline:** Be proactive for delays, reactive for other issues.

### **Decision 2: How much empathy is too much?**

**Not enough:**
```
Agent: "Your order is delayed. Ticket created. Anything else?"
```

**Too much:**
```
Agent: "Oh no! I'm so incredibly sorry! This must be so frustrating 
        for you! I can't imagine how disappointed you must feel! Let me..."
```

**Just right:**
```
Agent: "I apologize for this delay. I understand you were expecting 
        delivery by now. I've created a support ticket and our team 
        will contact you within 24 hours to get this resolved."
```

**Guideline:** One genuine apology + action + clear next steps.

### **Decision 3: What to do when information is missing?**

**Bad approach:**
```
Customer: "Where's my order?"
Agent: "I don't have enough information."
```

**Good approach:**
```
Customer: "Where's my order?"
Agent: "I'd be happy to look that up! Could you provide either:
        - Your order number (starts with FAB-2025-), or
        - The email address used when ordering?"
```

**Guideline:** Never dead-end. Always offer 2-3 paths forward.

---

## 🎯 Scenario-Specific Guidance

### **Scenario 1: Simple Order Lookup**

**Architecture:**
```
Customer provides order number
   ↓
Call get_orders(orderNumber)
   ↓
Analyze result:
  - Is order delayed? (check days)
  - What status? (explain next steps)
  - Any issues? (create ticket if needed)
   ↓
Respond with:
  - Current status
  - What it means
  - What happens next
  - Timeline expectations
```

**Key pattern:** Don't just repeat the status field. INTERPRET it for the customer.

### **Scenario 2: Delayed Order Detection**

**Critical logic flow:**
```
Customer asks about order
   ↓
Call get_orders
   ↓
Get order date from response
   ↓
Calculate: days_elapsed = (today - order_date)
   ↓
IF days_elapsed > 30 AND status == "InProduction":
   ↓
   This is DELAYED!
   ↓
   IMMEDIATELY call create_support_ticket:
     - category: "OrderInquiry"
     - priority: "High"
     - subject: "Order Delay - [order number]"
     - description: Include timeline calculation
   ↓
   Respond to customer:
     - Acknowledge delay with apology
     - Explain what you've done (ticket created)
     - Set expectation (24-hour callback)
     - Provide ticket number
```

**Common mistake:** Detecting the delay but saying "I'll create a ticket" without actually calling the tool. Your agent must TAKE ACTION, not just talk about it!

### **Scenario 3: Product Comparison**

**Pattern:**
```
Customer wants to compare products
   ↓
Call get_products (no parameters = all products)
   ↓
Filter results to customer's criteria:
  - Ask about: budget, family size, needs
  - Narrow down options
   ↓
Present comparison:
  - Side-by-side key features
  - Highlight differences
  - Explain trade-offs
   ↓
Remain neutral:
  - Help them decide (don't push)
  - Offer to connect with sales if needed
```

**Key insight:** Product comparison is a SALES conversation, not support. Be helpful but know your limits.

### **Scenario 4: Angry Customer with Damage**

**Emotional intelligence pattern:**
```
Customer expresses frustration
   ↓
FIRST: Acknowledge emotion
  "I understand this is frustrating..."
   ↓
SECOND: Gather information
  - Order number
  - What happened
  - Severity of damage
   ↓
THIRD: Take immediate action
  Call create_support_ticket:
    - category: "ProductDefect"
    - priority: "Critical" (damage = urgent)
    - Include all details
   ↓
FOURTH: Set clear expectations
  - "Production team will call within 2 hours"
  - "We'll get this resolved quickly"
  - Provide ticket number
   ↓
FIFTH: Follow up
  - "Is there anything else I can help with?"
```

**Critical rules:**
- Never minimize ("it's not that bad")
- Never blame ("the shipping company...")
- Never say "I'll try" (say "I will")
- Always give specific timelines (not "soon")

### **Scenario 5: Order Not Found**

**Graceful degradation pattern:**
```
Customer provides order number
   ↓
Call get_orders(orderNumber)
   ↓
Result: null or error
   ↓
DON'T SAY: "That order doesn't exist"
   ↓
DO SAY: "I'm not finding that order number in our system. 
         Let's try another way..."
   ↓
Offer alternatives:
  1. "Could you double-check the order number? It should start with FAB-2025-"
  2. "I can also search by the email address you used when ordering"
  3. "Or I can create a support ticket to help track this down"
   ↓
Call get_customers if they provide email
   ↓
If still no results:
  Create support ticket with category "OrderInquiry"
```

**Key principle:** Every failure is an opportunity to help in a different way.

---

## 🧩 Putting It All Together

### **The instructions Formula**

```
[ROLE] (3-4 sentences defining who you are)
  +
[PERSONALITY] (5-7 attributes with examples)
  +
[TOOLS] (Each tool with purpose, when-to-use, what-to-do-after)
  +
[BUSINESS RULES] (Timeline rules, ticket rules, categories, priorities)
  +
[CONVERSATION FLOW] (Numbered steps)
  +
[ERROR HANDLING] (What to do when things go wrong)
```

### **Testing Progression**

Don't try to build everything at once! Use this progression:

**Phase 1: Basic Tool Calling**
- Test Scenario 1 (simple order lookup)
- Verify tools are connected
- Check that responses include data

**Phase 2: Add Business Logic**
- Add production timeline rules
- Test delay detection math
- Verify ticket creation works

**Phase 3: Add Personality**
- Refine tone and empathy
- Test Scenario 4 (angry customer)
- Ensure responses feel natural

**Phase 4: Add Error Handling**
- Test Scenario 5 (order not found)
- Verify graceful degradation
- Check alternative paths work

**Phase 5: Polish & Optimize**
- Test all scenarios
- Refine edge cases
- Ensure consistency

---

## ⚠️ Common Pitfalls to Avoid

### **Pitfall 1: "Tool-Blind" Agent**
**Problem:** Agent has access to tools but doesn't know when to use them.

**Symptom:**
```
Customer: "What's my order status?"
Agent: "I don't have access to that information."
(Even though get_orders tool is available!)
```

**Fix:** In your TOOLS section, specify clear triggers:
```
get_orders:
  Use when: Customer mentions order number, asks "where is my order", 
           asks about delivery, provides FAB-2025-XXX format
```

### **Pitfall 2: "Parrot" Agent**
**Problem:** Agent just repeats tool output without analysis.

**Symptom:**
```
Customer: "Where is my order?"
Agent: "Your order status is InProduction since January 15."
(No analysis of whether this is normal or delayed!)
```

**Fix:** Add ANALYSIS instructions after tool calls:
```
After calling get_orders:
1. Calculate days elapsed
2. Compare to standard timeline
3. Determine if action needed
4. Provide interpretation, not just data
```

### **Pitfall 3: "All Talk, No Action" Agent**
**Problem:** Agent says it will create a ticket but never calls the tool.

**Symptom:**
```
Agent: "I'll create a support ticket for you right away!"
(But create_support_ticket tool never gets called)
```

**Fix:** Use imperative language in your prompt:
```
When order is delayed:
  IMMEDIATELY call create_support_ticket
  DO NOT just say you will - actually call the tool!
  Use these exact parameters: [...]
```

### **Pitfall 4: Vague Business Rules**
**Problem:** Rules are unclear or missing.

**Symptom:**
```
"Create tickets for problems" 
(What counts as a problem? What category? What priority?)
```

**Fix:** Be specific:
```
Create support tickets when:
  - Order delayed beyond 30 days → category: "OrderInquiry", priority: "High"
  - Damage reported → category: "ProductDefect", priority: "Critical"
  - Customer frustrated → category: "Complaint", priority: "High"
```

### **Pitfall 5: Robotic Tone**
**Problem:** Responses sound mechanical.

**Symptom:**
```
Agent: "Order FAB-2025-015 status: InProduction. Timeline: 49 days."
```

**Fix:** Add personality guidance:
```
Use natural language:
  ❌ "Order FAB-2025-015 status: InProduction"
  ✅ "I can see your Starter Studio 400 is currently in production"
  
Show empathy when needed:
  ❌ "Order delayed. Ticket created."
  ✅ "I apologize for this delay. I've created a support ticket 
      and our team will contact you within 24 hours."
```

---

## 🎓 What Makes a 100-Point Solution?

### **Scoring Breakdown**

**Basic (30 points):**
- Tools are connected and callable
- Agent responds to basic queries
- Tickets can be created manually

**Good (60 points):**
- Agent knows when to use which tool
- Natural conversation flow
- Empathetic tone
- Error handling works

**Excellent (100 points):**
- **Proactive delay detection** (the hardest part!)
- **Automatic ticket creation** (action, not just talk)
- **Business context awareness** (interprets data, not repeats it)
- **Anticipates needs** (offers next steps)

### **The 100-Point Checklist**

✅ **Tool Integration**
- All 4 MCP tools configured
- Agent knows when to use each one
- Tools are called automatically (not manually prompted)

✅ **Delay Detection**
- Agent calculates days elapsed
- Compares to 30-day standard
- Detects delays without being told
- Creates ticket AUTOMATICALLY when delayed

✅ **Ticket Creation**
- Uses correct categories (exact strings)
- Sets appropriate priorities
- Includes detailed descriptions
- Actually calls the tool (not just talks about it)

✅ **Personality**
- Warm and professional tone
- Empathy for frustrated customers
- Clear, specific language
- Takes ownership (not "system says...")

✅ **Error Handling**
- Graceful when order not found
- Offers alternative paths
- Never dead-ends conversation
- Creates tickets for unresolvable issues

✅ **Business Logic**
- Understands 30-day production timeline
- Knows all ticket categories
- Sets correct priorities
- Follows escalation patterns

---

## 🚀 Next Steps

### **If You're Still Stuck:**

1. **Review the [hints](./hints.md)** for specific guidance without full spoilers
2. **Check [conversation-examples.md](./conversation-examples.md)** to see patterns in action
3. **Test incrementally** - don't try to build everything at once
4. **Ask for help** - proctors are here to guide you!

### **If You're Ready to See the Full Solution:**

The [full-solution.md](./full-solution.md) contains:
- ✅ Complete instructions (word-for-word)
- ✅ All 4 conversation examples with annotations
- ✅ Exact MCP tool configuration
- ✅ Troubleshooting for common issues

**But try building it yourself first!** You'll learn more by struggling through the delay detection logic than by copying the solution.

---

## 💡 Remember

**The goal isn't to build a perfect agent.** The goal is to:
- Learn how AI agents think differently than chatbots
- Understand when to use tools vs when to use knowledge
- Practice engineering prompts that drive behavior
- Experience the debugging process

**Even a 60-point solution is a huge achievement!** You're building real AI capabilities that businesses need.

Good luck, and remember: **Action over conversation. Analysis over repetition. Empathy over efficiency.** 🚀

---

**Ready for the complete solution?** → [View Full Solution](./full-solution.md)
