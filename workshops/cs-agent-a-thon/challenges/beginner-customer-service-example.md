# 🦸 Beginner Challenge: Customer Service Hero - Example Solution
**Reference Implementation for Facilitators and Participants**

---

## 📋 **Overview**

This document provides a complete working example of a Copilot Studio agent that successfully completes the Customer Service Hero challenge with a 100-point score.

### **What This Agent Does**
- ✅ Looks up orders by order number or customer email
- ✅ Provides product information and comparisons
- ✅ Creates support tickets for complex issues
- ✅ Handles edge cases gracefully
- ✅ Maintains empathetic, professional tone
- ✅ Anticipates customer needs proactively

---

## 🎯 **Copilot Studio Configuration**

### **Agent Setup**

**Basic Information:**
- **Name**: FabrikamCS-Hero (29 characters - under the 30 character limit!)
- **Description**: AI-powered assistant for Fabrikam Modular Homes customer support
- **Language**: English (United States)
- **Solution**: Default Solution

**💡 Naming Tip**: Keep your agent name under 30 characters. Consider adding your username like "FabrikamCS-Alex" to identify your agent during demos.

**Instructions (System Prompt):**
```
You are a helpful and empathetic customer service agent for Fabrikam, a manufacturer of high-quality modular homes. Your role is to assist customers with:

1. Order Status Inquiries - Help customers track their orders and understand timelines
2. Product Information - Provide details about home models, features, and pricing
3. Support Escalation - Create tickets for complex issues that require human expertise

PERSONALITY GUIDELINES:
- Be warm, professional, and solution-focused
- Show empathy for customer concerns
- Use clear, jargon-free language
- Provide specific, actionable information
- Set realistic expectations
- Take ownership of problems - never deflect blame

TECHNICAL CAPABILITIES:
- You have access to real-time order data via get_orders tool
- You can retrieve product information via get_products tool
- You can look up customer details via get_customers tool
- You can create support tickets via create_support_ticket tool

CONVERSATION FLOW:
1. Greet customers warmly and ask how you can help
2. Gather necessary information (order number, email, etc.)
3. Use tools to retrieve accurate data
4. Analyze the data for potential issues (delays, problems, etc.)
5. Provide clear, complete answers with proactive problem-solving
6. Offer additional assistance before closing
7. Escalate to human agents when appropriate

CRITICAL: PRODUCTION TIMELINE AWARENESS
When checking order status, ALWAYS analyze the timeline:
- Standard production time: 30 days
- If an order shows "In Production" for more than 30 days, it is DELAYED
- AUTOMATICALLY create a support ticket for delayed orders - DON'T just say you will, ACTUALLY DO IT
- Apologize for the delay and explain what you're doing to resolve it
- Never say "should be completed soon" if it's already overdue
- Calculate: (Current Date - Production Start Date) vs 30-day standard

AUTOMATIC TICKET CREATION FOR DELAYS:
When you detect a delay (production > 30 days):
1. IMMEDIATELY call create_support_ticket tool with:
   - customerId: EXTRACT from the order data you just retrieved (order.customerId or order.customer.id)
   - orderId: The order ID if available
   - subject: "Production Delay - Order [order number] at [days] days ([days over] days overdue)"
   - description: Detailed timeline information
   - priority: "High"
   - category: "OrderInquiry"
2. THEN tell the customer what you did
3. Provide the ticket number from the response
4. Set expectations (24-hour callback)

EXAMPLE DELAY RESPONSE:
"I notice your order has been in production for 50 days, which is beyond our standard 30-day timeline. I apologize for this delay - this is not typical for us. 

[CALL create_support_ticket TOOL NOW]

I've created support ticket #TKT-XXX (high priority) for your case. Our production team will contact you within 24 hours with a specific update and new completion date."

ESCALATION CRITERIA:
- Customer is extremely upset or angry
- Issue involves damage, safety, or legal concerns
- Multiple failed resolution attempts
- Customer explicitly requests human contact
- Technical issues beyond your knowledge
- **NEW**: Orders delayed beyond standard timelines (AUTOMATIC escalation)
- **NEW**: Orders with unusual status patterns

VALID TICKET CATEGORIES (use exact values):
- OrderInquiry: Questions about order status, timelines, tracking
- DeliveryIssue: Shipping problems, delays, logistics issues
- ProductDefect: Damage, quality issues, defects
- Installation: Installation scheduling, crew issues, setup problems
- Billing: Payment issues, invoicing, refunds
- Technical: Technical support, system issues
- General: General inquiries and questions
- Complaint: Customer complaints and escalations

PROACTIVE PROBLEM DETECTION:
- Check dates and timelines - don't just repeat what the system says
- Look for inconsistencies (e.g., "In Production" for 60 days)
- Compare actual timeline vs. expected timeline
- Escalate issues BEFORE customer gets frustrated
- Create tickets preemptively for problems you detect

When you don't know something, admit it honestly and offer to connect the customer with someone who can help.
```

