# 💡 Advanced Challenge: Hints & Tips

**Production-Ready Agent Development Patterns**

These hints provide guidance without giving away complete solutions. Use them when you're stuck or want to validate your approach!

---

## 🏗️ Architecture Patterns

### **Project Structure**

**Pattern: Clean Separation of Concerns**

```
/your-agent-project
  /src
    /agent           # Agent definition and orchestration
    /tools           # MCP tool wrappers
    /services        # Business logic (delay detection, ticket creation)
    /models          # Data models and DTOs
    /config          # Configuration management
  /tests
    /unit            # Unit tests
    /integration     # Integration tests
  /docs              # Documentation
  .env.example       # Environment variable template
  README.md          # Setup and usage instructions
```

**Why This Matters**: Clean separation makes code testable, maintainable, and easier to debug.

---

## 🔧 MCP Tool Integration

### **Pattern 1: Tool Wrapper Classes**

**Hint**: Don't call HTTP endpoints directly in your agent code. Wrap them!

**Benefits**:
- ✅ Centralized error handling
- ✅ Retry logic in one place
- ✅ Easy to mock for testing
- ✅ Type safety and validation

**Example Structure** (language-agnostic):
```
class GetOrdersTool:
    def __init__(http_client, base_url, logger):
        # Store dependencies
    
    async def execute(order_id):
        # Call MCP endpoint
        # Handle errors
        # Parse response
        # Return structured data
    
    def _handle_error(error):
        # Retry logic
        # Logging
        # Meaningful error messages
```

### **Pattern 2: Tool Response Parsing**

**Hint**: MCP tools return JSON. Parse it into strongly-typed objects!

**Anti-Pattern** ❌:
```python
# Don't do this - too fragile!
order_date = response['orderDate']
status = response['status']
```

**Better Pattern** ✅:
```python
class Order:
    order_id: str
    customer_id: int
    order_date: datetime
    delivery_date: Optional[datetime]
    status: str
    total: float

order = Order.from_json(response)
```

**Why**: Type safety catches errors early, makes code self-documenting.

---

## 🛡️ Error Handling

### **Pattern: Layered Error Handling**

**Layer 1: Network/HTTP Errors**
```
- Connection failures → Retry with exponential backoff
- Timeouts → Log and return user-friendly message
- 404 Not Found → Valid business case, not an error
- 500 Server Error → Retry limited times, then fail gracefully
```

**Layer 2: Tool Response Errors**
```
- Empty results → "Order not found, try searching by email?"
- Invalid data → Log warning, ask user to try again
- Missing fields → Use defaults or prompt for clarification
```

**Layer 3: LLM Errors**
```
- Rate limits → Exponential backoff, queue requests
- Token limits → Summarize context, truncate if needed
- Invalid tool calls → Log and ask LLM to try again
```

### **Pattern: Retry Logic**

**Hint**: Not all errors should retry!

**Retry These**:
- ✅ Network timeouts
- ✅ 503 Service Unavailable
- ✅ 429 Rate Limit
- ✅ Temporary connection failures

**Don't Retry These**:
- ❌ 400 Bad Request (fix the request instead)
- ❌ 401 Unauthorized (auth issue, not transient)
- ❌ 404 Not Found (valid business case)
- ❌ Invalid JSON responses (broken API, not transient)

---

## 📊 Logging & Observability

### **Pattern: Structured Logging**

**Hint**: Use structured logs, not string concatenation!

**Anti-Pattern** ❌:
```python
logger.info("User asked about order " + order_id + " and it was " + status)
```

**Better Pattern** ✅:
```python
logger.info(
    "Order status inquiry",
    extra={
        "order_id": order_id,
        "status": status,
        "customer_id": customer_id,
        "action": "order_lookup"
    }
)
```

**Why**: Structured logs are searchable, filterable, and analyzable.

### **What to Log**

