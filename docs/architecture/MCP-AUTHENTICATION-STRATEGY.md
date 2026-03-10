# 🔐 MCP Authentication Strategy - SDL Compliance Analysis

> **Status**: Gap Analysis Complete | **Next Steps**: Implementation Required  
> **Last Updated**: December 1, 2025 | **Priority**: High (Security Requirement)

## 📋 Executive Summary

This document analyzes the Fabrikam Project's current MCP server authentication against Microsoft's SDL requirements and the MCP Authorization specification. It provides a roadmap for implementing production-ready OAuth 2.1 authentication with Protected Resource Metadata (PRM).

### **🚨 Current State vs. Requirements**

| Requirement | Current Status | Gap |
|------------|----------------|-----|
| **Server-level authentication** | ✅ Implemented | None - JWT Bearer tokens required |
| **No shared secrets/PATs** | ⚠️ Partial | Using JWT secrets (Azure Key Vault in prod) |
| **OAuth 2.1 with PRM** | ❌ Not implemented | Must implement MCP Authorization spec |
| **Microsoft Entra ID integration** | ❌ Not implemented | Planned but not active |
| **Production deployment** | ⚠️ Not SDL-compliant | Cannot publish without OAuth 2.1 |

### **🎯 Recommended Approach**

**Implement MCP Authorization with Protected Resource Metadata (PRM) using Microsoft Entra ID as the authorization server.**

This aligns with:
- Microsoft SDL requirements (no shared secrets)
- MCP Authorization specification (OAuth 2.1 + PRM)
- Microsoft's recommended sample implementation
- Azure best practices (Managed Identity)

---

## 📚 Understanding the Microsoft Sample

### **Repository**: [blackchoey/remote-mcp-apim-oauth-prm](https://github.com/blackchoey/remote-mcp-apim-oauth-prm)

### **What It Demonstrates**

1. **Protected Resource Metadata (PRM)**: Latest MCP authorization approach
2. **Microsoft Entra ID Integration**: Uses Entra as OAuth 2.1 authorization server
3. **Zero-Config Deployment**: Complete Azure infrastructure with `azd up`
4. **Managed Identity**: No client secrets - uses federated credentials
5. **Microsoft Graph Access**: Example of accessing protected resources

### **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                      VS Code (MCP Client)                        │
│  • GitHub Copilot with MCP extension                            │
│  • Handles OAuth 2.1 authorization flow                         │
│  • Stores and manages access tokens                             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ 1. Initial request (no token)
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│              Azure API Management (Entry Point)                  │
│  • Public endpoint for MCP server                               │
│  • Routes requests to App Service                               │
│  • Can add rate limiting, logging, etc.                         │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ 2. Forward to MCP Server
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                 App Service (MCP Server)                         │
│  • ASP.NET Core web app                                         │
│  • Implements MCP Authorization spec                            │
│  • Returns 401 with WWW-Authenticate header                     │
│  • Validates Bearer tokens on subsequent requests               │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ 3. Token validation
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│           Microsoft Entra ID (Authorization Server)              │
│  • OAuth 2.1 authorization server                               │
│  • Issues access tokens                                         │
│  • User consent management                                      │
│  • Managed Identity as federated credential                     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ 4. Access protected resources
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│              Microsoft Graph API (Example)                       │
│  • User profile data                                            │
│  • Requires user-delegated permissions                          │
│  • Accessed with user's access token                            │
└─────────────────────────────────────────────────────────────────┘
```

### **Key Flow: 401 Challenge with PRM**

The critical innovation is the **WWW-Authenticate** header response:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="https://mcp.example.com/.well-known/oauth-protected-resource",
                         scope="files:read"
```

This tells the MCP client:
1. **Where to find authorization server info** (`resource_metadata` URL)
2. **What permissions are needed** (`scope` parameter)

The client then:
1. Fetches the PRM document at the `resource_metadata` URL
2. Discovers the authorization server endpoints
3. Initiates OAuth 2.1 authorization code flow with PKCE
4. Obtains access token
5. Retries original request with `Authorization: Bearer <token>` header

---

## 🔍 MCP Authorization Specification Deep Dive

### **Core Requirements**