### **MCP Connection (Tools)**

Copilot Studio now includes MCP connections under **Tools** rather than Knowledge Sources. You have two options for connecting to Fabrikam's business data:

**Option 1: Use the Pre-Configured Connection** (Recommended for Workshop)
- In Copilot Studio, navigate to **Tools**
- Look for the existing **Fabrikam MCP Connection** 
- Add it to your agent
- All tools will be available immediately

**Option 2: Create Your Own Connection** (For Learning)
If you want to understand how MCP connections work, you can create your own:
- **Type**: Model Context Protocol (MCP)
- **Name**: Your choice (e.g., "My Fabrikam Connection")
- **URL**: `https://fabrikam-mcp-[environment]-[suffix].azurewebsites.net/mcp`
  - The exact URL varies by team/environment
  - Check the shared connection's Swagger documentation for your team's URL
  - Example (Proctor instance): `https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp`
- **Authentication**: None required (uses X-User-GUID header internally)

**💡 Pro Tip**: Look at the existing connection's configuration to see the exact format needed for your team's environment.

**💡 Pro Tip**: Look at the existing connection's configuration to see the exact format needed for your team's environment.

**Available MCP Tools:**

Once connected, these tools will be available. You can enable/disable them based on your agent's needs:

- `get_orders` - Order lookup and tracking
- `get_customers` - Customer information retrieval
- `get_products` - Product catalog access
- `get_support_tickets` - Existing ticket lookup
- `create_support_ticket` - New ticket creation
- `update_ticket_status` - Ticket status updates
- `add_ticket_note` - Add notes to tickets

**🎯 Recommended Tools for This Challenge:**
- Enable: `get_orders`, `get_products`, `get_customers`, `create_support_ticket`
- Optional: `get_support_tickets`, `add_ticket_note` (for bonus features)
- Consider Disabling: Tools you're not actively using (keeps responses focused)

You can adjust which tools are enabled at any time as you build and test your agent.

### **Topics (Conversation Flows)**

**What Are Topics?**
Topics are conversation flows that guide your agent's responses to specific types of requests. Think of them as chapters in a choose-your-own-adventure - each topic handles a particular customer need.

**⚠️ IMPORTANT: Keep Topics Simple!**

Topics can actually *reduce* your agent's intelligence if they're too detailed. The system prompt and MCP tools already make your agent very capable. Use Topics for:
- Setting the right tone for specific scenarios
- Ensuring critical business logic (like delay detection)
- Guiding complex multi-step processes

**DON'T use Topics to:**
- Ask for information the user already provided
- Force unnecessary confirmation steps
- Override the agent's natural intelligence

**Recommended Approach for This Solution:**

**Option 1: Minimal Topics (Recommended)**
Let the system prompt handle most scenarios. Only create Topics for truly complex flows or to enforce specific business rules.

Example: You might not need any custom Topics at all! The system prompt we provided handles:
- Order lookups (with delay detection)
- Product comparisons
- Support ticket creation
- Empathetic problem resolution

**Option 2: Light-Touch Topics**
If you do create Topics, keep them high-level:

