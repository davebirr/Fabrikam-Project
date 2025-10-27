# 🚀 Quick Start Templates
**Get Building Fast with These Templates**

---

## 🎨 **Copilot Studio Templates**

### **Customer Service Agent Template**
```yaml
Agent Name: Fabrikam Customer Service Hero
Description: AI assistant for Fabrikam customer support

System Message:
"You are a helpful customer service representative for Fabrikam, a modular homes manufacturing company. You have access to order information, product details, and can create support tickets. Always be empathetic, solution-focused, and professional. If you cannot solve a problem directly, escalate to human agents with complete context."

Key Topics:
1. Order Status Inquiry
2. Product Information Request  
3. Installation Support
4. Warranty Questions
5. General Help
6. Escalation to Human

Sample Conversation Starters:
- "Hi, I need to check on my order status"
- "Can you tell me about your different home models?"
- "I'm having issues with my installation"
- "I need help with a warranty claim"
```

### **Sales Intelligence Template**
```yaml
Agent Name: Fabrikam Sales Intelligence Assistant
Description: AI-powered sales analytics and forecasting

System Message:
"You are a sales intelligence analyst for Fabrikam. You provide data-driven insights, lead scoring, performance analytics, and forecasting. Always present information in a business-friendly format with clear recommendations and action items. Focus on helping sales teams and executives make better decisions."

Key Capabilities:
1. Sales Performance Analysis
2. Lead Scoring and Prioritization
3. Revenue Forecasting
4. Market Trend Analysis
5. Customer Segmentation
6. Competitive Intelligence

Sample Queries:
- "Show me this month's sales performance"
- "Which leads should I prioritize this week?"
- "What's our revenue forecast for next quarter?"
- "Analyze our top-performing products"
```

---

## 💻 **Semantic Kernel Templates**

### **Basic Agent Setup**
```csharp
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;

public class FabrikamAgent
{
    private readonly Kernel _kernel;
    private readonly IChatCompletionService _chatService;
    
    public FabrikamAgent(string apiKey, string endpoint)
    {
        var builder = Kernel.CreateBuilder();
        builder.AddAzureOpenAIChatCompletion(
            "gpt-4", 
            endpoint, 
            apiKey
        );
        
        _kernel = builder.Build();
        _chatService = _kernel.GetRequiredService<IChatCompletionService>();
    }
    
    public async Task<string> ProcessCustomerInquiry(string inquiry)
    {
        var prompt = $@"
You are a customer service agent for Fabrikam modular homes.
Customer inquiry: {inquiry}

Respond helpfully and professionally. If you need to look up specific information, indicate what data you would need to access.
";
        
        var result = await _kernel.InvokePromptAsync(prompt);
        return result.GetValue<string>() ?? "";
    }
}
```

### **Business Intelligence Plugin**
```csharp
using Microsoft.SemanticKernel;
using System.ComponentModel;

public class FabrikamBusinessPlugin
{
    private readonly HttpClient _httpClient;
    private readonly string _apiBaseUrl;
    
    public FabrikamBusinessPlugin(HttpClient httpClient, string apiBaseUrl)
    {
        _httpClient = httpClient;
        _apiBaseUrl = apiBaseUrl;
    }
    
    [KernelFunction, Description("Get sales performance analytics")]
    public async Task<string> GetSalesAnalytics(
        [Description("Time period: 'current-month', 'last-month', 'quarter', etc.")] 
        string period = "current-month")
    {
        var response = await _httpClient.GetAsync($"{_apiBaseUrl}/api/orders/analytics?period={period}");
        var data = await response.Content.ReadAsStringAsync();
        
        return $"Sales analytics for {period}: {data}";
    }
    
    [KernelFunction, Description("Look up customer order status")]
    public async Task<string> GetOrderStatus(
        [Description("Customer order number")] 
        string orderNumber)
    {
        var response = await _httpClient.GetAsync($"{_apiBaseUrl}/api/orders?orderNumber={orderNumber}");
        
        if (response.IsSuccessStatusCode)
        {
            var orderData = await response.Content.ReadAsStringAsync();
            return $"Order {orderNumber} status: {orderData}";
        }
        
        return $"Order {orderNumber} not found. Please verify the order number.";
    }
}
```

