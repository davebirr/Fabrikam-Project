# 🟢 Beginner Challenge: Customer Service Foundation

**Build Your First AI Agent** | 90 minutes | Guided Experience

---

## 🎯 Challenge Overview

Welcome to your first AI agent! You'll build **FabrikamCS**, a customer service agent for Fabrikam Modular Homes that helps customers with order inquiries, product information, and support issues.

**What Makes This Different**: Most chatbots just answer questions. Your agent will **take action**—looking up real orders, analyzing timelines, and creating support tickets automatically.

---

## 📖 The Story

**You are**: An AI engineer at Fabrikam Modular Homes

**The Problem**: Customer service is overwhelmed with:
- "Where is my order?"
- "Which home model should I buy?"
- "My home arrived damaged—help!"

**Your Mission**: Build an AI agent that handles tier-1 support professionally, escalating complex issues to human agents with all the context they need.

---

## 📚 What You Need to Know

### **Understanding MCP (Model Context Protocol)**

Your agent will use **MCP tools** to connect to Fabrikam's business systems. Think of MCP as giving your AI agent "superpowers" to take real actions:

**Without MCP**: Your agent can only chat (like asking a librarian who can only talk)  
**With MCP**: Your agent can DO things (like a librarian who can also check inventory, reserve books, and notify you when books arrive)

**In This Challenge**, your agent uses 4 MCP tools:
- 🔍 `get_orders` - Look up order status and details
- 📦 `get_products` - Retrieve product information
- 👤 `get_customers` - Find customer details
- 🎫 `create_support_ticket` - Create support tickets

**The key insight**: When your agent detects a problem (like a delayed order), it doesn't just tell you about it—it TAKES ACTION by creating a support ticket automatically!

💡 **Want to learn more about MCP?** See our <a href="../../../ws-coe-aug27/README.md#-understanding-mcp-model-context-protocol" target="_blank">MCP Primer</a> for the full story of why this protocol is revolutionizing AI integration.

---

## 🚀 Getting Started

