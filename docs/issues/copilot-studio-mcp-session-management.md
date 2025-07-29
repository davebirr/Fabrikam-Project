# 🔄 Copilot Studio MCP Session Management Issue

**Issue ID**: #CSMC-001  
**Date Created**: July 29, 2025  
**Reporter**: David B.  
**Priority**: Medium  
**Status**: Documented - Pending Implementation  
**Affects**: Copilot Studio integration with deployed MCP server  

---

## 📋 **Issue Summary**

Copilot Studio experiences **MCP session timeout/expiration issues** when testing the deployed Fabrikam MCP server after extended chat sessions. The error manifests as JSON-RPC "Session not found" responses, but is resolved by starting a new chat session.

## 🔍 **Error Details**

### **Error Response**
```json
{
  "reasonCode": "RequestFailure",
  "errorMessage": "Connector request failed",
  "HttpStatusCode": "notFound", 
  "errorResponse": "[{\"jsonrpc\":\"2.0\",\"id\":\"\",\"error\":{\"Code\":-32001,\"Message\":\"Session not found\"}}]",
  "dialogSchemaName": "cr2d1_fabrikamBusinessAssistant2.action.MCP-Streamable-HTTP-MCPServerStreamableHTTP"
}
```

### **Error Pattern**
- **Initial Behavior**: New chat sessions work perfectly ✅
- **After Extended Use**: MCP calls start failing with "Session not found" ❌  
- **Workaround**: Starting new chat session immediately resolves issue ✅
- **MCP Server Status**: Remains healthy and responsive throughout ✅

## 🎯 **Root Cause Analysis**

### **Confirmed Working Components**
1. **MCP Server Deployment**: ✅ Healthy and responding
   - URL: `https://fabrikam-mcp-dev-izbd.azurewebsites.net/`
   - Status endpoint: Operational
   - MCP endpoint: Accessible at `/mcp`

2. **Azure Infrastructure**: ✅ Both services deployed correctly
   - `fabrikam-api-dev-izbD` (API)
   - `fabrikam-mcp-dev-izbd` (MCP Server)

3. **MCP Protocol Implementation**: ✅ Server correctly implements JSON-RPC 2.0
   - Returns proper error codes (-32001 for session not found)
   - Follows MCP HTTP transport specifications

### **Suspected Root Causes**

#### **Primary Suspect: Copilot Studio Session Management**
- Copilot Studio may not be properly maintaining MCP session state across chat turns
- Long-running chat sessions might experience session token expiration
- Studio might be reusing expired session IDs

#### **Secondary Suspect: MCP Server Session Handling**  
- HTTP transport session persistence configuration
- In-memory session storage without proper cleanup
- Session timeout/expiration policies

## 🔧 **Investigation Areas**

### **1. Copilot Studio Configuration**
Need to examine:
- MCP connector configuration in Copilot Studio
- Session management settings for custom connectors
- HTTP transport configuration parameters
- Authentication and session token handling

### **2. MCP Server Implementation**
Need to review:
- Session initialization handling in HTTP transport
- Session storage and cleanup mechanisms  
- Session timeout configuration
- Cross-request session persistence

### **3. MCP Protocol Compliance**
Verify adherence to:
- MCP session lifecycle (initialize → tools → cleanup)
- HTTP transport session management best practices
- Proper error handling for expired sessions

## 🛠️ **Potential Solutions**

### **Option A: Copilot Studio Configuration Fix**
```yaml
# Potential Studio connector settings to investigate
Connection:
  SessionManagement: 
    - EnableSessionPersistence: true
    - SessionTimeout: "30 minutes"  
    - AutoRenewSessions: true
    - RetryOnSessionExpired: true
```

### **Option B: MCP Server Enhancement**
```csharp
// Potential code changes in Program.cs
builder.Services.AddMcpServer()
    .WithHttpTransport(options => {
        options.SessionTimeout = TimeSpan.FromMinutes(30);
        options.EnableSessionPersistence = true;
        options.AutoCleanupExpiredSessions = true;
    })
    .WithTools<FabrikamSalesTools>()
    // ... other tools
```

### **Option C: Hybrid Solution**
- Configure Copilot Studio for better session handling
- Add server-side session management improvements
- Implement graceful session recovery mechanisms

## 📝 **Implementation Plan**

### **Phase 1: Investigation** (Post-Authentication Features)
1. **Document Current Behavior**
   - Create detailed reproduction steps
   - Capture timing patterns for session expiration
   - Test different chat session lengths

2. **Analyze Copilot Studio Configuration**
   - Review MCP connector settings
   - Examine session management options
   - Research Copilot Studio best practices for custom connectors

3. **Review MCP Server Implementation**
   - Audit current session handling code
   - Research MCP HTTP transport session management
   - Identify potential improvement areas

### **Phase 2: Solution Implementation**
1. **Quick Win: Configuration Fixes**
   - Apply Copilot Studio session management improvements
   - Update MCP connector configuration

2. **Code Enhancement: Server-Side Improvements**  
   - Implement robust session management
   - Add session cleanup and recovery mechanisms
   - Enhance error handling for session issues

3. **Testing & Validation**
   - Test extended chat sessions
   - Verify session persistence across multiple tool calls
   - Validate error recovery mechanisms

## 🧪 **Testing Strategy**

### **Reproduction Steps**
1. Start new chat in Copilot Studio with Fabrikam MCP tools
2. Perform several MCP tool calls successfully
3. Continue chat session for extended period (15-30 minutes)
4. Attempt additional MCP tool calls
5. **Expected**: Session expiration error
6. Start new chat session
7. **Expected**: Tools work immediately

### **Success Criteria**
- [ ] Chat sessions maintain MCP connectivity for 30+ minutes
- [ ] Graceful handling of session expiration with auto-recovery
- [ ] No more "Session not found" errors in normal usage
- [ ] Clear error messages if session issues occur

## 🔄 **Current Status**

- **Deployment**: ✅ MCP server healthy and operational
- **Investigation**: 📋 Documented and ready for post-authentication work  
- **Priority**: Medium (affects user experience but has workaround)
- **Timeline**: Address after authentication features are complete

## 🔗 **Related Documentation**

- [MCP HTTP Transport Specification](https://github.com/modelcontextprotocol/specification)
- [Copilot Studio Custom Connector Documentation](https://docs.microsoft.com/copilot-studio)
- [Fabrikam MCP Server Implementation](../../FabrikamMcp/src/Program.cs)

## 👥 **Stakeholders**

- **Primary**: Development Team (session management implementation)
- **Secondary**: Business Users (improved chat experience)
- **Testing**: QA Team (validation of session handling)

---

**Note**: This issue does not block current development work and has a reliable workaround (new chat session). Prioritized for post-authentication implementation phase.
