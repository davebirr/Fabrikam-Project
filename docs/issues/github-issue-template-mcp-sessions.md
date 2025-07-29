# GitHub Issue: Copilot Studio MCP Session Management

## Issue Template for GitHub

**Title**: `Copilot Studio MCP Session Timeout - "Session not found" Error After Extended Chat`

**Labels**: `bug`, `mcp`, `copilot-studio`, `session-management`, `medium-priority`

**Assignees**: `@davebirr`

**Milestone**: `Post-Authentication Features`

---

## 🐛 **Bug Description**

Copilot Studio experiences MCP session timeout issues when using the deployed Fabrikam MCP server after extended chat sessions. Users receive "Session not found" JSON-RPC errors, but starting a new chat session immediately resolves the issue.

## 🔄 **To Reproduce**

1. Start new chat in Copilot Studio with Fabrikam Business Assistant
2. Successfully use MCP tools (sales analytics, inventory, etc.)
3. Continue chat session for 15-30 minutes with multiple tool calls
4. Attempt to use MCP tools again
5. **Observe**: `{"jsonrpc":"2.0","id":"","error":{"Code":-32001,"Message":"Session not found"}}`
6. Start new chat session
7. **Observe**: Tools work immediately

## ✅ **Expected Behavior**

- MCP sessions should persist for reasonable chat duration (30+ minutes)
- Graceful session renewal or clear error messages with recovery guidance
- No interruption to user workflow

## 🔍 **Current Status**

- **MCP Server**: ✅ Healthy and responding (`https://fabrikam-mcp-dev-izbd.azurewebsites.net/`)
- **Azure Infrastructure**: ✅ Both API and MCP services deployed correctly  
- **Workaround**: ✅ Starting new chat resolves issue immediately
- **Impact**: 🟡 Medium - affects UX but has reliable workaround

## 🛠️ **Investigation Areas**

### Copilot Studio Configuration
- [ ] Review MCP connector session management settings
- [ ] Examine HTTP transport configuration
- [ ] Research Studio best practices for custom connectors

### MCP Server Implementation  
- [ ] Audit session handling in HTTP transport
- [ ] Review session timeout and cleanup mechanisms
- [ ] Consider session persistence enhancements

## 💡 **Potential Solutions**

1. **Studio Configuration**: Update MCP connector session settings
2. **Server Enhancement**: Improve session management and error recovery
3. **Hybrid Approach**: Both client and server-side improvements

## 📚 **Documentation**

- Detailed analysis: `docs/issues/copilot-studio-mcp-session-management.md`
- MCP Server code: `FabrikamMcp/src/Program.cs`
- Deployment status: Both services healthy in Azure

## 🎯 **Acceptance Criteria**

- [ ] Chat sessions maintain MCP connectivity for 30+ minutes
- [ ] Graceful session handling with auto-recovery when possible
- [ ] Clear error messages and recovery guidance for users
- [ ] No breaking changes to existing functionality

## 🔗 **Environment**

- **MCP Server**: `fabrikam-mcp-dev-izbd.azurewebsites.net`
- **API Server**: `fabrikam-api-dev-izbd.azurewebsites.net`  
- **Azure Subscription**: MCAPS-Hybrid-REQ-59531-2023-davidb
- **Resource Group**: rg-fabrikam-dev

---

**Priority**: Medium (post-authentication features)  
**Effort Estimate**: 1-2 sprints (investigation + implementation)  
**Dependencies**: None (authentication work takes priority)
