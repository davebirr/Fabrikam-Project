# 💡 Beginner Challenge - Hints & Tips

**Guidance without spoilers!** Use these hints when you're stuck, but try solving problems yourself first.

---

## 🎯 General Approach

### **Start Simple, Then Build**

Don't try to build the perfect agent all at once! Follow this progression:

1. **Phase 1**: Get ONE tool working (try `get_orders`)
2. **Phase 2**: Add natural language and error handling
3. **Phase 3**: Add more tools (`get_products`, `get_customers`)
4. **Phase 4**: Tackle the hardest part (automatic delay detection and ticket creation)

### **Test Frequently**

After EVERY change:
- Test in Copilot Studio's test pane
- Try one of the test scenarios
- Refine your instructions
- Test again

---

## 🛠️ MCP Connection Issues

### **Problem**: "Tools not showing up"

**Checklist**:
- [ ] Did you add the Fabrikam MCP Connection under **Tools**?
- [ ] Did you enable the specific tools you want to use?
- [ ] Did you save the agent configuration?
- [ ] Try refreshing the browser

### **Problem**: "Tool calls failing"

**Possible causes**:
- MCP server might be starting up (wait 30 seconds)
- Check the MCP URL is correct
- Verify you're using the right team's server
- Ask your proctor to verify server status

---

## 📝 instructions (Instructions) Tips

### **What Makes a Good instructions?**

Think of it as **training instructions for a new employee**:

✅ **DO Include**:
- Who the agent is (role and company)
- What capabilities they have (list the tools!)
- How to use each tool (when and why)
- Personality guidelines (warm, professional, empathetic)
- Business rules (timelines, policies, escalation criteria)
- Examples of good behavior