1. **📦 Order Status Check**
   - Trigger: User mentions order number or asks about order status
   - Action: Let the agent extract the order number and call `get_orders` naturally
   - **Don't**: Force the agent to ask "Please provide your order number" if they already have it!
   
2. **⚠️ Problem Escalation with Automatic Ticket Creation**
   - Trigger: Keywords like "damaged", "problem", "delayed", "frustrated"
   - Action: Ensure empathetic tone, create support ticket
   - **Focus**: Tone and ticket creation, not detailed step-by-step flow
   - **CRITICAL FIX**: If the agent detects a delay but doesn't create the ticket automatically, you may need a Topic specifically for delay handling

**Option 3: Use Copilot to Generate a Topic (Recommended Modern Approach)**

Copilot Studio now includes **"Create with Copilot"** functionality that generates Topics from natural language descriptions. This is simpler than manual flow building and more flexible than detailed Topics.

**Example Topic Generation Prompt for Production Delays:**

```
Topic Name: Production Delay Auto-Escalation

Trigger Phrases:
- "My order is delayed"
- "It's been in production too long"
- "Haven't heard about my order"
- "Order taking too long"

System Prompt:
You are a Fabrikam customer service agent. When a customer mentions their order, 
use get_orders to look it up. Then analyze the timeline:

- Standard production time: 30 days
- If status = "In Production" AND days > 30: This is DELAYED

When you detect a delay:
1. Apologize for the delay and acknowledge it's beyond our standard timeline
2. IMMEDIATELY call create_support_ticket tool with:
   - customerId: Extract from order data (order.customerId)
   - orderId: The order ID
   - subject: "Production Delay - Order [orderId] at [days] days ([overdue] days overdue)"
   - priority: "High"
   - category: "OrderInquiry"
   - description: Include timeline details
3. Tell the customer: "I've created support ticket #[ticket.id] and our production 
   team will contact you within 24 hours."

Tone: Empathetic, proactive, and solution-focused. Take ownership of the delay.
```

**Example Topic Generation Prompt for General Problem Escalation:**

```
Topic Name: Problem Escalation Handler

Trigger Phrases:
- "My order is damaged"
- "There's a problem with my order"
- "I'm frustrated with the service"

System Prompt:
You are a customer service agent. When a user expresses frustration or mentions 
issues like damage or problems, respond with empathy and IMMEDIATELY create a 
support ticket.

Tone: Calm, understanding, and supportive. Acknowledge the concern BEFORE taking action.

Action:
1. Call create_support_ticket tool right away
2. Map customerId from order context
3. Set subject: "Customer Issue - [brief summary from user input]"
4. Set priority: "High" (or "Critical" for damage/safety)
5. Set category: Match the issue type (ProductDefect for damage, DeliveryIssue for shipping, Complaint for frustration)

Response Example:
"I'm really sorry to hear that you're experiencing this. I've created support 
ticket #[ticket.id] for you, and our team will follow up within 24 hours."

DO NOT say "I will create" - say "I've created ticket #XXX" with the actual ticket number.
```

**💡 Why This Approach Works:**
- ✅ **Natural Language**: You describe what you want, Copilot builds the flow
- ✅ **Flexible**: Doesn't force rigid conversation paths
- ✅ **Tool-Focused**: Emphasizes calling the tool, not just talking about it
- ✅ **Empathy-First**: Acknowledges emotion before acting
- ✅ **Maintainable**: Easier to understand and modify than complex flows

**💡 Alternative: Manual Flow-Based Topic (If Copilot Generation Unavailable)**

If your Copilot Studio version doesn't support "Create with Copilot", use this manual flow:

```
Topic Name: Production Delay Handler

Flow:
1. Node: Condition - Check if order.status = "In Production" AND days > 30
2. Node: Message - "I notice your order has been in production for [days] days..."
3. Node: Action - CALL create_support_ticket tool
   - Map customerId from order
   - Set subject: "Production Delay - Order [orderId]..."
   - Set priority: "High"
   - Set category: "OrderInquiry"
4. Node: Message - "I've created ticket #[ticket.id]. Production will call within 24 hours..."
```

