# 🔌 MCP Connector Setup for B2B Guest Access

**Problem**: B2B guest users cannot authenticate user-bound Power Platform connections  
**Solution**: Use service principal with "No Auth" connector and environment-scoped connection

---

## 🚨 **Critical Understanding**

### ❌ **What DOESN'T Work for B2B Guests**

```
User-Bound Connection
├─ Created by individual user (e.g., oscarw)
├─ Shared with "Can edit" or "Can use + share"
├─ Requires user authentication/token refresh
└─ ❌ B2B guests cannot authenticate (token refresh fails)
```

### ✅ **What DOES Work for B2B Guests**

```
Environment-Scoped Connection
├─ Created using Service Principal OR No Auth
├─ No user-specific credentials needed
├─ Shared with "Can use" permission
└─ ✅ B2B guests can use without authentication
```

---

## 📋 **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│ Copilot Studio (B2B Guest User: davidb)                     │
│                                                              │
│  Agent → MCP Connector → Connection (Environment-Scoped)    │
│           ↓                        ↓                         │
│      No Auth Required      Shared with "Can use"            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ Fabrikam MCP Server (Azure App Service)                     │
│  - Endpoint: https://fabrikam-mcp-proctor.azurewebsites.net │
│  - Authentication: None (public endpoint)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ **Implementation Steps**

### **Option 1: No Auth Connector** (Recommended for Workshop)

This is the simplest approach when your MCP server doesn't require authentication.

#### **Step 1: Create Custom Connector**

1. Navigate to: https://make.powerapps.com
2. Switch to environment: `Default-fd268415-22a5-4064-9b5e-d039761c5971`
3. Go to: **Data > Custom Connectors > + New custom connector > Create from blank**

**General Tab**:
```
Connector name: Fabrikam MCP Connector
Host: fabrikam-mcp-proctor.azurewebsites.net
Base URL: /
```

**Security Tab**:
```
Authentication type: No authentication ⚠️ CRITICAL!
```

**Definition Tab**:
- Add MCP tool actions (or import OpenAPI spec)
- Common MCP endpoints:
  - `POST /mcp/list_tools` - List available tools
  - `POST /mcp/call_tool` - Execute a tool
  - `GET /api/info` - Server info

**Test Tab**:
- Create a test connection
- Verify endpoints work

#### **Step 2: Create Connection**

1. Go to: **Data > Connections > + New connection**
2. Find and select: **Fabrikam MCP Connector**
3. Since authentication is "No Auth", just click: **Create**
   - No credentials needed
   - Connection created immediately
4. Note the connection name (e.g., `shared-fabrikam-mcp-connector-xxxxx`)

#### **Step 3: Share Connection with Security Groups**

1. Find the connection in **Data > Connections**
2. Click the three dots (...) > **Share**
3. Add security groups:
   - `Workshop-Team-Proctors` (for testing)
   - `Workshop-Team-01`, `Workshop-Team-02`, etc. (for participants)
4. **Permission**: `Can use` (NOT "Can edit")
   - "Can use" = Use in agents/flows
   - "Can use + share" = Use and share with others
   - "Can edit" = Modify connection settings (not needed)

#### **Step 4: Assign Environment Maker Role**

B2B guests MUST have Environment Maker role to access shared connections.

1. Navigate to: https://admin.powerplatform.microsoft.com
2. Go to: **Environments > Default environment**
3. Click: **Settings > Users + permissions > Security roles**
4. Assign **Environment Maker** to:
   - `Workshop-Team-Proctors` security group (bulk)
   - Or individual B2B guests

**What Environment Maker Enables**:
- Access to shared connections
- Create agents in Copilot Studio
- Create flows in Power Automate
- Create apps in Power Apps (limited)

#### **Step 5: Test with B2B Guest**

1. Login as B2B guest (e.g., davidb@microsoft.com)
2. Navigate to: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
3. Create or edit an agent
4. Go to: **Settings > Actions > Add action**
5. Search for: **Fabrikam MCP Connector**
6. Select connector and add to agent
   - Should NOT prompt for authentication
   - Connection should be automatically available
7. Test connector in agent conversation

---

### **Option 2: Service Principal Connector** (If Auth Required)

Use this if your MCP server requires authentication (Azure AD, API Key, etc.).

**Run the automated setup script**:
```powershell
cd workshops\cs-agent-a-thon\infrastructure\scripts
.\Setup-MCP-ServicePrincipal.ps1 -McpServerUrl "https://fabrikam-mcp-proctor.azurewebsites.net"
```

