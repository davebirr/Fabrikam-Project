# 🌱 Beginner Challenge: Customer Service Hero
**Estimated Time**: 90-120 minutes | **Difficulty**: Beginner | **Technology**: Copilot Studio

---

## 🎯 **Your Mission**

Fabrikam's customer service team is drowning in support tickets! Orders are delayed, customers have questions about products, and the team can't keep up. Your job is to create an AI agent that becomes their superhero sidekick.

### **The Problem**
- 📧 **150+ support tickets per day** overwhelming the team
- ⏱️ **24-48 hour response times** frustrating customers  
- 🔄 **Repetitive questions** taking up valuable human time
- 😰 **Stressed support agents** struggling to keep up

### **Your AI Agent Should**
- 🤖 **Instantly categorize** incoming tickets by type and urgency
- 💬 **Provide immediate responses** to common customer questions
- 📊 **Look up real order information** from the Fabrikam database
- 🚨 **Escalate complex issues** to human agents with context
- 📈 **Track resolution metrics** to improve over time

---

## 🛠️ **Getting Started**

### **Step 1: Access Copilot Studio**
1. **Sign in** to [Copilot Studio](https://copilotstudio.microsoft.com)
2. **Create a new agent** - Keep the name under 30 characters! 
   - Ideas: "Fabrikam Hero" or "FabrikamCS-[YourName]"
   - Pro tip:  Use **Configure** instead of **Describe** to see all of the possible options you have when making your agent.  Most things you will add **after** you create the agent (such as adding an MCP server)
   - Pro tip: Adding your username helps identify your agent in demos
3. **You're ready to build!** The Fabrikam environment is already deployed and waiting for you

### **Step 2: Understand the Business**
Fabrikam manufactures modular homes. Common customer inquiries include:
- **Order Status**: "Where's my Cozy Cottage 1200?"
- **Product Information**: "What's the difference between models?"
- **Installation Support**: "When will my home be installed?"
- **Warranty Questions**: "Is my deck covered under warranty?"

---

## 🎯 **Challenge Requirements**

### **✅ Must-Have Features**
1. **Order Status Lookup**
   - Customer provides order number or email
   - Agent retrieves current status and timeline
   - Provides helpful context about next steps

2. **Product Information**
   - Answer questions about different home models
   - Compare features and pricing
   - Help customers understand what they're buying

3. **Smart Escalation**
   - Recognize when a human is needed
   - Collect relevant information before handoff
   - Create support ticket with proper categorization

### **🌟 Bonus Features** (if time allows)
- **Installation Scheduling**: Help customers book installation appointments
- **Warranty Lookup**: Find warranty information for specific products
- **Satisfaction Survey**: Collect feedback after resolving issues
- **Proactive Notifications**: Alert customers about order updates

---

## 📊 **Sample Conversations**

### **Scenario 1: Order Status Inquiry**
```
Customer: "Hi, I'm wondering about my order. It's been 3 weeks since I placed it."

Your Agent Should:
1. Ask for order number or email address
2. Look up the order in the Fabrikam system
3. Provide current status and expected timeline
4. Offer additional help or escalate if needed

Expected Response:
"I'd be happy to check on your order! I found your Cozy Cottage 1200 (Order #FAB-2025-042) is currently in production and scheduled for delivery on October 25th. You'll receive tracking information 48 hours before delivery. Is there anything else I can help you with?"
```

### **Scenario 2: Product Question**
```
Customer: "What's the difference between the Family Haven 1800 and the Executive Manor 2500?"

Your Agent Should:
1. Access product database information
2. Compare key features and benefits
3. Provide helpful context for decision-making
4. Offer to connect with sales if interested

Expected Response:
"Great question! The Family Haven 1800 is our mid-range model with 1,800 sq ft, perfect for growing families. The Executive Manor 2500 is our premium option with 2,500 sq ft and luxury finishes. The main differences are size, included appliances, and customization options. Would you like detailed specifications for either model?"
```

### **Scenario 3: Complex Issue Escalation**
```
Customer: "My home was delivered damaged and the installation crew said it's not their problem!"

Your Agent Should:
1. Recognize this needs human intervention
2. Gather key details (order number, damage description, photos)
3. Create a priority support ticket
4. Connect customer with appropriate specialist
5. Set expectations for follow-up

Expected Response:
"I'm so sorry to hear about the damage to your new home. This definitely needs immediate attention from our quality assurance team. I'm creating a priority ticket and connecting you with Sarah from our resolution department. She'll contact you within 2 hours to discuss next steps and ensure this gets resolved quickly."
```

---

## 🔧 **Technical Implementation Guide**

### **Agent Setup**
1. **Create Your Agent** (max 30 characters)
   - Keep it short and identifiable
   - Consider adding your name/username
   - Example: "FabrikamCS-Alex" or "Fab Support Bot"

2. **Connect to Fabrikam Data**
   
   Your agent needs to talk to the Fabrikam business system. You have options:
   
   **🎯 For First-Time Builders** (The Easy Path):
   - Look under **Tools** in Copilot Studio
   - You'll find an **MCP Connection** already configured for you
   - Simply add it to your agent - that's it!
   - This connects you to Fabrikam's orders, products, and customers
   
   **🚀 For Experienced Builders** (Roll Your Own):
   - Want to explore how MCP connections work?
   - The Fabrikam MCP server is already deployed in your resource group
   - Create your own connection from scratch
   - Great for understanding the underlying architecture!
   
   **🤔 Not Sure Which to Choose?**
   - Start with the pre-configured connection to get moving quickly
   - You can always create your own connection later for learning
   - Both approaches give you access to the same powerful tools
   
   **What You'll Get Access To**:
   - Real-time order status and history
   - Complete product catalog with specifications
   - Customer information and preferences  
   - Ability to create support tickets
   - Business alerts and system notifications

3. **Build Your Conversation Logic**
   
   **What Are Topics?**
   
   Topics are conversation flows that guide your agent's responses. Think of them like chapters in a choose-your-own-adventure book - each topic handles a specific type of customer request. When a customer asks about their order, your "Order Lookup" topic kicks in. When they need help with product selection, your "Product Info" topic takes over.
   
   **Suggested Topics to Explore**:
   - 📦 Order status and tracking
   - 🏠 Product information and comparisons
   - 📅 Installation scheduling and support
   - ⚠️ Problem escalation and ticket creation
   - ❓ General help and FAQ
   
   You don't need all of these! Pick the ones that make sense for your solution. Some teams focus on doing 1-2 topics exceptionally well. Others create a broader experience. Both approaches can win.
   
   **Pro Tip**: Start with one topic, get it working perfectly, then expand. A great conversation flow beats a mediocre multi-topic agent every time.

4. **Explore Your MCP Tools**
   
   Once you've connected to Fabrikam, you'll have access to powerful tools that let your agent interact with the business system. Here's the fun part: **you get to decide which tools your agent uses!**
   
   **🔍 Discovering Your Tools**:
   - Browse the available MCP tools in your connection
   - Read the descriptions - they tell you what each tool does
   - Not every tool needs to be enabled for your agent
   - You can turn tools on and off as you build
   
   **🎯 Recommended Tools to Start With**:
   - `GetOrders` - Look up customer orders and status
   - `GetProducts` - Retrieve product details and specs
   - `GetCustomers` - Find customer information
   - `CreateSupportTicket` - Log issues that need human attention
   
   **💡 Experiment and Learn**:
   - Try enabling a tool and see how it changes your agent's capabilities
   - Disable tools you're not using to keep responses focused
   - Some scenarios need multiple tools working together
   - Test different combinations to find what works best
   
   **🤔 Questions to Ask Yourself**:
   - Does my agent need to create tickets, or just look up information?
   - Should I enable order history tools for better context?
   - Which tools support my primary use case?
   
   There's no single "right" answer - it depends on your strategy!

### **Sample Prompts**
```
System Prompt Example:
"You are a helpful customer service agent for Fabrikam, a modular homes manufacturer. You have access to order information, product details, and can create support tickets. Always be empathetic and solution-focused. If you can't solve a problem, escalate to human agents with all relevant context."

Order Lookup Prompt Example:
"When a customer asks about their order, use the GetOrders tool to find their information. Always provide the order number, current status, and expected timeline. If there are delays, acknowledge them and provide options."
```

---

## 🎯 **Success Criteria**

### **Basic Success** (30 points)
- ✅ Agent can look up orders by order number
- ✅ Agent provides product information when asked
- ✅ Agent has a clear escalation path for complex issues

### **Good Success** (60 points)
- ✅ All basic features plus natural conversation flow
- ✅ Agent handles multiple conversation turns effectively
- ✅ Clear error handling for invalid inputs
- ✅ Professional and empathetic tone

### **Excellent Success** (100 points)
- ✅ All good features plus proactive assistance
- ✅ Agent anticipates customer needs
- ✅ Seamless integration with business processes
- ✅ Demonstrates understanding of business context

---

## 💡 **Hints & Tips**

### **Getting Stuck? Try These**
1. **Start Simple**: Get basic order lookup working first
2. **Test Frequently**: Try your agent with sample data
3. **Use Templates**: Leverage pre-built conversation flows
4. **Ask for Help**: Proctors are here to support you!

### **Common Challenges**
- **Data Format**: Make sure you understand the API response format
- **Error Handling**: What happens when an order isn't found?
- **Conversation Flow**: How does your agent handle follow-up questions?
- **Escalation Logic**: When should humans take over?

### **Pro Tips**
- **Copy Real Examples**: Use actual support tickets as test cases
- **Think Like a Customer**: What would frustrate you?
- **Be Proactive**: Offer related help before customers ask
- **Test Edge Cases**: What if someone enters gibberish?

---

## 🏆 **Demo Preparation**

### **Prepare These Scenarios**
1. **Happy Path**: Order lookup that works perfectly
2. **Problem Solving**: Delayed order with helpful explanation
3. **Escalation**: Complex issue handed off to human
4. **Product Comparison**: Side-by-side feature comparison

### **Showcase Tips**
- **Tell a Story**: Create a realistic customer persona
- **Show Personality**: Let your agent's character shine through
- **Highlight Intelligence**: Demonstrate understanding, not just responses
- **Celebrate Wins**: Show how you solved real problems

---

## 📚 **Resources**

### **Technical Documentation**
- [Fabrikam API Reference](../../api-tests.http)
- [MCP Tools Overview](../../README.md#available-mcp-tools)
- [Copilot Studio Documentation](https://docs.microsoft.com/copilot-studio)

### **Business Context**
- [Fabrikam Business Model](../../BUSINESS-MODEL-SUMMARY.md)
- [Sample Orders Data](../../FabrikamApi/src/Data/SeedData/orders.json)
- [Product Catalog](../../FabrikamApi/src/Data/SeedData/products.json)

### **Support**
- **Proctors**: Available for hands-on help
- **Peer Network**: Learn from other teams
- **Documentation**: Comprehensive guides available

---

**Ready to become a Customer Service Hero? Let's build something amazing! 🦸‍♀️🦸‍♂️**