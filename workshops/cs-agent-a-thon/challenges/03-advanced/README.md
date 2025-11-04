## 🔴 Advanced Challenge: Production-Ready Agent Framework

**Build Enterprise-Grade Solutions** | 90 minutes | Completely Self-Directed

---

## ⚠️ **Important Note from the Author** 

If you're attempting the Advanced challenge, there's a good chance you already exceed the knowledge and capabilities of the person who wrote these materials. 🎓

**Consider this your official invitation:**

You are hereby encouraged—nay, *implored*—to contribute your brilliance, ideas, and innovations back to the **[Fabrikam-Project on GitHub](https://github.com/davebirr/Fabrikam-Project)**! 

- Found a better pattern? **Share it!**
- Built something awesome? **PR it!**
- Discovered a clever optimization? **Document it!**
- Fixed something broken? **You're a hero!**

The best learning happens when we learn from each other. Your advanced implementation might be the perfect example for the next cohort of participants! 🚀

*(Plus, the author would really appreciate not having to figure everything out alone.)* 😅

---

## 🎯 Challenge Overview

Welcome to the **deep end**! This challenge is for developers who want to build **production-ready** AI agents using code-first approaches from the start.

**The Ultimate Goal**: Build a customer service solution using **Azure AI Agent Framework** (or framework of choice) with enterprise patterns: proper error handling, telemetry, testing, state management, and deployment readiness.

**Your Choice**: Python, .NET, JavaScript, Go, or any framework/language you prefer. This is **your journey**.

---

## 💡 **Leverage Workshop Resources (Even If You Skipped the Other Challenges!)**

**Starting with Advanced? Great choice!** Here are valuable resources from the other challenges you can use:

### **System Prompts from Beginner Challenge**
- ✅ Pre-tested system prompt text for customer service agent
- ✅ Business rules already figured out (30-day delays, ticket categories)
- ✅ Conversation flows that work well
- 👉 **Use them directly in your code!** No need to reinvent prompts from scratch.

**Find them**: [Beginner Full Solution](../01-beginner/full-solution.md) has the complete, tested system prompt.

### **Multi-Agent Patterns from Intermediate Challenge**
- ✅ Orchestrator + specialist agent architecture
- ✅ Routing strategies (keyword vs LLM-based)
- ✅ Context handoff patterns
- 👉 **If you want to build multi-agent**: Check intermediate solutions for proven patterns.

**Find them**: [Intermediate Multi-Agent Solution](../02-intermediate/full-solution-multi-agent.md)

### **Test Scenarios (All Challenges)**
- ✅ Same test scenarios across all difficulty levels
- ✅ You can validate against beginner/intermediate implementations
- 👉 **See what "good" looks like** before you code it yourself.

**The Smart Approach**: Spend 5-10 minutes reviewing beginner system prompts and scenarios. It'll save you 30+ minutes of trial and error!

### **🤖 Use AI to Write Your Code!**

**GitHub Copilot is ESSENTIAL for this challenge!** You have 90 minutes to write production code—let AI help:

**GitHub Copilot Inline Suggestions:**
- Type comments describing what you need: `// Call get_orders MCP tool and parse response`
- Accept suggestions for boilerplate: HTTP clients, error handling, logging setup
- Speed through structure: class definitions, method signatures, config loading

**GitHub Copilot Chat:**
- "Write a Python function to call an MCP tool endpoint with retry logic"
- "How do I implement conversation memory in Semantic Kernel?"
- "Show me error handling best practices for async HTTP calls in C#"
- "Generate unit tests for this agent class"

**Copilot in VS Code Edits:**
- Select a block of code, ask Copilot to "add error handling and logging"
- Ask it to "refactor this to use dependency injection"
- Request "add type hints to this Python function"

**Pro Tip**: Spend 5 minutes setting up GitHub Copilot before starting to code. It will save you 30+ minutes!

---

## 🏆 The Challenge

### **Mission**

Build a customer service agent using **code-first development** that demonstrates production-ready engineering practices.

### **Freedom & Constraints**

**You Have Complete Freedom To**:
- ✅ Choose any programming language
- ✅ Use any AI framework (Agent Framework, LangChain, custom)
- ✅ Pick any model provider (Azure OpenAI, GitHub Models, others)
- ✅ Use the Fabrikam repo as reference or build from scratch
- ✅ Implement any architecture you prefer

**But You Must Demonstrate**:
- ✅ Code-first agent implementation (not no-code Copilot Studio)
- ✅ Integration with Fabrikam MCP tools
- ✅ Production-grade patterns (see below)

---

## ✅ Success Criteria

### **Basic Success (30 points)**

**Functional Agent**:
- ✅ Working agent responds to customer inquiries
- ✅ Calls at least 2 Fabrikam MCP tools successfully
- ✅ Code is organized and readable
- ✅ Basic error handling present

### **Good Success (60 points)**

**Production Patterns**:
- ✅ Comprehensive error handling with retries
- ✅ Structured logging throughout
- ✅ Configuration externalized (not hardcoded)
- ✅ State management implemented
- ✅ Tool responses properly parsed and used
- ✅ Tests present (unit or integration)

### **Excellent Success (100 points)**

**Enterprise-Grade Implementation**:
- ✅ Full telemetry (Application Insights or equivalent)
- ✅ Conversation memory/context persistence
- ✅ Comprehensive test coverage
- ✅ Deployment-ready configuration
- ✅ Documentation (README, setup instructions)
- ✅ Demonstrates advanced patterns (streaming, async, etc.)
- ✅ Handles edge cases gracefully
- ✅ Code follows best practices for chosen language

### **Bonus Features (up to 30 points)**

- 🌟 RAG implementation (policy documents, knowledge base)
- 🌟 Custom evaluators for quality assurance
- 🌟 Multi-agent orchestration in code
- 🌟 Streaming responses with token limits
- 🌟 Human-in-the-loop for sensitive operations
- 🌟 CI/CD pipeline ready
- 🌟 Containerized and ready to deploy
- 🌟 Performance optimization (caching, batching)

---

## 🛠️ Recommended Technology Stacks

### **Option 1: Python + Azure AI Agent Framework**

```python
# Example structure
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

# Initialize client
project_client = AIProjectClient.from_connection_string(
    credential=DefaultAzureCredential(),
    conn_str="your-project-connection-string"
)

# Create agent with custom tools
agent = project_client.agents.create_agent(
    model="gpt-4o",
    name="fabrikam-cs-agent",
    instructions=load_instructions(),
    tools=[
        {"type": "function", "function": get_orders_tool},
        {"type": "function", "function": create_ticket_tool}
    ]
)
```

**Pros**: 
- Rich ecosystem, Azure integration
- Agent Framework is Python-first
- Great for ML/AI developers

**Resources**:
- [Azure AI Agent Service](https://learn.microsoft.com/azure/ai-services/agents/)
- [Python SDK Docs](https://learn.microsoft.com/python/api/overview/azure/ai-projects)

---

### **Option 2: .NET + Semantic Kernel / Agent Framework**

```csharp
// Example structure
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;

// Build kernel with tools
var kernel = Kernel.CreateBuilder()
    .AddAzureOpenAIChatCompletion(deploymentName, endpoint, apiKey)
    .Build();

// Register MCP tools as plugins
kernel.ImportPluginFromObject(new FabrikamTools(httpClient));

// Create agent
var agent = new ChatCompletionAgent
{
    Name = "FabrikamCS",
    Instructions = LoadInstructions(),
    Kernel = kernel
};
```

**Pros**:
- Aligns with Fabrikam codebase
- Type safety, performance
- Enterprise .NET patterns

**Resources**:
- [Semantic Kernel](https://learn.microsoft.com/semantic-kernel/)
- [.NET Agent Framework](https://learn.microsoft.com/dotnet/ai/agents)

---

### **Option 3: JavaScript/TypeScript**

```typescript
// Example structure
import { OpenAI } from 'openai';

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const tools = [
  {
    type: "function",
    function: {
      name: "get_orders",
      description: "Look up customer orders",
      parameters: { /* schema */ }
    }
  }
];

const response = await client.chat.completions.create({
  model: "gpt-4o",
  messages: conversationHistory,
  tools: tools,
});
```

**Pros**:
- Familiar web stack
- Great for full-stack integration
- Fast prototyping

---

### **Option 4: Custom Framework**

Build your own agent orchestration:
- Use any LLM API directly
- Implement custom tool calling
- Full control over every aspect

**For the bold!**

---

## 🧪 Required Functionality

Your agent must demonstrate these capabilities:

### **1. MCP Tool Integration**
```
✅ Call Fabrikam MCP endpoints
✅ Parse responses correctly
✅ Handle tool errors gracefully
✅ Use tool responses in conversation
```

### **2. Conversation Management**
```
✅ Multi-turn conversations
✅ Maintain context across turns
✅ Handle topic changes
✅ Graceful conversation closure
```

### **3. Error Handling**
```
✅ Network failures (retry logic)
✅ Invalid tool responses
✅ LLM errors or rate limits
✅ User input validation
```

### **4. Observability**
```
✅ Structured logging
✅ Trace conversation flow
✅ Monitor tool calls
✅ Track errors and performance
```

---

## 📋 Test Scenarios

Your agent should handle these (same as beginner, but in code):

### **Scenario 1: Order Lookup**
```
Input: "What's the status of order FAB-2025-015?"
Expected: 
- Call get_orders tool
- Parse response
- Provide formatted answer
- Log the interaction
```

### **Scenario 2: Delayed Order Detection**
```
Input: "My order hasn't arrived and it's been 50 days"
Expected:
- Look up order
- Analyze timeline in code
- Automatically call create_support_ticket
- Return ticket number
- Log escalation
```

### **Scenario 3: Error Handling**
```
Input: "Check order FAB-2025-999"
Expected:
- Gracefully handle not found
- Don't crash or expose errors
- Offer alternative lookup methods
- Log the failed lookup
```

---

## 🏗️ Architecture Patterns to Consider

### **Pattern 1: Clean Separation**
```
/src
  /agents        # Agent definitions
  /tools         # MCP tool wrappers
  /services      # Business logic
  /models        # Data models
  /config        # Configuration
  /tests         # Unit & integration tests
```

### **Pattern 2: Dependency Injection**
```python
# Make components testable and swappable
class FabrikamAgent:
    def __init__(
        self, 
        llm_client: LLMClient,
        mcp_client: MCPClient,
        logger: Logger,
        config: Config
    ):
        self.llm = llm_client
        self.mcp = mcp_client
        self.logger = logger
        self.config = config
```

### **Pattern 3: Tool Abstraction**
```typescript
interface Tool {
  name: string;
  description: string;
  execute(params: any): Promise<ToolResult>;
  handleError(error: Error): ToolResult;
}

class GetOrdersTool implements Tool {
  async execute(params: { orderId: number }) {
    // Implementation with error handling
  }
}
```

---

## 💡 Hints & Tips

### **Starting Points**

1. **Copy your system prompt** from beginner/intermediate agent (don't reinvent!)
2. **Set up your dev environment**
   - API keys, endpoints
   - Local testing setup
   - **GitHub Copilot enabled** ⚡
3. **Start simple**: Basic LLM call with one tool
4. **Iterate**: Add features incrementally (just like beginner!)
5. **Test frequently**: Don't build everything then test

### **The Iteration Mindset (Code Edition)** 🔄

**Just like beginner, code-first agents require iteration!**

**The Process:**
1. **Get one thing working** - Simple agent responds to input
2. **Add one tool** - Get get_orders working end-to-end
3. **Test and debug** - Fix issues, add error handling
4. **Add logging** - See what's happening
5. **Add second tool** - Now that pattern works
6. **Refine and polish** - Better errors, tests, config
7. **Repeat** - Each iteration adds capability

**Don't aim for perfection in one pass!** Production-grade code emerges through testing and refinement.

### **Time Management (90 minutes)**

**⚠️ Reality Check**: 90 minutes for production-grade code is TIGHT!

**Suggested Approach - Be Strategic:**

**Minutes 0-10: Setup & Planning**
- Choose your language/framework
- Set up project structure
- Enable GitHub Copilot
- Review your beginner system prompt

**Minutes 10-40: Core Functionality** (Priority 1)
- ✅ Basic agent responds
- ✅ One MCP tool working (get_orders)
- ✅ Parse and use tool response
- ✅ Simple conversation loop

**Minutes 40-65: Production Patterns** (Priority 2)
- ✅ Error handling (network failures, invalid responses)
- ✅ Structured logging
- ✅ Configuration externalized
- ✅ Add second MCP tool (create_support_ticket)

**Minutes 65-85: Polish** (Priority 3)
- ✅ Tests (at least smoke tests)
- ✅ README with setup instructions
- ✅ Better error messages
- ✅ Code cleanup

**Minutes 85-90: Final Testing & Demo Prep**
- ✅ Run all scenarios
- ✅ Prepare to show code

**What to Skip if Time is Tight:**
- ❌ Full telemetry integration (basic logging is enough)
- ❌ Complex state persistence (in-memory is fine)
- ❌ Comprehensive test suite (focus on working code)
- ❌ RAG/advanced features (bonus only if time permits)

**Remember**: A simple agent that works with good error handling beats a complex agent that doesn't work!

### **Common Pitfalls**

❌ **Hardcoding credentials** → Use environment variables  
❌ **No error handling** → Network always fails eventually  
❌ **Ignoring tool responses** → Parse and use the data!  
❌ **No logging** → Can't debug without visibility  
❌ **Skipping tests** → Confidence requires validation  
❌ **Over-engineering** → In 90 min, simple > complex!

---

## 📚 Resources

### **Official Documentation**
- [Azure AI Agent Service](https://learn.microsoft.com/azure/ai-services/agents/)
- [Semantic Kernel](https://learn.microsoft.com/semantic-kernel/)
- [LangChain](https://python.langchain.com/docs/get_started/introduction)
- [OpenAI Assistants API](https://platform.openai.com/docs/assistants/overview)

### **Fabrikam Resources**
- **GitHub Repo**: Your proctor can share the Fabrikam-Project repo URL
- **MCP Server URL**: Your team's deployment
- **API Documentation**: Swagger at `/swagger/index.html`
- **Your Previous Work**: Beginner/intermediate system prompts and test conversations!

### **Code Samples**
- [Agent Framework Samples](https://github.com/Azure-Samples/azureai-samples)
- [Semantic Kernel Samples](https://github.com/microsoft/semantic-kernel/tree/main/python/samples)
- [OpenAI Cookbook](https://github.com/openai/openai-cookbook)

### **AI Coding Assistants**
- **GitHub Copilot**: Your coding partner for this challenge!
- **Copilot Chat**: Architecture questions, debugging, refactoring
- **Copilot in IDE**: Inline suggestions, boilerplate generation

---

## 💡 **Workshop Resources for Advanced Challenge**

### **Guidance Documents** 

**💡 Hints & Tips** - Production patterns without spoilers  
[→ View Hints](./hints.md)

**🏗️ Reference Architecture** - Language-agnostic production patterns  
[→ View Reference Architecture](./reference-architecture.md)

### **Code Examples**

**Real Production Code**: The Fabrikam-Project repo itself!
- **Location**: Ask proctor for repo URL
- **What to look at**:
  - `FabrikamApi/` - ASP.NET Core Web API patterns
  - `FabrikamMcp/` - MCP server implementation
  - `FabrikamTests/` - Testing patterns
  - Clean architecture, dependency injection, comprehensive logging

**Pro Tip**: Clone the Fabrikam repo and explore the code structure. It's a great reference for production patterns!

---

## 📊 Evaluation Criteria

### **Code Quality (30%)**
- Organization and structure
- Readability and maintainability
- Best practices for language
- Documentation

### **Functionality (30%)**
- Agent works correctly
- Tools integrated properly
- Handles test scenarios
- Business logic correct

### **Production Readiness (30%)**
- Error handling comprehensive
- Logging and telemetry
- Configuration management
- Testing present

### **Innovation (10%)**
- Creative solutions
- Advanced patterns
- Going beyond requirements
- Polish and UX

---

## 🎓 What You'll Learn

By completing this challenge, you'll master:
- ✅ **Code-first agent development** - Beyond no-code tools
- ✅ **Production patterns** - Error handling, logging, testing
- ✅ **Tool integration** - Wrapping external APIs as agent tools
- ✅ **State management** - Conversation history and context
- ✅ **Deployment thinking** - Configuration, monitoring, CI/CD
- ✅ **Real-world engineering** - The gap between demo and production

---

## 🏁 Submission

When you're done (or time's up!):

1. **Push your code** to a GitHub repo (public or share with proctors)
2. **Include README** with:
   - Setup instructions
   - How to run
   - What you implemented
   - What you'd add with more time
3. **Demo to proctor** (5 min walkthrough)
4. **Reflect**: What was hardest? What would you change?

---

## 💬 Final Thoughts

This is **your chance to shine**! We're not looking for perfection—we're looking for:
- 💪 Problem-solving skills
- 🧠 Engineering thinking
- 🚀 Production awareness
- 🎨 Creativity and polish

**90 minutes isn't much time**. Focus on:
1. ✅ Getting something working
2. ✅ Demonstrating key patterns
3. ✅ Showing your best work

**Good luck, and have fun building!** 🚀

---

## 🆘 Need Help?

- **Proctors are here!** We can help with:
  - Architecture decisions
  - Debugging
  - API questions
  - Time management

- **Fabrikam Repo Access**: Available as reference
- **MCP Server**: Your team's instance is deployed and ready

**Don't struggle alone—ask for help!**
