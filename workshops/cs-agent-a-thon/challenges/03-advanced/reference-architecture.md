# 🏗️ Reference Architecture: Production-Ready AI Agents

**Language-Agnostic Patterns for Enterprise Agent Development**

This document outlines production-ready architecture patterns for building AI agents with code. Use this as a reference for structuring your solution!

---

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                            │
│              (CLI, Web API, Chat Interface, etc.)                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Orchestration Layer                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Agent Controller                                         │  │
│  │  - Manages conversation state                            │  │
│  │  - Routes user input to agent                            │  │
│  │  - Handles streaming responses                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Agent Core                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │   System     │  │ LLM Client   │  │ Tool Registry      │   │
│  │   Prompt     │  │ (GPT-4, etc.)│  │ (MCP Tools)        │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Delay        │  │ Ticket       │  │ Order Analysis     │   │
│  │ Detection    │  │ Creation     │  │ Service            │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Tool Integration Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ GetOrders    │  │ GetProducts  │  │ CreateTicket       │   │
│  │ Tool         │  │ Tool         │  │ Tool               │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬─────────────┘   │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                 │
│                            │                                     │
│                  ┌─────────▼──────────┐                         │
│                  │   HTTP Client       │                         │
│                  │  (Retry, Logging)   │                         │
│                  └─────────┬──────────┘                         │
└────────────────────────────┼────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────────┐
                    │   Fabrikam MCP     │
                    │   Server           │
                    │  (External API)    │
                    └────────────────────┘

                             │
                    Cross-Cutting Concerns
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
         │ Logging │   │ Config  │   │ Metrics │
         └─────────┘   └─────────┘   └─────────┘
```

---

## 📁 Project Structure

### **Recommended File Organization**

```
/fabrikam-agent
├── /src
│   ├── /agent
│   │   ├── agent.py / Agent.cs / agent.ts
│   │   ├── system_prompt.py / SystemPrompt.cs / systemPrompt.ts
│   │   └── conversation_manager.py / ConversationManager.cs / conversationManager.ts
│   │
│   ├── /tools
│   │   ├── base_tool.py / ITool.cs / Tool.ts (interface/base class)
│   │   ├── get_orders_tool.py / GetOrdersTool.cs / getOrdersTool.ts
│   │   ├── get_products_tool.py / GetProductsTool.cs / getProductsTool.ts
│   │   ├── get_customers_tool.py / GetCustomersTool.cs / getCustomersTool.ts
│   │   └── create_ticket_tool.py / CreateTicketTool.cs / createTicketTool.ts
│   │
│   ├── /services
│   │   ├── delay_detection_service.py / DelayDetectionService.cs / delayDetectionService.ts
│   │   ├── ticket_service.py / TicketService.cs / ticketService.ts
│   │   └── order_analysis_service.py / OrderAnalysisService.cs / orderAnalysisService.ts
│   │
│   ├── /models
│   │   ├── order.py / Order.cs / order.ts
│   │   ├── product.py / Product.cs / product.ts
│   │   ├── customer.py / Customer.cs / customer.ts
│   │   └── support_ticket.py / SupportTicket.cs / supportTicket.ts
│   │
│   ├── /infrastructure
│   │   ├── http_client.py / HttpClient.cs / httpClient.ts
│   │   ├── logger.py / Logger.cs / logger.ts
│   │   └── config.py / Config.cs / config.ts
│   │
│   └── main.py / Program.cs / index.ts (entry point)
│
├── /tests
│   ├── /unit
│   │   ├── test_delay_detection.py / DelayDetectionTests.cs / delayDetection.test.ts
│   │   ├── test_tools.py / ToolsTests.cs / tools.test.ts
│   │   └── test_services.py / ServicesTests.cs / services.test.ts
│   │
│   └── /integration
│       ├── test_agent_scenarios.py / AgentScenariosTests.cs / agentScenarios.test.ts
│       └── test_mcp_integration.py / McpIntegrationTests.cs / mcpIntegration.test.ts
│
├── /docs
│   ├── README.md
│   ├── SETUP.md
│   └── DEPLOYMENT.md
│
├── /config
│   ├── config.dev.json (development settings)
│   └── config.prod.json (production settings)
│
├── .env.example (environment variable template)
├── .gitignore
├── requirements.txt / packages.config / package.json
├── Dockerfile (optional)
└── README.md
```

---

## 🧩 Component Details

### **1. Agent Core**

**Responsibilities**:
- Load and manage system prompt
- Coordinate with LLM
- Decide when to call tools
- Process tool results
- Maintain conversation context

**Key Patterns**:
```python
class FabrikamAgent:
    def __init__(
        self,
        llm_client: LLMClient,
        tools: List[Tool],
        config: Config,
        logger: Logger
    ):
        self.llm = llm_client
        self.tools = {tool.name: tool for tool in tools}
        self.config = config
        self.logger = logger
        self.system_prompt = load_system_prompt()
    
    async def process_message(
        self,
        user_message: str,
        conversation_id: str
    ) -> AgentResponse:
        # Add user message to conversation
        # Get LLM response
        # Check if tools should be called
        # Execute tools if needed
        # Get final response
        # Return to user
