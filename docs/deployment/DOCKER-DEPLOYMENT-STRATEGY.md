# 🐳 Docker Deployment Strategy

## Overview

This project uses a **hybrid deployment strategy** that maintains both Azure Web App CI/CD (for rapid development) and Docker containers (for production and self-hosted deployments).

## Deployment Architectures

### Architecture 1: Azure Web Apps (Existing - Development/Testing)

```
┌──────────────────┐
│  Git Push (main) │
└────────┬─────────┘
         │
         ▼
┌────────────────────────┐
│  GitHub Actions        │
│  - Build .NET project  │
│  - Deploy to Azure     │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  Azure App Services (4 instances)  │
│  - fabrikam-api-development        │
│  - fabrikam-mcp-development        │
│  - fabrikam-dash-development       │
│  - fabrikam-sim-development        │
└────────────────────────────────────┘

⏱️  Deployment Time: 3-5 minutes
💰 Cost: ~$60/month (4 instances)
🎯 Use Case: Daily development, testing, workshops
```

### Architecture 2: Docker Containers (New - Production/Self-Hosted)

```
┌─────────────────────┐
│  Git Tag (v1.x.x)   │
└────────┬────────────┘
         │
         ▼
┌──────────────────────────────┐
│  GitHub Actions              │
│  - Build Docker images       │
│  - Push to Docker Hub/ACR    │
│  - Tag with version + latest │
└────────┬─────────────────────┘
         │
         ├──────────────────────┬──────────────────────┐
         ▼                      ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Ubuntu Nodes    │  │  Azure Container │  │  Other Cloud/    │
│  (Home Network)  │  │  Apps (optional) │  │  On-Prem         │
│                  │  │                  │  │                  │
│  + Cloudflare    │  │  + Azure Front   │  │  + Your choice   │
│    Tunnel        │  │    Door          │  │    of SSL        │
│  + HTTPS (FREE)  │  │  + HTTPS (FREE)  │  │                  │
└──────────────────┘  └──────────────────┘  └──────────────────┘

⏱️  Deployment Time: 5-10 minutes (first), 1-2 min (updates)
💰 Cost: $0 (self-hosted) or ~$35/month (Azure Container Apps)
🎯 Use Case: Production, public MCP access, portability
```

## Workflow Comparison

### Daily Development Workflow (Azure Web Apps)

```bash
# 1. Make code changes
vim FabrikamApi/src/Controllers/OrdersController.cs

# 2. Commit and push
git add .
git commit -m "feat: add order filtering by date range"
git push origin main

# 3. Automatic deployment to Azure
# ✅ GitHub Actions triggers automatically
# ✅ Build completes in ~2 minutes
# ✅ Deploy completes in ~1 minute
# ✅ Test at https://fabrikam-api-development-tzjeje.azurewebsites.net

# 4. Iterate quickly - repeat steps 1-3
```

**Benefits:**
- ⚡ Fast feedback loop (3-5 minutes)
- 🔄 Automatic deployment on every push
- 🧪 Perfect for testing and iteration
- 👥 Great for team collaboration (workshop instances)

**Limitations:**
- 💰 Costs ~$15/month per instance
- 🔒 Azure-only (not portable)
- 🌐 Not ideal for public MCP server (needs custom domain setup)

---

### Production Release Workflow (Docker)

```bash
# 1. Development cycle complete (multiple commits on main)
git log --oneline
# a1b2c3d feat: add invoice duplicate detection
# d4e5f6g feat: improve customer analytics
# g7h8i9j fix: resolve order date timezone issue

# 2. Create version tag
git tag -a v1.2.0 -m "Release 1.2.0: Invoice features + analytics improvements"
git push origin v1.2.0

# 3. Automatic Docker build and push
# ✅ GitHub Actions triggers on tag
# ✅ Builds 4 Docker images in parallel
# ✅ Pushes to Docker Hub with version tags
# ✅ Images tagged as both v1.2.0 and latest

# 4. Deploy to Ubuntu nodes (automatic with Watchtower)
# ✅ Watchtower detects new :latest tag
# ✅ Pulls updated images
# ✅ Gracefully restarts containers
# ✅ Zero-downtime update

# 5. Verify deployment
curl https://fabrikam-mcp.csplevelup.com/status
# {"Status":"Ready","Version":"1.2.0",...}
```

**Benefits:**
- 📦 Portable (run anywhere: Ubuntu, AWS, GCP, Azure)
- 💰 Cost-effective (self-hosted = $0)
- 🔐 HTTPS with Cloudflare Tunnel (FREE)
- 🌍 Public MCP access for AI assistants
- 🔄 Easy rollback (docker pull fabrikam-mcp:v1.1.0)

