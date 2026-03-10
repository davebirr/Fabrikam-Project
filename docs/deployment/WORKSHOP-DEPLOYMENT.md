# 🎓 Workshop Deployment Guide

Complete guide for deploying Fabrikam platform for workshop participants with authenticated access to API, Dashboard, and MCP server.

## 📋 Overview

This deployment exposes **three services** via Cloudflare Tunnels with JWT authentication:

- **API Server**: `https://fabrikam-api.csplevelup.com` - REST API for business operations
- **Dashboard**: `https://fabrikam-dashboard.csplevelup.com` - Real-time Blazor dashboard
- **MCP Server**: `https://fabrikam-mcp.csplevelup.com` - Model Context Protocol for AI assistants

## 🏗️ Architecture

```
Workshop Participants → Internet (HTTPS)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
Cloudflare Edge    Cloudflare Edge    Cloudflare Edge
   (API URL)       (Dashboard URL)     (MCP URL)
        │                  │                  │
        │    Encrypted Tunnels (Outbound)    │
        │                  │                  │
        ▼                  ▼                  ▼
   ┌────────────────────────────────────────────┐
   │          Ubuntu Node (Docker Host)         │
   ├────────────────────────────────────────────┤
   │  Tunnel-API    Tunnel-Dashboard  Tunnel-MCP│
   │       │              │                │     │
   │       ▼              ▼                ▼     │
   │  API Server    Dashboard        MCP Server │
   │  (JWT Auth)    (JWT Auth)      (Optional)  │
   │       │              │                │     │
   │       └──────────────┴────────────────┘     │
   │                                              │
   │  Watchtower (auto-updates every 5 min)      │
   └────────────────────────────────────────────┘
```

## 🎯 Prerequisites

- Ubuntu server (20.04+ or 22.04 LTS)
- Docker and Docker Compose installed
- Cloudflare account with domain (csplevelup.com)
- Docker Hub account (for pulling images)

## 🔐 Step 1: Generate JWT Secret

Workshop participants will authenticate using JWT tokens. Generate a strong secret:

```bash
# Generate JWT secret key
openssl rand -base64 32

# Example output:
# XK7jP9mN2wQ8vR5tY1hF6gA3zL4bC0dE8fG2iJ5kM9n=

# Save this securely - you'll need it in .env file and for generating participant tokens
```

**⚠️ CRITICAL**: This secret must be:
- Kept confidential
- The same across all services (API, Dashboard, MCP if enabled)
- Used to generate participant JWT tokens

## 🌐 Step 2: Create Three Cloudflare Tunnels

### 2.1 Login to Cloudflare Dashboard

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **"Create a tunnel"**

### 2.2 Create MCP Tunnel

**Tunnel Name**: `fabrikam-mcp-production`

**Public Hostname Configuration**:
- **Subdomain**: `fabrikam-mcp`
- **Domain**: `csplevelup.com`
- **Service Type**: `HTTP`
- **Service URL**: `fabrikam-mcp:8080`
- **TLS verification**: ❌ Disabled

**Save tunnel token** as `CLOUDFLARE_TUNNEL_TOKEN_MCP`

### 2.3 Create API Tunnel

**Tunnel Name**: `fabrikam-api-production`

**Public Hostname Configuration**:
- **Subdomain**: `fabrikam-api`
- **Domain**: `csplevelup.com`
- **Service Type**: `HTTP`
- **Service URL**: `fabrikam-api:8080`
- **TLS verification**: ❌ Disabled

**Save tunnel token** as `CLOUDFLARE_TUNNEL_TOKEN_API`

### 2.4 Create Dashboard Tunnel

**Tunnel Name**: `fabrikam-dashboard-production`

**Public Hostname Configuration**:
- **Subdomain**: `fabrikam-dashboard`
- **Domain**: `csplevelup.com`
- **Service Type**: `HTTP`
- **Service URL**: `fabrikam-dashboard:8080`
- **TLS verification**: ❌ Disabled

**Save tunnel token** as `CLOUDFLARE_TUNNEL_TOKEN_DASHBOARD`

## 📝 Step 3: Configure Environment

On your Ubuntu node, create `.env` file:

```bash
cd /opt/fabrikam  # Or your deployment directory
nano .env
```

Add configuration:

```bash
# Docker Registry
DOCKER_REGISTRY=davebirr
VERSION=latest

# Cloudflare Tunnel Tokens
CLOUDFLARE_TUNNEL_TOKEN_MCP=eyJh...    # From Step 2.2
CLOUDFLARE_TUNNEL_TOKEN_API=eyJh...    # From Step 2.3
CLOUDFLARE_TUNNEL_TOKEN_DASHBOARD=eyJh... # From Step 2.4

# JWT Authentication (from Step 1)
JWT_SECRET_KEY=XK7jP9mN2wQ8vR5tY1hF6gA3zL4bC0dE8fG2iJ5kM9n=
JWT_ISSUER=https://fabrikam-api.csplevelup.com
JWT_AUDIENCE=FabrikamApi

# MCP Authentication (optional - can stay Disabled for AI assistants)
AUTH_MODE=Disabled
```

