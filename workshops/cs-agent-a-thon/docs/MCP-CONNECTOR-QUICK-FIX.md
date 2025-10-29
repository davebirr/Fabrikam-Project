# 🚀 MCP Connector Setup - Quick Action Guide

**Context**: oscarw created a user-bound MCP connection, but B2B guests (like davidb) cannot authenticate it.  
**Fix**: Delete the old connection and create a new environment-scoped connection with "No Auth".

---

## ✅ **Step-by-Step Fix (10 minutes)**

### **STEP 1: Delete Old User-Bound Connection** ❌

1. Go to: https://make.powerapps.com
2. Switch to environment: `Default-fd268415-22a5-4064-9b5e-d039761c5971`
3. Navigate to: **Data > Connections**
4. Find: The MCP connection oscarw created
5. Click: Three dots (...) > **Delete**
6. Confirm deletion

---

### **STEP 2: Verify/Update Custom Connector** 🔧

1. Still in https://make.powerapps.com
2. Navigate to: **Data > Custom Connectors**
3. Find: **Fabrikam MCP Connector** (or whatever oscarw named it)
4. Click: **Edit** (pencil icon)

**Security Tab - CRITICAL CHECK**:
```
Authentication type: No authentication
```

- If it's NOT "No authentication":
  - Change it to: **No authentication**
  - Click: **Update connector**
  
- If it IS "No authentication":
  - Just close (no changes needed)

---

### **STEP 3: Create New Environment-Scoped Connection** ✨

1. Navigate to: **Data > Connections**
2. Click: **+ New connection**
3. Search for and select: **Fabrikam MCP Connector**
4. Click: **Create**
   - Since auth is "No Auth", it creates immediately
   - No credentials required
   - No pop-ups
5. **Note the connection name** (e.g., `shared-fabrikam-mcp-connector-12345`)

---

### **STEP 4: Share Connection with Proctors** 👥

1. Find the NEW connection in **Data > Connections**
2. Click: Three dots (...) > **Share**
3. Add security group: `Workshop-Team-Proctors`
4. Permission: **Can use** (dropdown)
   - NOT "Can edit"
   - NOT "Can use + share"
   - Just: **Can use**
5. Click: **Save** or **Share**

---

### **STEP 5: Verify Environment Maker Role** 🎓

1. Go to: https://admin.powerplatform.microsoft.com
2. Navigate to: **Environments**
3. Find and click: **Default-fd268415...** environment
4. Click: **Settings** (top navigation)
5. Navigate to: **Users + permissions > Security roles**
6. Click: **+ Add members** (or similar)
7. Search for: `Workshop-Team-Proctors`
8. Assign role: **Environment Maker**
9. Click: **Save**

**Alternative - Add Individual Users**:
If group doesn't work, add individual B2B guests:
- Search: `davidb_microsoft.com#EXT#@levelup...`
- Assign: **Environment Maker**
- Repeat for other proctors

---

### **STEP 6: Test with davidb** 🧪

1. Open incognito/private browser window
2. Login as: `davidb@microsoft.com`
3. Navigate to: https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
4. **Wait 5-10 minutes** for permissions to propagate (grab coffee ☕)
5. Create new agent or edit existing agent
6. Go to: **Settings > Actions > Add action**
7. Search for: **Fabrikam MCP Connector**
8. Click: **Add** (should NOT prompt for authentication)
9. Verify: Connector appears in agent actions
10. Test: Use connector in agent conversation

**Expected Result**:
- ✅ Connector appears in search
- ✅ No authentication prompt when adding
- ✅ Connector available in agent
- ✅ Can call MCP tools successfully

**If Still Failing**:
- Wait another 10 minutes (permissions can be slow)
- Verify davidb is in Workshop-Team-Proctors group
- Check connection is shared correctly
- Verify Environment Maker role is assigned

---

## 🎯 **Validation Checklist**

Before proceeding to create 21 team connections:

- [ ] Old user-bound connection DELETED
- [ ] Custom connector uses "No authentication"
- [ ] New environment-scoped connection created
- [ ] Connection shared with Workshop-Team-Proctors ("Can use")
- [ ] Environment Maker role assigned to proctors
- [ ] Tested successfully with davidb (B2B guest)
- [ ] No authentication prompts when adding to agent
- [ ] MCP tools work in agent conversation

---

## 🔄 **Next Steps - Scale to 21 Teams**

Once davidb test is successful:

### **Option A: One Shared Connection** (Recommended)
```
1 Connection shared with 22 groups
  ├─ Workshop-Team-Proctors
  ├─ Workshop-Team-01
  ├─ Workshop-Team-02
  └─ ... Workshop-Team-21
```

**To Implement**:
1. Share existing connection with all 22 groups ("Can use")
2. Each team's agent uses same connection
3. Each team's MCP server URL configured in connector action parameters

**Pros**: Simple, fast, fewer moving parts  
**Cons**: All teams see same connector/connection name

---

### **Option B: 22 Separate Connections** (If Isolation Needed)
```
22 Connections (one per team)
  ├─ Fabrikam-MCP-Proctor → Workshop-Team-Proctors
  ├─ Fabrikam-MCP-Team-01 → Workshop-Team-01
  └─ ... (repeat 21 times)
```

**To Implement**:
1. Create 22 custom connectors (clone the working one)
2. Create 22 connections (one for each connector)
3. Share each connection with respective team group
4. Each connection hardcoded to team-specific MCP URL

**Pros**: Team isolation, clearer naming  
**Cons**: 22x the management overhead

---

## 📊 **What We Learned**

| ❌ **What Didn't Work** | ✅ **What Works** |
|------------------------|-------------------|
| User-bound connection (oscarw) | Environment-scoped connection |
| "Can edit" permission | "Can use" permission |
| OAuth/Interactive auth | "No authentication" |
| No environment role | Environment Maker role |
| Immediate testing | 5-10 min permission propagation |

---

## 🆘 **Troubleshooting Quick Reference**

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Connection not found" | Not shared with user's group | Share connection with group |
| "Authentication failed" | User-bound connection | Create new environment-scoped |
| "No permission" | Missing Environment Maker | Assign role in Admin Center |
| Can see connector but not connection | Connection not shared | Share connection ("Can use") |
| Works for oscarw but not davidb | User-bound to oscarw | Create environment-scoped |

---

## 📞 **Support Contacts**

If issues persist after following this guide:

- **Power Platform Support**: https://admin.powerplatform.microsoft.com > Support
- **Workshop Organizers**: [Your contact info]
- **Azure Support**: https://portal.azure.com > Support

---

**Estimated Time**: 10-15 minutes (+ 5-10 min permission propagation)  
**Difficulty**: Medium (requires admin access)  
**Impact**: Unblocks ALL B2B guest access to MCP connectors