---

## 🐍 **Python Templates (AutoGen/LangChain)**

### **AutoGen Multi-Agent Setup**
```python
import autogen
import os

# Configure LLM
config_list = [
    {
        "model": "gpt-4",
        "api_key": os.environ.get("OPENAI_API_KEY"),
    }
]

llm_config = {
    "config_list": config_list,
    "temperature": 0.1,
}

# Define specialized agents
strategic_monitor = autogen.AssistantAgent(
    name="StrategicMonitor",
    system_message="""You are a strategic business monitor for Fabrikam. 
    You analyze business patterns, identify trends, and detect potential opportunities or risks.
    Focus on high-level insights that would matter to executives.""",
    llm_config=llm_config,
)

risk_assessor = autogen.AssistantAgent(
    name="RiskAssessor", 
    system_message="""You are a risk assessment specialist for Fabrikam.
    You evaluate potential threats to business operations, financial performance, and strategic goals.
    Provide clear risk levels and mitigation recommendations.""",
    llm_config=llm_config,
)

operations_coordinator = autogen.AssistantAgent(
    name="OperationsCoordinator",
    system_message="""You are an operations coordinator for Fabrikam.
    You focus on workflow optimization, resource allocation, and cross-functional coordination.
    Provide actionable operational recommendations.""",
    llm_config=llm_config,
)

# Create user proxy for human interaction
user_proxy = autogen.UserProxyAgent(
    name="ExecutiveUser",
    human_input_mode="TERMINATE",
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda x: x.get("content", "").rstrip().endswith("TERMINATE"),
)

# Example multi-agent conversation
def analyze_business_situation(situation_description):
    user_proxy.initiate_chat(
        strategic_monitor,
        message=f"""Analyze this business situation from multiple perspectives:
        
        Situation: {situation_description}
        
        Please coordinate with RiskAssessor and OperationsCoordinator to provide:
        1. Strategic implications
        2. Risk assessment  
        3. Operational recommendations
        4. Coordinated action plan
        
        Begin the analysis."""
    )
```

### **LangChain Agent with Tools**
```python
from langchain.agents import AgentExecutor, create_openai_tools_agent
from langchain.tools import Tool
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
import requests

class FabrikamTools:
    def __init__(self, api_base_url):
        self.api_base_url = api_base_url
    
    def get_orders(self, customer_id=None, order_number=None):
        """Get customer orders from Fabrikam API"""
        params = {}
        if customer_id:
            params['customerId'] = customer_id
        if order_number:
            params['orderNumber'] = order_number
            
        response = requests.get(f"{self.api_base_url}/api/orders", params=params)
        return response.json() if response.status_code == 200 else "Orders not found"
    
    def get_products(self, category=None):
        """Get product information from Fabrikam catalog"""
        params = {}
        if category:
            params['category'] = category
            
        response = requests.get(f"{self.api_base_url}/api/products", params=params)
        return response.json() if response.status_code == 200 else "Products not found"

# Initialize tools
fabrikam_tools = FabrikamTools("https://your-fabrikam-api.azurewebsites.net")

tools = [
    Tool(
        name="get_orders",
        description="Get customer order information. Useful for checking order status, delivery dates, etc.",
        func=lambda query: str(fabrikam_tools.get_orders())
    ),
    Tool(
        name="get_products", 
        description="Get product catalog information. Useful for answering questions about home models, features, pricing.",
        func=lambda query: str(fabrikam_tools.get_products())
    ),
]

# Create agent
llm = ChatOpenAI(model="gpt-4", temperature=0.1)

prompt = ChatPromptTemplate.from_messages([
    ("system", """You are a helpful assistant for Fabrikam, a modular homes company.
    You have access to order and product information through tools.
    Always be professional, empathetic, and solution-focused.
    If you need to look up information, use the available tools."""),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),
])

agent = create_openai_tools_agent(llm, tools, prompt)
agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

# Use the agent
def chat_with_agent(user_input):
    return agent_executor.invoke({"input": user_input})
```

