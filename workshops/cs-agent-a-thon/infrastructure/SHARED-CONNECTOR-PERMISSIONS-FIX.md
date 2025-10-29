# Fixing Shared MCP Connector Permissions Issue

## Problem
User can see `Fabrikam-MCP-Proctor` connector but gets error when trying to add it to agent:
```
The caller with object id [user-id] does not have the minimum required 
permissions to use connection [connection-id]
```

## Root Cause
The connector is shared, but the **underlying connection** is not shared with "Can use" permissions.

In Power Platform/Copilot Studio:
- **Connector** = The API definition (what tools/operations exist)
- **Connection** = The actual authenticated instance (credentials to call the API)

You need to share BOTH.

## Solution: Share the Connection

### Option 1: Via Power Platform Admin Center (Recommended)

1. Go to: [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
2. Navigate to **Environments** → **Default-fd268415-22a5-4064-9b5e-d039761c5971**
3. Click **Dataverse** → **Custom Connectors**
4. Find **Fabrikam-MCP-Proctor** connector
5. Click on it → **Connections** tab
6. Find the connection (ID: `626a4dbf161a4399a32fbc214d4c663b`)
7. Click **Share**
8. Add the security group: **Workshop-Team-Proctors**
9. Grant permission: **Can use**
10. Click **Share**

### Option 2: Via Copilot Studio UI

1. Go to: [Copilot Studio](https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971)
2. Switch to **Default-fd268415-22a5-4064-9b5e-d039761c5971** environment
3. Go to **Settings** (gear icon) → **Connections**
4. Find **Fabrikam-MCP-Proctor** connection
5. Click the **...** menu → **Share**
6. Add: **Workshop-Team-Proctors** security group
7. Permission: **Can use**
8. Click **Share**

### Option 3: Via PowerShell (Fastest for bulk)

```powershell
# Install Power Platform CLI if not already installed
# https://aka.ms/PowerAppsCLI

# Authenticate to Power Platform
pac auth create --tenant fd268415-22a5-4064-9b5e-d039761c5971

# Select the environment
pac env select --environment Default-fd268415-22a5-4064-9b5e-d039761c5971

# Share the connection with the security group
# You'll need the connection ID: 626a4dbf161a4399a32fbc214d4c663b
# And the security group object ID for Workshop-Team-Proctors

pac connection share `
    --connection 626a4dbf161a4399a32fbc214d4c663b `
    --role CanUse `
    --principal <security-group-object-id>
```

## Verification

After sharing the connection, have the affected user:

1. **Sign out completely** from Copilot Studio (not just close the tab)
2. **Sign back in** as their workshop identity
3. Try adding the connector to their agent again
4. Should now work without the 403 Forbidden error

**If still failing after sign-out/sign-in:**
- Clear browser cache/cookies for `microsoft.com` and `powerapps.com`
- Try in InPrivate/Incognito mode
- Wait 5-10 minutes for backend permission sync (Azure AD group membership can take time to propagate)

**If user can SEE the connector but gets 403 when ADDING it:**
This indicates permissions are partially synced. The user's session token was issued before they were added to the security group. A fresh sign-in forces a new token with updated group memberships.

## Alternative Workaround (If Sharing Fails)

If you can't share the connection for some reason, users can create their own connection:

1. In Copilot Studio, go to **Actions** → **Connectors**
2. Find **Fabrikam-MCP-Proctor** connector
3. Click **+ Add connection**
4. This creates a NEW connection owned by that user
5. They use their own connection instead of the shared one

**Downside**: Each user needs to create their own connection (more management overhead).

## Prevention for Participants

When you share the connector with the 117 participants, remember to:
1. Share the **connector** (API definition)
2. Share the **connection** (authenticated instance) with "Can use" permission
3. Test with 2-3 participants before rolling out to all

## Technical Details

**Error Breakdown:**
- `statuscode: 403` = Forbidden (permission denied)
- `code: 10006` = Insufficient permissions
- Caller object ID: `0061ff85-0599-4c70-a294-359b1520387e` (the proctor's user ID)
- Connection ID: `626a4dbf161a4399a32fbc214d4c663b` (your shared connection)

The connection is owned by you (or the service principal) but not shared with users who need "Can use" permission.