**✅ Always Log**:
- Tool calls (what tool, what parameters)
- Tool responses (success/failure, latency)
- Errors and exceptions
- Business events (ticket created, delay detected)
- User intents (what they're asking for)

**❌ Never Log**:
- API keys or secrets
- Full customer data (PII concerns)
- Credit card numbers
- Passwords

**⚠️ Log Carefully** (consider privacy):
- Customer names (use customer_id instead)
- Email addresses (hash them)
- Order details (log IDs, not full content)

---

## 🧪 Testing Strategies

### **Pattern: Test Pyramid**

**Layer 1: Unit Tests** (Fast, Many)
```
✅ Tool parsers (JSON → Objects)
✅ Business logic (delay detection algorithm)
✅ Error handlers (retry logic)
✅ Validators (input validation)
```

**Layer 2: Integration Tests** (Medium, Some)
```
✅ Tool calls to real/mock MCP server
✅ Agent processes conversation
✅ End-to-end scenario (order lookup)
```

**Layer 3: Manual Tests** (Slow, Few)
```
✅ Full conversation flows
✅ Edge cases and unusual inputs
✅ User experience validation
```

### **Pattern: Mock MCP Tools for Testing**

**Hint**: Don't call real MCP server in unit tests!

**Example Approach**:
```python
class MockMCPClient:
    def get_orders(self, order_id):
        # Return canned test data
        if order_id == "FAB-2025-015":
            return {
                "orderId": "FAB-2025-015",
                "status": "InProduction",
                "orderDate": "2024-01-15",
                # ... test data
            }
        raise NotFoundException("Order not found")
```

**Why**: Fast, deterministic, no network dependency.

---

## ⚙️ Configuration Management

### **Pattern: Environment-Based Config**

**Hint**: Never hardcode URLs, API keys, or environment-specific values!

**Configuration Hierarchy**:
1. **Environment Variables** (highest priority)
   - `MCP_BASE_URL=https://mcp.fabrikam.com`
   - `OPENAI_API_KEY=sk-...`
   - `LOG_LEVEL=INFO`

2. **Config Files** (development defaults)
   - `config.json` or `appsettings.json`
   - `config.dev.json` vs `config.prod.json`

3. **Code Defaults** (fallbacks)
   - Reasonable defaults for optional settings

**Example Pattern**:
```python
class Config:
    def __init__(self):
        self.mcp_base_url = os.getenv(
            'MCP_BASE_URL',
            'https://localhost:7297'  # Dev default
        )
        self.log_level = os.getenv('LOG_LEVEL', 'INFO')
        self.retry_attempts = int(os.getenv('RETRY_ATTEMPTS', '3'))
```

---

## 🧠 Conversation State Management

### **Pattern 1: In-Memory State** (Simple, Good for Workshop)

```python
class ConversationManager:
    def __init__(self):
        self.conversations = {}  # Dict[conversation_id, messages]
    
    def add_message(self, conv_id, message):
        if conv_id not in self.conversations:
            self.conversations[conv_id] = []
        self.conversations[conv_id].append(message)
    
    def get_history(self, conv_id):
        return self.conversations.get(conv_id, [])
```

**Pros**: Simple, fast, works for demo
**Cons**: Lost on restart, not scalable

### **Pattern 2: Persistent State** (Production)

**Options**:
- Redis (fast, distributed)
- Database (reliable, queryable)
- Azure Cosmos DB (global, scalable)
- File system (simple, local dev)

**Hint**: Start with in-memory for workshop, mention persistence for production!

---

## 🚀 Agent Framework Integration

### **Pattern: Framework-Agnostic Tool Definition**

**Hint**: Define tools in a way that works across frameworks!

**Common Structure**:
```
Tool Definition:
  - name: "get_orders"
  - description: "Look up customer orders by order ID"
  - parameters:
      - order_id (required, string): "The order ID to look up"
  - function: async callable that returns result
```

**This maps to**:
- OpenAI function calling
- Azure AI Agent Service tools
- Semantic Kernel plugins
- LangChain tools
- Custom implementations

### **Pattern: System Prompt Reuse**

**Hint**: The system prompt you wrote for Copilot Studio? Use it here!

```python
SYSTEM_PROMPT = """
You are Alex, a friendly customer service agent for Fabrikam Modular Homes.

[... copy your refined prompt from beginner challenge ...]

When delivery is over 30 days past order date, IMMEDIATELY create a support ticket.
"""

agent = create_agent(
    instructions=SYSTEM_PROMPT,
    tools=[get_orders_tool, create_ticket_tool, ...]
)
```

**Why**: You already tested and refined it—don't reinvent!

---

## ⚡ Performance Optimization

### **Pattern: Async/Await**

**Hint**: Use async for I/O operations (HTTP calls, LLM requests)

**Anti-Pattern** ❌:
```python
# Blocks while waiting for response
response1 = requests.get(url1)
response2 = requests.get(url2)  # Waits for first to finish!
```

**Better Pattern** ✅:
```python
# Both requests happen in parallel
response1, response2 = await asyncio.gather(
    http_client.get(url1),
    http_client.get(url2)
)
```

**Why**: Faster response times, better resource utilization.

### **Pattern: Caching**

**When to Cache**:
- ✅ Product catalog (changes rarely)
- ✅ Customer information (within conversation)
- ✅ Business rules (static data)

**When NOT to Cache**:
- ❌ Order status (changes frequently)
- ❌ Support tickets (real-time data)
- ❌ User input (unique every time)

---

## 🎯 Business Logic Implementation

### **Delay Detection Algorithm**

**Hint**: You figured this out in beginner—implement it in code!

**Algorithm**:
```
1. Get order_date from order
2. Calculate days_since_order = today - order_date
3. If days_since_order > 30 AND status != "Delivered":
   4. Set is_delayed = True
   5. Create support ticket
   6. Notify customer
```

**Code Pattern**:
```python
def check_for_delays(order: Order) -> bool:
    days_since_order = (datetime.now() - order.order_date).days
    
    if days_since_order > 30 and order.status != "Delivered":
        logger.warning(
            "Delayed order detected",
            extra={
                "order_id": order.order_id,
                "days_since_order": days_since_order,
                "status": order.status
            }
        )
        return True
    
    return False
```

---

## 🔐 Security Best Practices

### **Pattern: Secrets Management**

**Never Do This** ❌:
```python
API_KEY = "sk-1234567890abcdef"  # Hardcoded!
```

**Better Approaches** ✅:

**Option 1: Environment Variables**
```python
API_KEY = os.getenv("OPENAI_API_KEY")
if not API_KEY:
    raise ValueError("OPENAI_API_KEY not set")
```

**Option 2: Azure Key Vault**
```python
from azure.keyvault.secrets import SecretClient

secret_client = SecretClient(vault_url, credential)
api_key = secret_client.get_secret("openai-api-key").value
```

**Option 3: Configuration Files** (excluded from git!)
```python
# .gitignore includes secrets.json
with open('secrets.json') as f:
    secrets = json.load(f)
    api_key = secrets['openai_api_key']
```

---

## 📦 Deployment Readiness

### **Checklist: Is Your Agent Production-Ready?**

**Code Quality**:
- [ ] No hardcoded secrets
- [ ] Environment-based configuration
- [ ] Proper error handling
- [ ] Structured logging
- [ ] Type hints/annotations (if language supports)

**Functionality**:
- [ ] All MCP tools integrated
- [ ] Business logic implemented (delay detection, etc.)
- [ ] Edge cases handled
- [ ] User-friendly error messages

**Testing**:
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Test coverage > 50% (ideally)

**Documentation**:
- [ ] README with setup instructions
- [ ] Environment variable documentation
- [ ] API documentation (if exposing endpoints)
- [ ] Known limitations documented

**Observability**:
- [ ] Logging configured
- [ ] Health check endpoint (if web service)
- [ ] Metrics exposed (if applicable)
- [ ] Alerts configured (production)

**Deployment**:
- [ ] Dependencies documented (requirements.txt, package.json, etc.)
- [ ] Dockerfile present (if containerizing)
- [ ] CI/CD pipeline configured (bonus)
- [ ] Rollback plan documented

---

## 💡 Quick Wins for This Challenge

**If time is limited, focus on these high-value items**:

**Must Have** (Priority 1):
1. ✅ One MCP tool working end-to-end
2. ✅ Basic error handling (try/catch)
3. ✅ Logging tool calls and responses
4. ✅ README with run instructions

**Should Have** (Priority 2):
5. ✅ Second MCP tool integrated
6. ✅ Retry logic for network failures
7. ✅ Configuration externalized
8. ✅ One smoke test

**Nice to Have** (Priority 3):
9. ✅ All tools integrated
10. ✅ Comprehensive tests
11. ✅ Deployment artifacts (Dockerfile)
12. ✅ Advanced features

**Remember**: Working simple code beats broken complex code!

---

## 🎓 Learning Resources

**Async/Await Patterns**:
- Python: [asyncio documentation](https://docs.python.org/3/library/asyncio.html)
- C#: [async/await guide](https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/)
- JavaScript: [Promises and async/await](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function)

**Testing**:
- Python: pytest, unittest
- C#: xUnit, NUnit, MSTest
- JavaScript: Jest, Mocha

**Logging**:
- Python: structlog, python-json-logger
- C#: Serilog, NLog
- JavaScript: winston, pino

**HTTP Clients**:
- Python: httpx (async), requests (sync)
- C#: HttpClient
- JavaScript: axios, fetch

---

**Need More Help?** Ask your proctor! We're here to help you succeed. 🚀