**The script will**:
1. Create Azure AD application
2. Create service principal
3. Generate client secret
4. Guide you through manual Power Platform steps

**Then complete manual steps** as prompted by the script.

---

## 🔍 **Troubleshooting**

### **Error: "The request had a connection that the user did not have access to"**

**Causes**:
1. ❌ B2B guest doesn't have Environment Maker role
2. ❌ Connection not shared with user's security group
3. ❌ Connection shared with wrong permission level
4. ❌ Connection is user-bound (not environment-scoped)

**Solution**:
1. ✅ Assign Environment Maker role to B2B guest
2. ✅ Share connection with security group using "Can use"
3. ✅ Use "No Auth" connector type
4. ✅ Create new environment-scoped connection

---

### **Error: "Authentication failed" or "Token refresh failed"**

**Cause**: Using user-bound authentication (OAuth, Azure AD interactive)

**Solution**: 
- Change connector to "No authentication"
- OR use service principal with OAuth (not interactive)

---

### **B2B Guest Can See Connector but Not Connection**

**Cause**: Connection not shared with guest's security group

**Solution**:
1. Verify guest is member of security group (e.g., Workshop-Team-Proctors)
2. Share connection with that security group
3. Use "Can use" permission level
4. Wait 5-10 minutes for permissions to propagate

---

### **Connection Works for Native Users but Not B2B Guests**

**Cause**: Missing Environment Maker role

**Solution**:
1. Go to Power Platform Admin Center
2. Navigate to environment settings
3. Assign Environment Maker role to B2B guests or their security group

---

## 📊 **Permission Matrix**

| User Type | Environment Role | Connection Permission | Can Use MCP? |
|-----------|------------------|----------------------|--------------|
| Native User | Environment Maker | Can use | ✅ YES |
| Native User | Basic User | Can use | ✅ YES |
| Native User | None | Can use | ❌ NO |
| B2B Guest | Environment Maker | Can use | ✅ YES |
| B2B Guest | Basic User | Can use | ⚠️ MAYBE* |
| B2B Guest | None | Can use | ❌ NO |
| B2B Guest | Environment Maker | Can edit | ❌ NO** |

\* May work but not recommended  
\** "Can edit" doesn't grant usage rights for B2B guests

---

## ✅ **Validation Checklist**

Before workshop day, verify:

- [ ] Custom connector created with "No authentication"
- [ ] Environment-scoped connection created
- [ ] Connection shared with all team security groups ("Can use")
- [ ] Environment Maker role assigned to all B2B guests
- [ ] Tested connection with at least one B2B guest user
- [ ] MCP server endpoint is accessible from Power Platform
- [ ] Agent can call MCP tools successfully

---

## 🎯 **Workshop Deployment Pattern**

For 21 participant teams + 1 proctor team:

### **Shared Approach** (Recommended)
```
1 MCP Connector (No Auth)
  ├─ 1 Environment-Scoped Connection
  ├─ Shared with 22 security groups ("Can use")
  ├─ Each team uses same connection
  └─ Each team has unique MCP server URL (via connector parameter)
```

**Pros**: Simple, fewer connections to manage  
**Cons**: All teams see same connector name

### **Isolated Approach** (If Needed)
```
22 MCP Connectors (No Auth)
  ├─ Connector 1: "Fabrikam MCP - Proctors"
  ├─ Connector 2: "Fabrikam MCP - Team 01"
  ├─ Connector 3: "Fabrikam MCP - Team 02"
  └─ ... (each with own connection and team-specific URL)
```

**Pros**: Team isolation, clearer naming  
**Cons**: 22 connectors to create and manage

---

## 📚 **References**

- [Power Platform Custom Connectors Documentation](https://learn.microsoft.com/en-us/connectors/custom-connectors/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io)
- [Sharing Connections in Power Platform](https://learn.microsoft.com/en-us/power-platform/admin/wp-connection-sharing)
- [Environment Security Roles](https://learn.microsoft.com/en-us/power-platform/admin/database-security)

---

## 🔑 **Key Takeaways**

1. **B2B guests CANNOT use user-bound connections** (token refresh fails)
2. **Use "No Auth" connector** for simplest B2B compatibility
3. **Share connection with "Can use"** (not "Can edit")
4. **B2B guests MUST have Environment Maker role**
5. **Test with real B2B guest before workshop** (don't assume it works)

---

**Questions?** Contact workshop organizers or Azure support.