**Limitations:**
- ⏱️ Slower than Azure Web Apps (5-10 min first build)
- 🛠️ Requires manual tagging (intentional - prevents accidental releases)

---

## Cloudflare Tunnel Strategy

### Why Cloudflare Tunnel?

Traditional HTTPS setup requires:
- ❌ Public IP address
- ❌ Router port forwarding (security risk)
- ❌ SSL certificate management
- ❌ DDoS protection setup
- ❌ Firewall configuration

Cloudflare Tunnel provides:
- ✅ FREE HTTPS with trusted certificate
- ✅ No public IP needed
- ✅ No port forwarding (works behind NAT)
- ✅ DDoS protection included
- ✅ Works from home network
- ✅ Zero-trust network access

### Architecture

```
┌──────────────────────────────────────────────────────┐
│  AI Assistants (GitHub Copilot, Copilot Studio)     │
└────────┬─────────────────────────────────────────────┘
         │
         │ HTTPS Request
         │ https://fabrikam-mcp.csplevelup.com/mcp
         ▼
┌──────────────────────────────────────────────────────┐
│  Cloudflare Network                                  │
│  - FREE SSL Certificate (*.csplevelup.com)          │
│  - DDoS Protection                                   │
│  - CDN (optional caching)                            │
└────────┬─────────────────────────────────────────────┘
         │
         │ Encrypted Tunnel (cloudflared)
         │ No ports opened on router!
         ▼
┌──────────────────────────────────────────────────────┐
│  Your Home Network / Ubuntu Node                     │
│  ┌────────────────────────────────────────────┐     │
│  │  Cloudflare Tunnel Container               │     │
│  │  (cloudflared)                              │     │
│  └────────┬───────────────────────────────────┘     │
│           │                                          │
│           │ HTTP (internal only)                     │
│           ▼                                          │
│  ┌────────────────────────────────────────────┐     │
│  │  Fabrikam MCP Container                    │     │
│  │  Port: 8080 (not exposed to internet)      │     │
│  └────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────┘
```

### Security Model

**Traditional Model (Requires Port Forwarding):**
```
Internet → Router:443 → Ubuntu:443 → MCP Container
         ⚠️ Attack surface: Direct internet exposure
```

**Cloudflare Tunnel Model:**
```
Internet → Cloudflare → Encrypted Tunnel → Ubuntu (no open ports) → MCP Container
         ✅ Attack surface: None (outbound tunnel only)
```

---

## Deployment Targets

### Target 1: Ubuntu Nodes (Home Network)

**Hardware:**
- Your Ubuntu nodes on local network
- Docker installed
- Cloudflare Tunnel for HTTPS

**Advantages:**
- 💰 Zero hosting cost
- ⚡ Low latency (local network)
- 🔧 Full control
- 🧪 Test environment

**Use Cases:**
- Production MCP server (public access via Cloudflare)
- Development testing on real hardware
- Learning Docker orchestration

---

### Target 2: Azure Container Apps (Optional Cloud Production)

**If you want Azure-hosted containers:**

```bash
# Deploy same Docker images to Azure
az containerapp up \
  --name fabrikam-mcp \
  --image davebirr/fabrikam-mcp:latest \
  --environment fabrikam-env \
  --ingress external \
  --target-port 8080
```

**Advantages:**
- ☁️ Managed infrastructure
- 🔄 Auto-scaling
- 🌍 Global distribution
- 🔐 Free managed SSL certificate (via Azure Front Door)

**Costs:**
- ~$15-35/month depending on usage

---

## Version Tagging Strategy

### Semantic Versioning

```bash
# Major version (breaking changes)
git tag -a v2.0.0 -m "Breaking: New authentication system"

# Minor version (new features, backward compatible)
git tag -a v1.3.0 -m "Feature: Add invoice duplicate detection"

# Patch version (bug fixes)
git tag -a v1.2.1 -m "Fix: Resolve date timezone handling in orders"
```

### Docker Image Tags

Each release creates multiple tags:

```
davebirr/fabrikam-api:latest        ← Always points to newest
davebirr/fabrikam-api:v1.2.0        ← Specific version (immutable)
davebirr/fabrikam-api:v1.2          ← Minor version (updates with patches)
davebirr/fabrikam-api:v1            ← Major version (updates with minors)
```

### Rollback Strategy

```bash
# If v1.2.0 has issues, rollback to v1.1.0
docker-compose down
docker pull davebirr/fabrikam-mcp:v1.1.0
# Update docker-compose.yml to use v1.1.0
docker-compose up -d

# Or use specific version tag
docker run -d davebirr/fabrikam-mcp:v1.1.0
```

---

## Configuration Management

### Environment-Specific Configuration