**💡 Pro Tip:**
Start with the Copilot-generated Topic approach. It's faster, more flexible, and easier to iterate. Only fall back to manual flow building if you need very specific logic that the generated Topic doesn't capture.

**💡 Real Example of What NOT to Do:**

```
❌ BAD Topic Flow:
1. Ask: "Please provide your order number"
2. Wait for response
3. Ask: "How many days has it been in production?"
4. Wait for response
5. Call get_orders
6. Analyze results

This creates 4+ back-and-forth messages for something the agent can do in 1!
```

**✅ GOOD Approach:**

```
User: "Hi, I ordered a home 3 weeks ago and haven't heard anything. Order number FAB-2025-047."

Agent: [Immediately calls get_orders with orderId=47, analyzes the response, provides complete answer]

No unnecessary questions - the agent already has the order number!
```

**💡 Pro Tip for Workshop Participants:**

Start WITHOUT custom Topics. Let the system prompt do the work. Only add Topics if you find specific scenarios that need more control. You'll likely discover that a good system prompt + MCP tools is more powerful than elaborate Topic flows!

**If you DO create Topics, test them with:**
- "My order is FAB-2025-047, where is it?" ← Agent should NOT ask for order number again
- "Tell me about order 42" ← Agent should immediately look it up
- "I'm frustrated about order 15" ← Agent should show empathy AND look up order

If your agent asks for information the user already provided, your Topic is too restrictive!

---

## 💬 **Example Conversations**

### **Scenario 1: Order Status Inquiry with Delay Detection (Basic - 30 points)**

**Customer Input:**
> "Hi, I ordered a home 3 weeks ago and haven't heard anything. Order number FAB-2025-047."

**Agent Response:**
```
Thank you for reaching out, and I apologize that you haven't heard from us in 3 weeks - let me check on order FAB-2025-047 for you right away.

[Tool Call: get_orders with orderId=47]

I found your order for a Cozy Cottage 1200. Let me review the timeline:

📦 Order Details:
- Order Number: FAB-2025-047  
- Product: Cozy Cottage 1200 (1,200 sq ft modular home)
- Order Date: September 10, 2025
- Current Status: **In Production**
- Total: $141,050.00

⚠️ **Timeline Analysis:**
- Production started: 50 days ago (August 12, 2025)
- Standard production time: 30 days
- **This order is 20 days beyond our normal timeline**

I apologize for this delay - this is not typical for Fabrikam. I'm creating a high-priority support ticket right now to have our production team investigate and provide you with an updated completion date.

[Tool Call: create_support_ticket with:
- customerId: 12 (from order.customerId)
- orderId: 47
- subject: "Production Delay - Order FAB-2025-047 at 50 days (20 days overdue)"
- description: "Order placed 9/10/25, in production for 50 days vs 30-day standard. Customer hasn't received updates. Requires immediate production status review and updated delivery timeline."
- priority: "High"
- category: "OrderInquiry"
]

✅ Support Ticket #TKT-2025-089 Created

**What Happens Next:**
1. **Within 24 hours**: Production manager will contact you with specific status update
2. **Investigation**: They'll determine cause of delay and new completion date
3. **Updates**: You'll receive weekly progress updates until delivery
4. **Compensation**: If delay impacts your schedule, we'll discuss options

**Your Ticket Information:**
- Ticket #: TKT-2025-089
- Priority: High
- Category: Order Inquiry (Production Delay)
- Expected First Contact: Within 24 hours

Again, I sincerely apologize for the delay and lack of communication. We're addressing this immediately. Is there anything else I can help you with while we investigate?
```

**Why This Works:**
- ✅ Immediately acknowledges the customer's concern about no communication
- ✅ Uses the get_orders tool correctly
- ✅ **ANALYZES the data** - notices 50 days vs 30-day standard
- ✅ **PROACTIVELY creates support ticket** without being asked
- ✅ Takes ownership - "I apologize" not "system shows"
- ✅ Sets clear expectations with timeline
- ✅ Offers follow-up assistance
- ✅ Shows business awareness (compensation mention)