---

## ⚡ **Quick Integration Snippets**

### **API Authentication**
```csharp
// .NET HTTP Client with Bearer Token
public class FabrikamApiClient
{
    private readonly HttpClient _httpClient;
    
    public FabrikamApiClient(string baseUrl, string bearerToken = null)
    {
        _httpClient = new HttpClient { BaseAddress = new Uri(baseUrl) };
        
        if (!string.IsNullOrEmpty(bearerToken))
        {
            _httpClient.DefaultRequestHeaders.Authorization = 
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", bearerToken);
        }
    }
    
    public async Task<T> GetAsync<T>(string endpoint)
    {
        var response = await _httpClient.GetAsync(endpoint);
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(json);
    }
}
```

```python
# Python requests with authentication
import requests
from typing import Optional

class FabrikamAPIClient:
    def __init__(self, base_url: str, api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json'
            })
    
    def get_orders(self, **params):
        response = self.session.get(f"{self.base_url}/api/orders", params=params)
        response.raise_for_status()
        return response.json()
    
    def get_products(self, **params):
        response = self.session.get(f"{self.base_url}/api/products", params=params)
        response.raise_for_status()
        return response.json()
```

### **Error Handling Templates**
```csharp
// Robust API call with retry
public async Task<string> SafeApiCall(Func<Task<string>> apiCall, int maxRetries = 3)
{
    for (int attempt = 1; attempt <= maxRetries; attempt++)
    {
        try
        {
            return await apiCall();
        }
        catch (HttpRequestException ex) when (attempt < maxRetries)
        {
            await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt))); // Exponential backoff
        }
        catch (Exception ex)
        {
            return $"Error: {ex.Message}. Please try again or contact support.";
        }
    }
    
    return "Service temporarily unavailable. Please try again later.";
}
```

```python
# Python retry decorator
from functools import wraps
import time
import random

def retry_with_backoff(max_retries=3, base_delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries - 1:
                        return f"Error after {max_retries} attempts: {str(e)}"
                    
                    delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
                    time.sleep(delay)
            
        return wrapper
    return decorator

@retry_with_backoff(max_retries=3)
def call_fabrikam_api(endpoint):
    # Your API call here
    pass
```

---

## 🎯 **Environment Variables Template**

### **.env File Template**
```bash
# API Configuration
FABRIKAM_API_BASE_URL=https://your-deployment.azurewebsites.net
FABRIKAM_MCP_URL=https://your-mcp.azurewebsites.net:5000

# AI Service Configuration  
OPENAI_API_KEY=your-openai-key
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com
AZURE_OPENAI_API_KEY=your-azure-openai-key

# Optional: Authentication
FABRIKAM_API_TOKEN=your-api-token
```

### **Configuration Loading**
```csharp
// .NET Configuration
public class FabrikamConfig
{
    public string ApiBaseUrl { get; set; } = "";
    public string McpUrl { get; set; } = "";
    public string OpenAIApiKey { get; set; } = "";
    public string ApiToken { get; set; } = "";
}

// In Program.cs or Startup
builder.Services.Configure<FabrikamConfig>(
    builder.Configuration.GetSection("Fabrikam")
);
```

```python
# Python environment loading
import os
from dataclasses import dataclass

@dataclass
class Config:
    api_base_url: str = os.getenv('FABRIKAM_API_BASE_URL', 'https://localhost:7297')
    mcp_url: str = os.getenv('FABRIKAM_MCP_URL', 'http://localhost:5000')
    openai_api_key: str = os.getenv('OPENAI_API_KEY', '')
    api_token: str = os.getenv('FABRIKAM_API_TOKEN', '')

config = Config()
```

---

**Ready to start building? Pick a template that matches your challenge and technology choice, then customize it for your specific solution! 🚀**