❌ **DON'T**:
- Make it too short ("You're a customer service agent" won't work!)
- Forget to mention the tools by name
- Use vague language ("be helpful" - be specific HOW!)
- Assume the agent knows your business context

### **Structure Template**

```markdown
You are [ROLE] for [COMPANY]

Your responsibilities:
1. [Capability 1] - [When to use tool X]
2. [Capability 2] - [When to use tool Y]
3. [Capability 3] - [When to use tool Z]

PERSONALITY:
- [Tone guideline 1]
- [Tone guideline 2]

TOOLS YOU HAVE:
- tool_name: [Description and when to use]

BUSINESS RULES:
- [Critical rule 1 with specific numbers]
- [Critical rule 2]

CRITICAL BEHAVIORS:
- [What to do in situation X]
- [What to do in situation Y]
```

---

## 🔍 Order Lookup Issues

### **Problem**: "Agent doesn't use get_orders tool"

**Hint**: The agent needs to know:
1. The tool exists (mention it by name in instructions!)
2. When to use it (customer asks about order status)
3. What parameters it needs (orderId or customerId)

**Try adding to your instructions**:
```
When a customer provides an order number like FAB-2025-047:
1. Extract the number after "FAB-2025-" (that's the orderId)
2. Call the get_orders tool with that orderId
3. Use the returned data to answer their question
```

### **Problem**: "Agent finds the order but just repeats raw data"

**Hint**: Tell the agent to ANALYZE and FORMAT the data, not just repeat it!

**Add guidance like**:
```
When you receive order data:
- Don't just say "status is InProduction"
- Explain what that means ("Your home is currently being built")
- Provide next steps ("Expected completion in X days")
- Be conversational and helpful
```

---

## ⚠️ The Delay Detection Challenge (HARDEST PART!)

This is where most beginners struggle! The agent needs to:
1. Look up the order
2. Calculate how long it's been in production
3. Compare to 30-day standard
4. RECOGNIZE when it's delayed
5. AUTOMATICALLY create a ticket

### **Problem**: "Agent doesn't detect delays"

**Root Cause**: The agent is just repeating system data, not analyzing it!

**Bad Response** (doesn't work):
> "Your order started production on September 10 and typically takes 30 days, so it should be done soon!"
> 
> *(But it's November 1st - that's 52 days! The agent missed the delay!)*

**Good Response** (works):
> "I see your order started production on September 10, which is 52 days ago. Our standard timeline is 30 days, so this is running 22 days behind schedule. I apologize for this delay..."

**The Fix**: Add EXPLICIT instructions to analyze timelines:

```
CRITICAL: PRODUCTION TIMELINE AWARENESS
When checking order status, you MUST analyze the timeline:
- Standard production time: 30 days
- If an order shows "InProduction" for more than 30 days, it is DELAYED
- Calculate: (Today's Date - Production Start Date) vs 30-day standard
- If delayed, IMMEDIATELY create a support ticket

NEVER say "should be completed soon" if it's already past the 30-day mark!
```
**Hint**: Use strong phrases, such as: "You MUST create the ticket" and not "You SHOULD create the ticket".

### **Problem**: "Agent says it will create a ticket but doesn't"

**Root Cause**: The agent understands it SHOULD create a ticket, but it's not actually CALLING the tool!

**Symptoms**:
- Agent says "I'm creating a support ticket for you"
- Agent says "I'll escalate this to our team"
- But no actual ticket number appears
- The `create_support_ticket` tool never gets called

**The Fix**: Be MORE EXPLICIT about tool usage:

```
AUTOMATIC TICKET CREATION FOR DELAYS:
When you detect a delay (production > 30 days):
1. IMMEDIATELY call create_support_ticket tool with:
   - customerId: Extract from order data
   - orderId: The order ID
   - subject: "Production Delay - Order [number] at [days] days"
   - priority: "High"
   - category: "OrderInquiry"
2. THEN tell the customer what you did
3. Provide the ACTUAL ticket number from the response

DO NOT just say you're creating a ticket - ACTUALLY CALL THE TOOL!
```

---

## 🎫 Support Ticket Creation

### **Problem**: "Ticket creation fails with validation error"

**Common mistakes**:

1. **Wrong category value**
   - ❌ "Order Issue" 
   - ✅ "OrderInquiry" (exact value from the allowed list!)

2. **Wrong priority value**
   - ❌ "Urgent"
   - ✅ "High" (exact value: Critical, High, Medium, Low)

3. **Missing required fields**
   - customerId is REQUIRED (get it from order data or customer lookup)
   - subject is REQUIRED
   - category is REQUIRED

**Valid Categories** (use these EXACT values):
- `OrderInquiry` - Order status questions
- `DeliveryIssue` - Shipping problems
- `ProductDefect` - Damage or quality issues
- `Installation` - Installation problems
- `Billing` - Payment issues
- `Technical` - Technical support
- `General` - General questions
- `Complaint` - Customer complaints

**Hint**: Include this list in your instructions so the agent knows the exact values!

---

## 🗣️ Conversation Flow Issues

### **Problem**: "Agent asks for info the customer already provided"

**Example of bad behavior**:
```
Customer: "What's the status of order FAB-2025-047?"
Agent: "I can help! What's your order number?"  ❌
```

**Why this happens**: Topics or conversation flows are forcing unnecessary questions.

**The Fix**:
- **Note**: Copilot Studio includes built-in topics (Goodbye, Greeting, Start Over, Thank you) - these are fine to keep!
- Don't add complex custom topics - let your Instructions handle the conversation flow
- For this challenge, focus on writing great Instructions rather than creating topics
- Trust the instructions to guide the agent's behavior naturally

### **Problem**: "Agent responses feel robotic"

**Signs**:
- Uses phrases like "I have retrieved your order data"
- Repeats technical jargon
- No empathy or personality

**The Fix**: Add personality guidelines to your instructions:

```
PERSONALITY GUIDELINES:
- Be warm and conversational (like a helpful neighbor, not a robot)
- Use "I" and "you" (not "the system" or "your order has been retrieved")
- Show empathy for customer concerns
- Apologize when appropriate (delays, issues)
- Take ownership (say "I apologize" not "the system shows")
```

---

## 🧪 Testing Strategies

### **Use This Testing Order**

1. **Test: Simple Happy Path**
   - "What's the status of order FAB-2025-044?"  
   - (This should work - it's shipped, recent, no issues)
   
2. **Test: Product Question**
   - "Tell me about the Family Haven 1800"
   - (Tests if `get_products` tool works)

3. **Test: Error Handling**
   - "Check order FAB-2025-999"
   - (Order doesn't exist - how does agent handle it?)

4. **Test: THE BIG ONE - Delay Detection**
   - "I ordered a home 7 weeks ago (order FAB-2025-047). When will it be done?"
   - (This is InProduction since Sept 10 - currently 52 days DELAYED!)
   - Agent MUST detect delay AND create ticket automatically!

### **What "Success" Looks Like**

For the delayed order test:

✅ **Agent should**:
- Look up order FAB-2025-047
- Notice it's been in production since September 10 (52 days as of Nov 1)
- RECOGNIZE this is 22 days over the 30-day standard
- Apologize for the delay
- **CALL create_support_ticket tool** (you'll see this in the logs!)
- Provide actual ticket number (like TKT-2025-XXX)
- Set 24-hour callback expectation

❌ **Agent should NOT**:
- Say "should be completed soon" (it's already late!)
- Just repeat the status without analyzing
- Say it will create a ticket but not actually do it
- Miss the delay entirely

---

## 🎓 Common Beginner Mistakes

### **Mistake 1: instructions Too Short**

**Problem**: "You are a customer service agent. Help customers."

**Why it fails**: No context, no tool guidance, no business rules!

**Fix**: Aim for at least 30-50 lines of detailed instructions.

### **Mistake 2: Not Testing Incrementally**

**Problem**: Writing entire instructions, then testing once

**Why it fails**: Too many variables to debug!

**Fix**: Test after every major addition. Build confidence step by step.

### **Mistake 3: Forgetting Tool Names**

**Problem**: Instructions say "look up orders" but don't mention `get_orders` tool name

**Why it fails**: Agent doesn't know which tool to use!

**Fix**: Always use the EXACT tool names in your instructions.

### **Mistake 4: Passive Language**

**Problem**: "Tickets can be created for delays"

**Why it fails**: Agent doesn't know it should CREATE the ticket!

**Fix**: Use active, directive language: "YOU MUST create a ticket when..."

---

## 💪 When You're Really Stuck

### **Debug Checklist**

1. **Check MCP Connection**
   - Go to Tools, then verify Fabrikam connection is added
   - Check which tools are enabled

2. **Review Tool Calls**
   - In test pane, look at the conversation details
   - Did the tool actually get called?
   - What parameters were sent?
   - What was the response?

3. **Simplify**
   - Comment out complex parts of your instructions
   - Test with just basic order lookup
   - Add back complexity gradually

4. **Compare to Examples**
   - Look at the partial solution for architecture ideas
   - Check test scenarios for expected behavior
   - Don't copy-paste - understand the patterns!

### **Ask Your Proctor**

Proctors are here to help! Great questions:
- "My agent isn't calling the get_orders tool - can you look at my instructions?"
- "I'm detecting the delay but the ticket isn't being created - ideas?"
- "My test pane shows an error - what does this mean?"

Avoid vague questions like:
- "It's not working" (too broad!)
- "Can you fix this?" (try debugging first!)

---

## 🚀 Going Beyond Basics

Once you have the core functionality working, try adding:

### **Proactive Behavior**
- Anticipate customer's next question
- Offer related information without being asked
- Suggest helpful next steps

### **Better Error Handling**
- Multiple ways to look up orders (by number, email, customer)
- Graceful handling of missing data
- Helpful suggestions when things aren't found

### **Enhanced Empathy**
- Acknowledge frustration explicitly
- Customize responses based on order status
- Show extra care for delayed orders

---

## ✅ Self-Check Questions

Before asking for help, ask yourself:

- [ ] Did I test with the simple scenarios first?
- [ ] Are my MCP tools actually enabled?
- [ ] Does my instructions mention tools by name?
- [ ] Am I using EXACT category/priority values for tickets?
- [ ] Have I explicitly told the agent to ANALYZE timelines?
- [ ] Did I look at the conversation logs to see what's happening?

---

**Remember**: Everyone struggles with the delay detection part! It's the hardest concept. Take your time, test frequently, and don't hesitate to ask for help. You've got this! 🎉