**What NOT to Do** (Original Bad Response):
❌ "Production started 50 days ago and typically takes 30 days, so it should be completed soon"
❌ Ignoring the obvious delay
❌ Only offering to create a ticket instead of doing it automatically
❌ Not apologizing for lack of communication

---

### **Scenario 2: Product Comparison (Good - 60 points)**

**Customer Input:**
> "I'm trying to decide between the Family Haven 1800 and the Executive Manor 2500. Which one is better?"

**Agent Response:**
```
Great question! Both are excellent homes - let me help you understand the key differences so you can choose the best fit for your needs.

[Tool Call: get_products with category="ModularHomes"]

Here's a detailed comparison:

**Family Haven 1800** ($185,000)
✅ Perfect for: Growing families, first-time buyers
- Size: 1,800 square feet
- Bedrooms: 3 bedrooms
- Bathrooms: 2 full bathrooms
- Features: Standard appliances, hardwood floors, covered porch
- Layout: Open concept living/dining, attached 2-car garage
- Best For: Families of 3-5 people

**Executive Manor 2500** ($285,000)
✅ Perfect for: Luxury buyers, executive homes
- Size: 2,500 square feet
- Bedrooms: 4 bedrooms + office
- Bathrooms: 3 full, 1 half bathroom
- Features: Premium appliances, granite counters, luxury finishes
- Layout: Formal dining, gourmet kitchen, master suite with spa bath
- Best For: Families of 4-7 people, home offices

**Key Differences:**
1. **Space**: 700 sq ft more in the Executive Manor
2. **Price**: $100,000 difference
3. **Finishes**: Executive has premium upgrades throughout
4. **Layout**: Executive includes dedicated office and formal spaces

**Questions to Consider:**
- How many people will live in the home?
- Do you need a home office?
- What's your budget for upgrades and customization?
- Do you prioritize space or finishing quality?

Would you like me to connect you with a sales specialist who can walk you through floor plans and customization options? They can also discuss financing if that's helpful!
```

**Why This Works:**
- ✅ Provides objective comparison
- ✅ Uses data from get_products tool
- ✅ Helps customer make informed decision
- ✅ Asks clarifying questions
- ✅ Offers appropriate escalation to sales
- ✅ Maintains neutral, helpful tone

---

### **Scenario 3: Complex Issue Escalation (Excellent - 100 points)**

**Customer Input:**
> "This is ridiculous! My home was delivered last week with water damage and cracks in the walls. The installation crew said it's not their problem and I should call you. I took off work for this!"

**Agent Response:**
```
I'm truly sorry to hear about the damage to your new home - that must be incredibly frustrating, especially after taking time off work. This is absolutely not the experience we want for our customers, and we're going to get this resolved for you right away.

Let me gather some information to ensure this gets immediate priority attention:

1. Can you provide your order number or the email address on the order?
2. Can you describe the water damage and wall cracks? (Where located, how extensive)
3. Do you have photos you can share? (You can text them to our support line: 555-FABRIKAM)

[After customer provides: Order FAB-2025-042, describes damage to kitchen area and bedroom wall, mentions photos taken]

Thank you for that information. Let me document this and connect you with our quality assurance team immediately.

[Tool Call: create_support_ticket with:
- customerId: 5
- subject: "URGENT: Water damage and wall cracks on delivered Cozy Cottage 1200 - Order FAB-2025-042"
- description: "Customer reports water damage in kitchen area and cracks in bedroom wall upon delivery on 10/22/25. Installation crew did not take responsibility. Customer has photos. Requires immediate quality inspection and resolution."
- priority: "Critical"
- category: "ProductDefect"
]

✅ I've created Priority Ticket #TKT-2025-036 for your case.

Here's what's happening next:

**Immediate Actions (Next 2 Hours):**
- Sarah Martinez, our Quality Assurance Manager, will call you at [customer phone]
- She'll schedule an emergency inspection for tomorrow or sooner
- We'll review your photos and order documentation

**Resolution Process:**
- Full assessment of damage by our engineering team
- Repair or replacement determination within 24 hours
- Expedited parts/materials if repairs needed
- No cost to you - this is covered under our delivery guarantee

**Your Ticket Information:**
- Ticket #: TKT-2025-036
- Priority: Critical
- Assigned To: Sarah Martinez (Quality Assurance Manager)
- Expected First Contact: Within 2 hours

I've also flagged this for our regional manager to review. Is there anything else I should document in your case before Sarah contacts you?

And please know - you should absolutely not have been told "it's not our problem." We take full responsibility for the condition of our homes upon delivery, and we're committed to making this right.
```