```

**Design Decisions**:
- ✅ **Dependency Injection**: All dependencies passed to constructor (testable!)
- ✅ **Async by Default**: All I/O operations are async
- ✅ **Tool Registry**: Tools registered by name for easy lookup
- ✅ **Separation**: Agent orchestrates, doesn't implement business logic

---

### **2. Tool Integration Layer**

**Responsibilities**:
- Wrap MCP HTTP endpoints
- Handle network errors and retries
- Parse and validate responses
- Provide typed interfaces

**Key Patterns**:
```python
class BaseTool:
    def __init__(self, http_client: HttpClient, config: Config, logger: Logger):
        self.http = http_client
        self.config = config
        self.logger = logger
    
    @abstractmethod
    async def execute(self, **params) -> ToolResult:
        pass
    
    async def _call_mcp_endpoint(
        self,
        endpoint: str,
        params: Dict
    ) -> Dict:
        try:
            response = await self.http.get(
                f"{self.config.mcp_base_url}/{endpoint}",
                params=params,
                timeout=self.config.http_timeout
            )
            return response.json()
        except HTTPError as e:
            self.logger.error(f"MCP call failed: {endpoint}", error=e)
            raise ToolExecutionError(f"Failed to call {endpoint}")

class GetOrdersTool(BaseTool):
    name = "get_orders"
    description = "Look up customer orders by order ID or email"
    
    async def execute(self, order_id: str = None, email: str = None) -> ToolResult:
        if order_id:
            data = await self._call_mcp_endpoint("api/orders", {"id": order_id})
        elif email:
            data = await self._call_mcp_endpoint("api/orders", {"email": email})
        else:
            raise ValueError("Must provide order_id or email")
        
        order = Order.from_dict(data)
        return ToolResult(success=True, data=order)
```

**Design Decisions**:
- ✅ **Base Class**: Common functionality (HTTP calls, error handling) in base
- ✅ **Specific Tools**: Each tool knows its endpoint and parsing logic
- ✅ **Type Safety**: Return strongly-typed models, not raw JSON
- ✅ **Error Isolation**: Tool failures don't crash the agent

---

### **3. Business Logic Layer**

**Responsibilities**:
- Implement business rules (delay detection, ticket categorization)
- Analyze tool results
- Make business decisions
- Provide clean interfaces for agent

**Key Patterns**:
```python
class DelayDetectionService:
    STANDARD_PRODUCTION_DAYS = 30
    
    def __init__(self, logger: Logger):
        self.logger = logger
    
    def is_order_delayed(self, order: Order) -> DelayAnalysis:
        """
        Analyze if order is delayed based on business rules.
        """
        if order.status == "Delivered":
            return DelayAnalysis(is_delayed=False, reason="Already delivered")
        
        days_since_order = (datetime.now() - order.order_date).days
        
        if days_since_order > self.STANDARD_PRODUCTION_DAYS:
            self.logger.warning(
                "Delayed order detected",
                order_id=order.order_id,
                days_elapsed=days_since_order
            )
            return DelayAnalysis(
                is_delayed=True,
                days_elapsed=days_since_order,
                reason=f"Order placed {days_since_order} days ago, still in {order.status}"
            )
        
        return DelayAnalysis(is_delayed=False, reason="Within normal timeline")

