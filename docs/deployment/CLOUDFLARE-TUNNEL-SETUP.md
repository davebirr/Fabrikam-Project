# 🌐 Cloudflare Tunnel Setup Guide

This guide explains how to set up a FREE Cloudflare Tunnel to expose your Fabrikam MCP server to the internet with HTTPS, without requiring port forwarding or public IP addresses.

## 📋 Table of Contents

- [Why Cloudflare Tunnel?](#why-cloudflare-tunnel)
- [Prerequisites](#prerequisites)
- [Step 1: Create Cloudflare Account](#step-1-create-cloudflare-account)
- [Step 2: Add Your Domain](#step-2-add-your-domain)
- [Step 3: Create Cloudflare Tunnel](#step-3-create-cloudflare-tunnel)
- [Step 4: Configure Tunnel](#step-4-configure-tunnel)
- [Step 5: Get Tunnel Token](#step-5-get-tunnel-token)
- [Step 6: Update Production Config](#step-6-update-production-config)
- [Step 7: Start Services](#step-7-start-services)
- [Step 8: Verify HTTPS Access](#step-8-verify-https-access)
- [Security Configuration](#security-configuration)
- [Troubleshooting](#troubleshooting)

## 🎯 Why Cloudflare Tunnel?

**Benefits:**
- ✅ **FREE HTTPS** - Trusted certificates automatically managed
- ✅ **No port forwarding** - Works behind NAT/firewall
- ✅ **No public IP needed** - Tunnel creates outbound connection
- ✅ **DDoS protection** - Cloudflare's global network
- ✅ **Access controls** - Optional authentication layers
- ✅ **AI assistant compatible** - GitHub Copilot, Copilot Studio, etc.

**Comparison:**
| Solution | Cost | Setup Complexity | HTTPS Support | Port Forwarding Required |
|----------|------|------------------|---------------|-------------------------|
| Cloudflare Tunnel | $0/year | Medium | ✅ Free | ❌ No |
| Azure App Service Cert | $69.99/year | Easy | ✅ Paid | N/A (Azure) |
| Let's Encrypt | $0/year | Hard | ✅ Free | ✅ Yes |
| Self-signed | $0/year | Easy | ⚠️ Untrusted | ✅ Yes |

## 📦 Prerequisites

- **Domain name** you own (e.g., `csplevelup.com`)
- **Cloudflare account** (free tier is fine)
- **Docker Compose** installed on Ubuntu node
- **Internet connection** from Ubuntu node

## Step 1: Create Cloudflare Account

1. Go to [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Create a free account
3. Verify your email address
4. Log in to Cloudflare dashboard

## Step 2: Add Your Domain

1. Click **"Add a Site"** in Cloudflare dashboard
2. Enter your domain (e.g., `csplevelup.com`)
3. Select **Free plan**
4. Cloudflare will scan your DNS records
5. Update your domain's nameservers at your registrar:
   - Go to your domain registrar (e.g., GoDaddy, Namecheap)
   - Replace existing nameservers with Cloudflare's (shown in dashboard)
   - Example Cloudflare nameservers:
     ```
     aaron.ns.cloudflare.com
     bridget.ns.cloudflare.com
     ```
6. Wait for DNS propagation (usually 5-30 minutes)
7. Cloudflare will email you when activation is complete

### Verify Domain Active

```bash
# Check nameservers
nslookup -type=ns csplevelup.com

# Should show Cloudflare nameservers
```

## Step 3: Create Cloudflare Tunnel

1. In Cloudflare dashboard, select your domain
2. Navigate to **Zero Trust** (left sidebar)
3. Go to **Networks** → **Tunnels**
4. Click **"Create a tunnel"**
5. Choose **"Cloudflared"** connector type
6. Name your tunnel: `fabrikam-mcp-production`
7. Click **"Save tunnel"**

## Step 4: Configure Tunnel

### 4.1 Connector Setup

Cloudflare will show installation instructions. **Skip these** - we'll use Docker instead.

### 4.2 Public Hostname Configuration

1. Click **"Add a public hostname"**
2. Configure:
   - **Subdomain**: `fabrikam-mcp`
   - **Domain**: `csplevelup.com` (select from dropdown)
   - **Full hostname**: `fabrikam-mcp.csplevelup.com`
3. **Service** section:
   - **Type**: `HTTP`
   - **URL**: `fabrikam-mcp:8080`
     - ⚠️ Use the Docker service name, NOT localhost
     - ⚠️ Use port 8080 (internal container port)
4. **Advanced settings** (expand):
   - **TLS verification**: ❌ Disable (internal HTTP is OK)
   - **No TLS verify**: ✅ Enable
   - **HTTP Host Header**: Leave empty
5. Click **"Save hostname"**

### Configuration Result

```
Tunnel: fabrikam-mcp-production
Public URL: https://fabrikam-mcp.csplevelup.com
Origin: http://fabrikam-mcp:8080
```

## Step 5: Get Tunnel Token

1. In the tunnel configuration page, find **"Install and run a connector"**
2. Copy the full Docker command shown (example):
   ```bash
   docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiNGE...
   ```
3. Extract the **token** (everything after `--token `):
   ```
   eyJhIjoiNGE4YjZlMWQtZTBjYi00ZTBkLWJkNGMtYjk2ZjQyZTU4YmQ5IiwidCI6IjdmYmY0ZTZiLTNmMzYtNGQyZi1hNzM1LWQ0YjVjNjE4ZDQ1YyIsInMiOiJZVFE0TXpJek16QT0ifQ==
   ```
4. **Save this token securely** - you'll need it for Docker Compose

## Step 6: Update Production Config

On your Ubuntu node, create/update `.env` file:

```bash
cd ~/fabrikam-project  # Or your deployment directory

# Create .env file
nano .env
```

Add these variables:

```bash
# Docker Registry
DOCKER_REGISTRY=davebirr

# Version to deploy
VERSION=latest

# Cloudflare Tunnel Token (REQUIRED)
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiNGE4YjZlMWQtZTBjYi00ZTBkLWJkNGMtYjk2ZjQyZTU4YmQ5IiwidCI6IjdmYmY0ZTZiLTNmMzYtNGQyZi1hNzM1LWQ0YjVjNjE4ZDQ1YyIsInMiOiJZVFE0TXpJek16QT0ifQ==

# Authentication (optional - start with Disabled)
AUTH_MODE=Disabled

# JWT Configuration (only if AUTH_MODE=BearerToken)
# JWT_SECRET_KEY=your-secret-key-here
# JWT_ISSUER=https://fabrikam-mcp.csplevelup.com
# JWT_AUDIENCE=FabrikamMcp
```

**Security Note**: Never commit `.env` file to git!

```bash
# Add to .gitignore (already configured in project)
echo ".env" >> .gitignore
```

## Step 7: Start Services

```bash
# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Start core services (API + MCP + Cloudflare Tunnel)
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Look for success messages:
# - fabrikam-api: "Application started. Press Ctrl+C to shut down."
# - fabrikam-mcp: "Now listening on: http://[::]:8080"
# - cloudflared: "Connection registered" (shows Cloudflare connection successful)
```

### Verify Tunnel Connection

Check Cloudflare Tunnel status:

```bash
docker-compose -f docker-compose.prod.yml logs cloudflared | grep -i "connection registered"
```

Should show:
```
cloudflared | Connection registered connIndex=0 location=DFW
cloudflared | Connection registered connIndex=1 location=ATL
cloudflared | Connection registered connIndex=2 location=ORD
cloudflared | Connection registered connIndex=3 location=IAD
```

## Step 8: Verify HTTPS Access

### Test from External Machine

```bash
# Basic connectivity
curl https://fabrikam-mcp.csplevelup.com/status

# Expected response:
{
  "status": "OK",
  "environment": "Production",
  "version": "1.0.0"
}
```

### Test MCP Protocol

```bash
# List available MCP tools
curl -X POST https://fabrikam-mcp.csplevelup.com/mcp/v1/tools/list \
  -H "Content-Type: application/json" \
  -d '{}'

# Expected: JSON array of available tools
```

### Test in GitHub Copilot

1. Open VS Code or GitHub Copilot Chat
2. Go to Copilot settings
3. Add MCP server:
   ```json
   {
     "mcpServers": {
       "fabrikam": {
         "url": "https://fabrikam-mcp.csplevelup.com"
       }
     }
   }
   ```
4. Ask Copilot: "What Fabrikam tools are available?"

## 🔒 Security Configuration

### Enable Authentication (Optional)

After verifying basic connectivity, enable JWT authentication:

1. **Generate secret key:**
   ```bash
   openssl rand -base64 32
   ```

2. **Update `.env` file:**
   ```bash
   AUTH_MODE=BearerToken
   JWT_SECRET_KEY=your-generated-secret-here
   JWT_ISSUER=https://fabrikam-mcp.csplevelup.com
   JWT_AUDIENCE=FabrikamMcp
   ```

3. **Restart services:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

4. **Test with authentication:**
   ```bash
   # Generate token (use your actual secret)
   # Then include in requests:
   curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     https://fabrikam-mcp.csplevelup.com/status
   ```

### Cloudflare Access Policies (Advanced)

Add additional security layer via Cloudflare Zero Trust:

1. In Cloudflare dashboard → **Zero Trust** → **Access** → **Applications**
2. Click **"Add an application"**
3. Choose **"Self-hosted"**
4. Configure:
   - **Application name**: Fabrikam MCP
   - **Subdomain**: `fabrikam-mcp`
   - **Domain**: `csplevelup.com`
5. Add policies:
   - **Allow**: Emails ending in `@microsoft.com`
   - **Require**: Email verification
6. Save and test

This adds Cloudflare's authentication **before** requests reach your MCP server.

## 🔧 Troubleshooting

### Tunnel Not Connecting

**Symptoms:**
- `cloudflared` container logs show connection errors
- Public URL returns 502 Bad Gateway

**Solutions:**

1. **Verify token:**
   ```bash
   # Check environment variable is set
   docker-compose -f docker-compose.prod.yml config | grep CLOUDFLARE_TUNNEL_TOKEN
   ```

2. **Restart tunnel:**
   ```bash
   docker-compose -f docker-compose.prod.yml restart cloudflared
   docker-compose -f docker-compose.prod.yml logs -f cloudflared
   ```

3. **Check network:**
   ```bash
   # Verify cloudflared can reach Cloudflare servers
   docker exec cloudflare-tunnel ping -c 3 1.1.1.1
   ```

### MCP Server Not Responding

**Symptoms:**
- Tunnel connects but MCP endpoints return errors
- Health checks failing

**Solutions:**

1. **Verify MCP server is healthy:**
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   # fabrikam-mcp-prod should show "healthy"
   
   # Check health endpoint directly
   docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status
   ```

2. **Check MCP server logs:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs fabrikam-mcp
   ```

3. **Verify API connectivity:**
   ```bash
   # MCP depends on API - ensure API is healthy
   docker-compose -f docker-compose.prod.yml logs fabrikam-api
   ```

### DNS Not Resolving

**Symptoms:**
- `curl` shows "could not resolve host"
- `nslookup` fails

**Solutions:**

1. **Verify Cloudflare nameservers:**
   ```bash
   nslookup -type=ns csplevelup.com
   ```

2. **Check DNS propagation:**
   - Visit: https://dnschecker.org
   - Enter: `fabrikam-mcp.csplevelup.com`
   - Should show Cloudflare IPs globally

3. **Clear DNS cache:**
   ```bash
   # Ubuntu
   sudo systemd-resolve --flush-caches
   
   # macOS
   sudo dscacheutil -flushcache
   
   # Windows
   ipconfig /flushdns
   ```

### Certificate Errors

**Symptoms:**
- Browser shows "Your connection is not private"
- `curl` shows SSL certificate errors

**Solutions:**

1. **Verify Cloudflare SSL mode:**
   - Cloudflare dashboard → **SSL/TLS** → **Overview**
   - Set to **"Full"** or **"Full (strict)"**

2. **Check certificate:**
   ```bash
   curl -vI https://fabrikam-mcp.csplevelup.com 2>&1 | grep -i certificate
   ```

3. **Verify tunnel configuration:**
   - Ensure service URL is `http://fabrikam-mcp:8080` (HTTP, not HTTPS)
   - Cloudflare handles HTTPS termination

### Watchtower Not Updating

**Symptoms:**
- New version pushed but containers not updating
- Watchtower logs show no activity

**Solutions:**

1. **Check Watchtower logs:**
   ```bash
   docker logs watchtower
   ```

2. **Verify poll interval:**
   ```bash
   docker inspect watchtower | grep WATCHTOWER_POLL_INTERVAL
   # Should show 300 (5 minutes)
   ```

3. **Manually trigger update:**
   ```bash
   docker-compose -f docker-compose.prod.yml pull
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 🔗 Additional Resources

- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Watchtower Docs**: https://containrrr.dev/watchtower/
- **Fabrikam Project Docs**:
  - [Docker Deployment Strategy](./DOCKER-DEPLOYMENT-STRATEGY.md)
  - [Ubuntu Deployment Guide](./UBUNTU-DEPLOYMENT.md)
  - [Docker Troubleshooting](./DOCKER-TROUBLESHOOTING.md)

## 📞 Support

- **GitHub Issues**: https://github.com/{owner}/{repo}/issues
- **Cloudflare Community**: https://community.cloudflare.com/
- **Docker Community**: https://forums.docker.com/

---

**✅ Once configured, your MCP server is accessible at:**
```
https://fabrikam-mcp.csplevelup.com
```

**🤖 Compatible with:**
- GitHub Copilot
- Microsoft Copilot Studio
- Any MCP-compatible AI assistant
- Standard HTTP clients (curl, Postman, etc.)

**🔒 Security:**
- HTTPS with trusted Cloudflare certificate
- No open ports on your network
- Optional JWT authentication
- Optional Cloudflare Access policies