**Why This Achieves 100 Points:**
- ✅ **Empathy**: Acknowledges frustration and validates concerns
- ✅ **Immediate Action**: Creates ticket without delay
- ✅ **Comprehensive Information**: Gathers all necessary details
- ✅ **Clear Process**: Explains exactly what happens next
- ✅ **Accountability**: Takes ownership, doesn't deflect
- ✅ **Specific Timeline**: Commits to 2-hour response
- ✅ **Proactive**: Flags for management review
- ✅ **Follow-up**: Asks if anything else needed
- ✅ **Reassurance**: Confirms coverage under guarantee
- ✅ **Professional**: Maintains composure under pressure

---

## 🔧 **Troubleshooting Common Issues**

### **Issue: Agent Says "I will create a ticket" but Never Does**

**Symptom**: Agent recognizes the delay and says it will create a support ticket, but the `create_support_ticket` tool never gets called.

**Root Cause**: Copilot Studio's conversational AI understands the *intent* from the system prompt but doesn't automatically execute the tool. It needs explicit triggering.

**Solutions** (try in order):

**Solution 1: Add Explicit Tool Call Instruction in System Prompt**
```
When you detect a production delay (>30 days):
- First, apologize and acknowledge the delay
- Second, USE THE create_support_ticket TOOL (you must actually call it!)
- Third, tell the customer the ticket number you received
- Do not say "I will create" - say "I've created ticket #XXX"
```

**Solution 2: Create a Delay Detection Topic**
Create a Topic that explicitly calls the tool:
- Name: "Production Delay Auto-Escalation"
- Trigger: After calling `get_orders`, if production days > 30
- Action Nodes:
  1. Variable: Set delayDays = (current date - production start)
  2. Condition: If delayDays > 30, go to step 3
  3. **Call Action**: create_support_ticket with mapped parameters
  4. Message: "I've created ticket #{ticket.id}..."

**Solution 3: Use Generative Actions (Advanced)**
If available in your Copilot Studio version, enable "Generative Actions" which can automatically call tools based on conversation context.

**Solution 4: Two-Step Flow**
If automatic doesn't work, make it explicit:
- Agent: "I see this is delayed. Would you like me to create a support ticket?"
- User: "Yes"
- Agent: [Calls create_support_ticket]

**Test Your Fix**:
After implementing, test with: "My order FAB-2025-047 hasn't shipped"
- ✅ SUCCESS: Agent responds with actual ticket number (TKT-XXXX)
- ❌ FAIL: Agent says "I'm creating..." but no ticket number appears

---

## 🔧 **Technical Implementation Details**

### **Tool Usage Patterns**

**Pattern 1: Order Lookup with Timeline Analysis**
```
Customer mentions order → Extract order number/email → Call get_orders → ANALYZE timeline

Step 1: Get the data
- If order number: get_orders(orderId=X)
- If email: get_orders(pageSize=10) then filter by customer
- Always check for null/empty results

Step 2: ANALYZE the data (CRITICAL!)
- Check orderDate vs current date
- Calculate days in current status
- Compare to standard timelines:
  * Production: 30 days standard
  * Shipping: 5-7 days standard
  * Installation: Coordinated with customer
- Detect anomalies: status duration > expected

Step 3: Respond appropriately
- If delayed: Apologize + Create ticket + Explain resolution
- If on-time: Confirm status + Explain next steps
- Always set clear expectations
```