class TicketService:
    def __init__(self, create_ticket_tool: CreateTicketTool, logger: Logger):
        self.ticket_tool = create_ticket_tool
        self.logger = logger
    
    async def create_delay_ticket(
        self,
        order: Order,
        delay_analysis: DelayAnalysis
    ) -> SupportTicket:
        """
        Create support ticket for delayed order with proper categorization.
        """
        ticket = await self.ticket_tool.execute(
            customer_id=order.customer_id,
            category="OrderInquiry",
            priority="High",
            description=f"Order {order.order_id} delayed. {delay_analysis.reason}"
        )
        
        self.logger.info(
            "Delay ticket created",
            order_id=order.order_id,
            ticket_id=ticket.ticket_id
        )
        
        return ticket
```

**Design Decisions**:
- ✅ **Single Responsibility**: Each service has one clear purpose
- ✅ **Business Constants**: Named constants (STANDARD_PRODUCTION_DAYS) not magic numbers
- ✅ **Rich Return Types**: Return analysis objects, not just bool/string
- ✅ **Composable**: Services can use tools and other services

---

### **4. Data Models**

**Responsibilities**:
- Define data structures
- Validation
- Serialization/deserialization
- Type safety

**Key Patterns**:
```python
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class Order:
    order_id: str
    customer_id: int
    order_date: datetime
    delivery_date: Optional[datetime]
    status: str
    total: float
    items: List[OrderItem]
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Order':
        """Parse API response into Order object."""
        return cls(
            order_id=data['orderId'],
            customer_id=data['customerId'],
            order_date=datetime.fromisoformat(data['orderDate']),
            delivery_date=datetime.fromisoformat(data['deliveryDate']) 
                if data.get('deliveryDate') else None,
            status=data['status'],
            total=float(data['total']),
            items=[OrderItem.from_dict(item) for item in data.get('items', [])]
        )
    
    def to_dict(self) -> Dict:
        """Serialize Order for API calls."""
        return {
            'orderId': self.order_id,
            'customerId': self.customer_id,
            # ... etc
        }

@dataclass
class DelayAnalysis:
    is_delayed: bool
    days_elapsed: Optional[int] = None
    reason: str = ""
```

**Design Decisions**:
- ✅ **Immutable Where Possible**: Use dataclasses/records/readonly
- ✅ **Type Hints**: Full type annotations for IDE support and validation
- ✅ **Parse Methods**: from_dict/from_json for API responses
- ✅ **Serialize Methods**: to_dict/to_json for API requests

---

### **5. Configuration Management**

**Responsibilities**:
- Load configuration from files and environment
- Provide typed access to settings
- Handle environment-specific overrides

**Key Patterns**:
```python
class Config:
    def __init__(self):
        # Load from environment with fallbacks
        self.mcp_base_url = os.getenv(
            'MCP_BASE_URL',
            'https://localhost:7297'
        )
        
        self.openai_api_key = os.getenv('OPENAI_API_KEY')
        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY must be set")
        
        self.model_name = os.getenv('MODEL_NAME', 'gpt-4o')
        self.log_level = os.getenv('LOG_LEVEL', 'INFO')
        self.http_timeout = int(os.getenv('HTTP_TIMEOUT', '30'))
        self.max_retries = int(os.getenv('MAX_RETRIES', '3'))
    
    @classmethod
    def from_file(cls, config_path: str) -> 'Config':
        """Load configuration from JSON file."""
        with open(config_path) as f:
            config_data = json.load(f)
        
        config = cls()
        # Override with file values
        for key, value in config_data.items():
            if hasattr(config, key):
                setattr(config, key, value)
        
        return config
