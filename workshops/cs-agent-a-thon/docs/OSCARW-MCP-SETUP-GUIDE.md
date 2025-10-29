# 🎯 Quick Setup for oscarw - MCP Connector for B2B Guests

**You have**: Global Admin + Power Platform Admin  
**Goal**: Create MCP connector that B2B guests can use  
**Time**: 10 minutes

---

## ✅ **Step-by-Step (Do as oscarw@fabrikam1.csplevelup.com)**

### **1. Create Custom Connector** (5 min)

1. Navigate to: **https://make.powerapps.com**
2. **Sign in as**: oscarw@fabrikam1.csplevelup.com
3. **Switch to environment**: Fabrikam (default)
4. Go to: **Data > Custom Connectors**
5. Click: **+ New custom connector > Create from blank**

**General Tab**:
```
Connector name: Fabrikam MCP Proctor
Scheme: HTTPS
Host: fabrikam-mcp-proctor.azurewebsites.net
   (or whatever the actual MCP server URL is - check Azure App Service)
Base URL: /
```

**Security Tab** - ⚠️ **CRITICAL FOR B2B GUESTS**:
```
Authentication type: No authentication
```
Click **Update connector** at top

**Definition Tab** - Add basic actions:
```
Action 1:
  Summary: List MCP Tools
  Operation ID: list_tools
  Request:
    - Method: POST
    - URL: /mcp/list_tools
    - Headers: Content-Type = application/json
    
Action 2:
  Summary: Call MCP Tool  
  Operation ID: call_tool
  Request:
    - Method: POST
    - URL: /mcp/call_tool
    - Headers: Content-Type = application/json
    - Body (sample):
      {
        "tool": "get_customers",
        "arguments": {}
      }
```

Click **Create connector** at top

---

### **2. Create Connection** (1 min)

1. Go to: **Data > Connections**
2. Click: **+ New connection**
3. Search for: **Fabrikam MCP Proctor**
4. Click on it
5. Since auth is "No Auth", it will create immediately
6. **Copy the connection name** (e.g., `shared-fabrikam-mcp-proctor-xyz`)

---

### **3. Share Connection with Proctors** (2 min)

1. Still in **Data > Connections**
2. Find: The connection you just created
3. Click: **Three dots (...) > Share**
4. Add: `Workshop-Team-Proctors` (search for the security group)
5. **Permission**: Select **"Can use"** from dropdown
   - NOT "Can edit"
   - NOT "Can use + share"
   - Just: **"Can use"**
6. Click: **Share**

---

### **4. Assign Environment Maker to Proctors** (2 min)

1. Navigate to: **https://admin.powerplatform.microsoft.com**
2. Go to: **Environments**
3. Click: **Fabrikam (default)** environment
4. Click: **Settings** (top menu)
5. Navigate to: **Users + permissions > Security roles**
6. Click: **+ Add members** or **Manage security roles**
7. Search for: `Workshop-Team-Proctors`
8. Select the group
9. Assign role: **Environment Maker**
10. Click: **Save**

---

### **5. Test with davidb** (After 5-10 min wait)

1. **Open incognito window**
2. Navigate to: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
3. **Sign in as**: davidb@microsoft.com (B2B guest)
4. Create or open an agent
5. Go to: **Settings > Actions > Add action**
6. Search for: **Fabrikam MCP Proctor**
7. Should appear and add WITHOUT authentication prompt
8. Test calling MCP tools in conversation

---

## ✅ **Success Criteria**

- [ ] Custom connector created with "No authentication"
- [ ] Environment-scoped connection created
- [ ] Connection shared with Workshop-Team-Proctors ("Can use")
- [ ] Environment Maker role assigned to Workshop-Team-Proctors
- [ ] davidb (B2B guest) can add connector to agent WITHOUT auth prompt
- [ ] MCP tools work in agent conversation

---

## 🆘 **If It Doesn't Work**

### **davidb still gets authentication error**:
- Wait 10 minutes for permissions to propagate
- Verify connection is shared with "Can use" (not "Can edit")
- Verify davidb is in Workshop-Team-Proctors Entra group
- Verify Environment Maker is assigned to the group

### **Can't create custom connector**:
- Verify you're signed in as oscarw@fabrikam1.csplevelup.com
- Verify in correct environment (Fabrikam default)
- Your Global Admin + Power Platform Admin should allow this

### **MCP server URL unknown**:
Check Azure App Service deployment or run:
```powershell
az webapp list --resource-group rg-agentathon-proctor --query "[?contains(name, 'mcp')].{Name:name, URL:defaultHostName}" -o table
```

---

## 📋 **For 21 Participant Teams Later**

Once this works for proctors:

**Option A**: Share same connection with all 22 groups
- Faster, simpler
- All teams use same connector/connection

**Option B**: Create 22 separate connectors
- Better isolation
- More management overhead

---

**Estimated Time**: 10 minutes  
**Prerequisites**: Global Admin + Power Platform Admin (you have both!)  
**Result**: All B2B guest proctors can use MCP connector in Copilot Studio