**Azure Web Apps (Current):**
```
appsettings.json                    ← Base configuration
appsettings.Development.json        ← Dev overrides
Azure App Settings (Portal)         ← Production secrets
```

**Docker Containers (New):**
```
appsettings.json                    ← Base configuration
docker-compose.yml                  ← Development config
docker-compose.prod.yml             ← Production config
.env (not committed)                ← Secrets (local)
Azure Key Vault (optional)          ← Secrets (cloud)
```

### Example: Database Connection

**Azure Web App:**
```bash
# Set in Azure Portal → Configuration → Application Settings
ConnectionStrings__FabrikamDb=Server=...;Database=...;
```

**Docker Container:**
```yaml
# docker-compose.prod.yml
services:
  fabrikam-api:
    environment:
      - ConnectionStrings__FabrikamDb=${FABRIKAM_DB_CONNECTION}
```

```bash
# .env (not committed to git)
FABRIKAM_DB_CONNECTION=Server=...;Database=...;
```

---

## Migration Path

### Phase 1: Setup (Week 1)
- ✅ Create Dockerfiles for all services
- ✅ Create docker-compose.yml for local testing
- ✅ Create GitHub Actions workflow for Docker builds
- ✅ Test locally with `docker-compose up`
- ✅ Document setup process

### Phase 2: Cloudflare Tunnel (Week 2)
- ✅ Setup Cloudflare account (free tier)
- ✅ Configure DNS: fabrikam-mcp.csplevelup.com
- ✅ Install cloudflared on Ubuntu node
- ✅ Create persistent tunnel configuration
- ✅ Test HTTPS access from GitHub Copilot

### Phase 3: Production Deployment (Week 3)
- ✅ Deploy to Ubuntu nodes with Watchtower auto-updates
- ✅ Create first production release (v1.0.0)
- ✅ Test MCP server with AI assistants
- ✅ Monitor and validate

### Phase 4: Optimization (Ongoing)
- ✅ Add health checks
- ✅ Configure monitoring (Prometheus/Grafana)
- ✅ Implement backup strategies
- ✅ Add staging environment (optional)

---

## Costs Comparison

### Current Setup (Azure Web Apps Only)

| Service | Cost/Month |
|---------|------------|
| API (B1) | $15 |
| MCP (B1) | $15 |
| Dashboard (B1) | $15 |
| Simulator (B1) | $15 |
| **Total** | **$60/month** |

### Hybrid Setup (Azure + Docker)

| Service | Cost/Month |
|---------|------------|
| Azure Web Apps (dev/test) | $60 |
| Ubuntu Node (self-hosted) | $0 |
| Cloudflare Tunnel | $0 |
| Docker Hub (free tier) | $0 |
| **Total** | **$60/month** |

*(Same cost, but adds production-ready self-hosted option)*

### Future: Docker-Only (Optional)

| Service | Cost/Month |
|---------|------------|
| Ubuntu Node (self-hosted) | $0 |
| Cloudflare Tunnel | $0 |
| **Total** | **$0/month** |

*(Could retire Azure Web Apps if no longer needed)*

---

## Next Steps

1. **Create Docker Infrastructure** (This PR)
   - Dockerfiles for all 4 services
   - docker-compose.yml
   - .dockerignore
   - GitHub Actions workflow

2. **Test Locally**
   ```bash
   docker-compose up --build
   ```

3. **Setup Cloudflare Tunnel**
   - Follow: `docs/deployment/CLOUDFLARE-TUNNEL-SETUP.md`

4. **Deploy to Ubuntu**
   - Follow: `docs/deployment/UBUNTU-DEPLOYMENT.md`

5. **First Production Release**
   ```bash
   git tag -a v1.0.0 -m "Initial production release"
   git push origin v1.0.0
   ```

---

## Documentation Index

- [Docker Build Guide](./DOCKER-BUILD-GUIDE.md)
- [Cloudflare Tunnel Setup](./CLOUDFLARE-TUNNEL-SETUP.md)
- [Ubuntu Deployment Guide](./UBUNTU-DEPLOYMENT.md)
- [Troubleshooting Docker Issues](./DOCKER-TROUBLESHOOTING.md)
- [Azure Container Apps Deployment](./AZURE-CONTAINER-APPS.md) (optional)

---

## Support and Questions

For issues or questions about Docker deployment:
1. Check [DOCKER-TROUBLESHOOTING.md](./DOCKER-TROUBLESHOOTING.md)
2. Review container logs: `docker-compose logs -f`
3. Check Cloudflare Tunnel status: `docker logs cloudflared`

For Azure Web App deployments:
1. Check existing documentation
2. Review GitHub Actions logs
3. Check Azure Portal diagnostics