### **Step 1: Access Your Tools**
1. Open **[Microsoft Copilot Studio](https://copilotstudio.microsoft.com)**
2. Create a new agent (name it under 30 characters!)
3. Connect to the **Fabrikam MCP Server**:
   - In Copilot Studio, go to **Tools**
   - Look for existing **Fabrikam MCP Connection**
   - Add it to your agent

**⚠️ Important First-Time Setup:**
The first time you test your agent and try to use the MCP tools, **it will NOT work immediately**. This is normal! You'll be prompted to open the **Connection Manager** and create a connection. Simply follow the prompts to authenticate and establish the connection. After that, your agent will work perfectly.

### **Step 2: Configure Your Agent**

#### **1. Set the Instructions (System Prompt)**

The system prompt is how you teach your agent its role, capabilities, and behavior. Here's a **starter template** to get you going:

```
You are a helpful customer service agent for Fabrikam, a manufacturer of modular homes.

Your role is to assist customers with:
- Order status inquiries
- Product information
- Support ticket creation for complex issues

PERSONALITY:
- Be warm, professional, and empathetic
- Use clear, simple language
- Provide specific information
- Take ownership of problems

CAPABILITIES:
You have access to these tools:
- get_orders - Look up order information
- get_products - Retrieve product details
- get_customers - Find customer information
- create_support_ticket - Create support tickets

CONVERSATION FLOW:
1. Greet the customer warmly
2. Understand what they need
3. Use your tools to get accurate information
4. Provide a complete, helpful answer
5. Offer additional assistance

When you don't know something, admit it honestly and offer to escalate to a human agent.
```

**⚠️ Important**: This starter prompt will get you started, but **won't achieve 100 points**! You'll need to add:
- Business rules (production timelines, ticket categories)
- Delay detection logic (the hardest part!)
- Error handling guidance
- Specific instructions for when to create tickets

💡 **Tip**: Start with this, test with Scenario 1 (simple order lookup), then incrementally add more as you tackle harder scenarios!

**🎯 What Makes a Great System Prompt?**
As you refine your starter prompt, consider adding:

| Element | Why It Matters | Example |
|---------|----------------|---------|
| **Business Rules** | Agent needs to know the standards | "Standard production: 30 days" |
| **When to Act** | Don't just talk, do! | "IMMEDIATELY call create_support_ticket when..." |
| **Error Handling** | What to do when things fail | "If order not found, ask for email instead" |
| **Tone Guidance** | How to handle emotions | "Show empathy for frustrated customers" |
| **Specific Values** | Exact categories and priorities | "Use 'OrderInquiry' for delay tickets" |

Check the [hints](./hints.md) for examples of each without spoiling the full solution!

#### **2. Enable MCP Tools**

**What are MCP Tools?** MCP (Model Context Protocol) is like a **USB-C port for AI applications** - it provides a standardized way for AI agents to connect to business systems and data sources. Instead of custom integrations, MCP gives your agent pre-built "tools" it can use to take actions.

**In Copilot Studio**, these tools appear under **Tools** (not Knowledge Sources). Think of them as capabilities you're giving your agent:
- `get_orders` - Lets your agent look up order information from Fabrikam's database
- `get_products` - Provides access to the product catalog
- `get_customers` - Retrieves customer details
- `create_support_ticket` - Allows your agent to create tickets in the support system

**Enable these tools** for your agent:
- `get_orders` ✅
- `get_products` ✅
- `get_customers` ✅
- `create_support_ticket` ✅

💡 **New to MCP?** Learn more about the Model Context Protocol and why it matters: [MCP Primer](../../../ws-coe-aug27/README.md#-understanding-mcp-model-context-protocol)

### **Step 3: Test & Iterate (This is where the magic happens!)**

**🔄 Critical Mindset: Building agents is ITERATIVE!**

You won't get it perfect on the first try - nobody does! Great agents emerge through cycles of testing and refinement.

**The Winning Process:**
1. **Start with Scenario 1** (simple order lookup) - Test basic functionality
2. **Test in Copilot Studio's test pane** - See what happens
3. **Analyze what went wrong** - Did it call the tool? Use the results? Sound natural?
4. **Refine your system prompt** - Add clarity, examples, or business rules
5. **Test the same scenario again** - Did it improve?
6. **Move to harder scenarios** - Test Scenario 2, then 3, then 4
7. **Keep refining** - Each test reveals something new to improve!

**🤖 Pro Tip: Use AI to Build Your AI!**

Don't write system prompts from scratch - you have powerful assistants:

- **M365 Copilot Prompt Coach**: Paste your system prompt and ask:
  - "Review this agent prompt for clarity and completeness"
  - "How can I improve this to handle delayed orders better?"
  - Get expert feedback instantly!

- **GitHub Copilot Chat**: Ask for help:
  - "Write a system prompt for a customer service agent that detects 30-day delays"
  - "How should I structure business rules in an agent prompt?"
  - Copy a failed conversation and ask "What went wrong? How do I fix it?"

- **Copilot in Your Browser**: Research and iterate:
  - "What makes a good customer service agent empathetic?"
  - "Example system prompts for e-commerce support"

**Example Evolution Through Testing:**
```
Test 1: "You are a customer service agent"
→ Agent doesn't use tools ❌

Test 2: "Use get_orders when customers ask about orders"
→ Agent calls tool but just repeats raw data ❌

Test 3: "Use get_orders and ANALYZE the results. If delivery is late, explain why."
→ Agent analyzes but doesn't create tickets ❌

Test 4: "If delivery is over 30 days late, IMMEDIATELY create a support ticket."
→ Now it works! ✅
```

**Remember**: Every test teaches you something. Embrace the iteration!

**📈 Suggested Progression**:
```
1. Start with Test Scenario 1 (order lookup)
2. If it works: Add product comparison
   If it doesn't work: Check hints.md for MCP issues
3. Add error handling (Scenario 5)
4. Add delay detection (HARD!)
5. Test Scenario 2 & refine
6. Add empathy (Scenario 4)
7. Test all 5 scenarios
8. Achieve 60-100 points! 🎉
```

💡 **Key Insight**: Each scenario builds on the previous one. Don't try to solve everything at once!

---

## ✅ Success Criteria

### **Basic Success (30 points)**
Your agent can:
- ✅ Look up orders by order number
- ✅ Provide product information
- ✅ Create support tickets for complex issues
- ✅ Respond professionally and politely

### **Good Success (60 points)**
Everything above, plus:
- ✅ Natural, multi-turn conversations
- ✅ Graceful error handling
- ✅ Context awareness across conversation
- ✅ Empathetic tone with frustrated customers

### **Excellent Success (100 points)**
Everything above, plus:
- ✅ **Proactive problem detection** (notices delayed orders without being asked)
- ✅ **Automatic escalation** (creates tickets for problems it detects)
- ✅ **Business context awareness** (understands timelines, policies, processes)
- ✅ **Anticipates customer needs** (offers next steps, related information)

### **Bonus Features (up to 20 points)**
- 🌟 Proactive order status notifications
- 🌟 Product comparison recommendations
- 🌟 Multi-channel support references (email, phone, text)
- 🌟 Warranty and policy lookups
- 🌟 Your creative additions!

---

## 🛠️ What You'll Build

### **Core Capabilities**

1. **Order Status Inquiries**
   - Accept order number or customer email
   - Retrieve current order status
   - **Analyze timeline** (not just repeat system data!)
   - Detect delays and problems
   - Create tickets for delays automatically

2. **Product Information**
   - Provide details about home models
   - Compare products side-by-side
   - Help customers make informed decisions
   - Guide to sales team when appropriate

3. **Support Ticket Creation**
   - Gather necessary information
   - Create tickets with proper priority/category
   - Set clear expectations for resolution
   - Provide ticket numbers for tracking

### **Key Business Rules**

**Production Timelines**:
- Standard production: **30 days**
- If order is in production more than 30 days, then it is **DELAYED** (create ticket!)
- Standard shipping: **5-7 days**

**Ticket Categories** (use exact values):
- `OrderInquiry` - Order status, timelines, tracking
- `DeliveryIssue` - Shipping problems, delays
- `ProductDefect` - Damage, quality issues
- `Installation` - Installation scheduling, crew issues
- `Billing` - Payment issues, refunds
- `Technical` - Technical support
- `General` - General inquiries
- `Complaint` - Customer complaints

**Ticket Priorities**:
- `Critical` - Safety, structural damage
- `High` - Urgent issues, delays, customer frustration
- `Medium` - Standard issues
- `Low` - General questions

---

## 🧪 Test Scenarios

Use these to validate your agent:

### **Scenario 1: Standard Order Inquiry**
```
Customer: "Hi, what's the status of order FAB-2025-015?"

Expected Behavior:
✅ Look up order using get_orders tool
✅ Provide order details (product, date, status)
✅ Explain current status and next steps
✅ Offer additional assistance
```

### **Scenario 2: Delayed Order Detection** (CRITICAL!)
```
Customer: "I ordered a home 7 weeks ago. When will it be done?"

Expected Behavior:
✅ Look up order
✅ ANALYZE timeline (7 weeks = 49 days > 30 day standard)
✅ RECOGNIZE this is delayed
✅ APOLOGIZE for the delay
✅ AUTOMATICALLY create support ticket (don't just say you will!)
✅ Provide ticket number
✅ Set 24-hour callback expectation
```

### **Scenario 3: Product Comparison**
```
Customer: "Should I get the Family Haven 1800 or Executive Manor 2500?"

Expected Behavior:
✅ Use get_products tool
✅ Provide side-by-side comparison
✅ Ask clarifying questions (budget, family size, needs)
✅ Offer to connect with sales specialist
✅ Remain neutral (help decide, don't push)
```

### **Scenario 4: Angry Customer with Damage**
```
Customer: "This is ridiculous! My home was delivered with water damage!"

Expected Behavior:
✅ Acknowledge frustration with empathy
✅ Gather information (order number, damage description)
✅ Create CRITICAL priority ticket
✅ Set immediate action expectations (2-hour callback)
✅ Take ownership (not "system says" or "they said")
✅ Provide ticket number and next steps
```

### **Scenario 5: Order Not Found**
```
Customer: "Where is order FAB-2025-999?"

Expected Behavior:
✅ Attempt lookup
✅ Handle gracefully when not found
✅ Ask for alternative information (email, phone)
✅ Offer to search by customer details
✅ Provide clear next steps
```

---

## 🚀 Getting Started

### **Step 1: Access Your Tools**
1. Open **Microsoft Copilot Studio**
2. Create a new agent (name it under 30 characters!)
3. Connect to the **Fabrikam MCP Server**:
   - In Copilot Studio, go to **Tools**
   - Look for existing **Fabrikam MCP Connection**
   - Add it to your agent

### **Step 2: Configure Your Agent**

#### **1. Set the Instructions (System Prompt)**

The system prompt is how you teach your agent its role, capabilities, and behavior. Here's a **starter template** to get you going:

```
You are a helpful customer service agent for Fabrikam, a manufacturer of modular homes.

Your role is to assist customers with:
- Order status inquiries
- Product information
- Support ticket creation for complex issues

PERSONALITY:
- Be warm, professional, and empathetic
- Use clear, simple language
- Provide specific information
- Take ownership of problems

CAPABILITIES:
You have access to these tools:
- get_orders - Look up order information
- get_products - Retrieve product details
- get_customers - Find customer information
- create_support_ticket - Create support tickets

CONVERSATION FLOW:
1. Greet the customer warmly
2. Understand what they need
3. Use your tools to get accurate information
4. Provide a complete, helpful answer
5. Offer additional assistance

When you don't know something, admit it honestly and offer to escalate to a human agent.
```

**⚠️ Important**: This starter prompt will get you started, but **won't achieve 100 points**! You'll need to add:
- Business rules (production timelines, ticket categories)
- Delay detection logic (the hardest part!)
- Error handling guidance
- Specific instructions for when to create tickets

💡 **Tip**: Start with this, test with Scenario 1 (simple order lookup), then incrementally add more as you tackle harder scenarios!

**🎯 What Makes a Great System Prompt?**
As you refine your starter prompt, consider adding:

| Element | Why It Matters | Example |
|---------|----------------|---------|
| **Business Rules** | Agent needs to know the standards | "Standard production: 30 days" |
| **When to Act** | Don't just talk, do! | "IMMEDIATELY call create_support_ticket when..." |
| **Error Handling** | What to do when things fail | "If order not found, ask for email instead" |
| **Tone Guidance** | How to handle emotions | "Show empathy for frustrated customers" |
| **Specific Values** | Exact categories and priorities | "Use 'OrderInquiry' for delay tickets" |

Check the [hints](./hints.md) for examples of each without spoiling the full solution!

#### **2. Enable MCP Tools**

**What are MCP Tools?** MCP (Model Context Protocol) is like a **USB-C port for AI applications** - it provides a standardized way for AI agents to connect to business systems and data sources. Instead of custom integrations, MCP gives your agent pre-built "tools" it can use to take actions.

**In Copilot Studio**, these tools appear under **Tools** (not Knowledge Sources). Think of them as capabilities you're giving your agent:
- `get_orders` - Lets your agent look up order information from Fabrikam's database
- `get_products` - Provides access to the product catalog
- `get_customers` - Retrieves customer details
- `create_support_ticket` - Allows your agent to create tickets in the support system

**Enable these tools** for your agent:
- `get_orders` ✅
- `get_products` ✅
- `get_customers` ✅
- `create_support_ticket` ✅

💡 **New to MCP?** Learn more about the Model Context Protocol and why it matters: [MCP Primer](../../../ws-coe-aug27/README.md#-understanding-mcp-model-context-protocol)

### **Step 3: Test & Iterate (This is where the magic happens!)**

**🔄 Critical Mindset: Building agents is ITERATIVE!**

You won't get it perfect on the first try - nobody does! Great agents emerge through cycles of testing and refinement.

**The Winning Process:**
1. **Start with Scenario 1** (simple order lookup) - Test basic functionality
2. **Test in Copilot Studio's test pane** - See what happens
3. **Analyze what went wrong** - Did it call the tool? Use the results? Sound natural?
4. **Refine your system prompt** - Add clarity, examples, or business rules
5. **Test the same scenario again** - Did it improve?
6. **Move to harder scenarios** - Test Scenario 2, then 3, then 4
7. **Keep refining** - Each test reveals something new to improve!

**🤖 Pro Tip: Use AI to Build Your AI!**

Don't write system prompts from scratch - you have powerful assistants:

- **M365 Copilot Prompt Coach**: Paste your system prompt and ask:
  - "Review this agent prompt for clarity and completeness"
  - "How can I improve this to handle delayed orders better?"
  - Get expert feedback instantly!

- **GitHub Copilot Chat**: Ask for help:
  - "Write a system prompt for a customer service agent that detects 30-day delays"
  - "How should I structure business rules in an agent prompt?"
  - Copy a failed conversation and ask "What went wrong? How do I fix it?"

- **Copilot in Your Browser**: Research and iterate:
  - "What makes a good customer service agent empathetic?"
  - "Example system prompts for e-commerce support"

**Example Evolution Through Testing:**
```
Test 1: "You are a customer service agent"
→ Agent doesn't use tools ❌

Test 2: "Use get_orders when customers ask about orders"
→ Agent calls tool but just repeats raw data ❌

Test 3: "Use get_orders and ANALYZE the results. If delivery is late, explain why."
→ Agent analyzes but doesn't create tickets ❌

Test 4: "If delivery is over 30 days late, IMMEDIATELY create a support ticket."
→ Now it works! ✅
```

**Remember**: Every test teaches you something. Embrace the iteration!
3. Refine your instructions
4. Progress through scenarios
5. Tackle the delayed order detection (hardest part!)

**📈 Suggested Progression**:
```
1. Start with Test Scenario 1 (order lookup)
2. If it works: Add product comparison
   If it doesn't work: Check hints.md for MCP issues
3. Add error handling (Scenario 5)
4. Add delay detection (HARD!)
5. Test Scenario 2 & refine
6. Add empathy (Scenario 4)
7. Test all 5 scenarios
8. Achieve 60-100 points! 🎉
```

💡 **Key Insight**: Each scenario builds on the previous one. Don't try to solve everything at once!

---

## 💡 Hints & Tips

**Available Without Spoilers!** [View Hints](./hints.md)

Common pitfalls and guidance to help you succeed without giving away the solution.

---

## 💬 Conversation Examples

**See What Great Looks Like!** [View Conversation Examples](./conversation-examples.md)

Realistic conversations using actual Fabrikam data showing exactly how an excellent agent responds. Learn the patterns without spoiling the solution!

---

## ⚠️ Partial Solution

**Architecture & Approach** [View Partial Solution](./partial-solution.md)

Stuck on how to structure your agent? This shows the overall approach without the complete implementation.

---

## 🚨 SPOILER ALERT - Full Solution

**Complete Working Implementation** [View Full Solution](./full-solution.md)

⚠️ **Warning**: This contains the complete, tested solution that achieves 100 points. It includes:
- Full system prompt with delay detection logic
- Complete MCP tool configuration
- All 4 example conversations with annotations
- Troubleshooting for common beginner issues

**Try the hints and partial solution first!** You'll learn more by struggling a bit before seeing the answer.

---

## 🆘 Common Issues & Troubleshooting

### **"Agent says it will create a ticket but never does"**
The agent understands the intent but isn't calling the tool. See the [hints page](./hints.md#ticket-creation-issues) for solutions.

### **"MCP tools not working"**
Check the connection configuration and authentication. See [MCP troubleshooting guide](../../resources/troubleshooting.md).

### **"Agent responses are too robotic"**
Focus on the personality section of your instructions. Use empathetic language patterns.

### **"Not detecting delays correctly"**
The agent needs explicit instruction to ANALYZE dates, not just repeat them. Check the [partial solution](./partial-solution.md).

---

## 🎓 What You'll Learn

By completing this challenge, you'll master:
- ✅ **Copilot Studio fundamentals** - Agent creation, configuration
- ✅ **System prompt engineering** - Writing effective instructions
- ✅ **MCP tool integration** - Connecting external systems
- ✅ **Conversation design** - Natural, empathetic interactions
- ✅ **Error handling** - Graceful failures and edge cases
- ✅ **Business logic** - Implementing rules and policies in AI

---

## ⏭️ Next Steps

Once you've completed this challenge:
1. **Test thoroughly** with all scenarios
2. **Get proctor validation** for your score
3. **Share insights** with your table
4. **Move to Intermediate** when ready!

**Next:** [**Proceed to Intermediate Challenge**](../02-intermediate/README.md)

---

**Good luck! Remember: The goal is learning, not perfection. Ask for help anytime!** 🚀