From the [MCP Authorization spec](https://modelcontextprotocol.io/specification/draft/basic/authorization):

#### **1. Authorization is OPTIONAL but Recommended**
- For HTTP-based transports: SHOULD implement OAuth 2.1 + PRM
- For STDIO transports: SHOULD use environment credentials instead

#### **2. Standards-Based Implementation**
Based on:
- OAuth 2.1 (draft-ietf-oauth-v2-1-13)
- OAuth 2.0 Authorization Server Metadata (RFC8414)
- OAuth 2.0 Protected Resource Metadata (RFC9728) ← **Key for PRM**
- Resource Indicators for OAuth 2.0 (RFC8707)
- OAuth Client ID Metadata Documents (draft)

#### **3. Roles**
- **MCP Server** = OAuth 2.1 Resource Server
- **MCP Client** (VS Code/Copilot) = OAuth 2.1 Client
- **Authorization Server** = Microsoft Entra ID (or other OAuth provider)

### **Implementation Checklist**

#### **MCP Server MUST:**
- [ ] Implement Protected Resource Metadata (RFC9728)
- [ ] Return 401 with `WWW-Authenticate` header on unauthorized requests
- [ ] Include `resource_metadata` URL in WWW-Authenticate header
- [ ] Serve PRM document at `.well-known/oauth-protected-resource`
- [ ] Validate Bearer tokens with authorization server
- [ ] Validate token audience matches server URI (RFC8707)
- [ ] Support scope-based authorization (return 403 for insufficient scope)
- [ ] Use HTTPS for all endpoints (except localhost)

#### **Authorization Server (Entra ID) MUST:**
- [ ] Implement OAuth 2.1 with PKCE
- [ ] Support Authorization Server Metadata (RFC8414) or OpenID Connect Discovery
- [ ] Issue tokens with proper audience claim (`aud`)
- [ ] Support Client ID Metadata Documents or Dynamic Client Registration
- [ ] Rotate refresh tokens for public clients

#### **MCP Client (VS Code) MUST:**
- [ ] Parse `WWW-Authenticate` headers
- [ ] Fetch Protected Resource Metadata
- [ ] Discover authorization server endpoints
- [ ] Implement OAuth 2.1 authorization code flow with PKCE
- [ ] Use `S256` code challenge method
- [ ] Include `resource` parameter in authorization/token requests (RFC8707)
- [ ] Handle 403 errors with step-up authorization flow
- [ ] Store tokens securely

### **Protected Resource Metadata Document**

Example `.well-known/oauth-protected-resource` response:

```json
{
  "resource": "https://mcp.fabrikam.com",
  "authorization_servers": [
    "https://login.microsoftonline.com/{tenant-id}/v2.0"
  ],
  "scopes_supported": [
    "mcp.tools.read",
    "mcp.tools.execute",
    "mcp.resources.read"
  ],
  "bearer_methods_supported": [
    "header"
  ]
}
```

### **Authorization Server Discovery**

The MCP client will attempt (in order):
1. OAuth 2.0 Authorization Server Metadata: `https://login.microsoftonline.com/{tenant}/.well-known/oauth-authorization-server`
2. OpenID Connect Discovery: `https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration`

Microsoft Entra ID supports both!

---

## 🏗️ Recommended Architecture for Fabrikam

### **Target Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                   MCP Clients (Copilot, etc.)                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ OAuth 2.1 Authorization Code Flow + PKCE
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         │                  │                  │
         ↓                  ↓                  ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ FabrikamMcp  │  │ FabrikamApi  │  │FabrikamDashbd│
│   (Port      │  │   (Port      │  │   (Blazor    │
│    5000)     │  │    7297)     │  │    App)      │
│              │  │              │  │              │
│ • MCP Tools  │  │ • REST API   │  │ • Admin UI   │
│ • OAuth 2.1  │  │ • JWT Bearer │  │ • Cookie     │
│   Resource   │  │   (Service   │  │   Auth       │
│   Server     │  │   JWT)       │  │              │
│ • PRM        │  │              │  │              │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │ Validate        │ Validate        │ Validate
       │ User Token      │ Service Token   │ User Session
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                         ↓
        ┌─────────────────────────────────────────┐
        │    Microsoft Entra External ID          │
        │  • OAuth 2.1 Authorization Server       │
        │  • Token Issuance                       │
        │  • User Consent                         │
        │  • Managed Identity (no secrets)        │
        └─────────────────────────────────────────┘
```

### **Authentication Strategy by Component**

| Component | Authentication Method | Token Type | Use Case |
|-----------|----------------------|------------|----------|
| **FabrikamMcp** | OAuth 2.1 + PRM (User tokens) | User-delegated Bearer | MCP client requests (Copilot) |
| **FabrikamApi** | JWT Bearer (Service tokens) | Service-to-service JWT | MCP → API communication |
| **FabrikamDashboard** | Cookie-based session | Session cookies | Browser-based admin UI |

### **Why Two Token Types?**

1. **User Tokens (OAuth 2.1)**: 
   - From Entra ID
   - Represent the end user (Copilot user)
   - Used for MCP client → MCP server
   - Short-lived, audience-bound to MCP server

2. **Service Tokens (JWT)**:
   - Generated by MCP server
   - Represent the MCP server acting on behalf of user
   - Used for MCP server → API server
   - Include user context but are service credentials

**Critical**: MCP server MUST NOT pass through user tokens to API (token passthrough vulnerability per MCP spec Section 11.8)

---

## 🔄 Authentication Flow Comparison

### **Current Flow (JWT Bearer - NOT SDL Compliant)**

```
1. User configures Copilot with JWT secret (shared secret ❌)
2. Copilot sends request with JWT in Authorization header
3. FabrikamMcp validates JWT signature
4. FabrikamMcp generates service JWT for API call
5. FabrikamApi validates service JWT
```

**Problems:**
- ❌ Shared secret (JWT signing key) distributed to clients
- ❌ No per-user authorization
- ❌ Cannot revoke access without changing shared secret
- ❌ Not SDL-compliant
- ❌ Cannot publish to production per Microsoft requirements

### **Target Flow (OAuth 2.1 + PRM - SDL Compliant)**

```
1. User adds MCP server to Copilot (no secrets needed)
2. Copilot makes initial request → 401 with WWW-Authenticate
3. Copilot fetches PRM document
4. Copilot discovers Entra ID authorization endpoints
5. Copilot redirects user to Entra ID login
6. User authenticates with Microsoft credentials
7. User consents to permissions (first time only)
8. Entra ID issues authorization code
9. Copilot exchanges code for access token (PKCE)
10. Copilot includes access token in Authorization header
11. FabrikamMcp validates token with Entra ID
12. FabrikamMcp generates service JWT for API call
13. FabrikamApi validates service JWT
```

**Benefits:**
- ✅ No shared secrets (Managed Identity for server credentials)
- ✅ Per-user authentication and authorization
- ✅ Granular scope-based permissions
- ✅ Token revocation capability
- ✅ SDL-compliant
- ✅ Can publish to production

---

## 📋 Implementation Roadmap

### **Phase 1: Understanding the Sample (Current)**
- [x] Review Microsoft sample repository
- [ ] Clone sample locally for hands-on exploration
- [ ] Deploy sample to Azure to see it working
- [ ] Test with VS Code to understand user experience
- [ ] Review MCP Authorization specification
- [ ] Understand Protected Resource Metadata

**Recommendation**: **YES, clone the sample locally** to understand:
- How PRM document is served
- How 401 challenges work
- How token validation is implemented
- How Managed Identity is configured
- How deployment automation works with `azd`

### **Phase 2: Planning**
- [ ] Design scope structure for Fabrikam MCP tools
- [ ] Map user roles to OAuth scopes
- [ ] Design PRM document for FabrikamMcp
- [ ] Update authentication architecture diagrams
- [ ] Plan backward compatibility (if needed)
- [ ] Create migration plan from current JWT approach

### **Phase 3: Entra ID Configuration**
- [ ] Create Entra External ID configuration
- [ ] Register FabrikamMcp application in Entra
- [ ] Configure redirect URIs for localhost testing
- [ ] Set up Managed Identity for FabrikamMcp
- [ ] Configure federated credentials (no client secrets)
- [ ] Define OAuth scopes in Entra app manifest
- [ ] Configure API permissions

### **Phase 4: MCP Server Implementation**
- [ ] Add OAuth 2.1 authentication middleware
- [ ] Implement Protected Resource Metadata endpoint
- [ ] Implement WWW-Authenticate challenge logic
- [ ] Add token validation with Entra ID
- [ ] Implement scope-based authorization for MCP tools
- [ ] Add 403 insufficient_scope error handling
- [ ] Implement resource parameter validation (RFC8707)
- [ ] Add security headers and HTTPS enforcement

### **Phase 5: Testing**
- [ ] Test with VS Code MCP extension
- [ ] Verify OAuth authorization code flow
- [ ] Test token validation
- [ ] Test scope challenges (403 errors)
- [ ] Test step-up authorization flow
- [ ] Verify no token passthrough to API
- [ ] Security audit and penetration testing
- [ ] Load testing with concurrent users

### **Phase 6: Deployment**
- [ ] Update Azure deployment templates (Bicep)
- [ ] Configure Managed Identity in Azure
- [ ] Set up Key Vault for any remaining secrets
- [ ] Deploy to development environment
- [ ] Deploy to production
- [ ] Update documentation
- [ ] Create user guides for authentication

### **Phase 7: Migration**
- [ ] Deprecate old JWT Bearer approach
- [ ] Notify existing users of authentication change
- [ ] Provide migration guide
- [ ] Sunset legacy authentication (with grace period)

---

## 🔧 Code Changes Required

### **1. Add NuGet Packages**

```xml
<!-- Add to FabrikamMcp/src/FabrikamMcp.csproj -->
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.0.0" />
<PackageReference Include="Microsoft.Identity.Web" Version="3.2.2" />
<PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="8.3.0" />
```

### **2. Add PRM Endpoint**

```csharp
// Add to FabrikamMcp/src/Program.cs or new controller

app.MapGet("/.well-known/oauth-protected-resource", () =>
{
    var baseUrl = $"{context.Request.Scheme}://{context.Request.Host}";
    var tenantId = builder.Configuration["Authentication:Entra:TenantId"];
    
    return Results.Json(new
    {
        resource = baseUrl,
        authorization_servers = new[]
        {
            $"https://login.microsoftonline.com/{tenantId}/v2.0"
        },
        scopes_supported = new[]
        {
            "mcp.tools.read",
            "mcp.tools.execute",
            "mcp.resources.read",
            "mcp.analytics.read"
        },
        bearer_methods_supported = new[] { "header" }
    });
});
```

### **3. Add 401 Challenge Middleware**

```csharp
// Add middleware to challenge unauthorized requests
app.Use(async (context, next) =>
{
    await next();
    
    if (context.Response.StatusCode == 401 && !context.Response.HasStarted)
    {
        var baseUrl = $"{context.Request.Scheme}://{context.Request.Host}";
        var metadataUrl = $"{baseUrl}/.well-known/oauth-protected-resource";
        
        context.Response.Headers.WWWAuthenticate = 
            $"Bearer resource_metadata=\"{metadataUrl}\", " +
            $"scope=\"mcp.tools.read mcp.tools.execute\"";
    }
});
```

### **4. Configure Entra ID Authentication**

```csharp
// Replace current JWT Bearer with Microsoft.Identity.Web
using Microsoft.Identity.Web;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("Authentication:Entra"));

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("McpToolsExecute", policy =>
        policy.RequireClaim("scp", "mcp.tools.execute"));
        
    options.AddPolicy("McpAnalyticsRead", policy =>
        policy.RequireClaim("scp", "mcp.analytics.read"));
});
```

### **5. Update appsettings.json**

```json
{
  "Authentication": {
    "Entra": {
      "Instance": "https://login.microsoftonline.com/",
      "TenantId": "{your-tenant-id}",
      "ClientId": "{your-app-registration-client-id}",
      "Audience": "api://{your-app-registration-client-id}",
      "TokenValidationParameters": {
        "ValidateIssuer": true,
        "ValidateAudience": true,
        "ValidateLifetime": true
      }
    }
  }
}
```

---

## 🔒 Security Considerations

### **From MCP Spec Section 11**

1. **Token Audience Binding (11.1)**: MUST validate tokens issued specifically for MCP server
2. **Token Theft (11.2)**: Use short-lived tokens, secure storage
3. **Communication Security (11.3)**: HTTPS everywhere (except localhost)
4. **Authorization Code Protection (11.4)**: MUST use PKCE with S256
5. **Open Redirection (11.5)**: Validate redirect URIs
6. **Confused Deputy (11.7)**: Do not pass through user tokens to API
7. **Token Passthrough (11.8)**: CRITICAL - MCP server must validate audience

### **Implementation Checklist**

- [ ] HTTPS enforcement (except localhost)
- [ ] PKCE with S256 code challenge
- [ ] Token audience validation (`aud` claim)
- [ ] No token passthrough (MCP → API uses service JWT)
- [ ] Short-lived access tokens (15-60 minutes)
- [ ] Refresh token rotation
- [ ] Secure token storage (client responsibility)
- [ ] Rate limiting on token endpoints
- [ ] Audit logging for authentication events
- [ ] CORS configuration for browser clients
- [ ] Content Security Policy headers

---

## 📚 Resources

### **Official Specifications**
- [MCP Authorization Specification](https://modelcontextprotocol.io/specification/draft/basic/authorization)
- [OAuth 2.1 (Draft)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-13)
- [RFC 9728: OAuth 2.0 Protected Resource Metadata](https://datatracker.ietf.org/doc/html/rfc9728)
- [RFC 8707: Resource Indicators for OAuth 2.0](https://www.rfc-editor.org/rfc/rfc8707.html)
- [OAuth Client ID Metadata Documents](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-client-id-metadata-document-00)

### **Microsoft Sample**
- [GitHub Repository](https://github.com/blackchoey/remote-mcp-apim-oauth-prm)
- Deploy command: `azd up`
- Includes full Azure infrastructure automation

### **Microsoft Documentation**
- [Microsoft Identity Platform](https://learn.microsoft.com/entra/identity-platform/)
- [Microsoft Entra External ID](https://learn.microsoft.com/entra/external-id/)
- [Managed Identity](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Microsoft.Identity.Web](https://learn.microsoft.com/azure/active-directory/develop/microsoft-identity-web)

### **Fabrikam Project Documents**
- [AUTHENTICATION.md](./AUTHENTICATION.md) - Current authentication implementation
- [DOCUMENTATION-INDEX.md](../DOCUMENTATION-INDEX.md) - Project documentation hub

---

## 🎯 Next Steps

### **Immediate Actions (This Week)**

1. **Clone and explore Microsoft sample**:
   ```powershell
   cd C:\Users\davidb\1Repositories
   git clone https://github.com/blackchoey/remote-mcp-apim-oauth-prm.git
   cd remote-mcp-apim-oauth-prm
   code .
   ```

2. **Deploy sample to Azure**:
   ```powershell
   azd up
   ```

3. **Test with VS Code**:
   - Add MCP server using endpoint from `azd up` output
   - Test authentication flow
   - Observe token validation
   - Try "Who am I?" query

4. **Document findings**:
   - How does PRM work in practice?
   - What's the user experience?
   - What Azure resources are needed?
   - How does Managed Identity work?

### **Planning Phase (Next 2 Weeks)**

1. Design Fabrikam-specific scope structure
2. Map roles to scopes
3. Update architecture diagrams
4. Create implementation plan
5. Get stakeholder approval

### **Implementation Phase (4-6 Weeks)**

1. Configure Entra External ID
2. Implement PRM in FabrikamMcp
3. Add OAuth 2.1 authentication
4. Test thoroughly
5. Deploy to dev environment
6. Security audit
7. Deploy to production

---

## 📞 Questions to Answer

1. **Backward Compatibility**: Do we need to support old JWT approach during transition?
2. **Scope Design**: What granularity of scopes do we need (per-tool vs. per-role)?
3. **User Experience**: How do we communicate the authentication change to users?
4. **Timeline**: What's the deadline for SDL compliance?
5. **Resources**: Who will implement this? (Backend team, security team, etc.)
6. **Testing**: What's the testing strategy for production deployment?
7. **Multi-tenancy**: Do we need to support multiple Entra tenants?

---

## ✅ Conclusion

**Current State**: Fabrikam MCP server uses JWT Bearer authentication with shared secrets - NOT SDL-compliant for production.

**Required State**: Implement OAuth 2.1 + Protected Resource Metadata with Microsoft Entra External ID - SDL-compliant, no shared secrets.

**Best Path Forward**: 
1. Clone and study Microsoft's sample implementation
2. Deploy it to Azure to see it working end-to-end
3. Adapt patterns to Fabrikam architecture
4. Implement PRM and OAuth 2.1 in FabrikamMcp
5. Migrate users from old JWT approach

**Estimated Effort**: 6-8 weeks (including learning, implementation, testing, deployment)

**Risk**: Medium - Well-documented patterns, Microsoft sample available, but significant architectural change

**Benefit**: High - SDL compliance, production-ready, no shared secrets, better security, per-user authorization