```

**.env.example** (for participants):
```bash
# MCP Server Configuration
MCP_BASE_URL=https://your-mcp-server.azurewebsites.net

# AI Model Configuration
OPENAI_API_KEY=your-api-key-here
MODEL_NAME=gpt-4o

# Application Settings
LOG_LEVEL=INFO
HTTP_TIMEOUT=30
MAX_RETRIES=3
```

**Design Decisions**:
- ✅ **Environment Variables First**: Easiest for deployment
- ✅ **Required vs Optional**: Fail fast if required config missing
- ✅ **Type Conversion**: Parse ints/bools from strings
- ✅ **Validation**: Check valid values at startup, not runtime

---

### **6. Logging & Observability**

**Responsibilities**:
- Structured logging
- Performance monitoring
- Error tracking
- Debugging support

**Key Patterns**:
```python
import structlog

logger = structlog.get_logger()

# Structured logging with context
logger.info(
    "Processing user message",
    conversation_id=conv_id,
    message_length=len(message),
    user_id=user_id
)

# Error logging with exception
try:
    result = await tool.execute()
except Exception as e:
    logger.error(
        "Tool execution failed",
        tool_name=tool.name,
        error=str(e),
        exc_info=True  # Include stack trace
    )
    raise

# Performance tracking
with logger.contextvars.bound_contextvars(operation="order_lookup"):
    start = time.time()
    result = await get_orders_tool.execute(order_id)
    duration = time.time() - start
    
    logger.info(
        "Tool execution completed",
        tool="get_orders",
        duration_ms=duration * 1000,
        success=result.success
    )
```

**What to Log**:
```
INFO  - Normal operations (tool calls, user requests, responses)
WARN  - Unusual but handled situations (delays detected, retries)
ERROR - Failures that need attention (tool errors, API failures)
DEBUG - Detailed debugging info (request/response payloads)
```

**Design Decisions**:
- ✅ **Structured**: JSON format, not strings (searchable, filterable)
- ✅ **Context**: Include relevant IDs (conversation, user, order)
- ✅ **Performance**: Log durations for optimization
- ✅ **Privacy**: Hash PII, never log secrets

---

## 🔄 Conversation Flow

**End-to-End Request Processing**:

```
1. User Input
   ↓
2. Agent receives message
   ↓
3. Agent adds to conversation history
   ↓
4. Agent sends to LLM with:
   - System prompt
   - Conversation history
   - Available tools
   ↓
5. LLM responds with:
   - Text response, OR
   - Tool call request
   ↓
6. If tool call requested:
   a. Agent looks up tool in registry
   b. Agent calls tool.execute(params)
   c. Tool calls MCP endpoint
   d. Tool parses response
   e. Tool returns result to agent
   f. Agent sends tool result to LLM
   g. LLM generates final response
   ↓
7. Agent returns response to user
   ↓
8. Response logged and stored
```

---

## 🧪 Testing Architecture

### **Test Structure**

```
Unit Tests (Fast, Isolated):
  ✅ Test individual functions/methods
  ✅ Mock all dependencies
  ✅ Focus on logic, not I/O
  
  Example:
    - test_delay_detection_with_30_day_order()
    - test_order_parsing_from_json()
    - test_ticket_creation_parameters()

Integration Tests (Slower, Real Connections):
  ✅ Test component interactions
  ✅ Use real or mock MCP server
  ✅ Test end-to-end scenarios
  
  Example:
    - test_agent_processes_order_lookup()
    - test_delayed_order_creates_ticket()
    - test_error_recovery_from_failed_tool()