Secure the file:

```bash
chmod 600 .env
```

## 🚀 Step 4: Deploy Services

```bash
# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Start all services (API, MCP, Dashboard + 3 tunnels)
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Look for success messages:
# - "Connection registered" from all three cloudflared containers
# - "Application started" from API, MCP, Dashboard
```

## ✅ Step 5: Verify Deployment

### 5.1 Check Container Status

```bash
docker-compose -f docker-compose.prod.yml ps

# Expected output:
# fabrikam-api-prod              Up (healthy)
# fabrikam-mcp-prod              Up (healthy)
# fabrikam-dashboard-prod        Up (healthy)
# cloudflare-tunnel-api          Up
# cloudflare-tunnel-mcp          Up
# cloudflare-tunnel-dashboard    Up
# watchtower                     Up
```

### 5.2 Test Tunnel Connections

```bash
# Check all tunnels connected
docker logs cloudflare-tunnel-api | grep "Connection registered"
docker logs cloudflare-tunnel-mcp | grep "Connection registered"
docker logs cloudflare-tunnel-dashboard | grep "Connection registered"

# Should see 4 connections each to different Cloudflare locations
```

### 5.3 Test Public URLs (Without Auth)

```bash
# These will fail with 401 Unauthorized (expected - auth required)
curl -I https://fabrikam-api.csplevelup.com/api/products
curl -I https://fabrikam-dashboard.csplevelup.com

# MCP should work (if AUTH_MODE=Disabled)
curl https://fabrikam-mcp.csplevelup.com/status
```

## 🎫 Step 6: Generate Workshop Participant Tokens

Workshop participants need JWT tokens to access API and Dashboard. You have two options:

### Option A: Use Existing Workshop Account System

Your workshop already has account provisioning scripts:

```bash
cd workshops/cs-agent-a-thon/infrastructure/scripts

# This will use your JWT_SECRET_KEY to generate tokens
# Update the script to use your production secret
```

### Option B: Generate Tokens Manually

Create a token generation script:

```bash
nano generate-workshop-token.sh
```

```bash
#!/bin/bash
# Generate JWT token for workshop participant

USER_GUID=$1
USER_EMAIL=$2

if [ -z "$USER_GUID" ] || [ -z "$USER_EMAIL" ]; then
  echo "Usage: $0 <user-guid> <user-email>"
  exit 1
fi

# Load JWT secret from .env
source .env

# Generate token (expires in 30 days)
# This is a simplified example - use proper JWT library in production
echo "Token for $USER_EMAIL"
echo "User GUID: $USER_GUID"
echo ""
echo "Add to workshop participant documentation:"
echo "Authorization: Bearer <generated-token>"
```

**Better Option**: Use the workshop provisioning scripts that already generate tokens with proper expiration.

### Option C: Use Workshop Provisioning System

Your existing workshop infrastructure (in `workshops/cs-agent-a-thon/infrastructure/`) has:

1. **Account creation scripts** - Create Entra ID accounts
2. **Token generation** - Generate JWT tokens for participants
3. **Email templates** - Send credentials to participants

Update those scripts to use your production JWT_SECRET_KEY and API URL.

## 📧 Step 7: Distribute Access to Participants

Provide each workshop participant with:

1. **URLs**:
   - API: `https://fabrikam-api.csplevelup.com`
   - Dashboard: `https://fabrikam-dashboard.csplevelup.com`
   - MCP: `https://fabrikam-mcp.csplevelup.com`

2. **JWT Token** (generated in Step 6)

3. **Usage Instructions**:
   ```bash
   # API Access
   curl -H "Authorization: Bearer <their-jwt-token>" \
     https://fabrikam-api.csplevelup.com/api/products

   # Dashboard Access
   # Open browser to: https://fabrikam-dashboard.csplevelup.com
   # Login with provided credentials

   # MCP Access (for AI assistants)
   # Add to VS Code settings:
   {
     "mcpServers": {
       "fabrikam": {
         "url": "https://fabrikam-mcp.csplevelup.com"
       }
     }
   }
   ```

## 🔒 Security Considerations

### JWT Token Security

✅ **DO**:
- Generate strong secret with `openssl rand -base64 32`
- Set reasonable expiration (30 days for workshop)
- Distribute tokens securely (email, secure portal)
- Rotate tokens if compromised

❌ **DON'T**:
- Commit JWT_SECRET_KEY to git
- Use simple/guessable secrets
- Share tokens publicly
- Reuse tokens across environments

### Additional Cloudflare Security (Optional)

Add authentication layer via Cloudflare Access:

1. Go to **Zero Trust** → **Access** → **Applications**
2. Create application for each hostname
3. Add policy: Allow emails from `@microsoft.com` (or participant domain)
4. Require email verification

