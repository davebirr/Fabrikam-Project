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

### **Step 1: Set Up Your Fabrikam Environment**
1. **Fork the Repository**: Visit [Fabrikam Project](https://github.com/davebirr/Fabrikam-Project) and click "Fork"
2. **Deploy to Azure**: Use the one-click deployment button
3. **Test the API**: Try some sample queries to understand the data structure

### **Step 2: Access Copilot Studio**
1. **Sign in** to [Copilot Studio](https://copilotstudio.microsoft.com)
2. **Create a new agent** called "Fabrikam Customer Service Hero"
3. **Connect to your MCP server** using your Azure deployment URL

### **Step 3: Understand the Business**
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

### **Copilot Studio Setup**
1. **Create New Agent**
   - Name: "Fabrikam Customer Service Hero"
   - Description: "AI assistant for Fabrikam customer support"

2. **Add Data Source**
   - Type: "Model Context Protocol (MCP)"
   - URL: Your deployed Fabrikam MCP server
   - Authentication: Follow the setup guide

3. **Configure Topics**
   - Order Status Lookup
   - Product Information
   - Installation Support
   - Escalation Workflow

### **Key MCP Tools to Use**
- `GetOrders` - Look up customer orders
- `GetProducts` - Retrieve product information
- `GetCustomers` - Find customer details
- `CreateSupportTicket` - Log issues for human follow-up
- `GetBusinessAlerts` - Check for system-wide issues

### **Sample Prompts**
```
System Prompt:
"You are a helpful customer service agent for Fabrikam, a modular homes manufacturer. You have access to order information, product details, and can create support tickets. Always be empathetic and solution-focused. If you can't solve a problem, escalate to human agents with all relevant context."

Order Lookup Prompt:
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