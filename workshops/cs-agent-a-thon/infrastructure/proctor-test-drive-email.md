# 🚀 Agent-A-Thon: Is This Thing On? (Test Your Setup!)

**Subject:** 🤖 Test Drive Your Fabrikam Agent - MCP Power Demo!

---

Hey **{{RealFirstName}}**! 👋

By now you should have your **{{FictitiousName}}** identity all set up. Time to make sure everything's actually working! Let's build a quick agent and see the magic of MCP in action.

## 🎯 The "Is This Thing On?" Test

We're going to create a **Fabrikam Business Assistant** that uses MCP to pull real business data. If it works, you'll see actual sales numbers, revenue, orders, etc. If it doesn't... well, you'll see the model making stuff up (which is NOT the point of MCP 😅).

---

## 🛠️ Build Your Test Agent (5 Minutes Max)

### Step 1: Create a New Agent
1. Go to [Copilot Studio](https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971)
2. Make sure you're in the **Fabrikam environment** (check the top-right environment selector)
3. Click **Create** → **New agent**
4. Name it: **Fabrikam Business Assistant ({{WorkshopUsername}})**
   - Example: "Fabrikam Business Assistant (oscarw)"
   - This helps keep agents organized if you start sharing with other proctors!
5. Click **Create**

### Step 2: Add the Instructions
Click on **Instructions** in the agent builder, then **paste this entire block**:

```
You are a helpful AI assistant for Fabrikam Modular Homes, a company that designs and sells modular homes online. You have access to real-time business data and can help with:

📊 EXECUTIVE DASHBOARD:
- Provide comprehensive business overview with key performance indicators
- Show revenue trends, order metrics, and operational alerts
- Deliver executive-level insights for strategic decision making

🏢 SALES OPERATIONS:
- View and filter orders by status (Pending, Processing, Shipped, Delivered, Cancelled)
- Track sales performance metrics and customer analytics
- Generate sales reports and identify trends
- Monitor revenue streams and customer acquisition
- If asked about customer performance, be sure to check their order history.

📦 INVENTORY MANAGEMENT:
- Check real-time product availability and stock levels
- Browse the complete product catalog with specifications
- Monitor inventory alerts and restocking needs
- Track product performance and demand patterns

🎧 CUSTOMER SERVICE:
- Manage customer support tickets and issue tracking
- View ticket status and resolution progress
- Analyze customer feedback and satisfaction metrics
- Access customer communication history

Always provide accurate, helpful information based on real-time data. When users ask for specific data, use the available tools to retrieve the most current information. Be professional, friendly, and focused on helping users accomplish their business goals efficiently.

NOTE: This is a demonstration environment with sample data for evaluation purposes.

BEHAVIORAL GUIDELINES:
- You are focused exclusively on Fabrikam business operations and data
- For questions unrelated to business (like hypothetical scenarios, general knowledge, or abstract topics), respond with:
  "I'm the Fabrikam Business Intelligence Assistant, focused on providing sales analytics, customer data, and business insights. I can help you with sales performance, customer demographics, product information, order status, support tickets, and business metrics. How can I assist you with Fabrikam business data today?"
- Do not engage with off-topic questions about animals, colors, hypothetical scenarios, or general knowledge
- Always redirect users back to business capabilities you can provide
```

**Feel free to tweak these instructions!** Add personality, change the tone, make it yours. This is just a starting point.

### Step 3: Connect the MCP Tool
1. In your agent builder, look for **Actions** in the left panel
2. Click **+ Add action** → **Connectors**
3. Find **"Fabrikam MCP Connector"** (should already be shared with proctors)
4. **Enable ALL the tools** you see (GetBusinessDashboard, GetCustomers, GetOrders, GetProducts, GetSupportTickets, etc.)
5. Click **Save**

### Step 4: Test It!
1. Click **Test** in the top-right corner
2. In the test chat, type: **"How is our business doing this year?"**

---

## ✅ What You Should See (The MCP Magic!)

If everything's working, your agent should return **real data** like:

```
📊 Fabrikam Business Dashboard (2025)

Orders: 19 total
Revenue: $4,384,942.50
Average Order Value: $230,786.45
Top Product: The Apex (5 orders, $1,125,000)
```

**These are actual numbers from the Fabrikam demo data!** That's MCP pulling live data from the backend.

---

## ❌ What You DON'T Want to See

If you get random numbers, generic responses, or the model saying things like:
- "Fabrikam is doing great with approximately $X million in revenue..." (made up numbers)
- "Let me help you analyze your business..." (but no actual data)
- Generic advice without specific numbers

**That means the MCP connection isn't working.** The model is just guessing, which is NOT the power of MCP.

---

## 🆘 Troubleshooting

**Agent doesn't show real data?**
1. Double-check you're in the **Fabrikam environment** (not Default)
2. Verify the MCP connector is added to your agent's **Actions**
3. Make sure you **enabled the tools** (they're off by default)
4. Try re-creating the agent from scratch

**Can't find the MCP connector?**
→ **First time in Copilot Studio?** Things might still be provisioning. Wait 2-3 minutes (grab a coffee ☕), then refresh the page.  
→ **Still not there after waiting?** Ping David Bjurman-Birr - it should be shared with all proctors.

**Getting "Something went wrong" or permission errors when adding the connector?**
→ **Try this:** Completely sign out of Copilot Studio (not just close the tab), then sign back in as **{{FictitiousName}}**. Permissions might not have synced yet.  
→ **Still failing?** Clear your browser cache/cookies for `microsoft.com` and `powerapps.com`, then try again.  
→ **Nuclear option:** Use InPrivate/Incognito mode, sign in as **{{FictitiousName}}**, and try adding the connector there.  
→ **If nothing works:** Ping David Bjurman-Birr - there might be a backend sync issue.

---

## 🎯 What's Next?

**Right now, the MCP server has READ-ONLY tools enabled:**
- ✅ Get business dashboard
- ✅ Get customers
- ✅ Get orders  
- ✅ Get products
- ✅ Get support tickets

**Coming soon (before the workshop):**
- 📝 Create/update orders
- 👤 Create/update customers
- 🎫 Create/update support tickets
- 📦 Inventory management

You won't be able to complete the full workshop challenges yet (those require write operations), but you can test the read capabilities and get familiar with the setup.

---

## 💡 Play Around!

Once you confirm the MCP connection works, try asking:
- "Show me all pending orders"
- "Who are our top customers?"
- "What products do we have in stock?"
- "How many support tickets are open?"

Get creative! Break things! This is your sandbox. 🏖️

---

## 📧 Report Back!

Once you've tested this, drop me a quick Teams message:
- ✅ "MCP works! Saw real data"
- ❌ "MCP not working - getting random numbers"
- 🤔 "Confused about [specific issue]"

This helps me know everyone's ready for the main event on **November 6th**.

---

See you in the agent-building trenches! 🤖⚡

*P.S. - If you make your agent say something hilarious, screenshots are encouraged.* 😎

---

**Your Friendly Neighborhood Workshop Infrastructure Team**  
*Agent Wranglers & MCP Magicians*  
CS Agent-A-Thon 2025 🚀