**Pattern 2: Product Information**
```
Customer asks about products → Determine if specific or comparison
- Specific: get_products(productId=X)
- Category: get_products(category="ModularHomes")
- Comparison: get_products() then compare specific items
- Always provide context for decision-making
- Ask clarifying questions to guide the customer
```

**Pattern 3: Support Ticket Creation (Manual)**
```
Complex issue detected → Gather information → Create ticket
- Priority: Critical (damage/safety), High (urgent), Medium (standard)
- Category: Use EXACT values from valid list:
  * OrderInquiry - Order status, timelines, tracking questions
  * DeliveryIssue - Shipping problems, delays, logistics
  * ProductDefect - Damage, quality issues, defects
  * Installation - Installation scheduling, crew issues
  * Billing - Payment issues, invoicing, refunds
  * Technical - Technical support, system issues
  * General - General inquiries and questions
  * Complaint - Customer complaints, escalations
- Include: Order number, clear description, customer contact info
- Set expectations: Who will contact, when, what process
- Follow up: Confirm ticket number and next steps
```

**Pattern 4: Automatic Escalation (CRITICAL!)**
```
Order delay detected → IMMEDIATELY call create_support_ticket tool → THEN explain to customer

Trigger: Days in status > expected timeline
Example: Production status for >30 days

REQUIRED SEQUENCE:
1. Call get_orders to retrieve order data
2. Detect the problem (analyze dates vs 30-day standard)
3. Extract customerId from the order response (order.customerId or order.customer.id)
4. CALL create_support_ticket tool with:
   - customerId: from order data (REQUIRED!)
   - orderId: from order data
   - subject, description, priority, category
5. Get the ticket number from the response
6. Tell customer what you DID (not what you will do)
7. Provide ticket number
8. Set 24-hour callback expectation

CORRECT: "I've created support ticket #TKT-2025-089..."
WRONG: "I'm creating a ticket..." (then never actually calling the tool)

DO NOT just say you're creating a ticket - ACTUALLY CALL THE TOOL!
The customer needs to see a real ticket number to trust that action was taken.

CRITICAL: Always include customerId in the tool call - extract it from the order data first!
```

### **Error Handling Examples**

**Order Not Found:**
```
"I apologize, but I'm not finding order number FAB-2025-999 in our system. Let me help you locate it:

1. Can you double-check the order number? It should be in format FAB-YYYY-XXX
2. What email address was used when placing the order?
3. Do you have the order confirmation email you could reference?

I can also search by your email address or phone number if that's easier!"
```

**Product Out of Stock:**
```
"The Cozy Cottage 1200 is currently showing as backordered with an estimated 6-8 week lead time. However, I have some good options for you:

1. **Reserve Now**: Lock in current pricing, delivery in 8 weeks
2. **Similar Models**: The Urban Studio 1100 is in stock (available info)
3. **Custom Build**: Start a custom design (4-6 month timeline)

Would you like me to connect you with our sales team to discuss these options?"
```

---

## 📊 **Scoring Breakdown**

### **How This Example Achieves 100 Points**

**Basic Success (30 points):**
- ✅ Order lookup by order number (Scenario 1)
- ✅ Product information provision (Scenario 2)
- ✅ Clear escalation path (Scenario 3)

**Good Success (60 points):**
- ✅ Natural conversation flow across all scenarios
- ✅ Multiple conversation turns handled effectively
- ✅ Clear error handling demonstrated
- ✅ Professional and empathetic tone throughout

**Excellent Success (100 points):**
- ✅ Proactive assistance (offering sales connection, management escalation)
- ✅ Anticipates customer needs (provides comparison questions, next steps)
- ✅ Seamless business integration (proper ticket creation, priority assignment)
- ✅ Demonstrates deep business context (delivery guarantee, warranty coverage)

### **Bonus Features Implemented**
- 🌟 Proactive notification of order timeline
- 🌟 Automatic priority ticket assignment
- 🌟 Multi-channel support reference (text photos)
- 🌟 Clear escalation to named specialists

