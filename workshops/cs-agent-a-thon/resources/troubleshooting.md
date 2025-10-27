# 🔧 Workshop Troubleshooting Guide
**Quick Solutions for Common Issues**

---

## 🚨 **Emergency Quick Fixes**

### **"I Can't Access the Fabrikam Data!"**
```bash
# Test your API connection
curl -k https://your-fabrikam-api.azurewebsites.net/api/info

# If that fails, check your deployment status
# Go to Azure Portal > Your Resource Group > Check deployment logs
```

### **"My Agent Isn't Working!"**
1. **Check the basics**: Is your API running? Is authentication working?
2. **Test with simple queries**: Start with basic questions before complex ones
3. **Check error logs**: Most platforms provide detailed error information
4. **Ask a proctor**: We're here to help!

### **"I'm Running Out of Time!"**
- **Scope down**: Pick one core feature and make it work perfectly
- **Use templates**: Leverage pre-built examples and modify them
- **Focus on demo**: Get something working for the showcase
- **Document what you learned**: Even partial solutions have value

---

## 🔍 **Common Issues by Technology**

### **Copilot Studio Problems**

#### **Issue**: Agent doesn't understand business context
**Solution**:
```
1. Check your MCP server connection
2. Verify data source authentication
3. Test API endpoints manually
4. Improve your system prompts with more business context
```

#### **Issue**: Conversation flow breaks
**Solution**:
```
1. Use the test panel to debug step-by-step
2. Check topic triggers and conditions
3. Simplify complex flows into smaller parts
4. Add fallback topics for unhandled cases
```

#### **Issue**: Can't connect to Fabrikam MCP server
**Solution**:
```
1. Verify your Azure deployment is running
2. Check the MCP server URL (usually ends with :5000)
3. Ensure authentication is configured correctly
4. Test the MCP endpoint directly in a browser
```

### **Semantic Kernel Problems**

#### **Issue**: Build errors with NuGet packages
**Solution**:
```bash
# Clear NuGet cache and restore
dotnet nuget locals all --clear
dotnet restore
dotnet build
```

#### **Issue**: Authentication errors with Fabrikam API
**Solution**:
```csharp
// Check your HTTP client configuration
httpClient.DefaultRequestHeaders.Add("Authorization", "Bearer " + token);
httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
```

#### **Issue**: Semantic functions not working
**Solution**:
```csharp
// Verify your kernel configuration
var kernel = Kernel.CreateBuilder()
    .AddAzureOpenAIChatCompletion(modelId, endpoint, apiKey)
    .Build();

// Test with simple function first
var result = await kernel.InvokePromptAsync("Say hello");
```

### **Python Framework Problems (AutoGen/LangChain)**

#### **Issue**: Package installation failures
**Solution**:
```bash
# Create virtual environment
python -m venv agent_env
source agent_env/bin/activate  # On Windows: agent_env\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### **Issue**: API rate limiting
**Solution**:
```python
# Add retry logic and delays
import time
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def call_api():
    # Your API call here
    pass
```

#### **Issue**: Agent conversations getting stuck
**Solution**:
```python
# Add conversation limits and fallbacks
max_turns = 10
conversation_history = []

if len(conversation_history) > max_turns:
    # Summarize or reset conversation
    conversation_history = summarize_conversation(conversation_history)
```

---

## 🌐 **Azure Deployment Issues**

### **"My Azure Deployment Failed"**
**Diagnosis Steps**:
1. Check Azure Portal > Resource Group > Deployments
2. Look for error messages in deployment logs
3. Verify resource quotas and limits
4. Check naming conflicts

**Common Solutions**:
```bash
# Resource name already exists
- Add random suffix to resource names
- Try different Azure region

# Quota exceeded
- Check subscription limits
- Request quota increase if needed

# Permissions error
- Verify you have Contributor role on subscription
- Check resource provider registrations
```

### **"API Returns 404 Errors"**
**Diagnosis**:
```bash
# Test the base URL
curl https://your-app.azurewebsites.net/api/info