This adds **double authentication**: Cloudflare Access + JWT tokens.

## 🔧 Maintenance Operations

### Update to New Version

```bash
# Edit .env
nano .env
# Change: VERSION=v1.1.0

# Pull and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### Rotate JWT Secret

```bash
# 1. Generate new secret
openssl rand -base64 32

# 2. Update .env file
nano .env
# Update JWT_SECRET_KEY=new-secret

# 3. Restart services
docker-compose -f docker-compose.prod.yml restart fabrikam-api fabrikam-dashboard

# 4. Regenerate all participant tokens with new secret

# 5. Notify participants of new tokens
```

### Monitor Service Health

```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Check specific service
docker logs fabrikam-api-prod --tail=100

# Monitor resource usage
docker stats
```

## 🐛 Troubleshooting

### Participants Get 401 Unauthorized

**Cause**: Invalid or expired JWT token

**Solution**:
1. Verify JWT_SECRET_KEY is correct in .env
2. Regenerate token for participant
3. Check token expiration
4. Verify token is included in Authorization header

### Dashboard Won't Load

**Cause**: Tunnel not connected or Dashboard not healthy

**Solution**:
```bash
# Check Dashboard health
docker inspect fabrikam-dashboard-prod | jq '.[0].State.Health'

# Check tunnel logs
docker logs cloudflare-tunnel-dashboard

# Restart Dashboard
docker-compose -f docker-compose.prod.yml restart fabrikam-dashboard

# Check if API is healthy (Dashboard depends on it)
curl http://localhost:8080/health  # From inside Dashboard container
```

### MCP Server Not Accessible

**Cause**: AUTH_MODE=BearerToken but no token provided

**Solution**:
- If for AI assistants: Set `AUTH_MODE=Disabled` in .env
- If for security: Generate MCP-specific tokens and configure assistants

### Tunnels Not Connecting

**Cause**: Invalid tunnel tokens

**Solution**:
```bash
# Verify tokens in .env
docker-compose -f docker-compose.prod.yml config | grep CLOUDFLARE_TUNNEL_TOKEN

# Check tunnel logs
docker logs cloudflare-tunnel-api
docker logs cloudflare-tunnel-dashboard
docker logs cloudflare-tunnel-mcp

# Regenerate tokens in Cloudflare dashboard if needed
```

## 📊 Workshop Monitoring Dashboard

Create monitoring dashboard to track participant activity:

```bash
# View API request logs
docker logs fabrikam-api-prod | grep "HTTP"

# Count active users (unique JWT tokens used)
docker logs fabrikam-api-prod | grep "Authorization" | sort | uniq | wc -l

# Monitor Dashboard connections
docker logs fabrikam-dashboard-prod | grep "Connection"
```

## 🔗 Related Documentation

- **Cloudflare Tunnel Setup**: [CLOUDFLARE-TUNNEL-SETUP.md](./CLOUDFLARE-TUNNEL-SETUP.md)
- **Ubuntu Deployment**: [UBUNTU-DEPLOYMENT.md](./UBUNTU-DEPLOYMENT.md)
- **Docker Troubleshooting**: [DOCKER-TROUBLESHOOTING.md](./DOCKER-TROUBLESHOOTING.md)
- **Workshop Infrastructure**: `workshops/cs-agent-a-thon/infrastructure/`

## ✅ Post-Workshop Cleanup

After workshop ends:

```bash
# Option 1: Stop services but keep data
docker-compose -f docker-compose.prod.yml down

# Option 2: Full cleanup
docker-compose -f docker-compose.prod.yml down -v
docker system prune -a --volumes -f

# Disable Cloudflare Tunnels in dashboard
# Delete tunnel configurations
```

## 📝 Workshop Checklist

### Pre-Workshop
- [ ] All three Cloudflare Tunnels created and tested
- [ ] JWT_SECRET_KEY generated and secured
- [ ] Services deployed and healthy
- [ ] Test participant token generated and verified
- [ ] Workshop participant accounts provisioned
- [ ] JWT tokens generated and distributed
- [ ] Documentation sent to participants
- [ ] Backup plan documented

### During Workshop
- [ ] Monitor service health
- [ ] Watch for authentication errors
- [ ] Help participants with connection issues
- [ ] Monitor resource usage
- [ ] Have token regeneration process ready

### Post-Workshop
- [ ] Gather participant feedback
- [ ] Disable workshop accounts (if using Entra ID)
- [ ] Rotate JWT secret
- [ ] Archive workshop logs
- [ ] Document lessons learned
- [ ] Consider disabling tunnels until next workshop

---

**✅ Workshop deployment complete!**

Participants can now access:
- 🌐 **API**: `https://fabrikam-api.csplevelup.com`
- 📊 **Dashboard**: `https://fabrikam-dashboard.csplevelup.com`
- 🤖 **MCP Server**: `https://fabrikam-mcp.csplevelup.com`

All with secure JWT authentication! 🔐
