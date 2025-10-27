# CSP Level Up Bootcamp Technical Training
## Copilot Agents with Custom MCP Servers
**September 2, 2025 | 15-20 Minute Presentation**

---

## 🎯 **Why Should Partners Care?**

### **The Business Challenge**
- Partners often need to demonstrate AI capabilities to clients
- Connecting multiple third-party systems is complex and time-consuming
- Building custom integrations requires significant technical expertise
- Demos need realistic, reliable data that showcases business scenarios

### **The Fabrikam Solution**
✅ **Pre-built MCP Server** - Ready-to-use business simulation platform  
✅ **Zero Integration Hassle** - No need to connect multiple APIs or databases  
✅ **Realistic Business Data** - Complete modular homes business with orders, customers, support tickets  
✅ **Perfect for Learning** - Understand MCP concepts without infrastructure complexity  
✅ **Demo-Ready** - Impressive business scenarios that resonate with clients  

### **Partner Value Proposition**
- **Accelerate sales cycles** with compelling AI demonstrations
- **Reduce technical barriers** to showcasing Copilot Agent capabilities
- **Learn MCP fundamentals** in a safe, controlled environment
- **Impress clients** with sophisticated business intelligence scenarios

---

## 📋 **What is the Fabrikam MCP Server?**

### **Complete Business Simulation Platform**
The Fabrikam Project is a full-stack .NET application that simulates a modular homes manufacturing business, specifically designed to showcase Microsoft Copilot Agent capabilities through the Model Context Protocol (MCP).

### **What's Included**
- **🏠 Business Domain**: Modular homes manufacturing and sales
- **📊 Realistic Data**: Orders, customers, products, support tickets, analytics
- **🔧 MCP Server**: Pre-built tools for business intelligence and operations
- **☁️ Azure Integration**: Deploys seamlessly to Azure with one-click templates
- **🔐 Authentication**: Enterprise-ready security with Azure Entra ID support

### **Available Business Tools**
- Sales analytics and forecasting
- Customer service management
- Inventory tracking and alerts
- Business performance dashboards
- Order processing and logistics

### **How to Get Started** *(High-Level Overview)*

1. **Fork the Repository**
   - Visit the [Fabrikam Project on GitHub](https://github.com/davebirr/Fabrikam-Project)
   - Click "Fork" to create your own copy

2. **Deploy to Azure**
   - Use the one-click deployment button in the README
   - Azure handles all the infrastructure setup automatically
   - No technical configuration required

3. **Connect to Copilot**
   - Copy your deployed MCP server URL
   - Add it as a data source in Copilot Studio
   - Start asking business questions immediately

**📖 Detailed Instructions**: Complete setup guide available in `workshops/ws-coe-aug27/COE-COMPLETE-SETUP-GUIDE.md`

---

## 🚀 **Demonstration: Connecting MCP Server to Copilot Agent**

### **Step 1: MCP Server Configuration**

**What happens behind the scenes:**
- MCP Server exposes business tools through standardized protocol
- Each tool includes rich descriptions for AI understanding
- Authentication handles secure access to business data
- Server automatically provides tool schemas to Copilot

**Key Configuration:**
```
MCP Server URL: https://your-fabrikam-mcp.azurewebsites.net
Authentication: Automatic via Azure connector
Tools Discovered: ~15 business intelligence functions
```

### **Step 2: Tool Discovery Process**

**How Copilot Learns About Your Business:**
1. **Connection Handshake**: Copilot connects to MCP server
2. **Tool Enumeration**: Server provides list of available business functions
3. **Schema Understanding**: Each tool includes description, parameters, expected outputs
4. **Context Building**: Copilot learns your business domain and capabilities

**Example Tool Registration:**
- **Tool**: `GetBusinessDashboard`
- **Description**: "Get comprehensive business dashboard with key metrics across sales, inventory, and customer service"
- **AI Understanding**: Copilot knows this provides executive-level business insights

### **Step 3: Live Demonstration Scenarios**

#### **🔍 Scenario 1: Executive Business Review**
**User Query**: *"Show me our business performance this month"*

**What Happens:**
1. Copilot analyzes the request
2. Identifies `GetBusinessDashboard` as the right tool
3. Calls MCP server with appropriate parameters
4. Receives structured business data
5. Formats response in executive-friendly format

**Expected Response**: Comprehensive dashboard with sales figures, order pipeline, support metrics, and regional performance

#### **🚨 Scenario 2: Operational Alerts**
**User Query**: *"Are there any urgent issues I should know about?"*

**What Happens:**
1. Copilot selects `GetBusinessAlerts` tool
2. MCP server analyzes current business data
3. Identifies critical issues (low inventory, overdue orders, support tickets)
4. Returns prioritized alerts with actionable recommendations

**Expected Response**: Specific alerts about inventory shortages, delayed orders, or critical support issues

#### **📈 Scenario 3: Sales Analysis**
**User Query**: *"How are our sales trending in the Pacific Northwest?"*

**What Happens:**
1. Copilot chooses regional sales analysis tools
2. Applies geographic filter for Pacific Northwest
3. Retrieves sales data, trends, and comparisons
4. Formats insights with context and recommendations

**Expected Response**: Regional sales performance with trends, top products, and growth opportunities

### **Step 4: The Magic of MCP Descriptions**

**How AI Chooses the Right Tool:**
- **Rich Descriptions**: Each tool explains its purpose in business terms
- **Parameter Guidance**: Clear explanation of what inputs are needed
- **Context Awareness**: Tools designed for specific business scenarios
- **Smart Routing**: Copilot matches user intent to appropriate business function

**Example Tool Descriptions:**
- *"Get performance alerts and recommendations for business operations"*
- *"Analyze sales trends and forecast future performance by region or product"*
- *"Retrieve customer service metrics and support ticket analytics"*

### **Step 5: Authentication & Security**

**Enterprise-Ready Security:**
- **Azure Entra ID Integration**: Secure user authentication
- **Role-Based Access**: Different tools for different business roles
- **Audit Logging**: Complete traceability of AI interactions
- **Data Protection**: Business data remains secure in your Azure tenant

---

## 🎯 **Key Takeaways for Partners**

### **Business Impact**
- **Faster Client Engagement**: Skip technical setup, focus on business value
- **Compelling Demonstrations**: Real business scenarios that resonate
- **Learning Platform**: Understand MCP without infrastructure complexity
- **Competitive Advantage**: Showcase advanced AI capabilities confidently

### **Technical Benefits**
- **Production-Ready**: Enterprise authentication and security
- **Scalable**: Azure cloud deployment with automatic scaling
- **Extensible**: Add your own business tools to the MCP server
- **Maintainable**: Well-documented, modern .NET architecture

### **Next Steps**
1. **Try It Yourself**: Fork and deploy the Fabrikam Project
2. **Practice Demos**: Use the business scenarios for client presentations
3. **Learn MCP**: Understand the protocol for future custom implementations
4. **Scale Up**: Apply concepts to real client business domains

---

**📚 Resources:**
- **GitHub Repository**: [Fabrikam-Project](https://github.com/davebirr/Fabrikam-Project)
- **Setup Guide**: `workshops/ws-coe-aug27/COE-COMPLETE-SETUP-GUIDE.md`
- **MCP Documentation**: Comprehensive primer in project README
- **Business Use Cases**: Example scenarios in `docs/demos/` folder

**🤝 Support:**
- Workshop materials and guides included
- Community-driven development and support
- Regular updates with new business scenarios