Smoke Tests (Fastest, Deployment Validation):
  ✅ Basic health checks
  ✅ Configuration valid
  ✅ Can connect to dependencies
  
  Example:
    - test_agent_initializes()
    - test_mcp_server_reachable()
    - test_config_loads()
```

### **Mock Pattern for Testing**

```python
class MockMCPClient:
    """Mock MCP server for testing without network calls."""
    
    def __init__(self):
        self.orders = {
            "FAB-2025-015": {
                "orderId": "FAB-2025-015",
                "orderDate": "2024-01-15",
                "status": "InProduction",
                "total": 45000
            }
        }
    
    async def get_orders(self, order_id: str) -> Dict:
        if order_id in self.orders:
            return self.orders[order_id]
        raise NotFoundException(f"Order {order_id} not found")

# In test
async def test_order_lookup():
    mock_client = MockMCPClient()
    tool = GetOrdersTool(http_client=mock_client, ...)
    
    result = await tool.execute(order_id="FAB-2025-015")
    
    assert result.success
    assert result.data.order_id == "FAB-2025-015"
```

---

## 🚀 Deployment Considerations

### **Environment Setup**

**Development**:
```bash
# Local MCP server
MCP_BASE_URL=https://localhost:7297
LOG_LEVEL=DEBUG
```

**Production**:
```bash
# Deployed MCP server
MCP_BASE_URL=https://fabrikam-mcp.azurewebsites.net
LOG_LEVEL=INFO
# Key Vault for secrets
KEYVAULT_URL=https://fabrikam-kv.vault.azure.net
```

### **Containerization** (Optional)

**Dockerfile**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/

CMD ["python", "src/main.py"]
```

### **Health Check Endpoint**

```python
@app.get("/health")
async def health_check():
    """Simple health check for deployment monitoring."""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "mcp_connection": await check_mcp_connection()
    }
```

---

## 📊 Success Metrics

**How to measure if your architecture is production-ready**:

**Code Quality**:
- ✅ No hardcoded secrets or URLs
- ✅ All dependencies injectable
- ✅ Clear separation of concerns
- ✅ Type hints/annotations throughout

**Reliability**:
- ✅ Comprehensive error handling
- ✅ Retry logic for transient failures
- ✅ Graceful degradation
- ✅ No crashes on bad input

**Observability**:
- ✅ Structured logging throughout
- ✅ Performance metrics tracked
- ✅ Error rates monitored
- ✅ Debug-friendly logs

**Maintainability**:
- ✅ Clear project structure
- ✅ README with setup instructions
- ✅ Tests provide confidence
- ✅ Configuration externalized

---

## 🎯 Workshop Focus Areas

**In 90 minutes, prioritize**:

1. **Core Structure** (30 min)
   - Project folders organized
   - Config loading works
   - Basic logging setup

2. **One Tool Working** (20 min)
   - get_orders tool implemented
   - HTTP client with retry
   - Parse response to model

3. **Agent Integration** (20 min)
   - Agent can call tool
   - Process tool result
   - Return response

4. **Polish** (20 min)
   - Error handling
   - README documentation
   - One smoke test

**Don't stress about perfect**:
- Full test coverage (>50% is great!)
- Advanced features (RAG, streaming)
- Complete deployment pipeline
- All 4 tools (2-3 is excellent!)

---

## 💡 Final Architecture Tips

**Keep It Simple**:
- Start with minimal structure, add complexity as needed
- In-memory state is fine for workshop
- Basic logging beats no logging

**Make It Testable**:
- Dependency injection enables testing
- Separate business logic from I/O
- Mock external dependencies

**Make It Observable**:
- Log key events
- Include context (IDs, parameters)
- Track performance

**Make It Configurable**:
- No hardcoded values
- Environment-based config
- Document required settings

---

**This architecture gives you a solid foundation. Adapt it to your language, framework, and style!** 🏗️
