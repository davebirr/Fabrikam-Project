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

TECHNICAL CAPABILITIES:
- You have access to real-time order data via get_orders tool
- You can retrieve product information via get_products tool
- You can look up customer details via get_customers tool
- You can create support tickets via create_support_ticket tool

CONVERSATION FLOW:
1. Greet customers warmly and ask how you can help
2. Gather necessary information (order number, email, etc.)
3. Use tools to retrieve accurate data
4. Provide clear, complete answers
5. Offer additional assistance before closing
6. Escalate to human agents when appropriate

ESCALATION CRITERIA:
- Customer is extremely upset or angry
- Issue involves damage, safety, or legal concerns
- Multiple failed resolution attempts
- Customer explicitly requests human contact
- Technical issues beyond your knowledge

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

**Recommended Topics for This Solution:**

1. **📦 Order Status Lookup**
   - Trigger phrases: "track order", "order status", "where is my order"
   - Flow: Ask for order number → Call get_orders → Display results → Offer help
   
2. **🏠 Product Information**
   - Trigger phrases: "tell me about", "product details", "compare models"
   - Flow: Identify product(s) → Call get_products → Present information → Suggest next steps
   
3. **⚠️ Support Escalation**
   - Trigger phrases: "damaged", "problem", "complaint", "speak to manager"
   - Flow: Gather details → Assess severity → Call create_support_ticket → Set expectations

4. **❓ General Greeting/Help**
   - Trigger phrases: "hello", "hi", "help", "what can you do"
   - Flow: Welcome message → Explain capabilities → Ask how to help

**💡 Implementation Tip**: You don't need to create separate topics for everything. The system prompt handles many scenarios automatically. Topics are most useful for complex, multi-step flows where you want precise control.

---

## 💬 **Example Conversations**

### **Scenario 1: Order Status Inquiry (Basic - 30 points)**

**Customer Input:**
> "Hi, I ordered a home 3 weeks ago and haven't heard anything. Order number FAB-2025-047."

**Agent Response:**
```
Thank you for reaching out! Let me check on order FAB-2025-047 for you right away.

[Tool Call: get_orders with orderId=47]

Good news! I found your order for a Cozy Cottage 1200. Here's the current status:

📦 Order Details:
- Order Number: FAB-2025-047
- Product: Cozy Cottage 1200 (1,200 sq ft modular home)
- Order Date: September 3, 2025
- Current Status: **In Production**
- Estimated Completion: November 15, 2025

Your home is currently being built at our manufacturing facility. This stage typically takes 8-10 weeks, and you're right on schedule! 

What Happens Next:
1. Production Completion (Nov 15) - You'll receive a completion notice
2. Quality Inspection (Nov 18-19) - Final checks before shipping
3. Delivery Scheduling (Nov 20) - We'll call to arrange delivery
4. Installation (Late November) - Coordinated with your site contractor

Is there anything specific about the production process or installation that I can help clarify?
```

**Why This Works:**
- ✅ Immediately addresses the concern
- ✅ Uses the get_orders tool correctly
- ✅ Provides comprehensive information
- ✅ Sets clear expectations
- ✅ Offers follow-up assistance

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
- category: "Quality"
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

## 🔧 **Technical Implementation Details**

### **Tool Usage Patterns**

**Pattern 1: Order Lookup**
```
Customer mentions order → Extract order number/email → Call get_orders
- If order number: get_orders(orderId=X)
- If email: get_orders(pageSize=10) then filter by customer
- Always check for null/empty results
- Provide full status, timeline, and next steps
```

**Pattern 2: Product Information**
```
Customer asks about products → Determine if specific or comparison
- Specific: get_products(productId=X)
- Category: get_products(category="ModularHomes")
- Comparison: get_products() then compare specific items
- Always provide context for decision-making
```

**Pattern 3: Support Ticket Creation**
```
Complex issue detected → Gather information → Create ticket
- Priority: Critical (damage/safety), High (urgent), Medium (standard)
- Category: Quality, Installation, Warranty, Billing, General
- Include: Order number, clear description, customer contact info
- Set expectations: Who will contact, when, what process
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
