# 🔐 davidb@microsoft.com - Workshop Tenant Access Guide

**Problem**: Browser defaults to Microsoft corporate tenant instead of workshop tenant  
**Solution**: Force tenant context with specific URLs and incognito mode

---

## ✅ **Step-by-Step: Access Workshop Tenant as davidb**

### **Step 1: Open Incognito/InPrivate Browser**

- **Edge**: Ctrl + Shift + N
- **Chrome**: Ctrl + Shift + N  
- **Firefox**: Ctrl + Shift + P

### **Step 2: Navigate to Tenant-Specific URL**

**For Dynamics 365 Settings (to manage teams/roles)**:
```
https://orga667300c.crm.dynamics.com/main.aspx?settingsonly=true
```

**For Power Apps Maker Portal**:
```
https://make.powerapps.com/?tenantId=fd268415-22a5-4064-9b5e-d039761c5971
```

**For Power Platform Admin Center**:
```
https://admin.powerplatform.microsoft.com/?tenantId=fd268415-22a5-4064-9b5e-d039761c5971
```

### **Step 3: Sign In**

1. Enter email: **davidb@microsoft.com**
2. Click **Next**
3. **CRITICAL**: On the account picker screen, look for:
   - "Work or school account" option
   - Or text showing "Sign in to levelupcspfy26cs01"
4. If it shows Microsoft corporate tenant, click **"Use another account"**
5. Re-enter: **davidb@microsoft.com**
6. Complete authentication

### **Step 4: Verify Correct Tenant**

Look for these indicators:
- ✅ Top-right corner shows: "levelupcspfy26cs01.onmicrosoft.com" or "fabrikam1.csplevelup.com"
- ✅ Environment shows: "Fabrikam (default)"
- ❌ If you see your Microsoft corporate email, you're in wrong tenant - start over

---

## 🎯 **Quick Task: Assign Environment Maker Role**

Once in the correct tenant as davidb:

### **Option A: Via Dynamics 365 Settings**

1. You should already be at: `https://orga667300c.crm.dynamics.com/main.aspx?settingsonly=true`
2. Navigate to: **Settings** > **Security** > **Teams**
3. Find team: "Workshop-Team-Proctors" or similar (Team Type = AAD Security Group)
4. Click on the team name
5. Click: **Manage Roles** (ribbon button)
6. Check: ☑ **Environment Maker**
7. Click: **OK**
8. Click: **Save**

### **Option B: Via Power Platform Admin Center**

1. Navigate to: `https://admin.powerplatform.microsoft.com/?tenantId=fd268415-22a5-4064-9b5e-d039761c5971`
2. Go to: **Environments**
3. Click: **Fabrikam (default)** environment
4. Click: **Settings** (top menu)
5. Navigate to: **Users + permissions** > **Security roles**
6. Try to add: Workshop-Team-Proctors with Environment Maker role

### **Option C: Add Individual User (Fastest for Testing)**

1. At: `https://orga667300c.crm.dynamics.com/main.aspx?settingsonly=true`
2. Navigate to: **Settings** > **Security** > **Users**
3. Click: **+ New**
4. Search for: **davidb** (yourself as B2B guest)
   - Should find: davidb_microsoft.com#EXT#@fabrikam1.csplevelup.com
5. Select and click: **Add**
6. Click on your user name once added
7. Click: **Manage Roles**
8. Check: ☑ **Environment Maker**
9. Click: **OK**

This assigns Environment Maker to yourself for immediate testing!

---

## 🔧 **Troubleshooting Tenant Switching**

### **Still Landing in Microsoft Tenant?**

**Solution 1: Clear Browser State**
```powershell
# Close ALL browser windows first, then:
# Edge: Settings > Privacy > Clear browsing data > Cached images and Cookies
# Or just use fresh Incognito window
```

**Solution 2: Use Different Browser**
- If you normally use Edge, try Chrome/Firefox
- Fresh browser = no cached tenant context

**Solution 3: Sign Out Everywhere First**
1. Go to: https://login.microsoftonline.com/common/oauth2/logout
2. Close all browser windows
3. Open incognito
4. Navigate to tenant-specific URL
5. Sign in fresh

**Solution 4: Use Browser Profile**
- Create a dedicated Edge/Chrome profile for workshop tenant
- This keeps contexts completely separate

---

## 📋 **Direct Links for davidb (Bookmark These)**

**Dynamics 365 Settings Portal**:
```
https://orga667300c.crm.dynamics.com/main.aspx?settingsonly=true
```

**Power Apps Maker (Workshop Tenant)**:
```
https://make.powerapps.com/?tenantId=fd268415-22a5-4064-9b5e-d039761c5971
```

**Power Platform Admin (Workshop Tenant)**:
```
https://admin.powerplatform.microsoft.com/?tenantId=fd268415-22a5-4064-9b5e-d039761c5971
```

**Copilot Studio (Workshop Tenant)**:
```
https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
```

**Azure Portal (Workshop Subscription)**:
```
https://portal.azure.com/#@fd268415-22a5-4064-9b5e-d039761c5971/resource/subscriptions/d3c2f651-1a5a-4781-94f3-460c4c4bffce
```

---

## ✅ **Success Checklist**

After assigning Environment Maker role:

- [ ] Accessed Dynamics 365 Settings in workshop tenant (verify URL shows orga667300c)
- [ ] Found Workshop-Team-Proctors team OR added individual user
- [ ] Assigned Environment Maker role
- [ ] Saved changes
- [ ] Waited 5-10 minutes for propagation
- [ ] Tested MCP connector access in Copilot Studio
- [ ] B2B guest can add connector without authentication prompt

---

## 🎯 **After Environment Maker is Assigned**

Test the full workflow:

1. **Sign out** of all browsers
2. **Open incognito** window
3. Navigate to: `https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971`
4. **Sign in as**: davidb@microsoft.com (as B2B guest)
5. Create or edit agent
6. Add MCP connector action
7. **Should work WITHOUT authentication prompt!**

---

**Key Takeaway**: Always use tenant-specific URLs or incognito mode when accessing workshop tenant as davidb@microsoft.com to avoid Microsoft corporate tenant redirect.