# Check specific endpoints
curl https://your-app.azurewebsites.net/api/products
```

**Solutions**:
- Verify deployment completed successfully
- Check application logs in Azure Portal
- Ensure database is seeded with test data
- Verify routing configuration

### **"MCP Server Not Responding"**
**Diagnosis**:
```bash
# Test MCP health endpoint
curl http://your-mcp.azurewebsites.net/health

# Check if server is running
curl http://your-mcp.azurewebsites.net:5000/
```

**Solutions**:
- Verify MCP server deployment
- Check application insights for errors
- Ensure proper port configuration
- Test authentication setup

---

## 🤖 **Agent-Specific Debugging**

### **Agent Gives Wrong Answers**
**Debug Process**:
1. **Test underlying data**: Query the API directly
2. **Check prompts**: Are your instructions clear?
3. **Verify context**: Is the agent getting the right information?
4. **Simplify queries**: Start with basic questions

**Improvement Strategies**:
```
# Better prompts
"You are a customer service agent for Fabrikam, a modular homes company. 
Always be helpful and accurate. If you don't know something, say so."

# Add examples
"Here are examples of good responses:
Customer: 'Where is my order?'
Agent: 'I'll check your order status. Can you provide your order number?'"
```

### **Agent Responses Are Too Slow**
**Optimization Tips**:
- Cache frequent queries
- Use streaming responses where possible
- Optimize API calls (batch requests, select only needed fields)
- Consider using faster models for simple queries

### **Agent Doesn't Handle Edge Cases**
**Robustness Strategies**:
```
# Input validation
if not order_number or len(order_number) < 5:
    return "Please provide a valid order number (at least 5 characters)"

# Graceful degradation
try:
    result = api_call()
except APIError:
    return "I'm having trouble accessing that information right now. Please try again in a moment."
```

---

## ⏰ **Time Management Strategies**

### **Running Behind Schedule?**
**Priority Order**:
1. **Get basic functionality working** (one successful scenario)
2. **Add error handling** (graceful failures)
3. **Improve user experience** (better prompts, formatting)
4. **Add advanced features** (only if time allows)

### **Stuck on Technical Issues?**
**Escalation Path**:
1. **Try simple workaround** (5 minutes)
2. **Check documentation** (5 minutes)
3. **Ask peer for help** (5 minutes)
4. **Get proctor assistance** (immediate)

### **Demo Preparation Tips**
**With 15 Minutes Left**:
- Choose your best working scenario
- Practice the demo flow 2-3 times
- Prepare a backup plan (screenshots, explanation)
- Have talking points ready about what you learned

---

## 🆘 **Getting Help**

### **Self-Service Resources**
- **Documentation**: Each challenge has comprehensive guides
- **API Testing**: Use the provided `api-tests.http` file
- **Sample Code**: Templates and examples available
- **Error Logs**: Check your development tools' console/logs

### **Peer Support**
- **Cross-pollination encouraged**: Learn from other teams
- **Different perspectives**: Business vs. technical viewpoints
- **Shared learning**: What worked for others might work for you

### **Expert Support**
- **Proctors**: Technical experts for hands-on debugging
- **Mentors**: Business domain experts for use case validation
- **Workshop Leaders**: Overall guidance and strategic direction

### **Asking Great Questions**
**Instead of**: "It's not working"
**Try**: "I'm getting a 404 error when calling the /api/orders endpoint, and I've verified my base URL is correct"

**Instead of**: "My agent is broken"
**Try**: "My agent responds to simple questions but fails when I ask about order status - here's the error message I'm seeing"

---

## 🎯 **Success Mindset**

### **Remember**:
- **Progress over perfection**: A working basic solution beats a perfect incomplete one
- **Learning is the goal**: Even failed experiments teach valuable lessons
- **Community support**: You're not alone in this challenge
- **Real-world application**: These are actual business problems worth solving

### **When Things Go Wrong**:
- Take a deep breath
- Break the problem into smaller pieces
- Ask for help (seriously, we want you to succeed!)
- Focus on what you can control
- Document what you learn for next time

---

**Remember: Every expert was once a beginner. You've got this! 🚀**