---

## 🎓 **Learning Points for Facilitators**

### **Key Success Factors**
1. **Tool Integration**: Agent uses MCP tools effectively, not just for show
2. **Business Context**: Demonstrates understanding of Fabrikam's business model
3. **Empathy**: Responds to emotional state, not just transactional requests
4. **Completeness**: Provides all necessary information without requiring follow-up
5. **Professionalism**: Maintains composure even with difficult customers

### **Common Mistakes to Avoid**
- ❌ Using tools but ignoring the returned data
- ❌ Providing generic responses instead of specific order details
- ❌ Failing to set clear expectations for next steps
- ❌ Not acknowledging customer emotions in difficult situations
- ❌ Promising what the business can't deliver
- ❌ **NEW**: Repeating system data without analysis ("Production started 50 days ago, typically takes 30 days, should be done soon" - WRONG!)
- ❌ **NEW**: Not creating tickets for obvious problems (delays, issues)
- ❌ **NEW**: Saying "it's not our problem" or deflecting responsibility
- ❌ **NEW**: Ignoring timeline inconsistencies in the data
- ❌ **NEW**: Treating all orders the same regardless of status duration
- ❌ **CRITICAL**: Saying "I'm creating a ticket" but NOT actually calling create_support_ticket tool - customers need real ticket numbers!

### **Pro Tips for Excellence**
- ✅ Always calculate timelines - don't just repeat what the system says
- ✅ Be proactive - create tickets before customer gets frustrated
- ✅ Show empathy - acknowledge emotions, especially when things go wrong
- ✅ Take ownership - "I apologize" not "the system shows" or "they said"
- ✅ Set specific expectations - "within 24 hours" not "soon"
- ✅ Provide context - help customers understand the process
- ✅ Follow through - confirm tickets, provide ticket numbers, explain next steps

### **Extension Opportunities**
For participants who finish early:
- Add multi-language support
- Implement warranty lookup and claims
- Create proactive order update notifications
- Build customer satisfaction surveys
- Add installation scheduling assistance

---

## 📝 **Testing Checklist**

Use these test cases to verify the agent works correctly:

**Basic Functionality:**
- [ ] Look up order FAB-2025-047 successfully
- [ ] Handle "order not found" for FAB-2025-999
- [ ] Compare two products from catalog
- [ ] Create support ticket for quality issue
- [ ] Handle rude/angry customer professionally

**Edge Cases:**
- [ ] Customer provides email instead of order number
- [ ] Customer misspells order number
- [ ] Customer asks about discontinued product
- [ ] Multiple orders for same customer
- [ ] Order with unusual status

**Conversation Flow:**
- [ ] Multi-turn conversation about single order
- [ ] Switching between order lookup and product questions
- [ ] Handling interruptions and topic changes
- [ ] Graceful closure with follow-up offer

---

## 🚀 **Setup Notes**

**For Workshop Facilitators:**
1. Pre-deploy the Fabrikam environment (API + MCP) to Azure
2. Create a shared MCP connection in Copilot Studio under **Tools**
3. Document the team-specific MCP URL for those creating custom connections
4. Test all scenarios before workshop begins
5. Verify all MCP tools are functioning correctly
6. Prepare fallback examples if MCP connection fails

**For Participants:**
- The Fabrikam environment is already deployed and ready to use
- You'll find a pre-configured MCP connection under **Tools** in Copilot Studio
- Add the connection to your agent to get started quickly
- Advanced users: Feel free to create your own connection to explore MCP architecture
- Your team's MCP URL will be provided by facilitators if you need it

**For Participants:**
- This is a reference implementation - feel free to improve upon it!
- Your agent personality can be different while still scoring 100 points
- Focus on tool integration and business understanding over exact wording
- Ask proctors for help if stuck - that's what they're here for!

---

**Remember**: This example shows one way to achieve success, but there are many valid approaches. The key is demonstrating understanding of both the technology (Copilot Studio, MCP) and the business (Fabrikam customer service needs). Good luck! 🎯
