# 🔧 Docker Troubleshooting Guide

This guide covers common issues when running Fabrikam platform with Docker and their solutions.

## 📋 Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Container Issues](#container-issues)
- [Networking Problems](#networking-problems)
- [Health Check Failures](#health-check-failures)
- [Cloudflare Tunnel Issues](#cloudflare-tunnel-issues)
- [Performance Problems](#performance-problems)
- [Image Build Errors](#image-build-errors)
- [Watchtower Issues](#watchtower-issues)
- [Data Persistence](#data-persistence)
- [Authentication Errors](#authentication-errors)
- [Advanced Debugging](#advanced-debugging)

## 🔍 Quick Diagnostics

### Check Overall System Status

```bash
# Container status
docker compose -f docker-compose.prod.yml ps

# Resource usage
docker stats --no-stream

# Disk space
df -h

# Docker disk usage
docker system df
```

### View Recent Logs

```bash
# Last 50 lines from all services
docker compose -f docker-compose.prod.yml logs --tail=50

# Last 100 lines from specific service
docker compose -f docker-compose.prod.yml logs --tail=100 fabrikam-mcp

# Follow logs in real-time
docker compose -f docker-compose.prod.yml logs -f
```

### Quick Health Check

```bash
# Test all services
for service in fabrikam-api fabrikam-mcp; do
  echo "Testing $service..."
  docker exec ${service}-prod curl -f http://localhost:8080/health || echo "FAILED"
done

# Test Cloudflare Tunnel connectivity
docker logs cloudflare-tunnel 2>&1 | grep -i "connection registered" || echo "Tunnel not connected"
```

## 🐳 Container Issues

### Container Won't Start

**Symptoms:**
- Container exits immediately after starting
- Status shows "Exited (1)" or "Restarting"

**Diagnostic Steps:**

```bash
# Check container logs
docker logs fabrikam-mcp-prod

# Check last exit code
docker inspect fabrikam-mcp-prod | jq '.[0].State.ExitCode'

# Check error message
docker inspect fabrikam-mcp-prod | jq '.[0].State.Error'
```

**Common Causes & Solutions:**

1. **Missing Environment Variables**

   ```bash
   # Verify .env file exists and is readable
   ls -la .env
   cat .env
   
   # Check environment variables loaded into container
   docker inspect fabrikam-mcp-prod | jq '.[0].Config.Env'
   ```

   **Solution**: Ensure all required variables are in `.env` file:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=...  # Required for cloudflared
   DOCKER_REGISTRY=davebirr     # Required for image names
   VERSION=latest                # Required for image tags
   ```

2. **Port Already in Use**

   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep 5173
   
   # Or with ss
   sudo ss -tulpn | grep 5173
   ```

   **Solution**: Stop conflicting service or change port in `docker-compose.prod.yml`

3. **Permission Issues**

   ```bash
   # Check container user
   docker inspect fabrikam-mcp-prod | jq '.[0].Config.User'
   
   # Check file permissions
   docker exec fabrikam-mcp-prod ls -la /app
   ```

   **Solution**: Containers run as non-root user `fabrikam:1000` - ensure files are readable

### Container Keeps Restarting

**Symptoms:**
- Container starts but exits shortly after
- Status shows "Restarting (1)" repeatedly

**Diagnostic Steps:**

```bash
# Watch container status
watch -n 1 'docker ps -a | grep fabrikam'

# Check restart count
docker inspect fabrikam-mcp-prod | jq '.[0].RestartCount'

# View crash logs
docker logs fabrikam-mcp-prod --tail=100
```

**Common Causes & Solutions:**

1. **Application Crash**

   Check logs for exceptions:
   ```bash
   docker logs fabrikam-mcp-prod 2>&1 | grep -i "error\|exception\|fail"
   ```

   **Solution**: Fix application error, rebuild image if needed

2. **Health Check Failing**

   ```bash
   # Check health check command
   docker inspect fabrikam-mcp-prod | jq '.[0].Config.Healthcheck'
   
   # Run health check manually
   docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status
   ```

   **Solution**: Fix health check endpoint or adjust timeout values

3. **Dependency Not Ready**

   ```bash
   # Check if API is healthy (MCP depends on it)
   docker inspect fabrikam-api-prod | jq '.[0].State.Health.Status'
   ```

   **Solution**: Ensure dependencies start in correct order (handled by `depends_on`)

### Container in "Unhealthy" State

**Symptoms:**
- `docker ps` shows `(unhealthy)` status
- Services not responding correctly

**Diagnostic Steps:**

```bash
# Check health status
docker inspect fabrikam-mcp-prod | jq '.[0].State.Health'

# View health check logs
docker inspect fabrikam-mcp-prod | jq '.[0].State.Health.Log'

# Run health check manually
docker exec fabrikam-mcp-prod curl -v http://localhost:8080/status
```

**Solutions:**

1. **Increase Health Check Timeout**

   Edit `docker-compose.prod.yml`:
   ```yaml
   healthcheck:
     start_period: 30s  # Increase from 15s
     timeout: 10s       # Increase from 3s
   ```

2. **Check Application Logs**

   ```bash
   docker logs fabrikam-mcp-prod --tail=200
   ```

3. **Restart Service**

   ```bash
   docker compose -f docker-compose.prod.yml restart fabrikam-mcp
   ```

## 🌐 Networking Problems

### Services Can't Communicate

**Symptoms:**
- MCP can't reach API
- Error: "Connection refused" or "No route to host"

**Diagnostic Steps:**

```bash
# Check network exists
docker network ls | grep fabrikam

# Inspect network
docker network inspect fabrikam-network-prod

# Test connectivity between containers
docker exec fabrikam-mcp-prod ping -c 3 fabrikam-api
docker exec fabrikam-mcp-prod curl -v http://fabrikam-api:8080/health
```

**Solutions:**

1. **Recreate Network**

   ```bash
   docker compose -f docker-compose.prod.yml down
   docker network prune -f
   docker compose -f docker-compose.prod.yml up -d
   ```

2. **Verify Service Names**

   Check `FabrikamApi__BaseUrl` environment variable:
   ```bash
   docker inspect fabrikam-mcp-prod | jq '.[0].Config.Env' | grep FabrikamApi
   # Should be: http://fabrikam-api:8080 (not localhost!)
   ```

3. **Check DNS Resolution**

   ```bash
   docker exec fabrikam-mcp-prod nslookup fabrikam-api
   ```

### Can't Access Dashboard on Localhost

**Symptoms:**
- Dashboard service running but `http://localhost:5173` not accessible

**Diagnostic Steps:**

```bash
# Check port binding
docker ps | grep fabrikam-dashboard-prod
# Should show: 127.0.0.1:5173->8080/tcp

# Test from server
curl -I http://127.0.0.1:5173

# Check if dashboard profile enabled
docker compose -f docker-compose.prod.yml config | grep -A 10 fabrikam-dashboard
```

**Solutions:**

1. **Start with Dashboard Profile**

   ```bash
   docker compose -f docker-compose.prod.yml --profile dashboard up -d
   ```

2. **Check Port Conflicts**

   ```bash
   sudo netstat -tulpn | grep 5173
   ```

3. **Access from Server Only**

   Dashboard is bound to `127.0.0.1` for security - it's NOT accessible from other machines.
   
   To access from another machine, use SSH tunnel:
   ```bash
   # From your local machine
   ssh -L 5173:localhost:5173 user@ubuntu-server
   # Then access: http://localhost:5173
   ```

## ❤️ Health Check Failures

### Health Check Keeps Failing

**Symptoms:**
- Container shows "unhealthy" despite app running
- Health check returns non-zero exit code

**Diagnostic Steps:**

```bash
# Run health check manually
docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status

# Check if curl is installed
docker exec fabrikam-mcp-prod which curl

# Test endpoint directly
docker exec fabrikam-mcp-prod curl -v -f http://localhost:8080/status
```

**Solutions:**

1. **Endpoint Not Ready**

   Increase `start_period`:
   ```yaml
   healthcheck:
     start_period: 30s  # Give app more time to start
   ```

2. **Wrong Endpoint Path**

   Verify correct path:
   - API: `/health`
   - MCP: `/status`
   - Simulator: `/health`
   - Dashboard: `/`

3. **Curl Not Working**

   Check curl installation in Dockerfile (should be present):
   ```dockerfile
   RUN apt-get update && apt-get install -y curl
   ```

### Health Check Timeout

**Symptoms:**
- Health check times out before completing
- Logs show "health check taking longer than 3s"

**Solution:**

Increase timeout in `docker-compose.prod.yml`:

```yaml
healthcheck:
  timeout: 10s  # Increase from 3s
  interval: 60s  # Check less frequently
```

## 🌩️ Cloudflare Tunnel Issues

### Tunnel Not Connecting

**Symptoms:**
- `cloudflared` logs show connection errors
- Public URL returns 502 Bad Gateway
- No "Connection registered" messages in logs

**Diagnostic Steps:**

```bash
# Check cloudflared container
docker logs cloudflare-tunnel

# Look for specific errors
docker logs cloudflare-tunnel 2>&1 | grep -i "error\|fail"

# Check tunnel token
docker compose -f docker-compose.prod.yml config | grep CLOUDFLARE_TUNNEL_TOKEN
```

**Common Errors & Solutions:**

1. **Invalid Token**

   Error: `Failed to get tunnel: Invalid token`
   
   **Solution**: Regenerate token in Cloudflare dashboard and update `.env`:
   ```bash
   nano .env
   # Update CLOUDFLARE_TUNNEL_TOKEN=new-token-here
   
   docker compose -f docker-compose.prod.yml restart cloudflared
   ```

2. **Network Connectivity**

   Error: `dial tcp: lookup api.cloudflare.com: no such host`
   
   **Solution**: Check internet connectivity:
   ```bash
   docker exec cloudflare-tunnel ping -c 3 1.1.1.1
   docker exec cloudflare-tunnel nslookup api.cloudflare.com
   ```

3. **Firewall Blocking Outbound HTTPS**

   **Solution**: Ensure port 443 outbound is allowed:
   ```bash
   sudo ufw status
   sudo ufw allow out 443/tcp
   ```

### Tunnel Connected But 502 Error

**Symptoms:**
- Cloudflare Tunnel shows "Connection registered"
- Public URL returns 502 Bad Gateway

**Diagnostic Steps:**

```bash
# Check if MCP service is healthy
docker ps | grep fabrikam-mcp-prod
# Should show (healthy)

# Test MCP from cloudflared container
docker exec cloudflare-tunnel wget -O- http://fabrikam-mcp:8080/status

# Check tunnel configuration in Cloudflare dashboard
# Service URL should be: http://fabrikam-mcp:8080
```

**Solutions:**

1. **Wrong Service URL in Cloudflare**

   Go to Cloudflare Dashboard → Zero Trust → Networks → Tunnels
   
   Edit public hostname:
   - Type: `HTTP` (not HTTPS!)
   - URL: `fabrikam-mcp:8080` (service name, not localhost!)

2. **MCP Service Not Healthy**

   ```bash
   docker compose -f docker-compose.prod.yml restart fabrikam-mcp
   docker logs fabrikam-mcp-prod
   ```

3. **Network Issue**

   ```bash
   # Recreate network
   docker compose -f docker-compose.prod.yml down
   docker network prune -f
   docker compose -f docker-compose.prod.yml up -d
   ```

### DNS Not Resolving

**Symptoms:**
- `nslookup fabrikam-mcp.csplevelup.com` fails
- Error: "server can't find fabrikam-mcp.csplevelup.com: NXDOMAIN"

**Solutions:**

1. **Check Cloudflare Nameservers**

   ```bash
   nslookup -type=ns csplevelup.com
   # Should show Cloudflare nameservers
   ```

2. **Verify DNS Record in Cloudflare**

   Go to Cloudflare Dashboard → DNS → Records
   
   Should see CNAME record:
   - Name: `fabrikam-mcp`
   - Content: `tunnel-id.cfargotunnel.com`
   - Proxy status: Proxied (orange cloud)

3. **Wait for DNS Propagation**

   Check propagation status: https://dnschecker.org
   
   Can take 5-30 minutes globally

4. **Clear DNS Cache**

   ```bash
   # Ubuntu
   sudo systemd-resolve --flush-caches
   
   # Verify resolution
   nslookup fabrikam-mcp.csplevelup.com
   ```

## ⚡ Performance Problems

### High Memory Usage

**Diagnostic Steps:**

```bash
# Check container memory usage
docker stats --no-stream

# Check system memory
free -h

# Check Docker memory limits
docker inspect fabrikam-mcp-prod | jq '.[0].HostConfig.Memory'
```

**Solutions:**

1. **Set Memory Limits**

   Edit `docker-compose.prod.yml`:
   ```yaml
   services:
     fabrikam-mcp:
       deploy:
         resources:
           limits:
             memory: 512M  # Limit memory usage
           reservations:
             memory: 256M  # Reserved minimum
   ```

2. **Reduce Logging**

   Edit `docker-compose.prod.yml`:
   ```yaml
   environment:
     - Logging__LogLevel__Default=Error  # Reduce from Warning
   ```

3. **Restart Containers**

   ```bash
   docker compose -f docker-compose.prod.yml restart
   ```

### High CPU Usage

**Diagnostic Steps:**

```bash
# Check CPU usage
docker stats --no-stream

# Check container processes
docker exec fabrikam-mcp-prod ps aux
```

**Solutions:**

1. **Set CPU Limits**

   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.50'  # Limit to 50% of one CPU
   ```

2. **Check for Infinite Loops**

   Review application logs:
   ```bash
   docker logs fabrikam-mcp-prod --tail=500
   ```

### Slow Response Times

**Diagnostic Steps:**

```bash
# Test response time from server
time curl https://fabrikam-mcp.csplevelup.com/status

# Test internal response time
docker exec fabrikam-mcp-prod sh -c 'time curl http://localhost:8080/status'

# Check if API is slow (MCP depends on it)
docker exec fabrikam-api-prod sh -c 'time curl http://localhost:8080/health'
```

**Solutions:**

1. **Check Resource Constraints**

   ```bash
   docker stats
   # Look for high CPU or memory usage
   ```

2. **Optimize API Queries**

   Check API logs for slow queries:
   ```bash
   docker logs fabrikam-api-prod | grep -i "slow\|timeout"
   ```

3. **Increase Container Resources**

   ```yaml
   deploy:
     resources:
       reservations:
         cpus: '1.0'    # Increase from 0.5
         memory: 1024M  # Increase from 512M
   ```

## 🏗️ Image Build Errors

### Build Fails - Missing Dependencies

**Error:**
```
error NU1101: Unable to find package FabrikamContracts
```

**Solution:**

Ensure all projects are present:
```bash
ls -la FabrikamContracts/FabrikamContracts.csproj
ls -la FabrikamApi/src/FabrikamApi.csproj
```

Build from repository root with proper context:
```bash
docker build -f FabrikamApi/Dockerfile -t fabrikam-api:test .
```

### Build Fails - Network Timeout

**Error:**
```
error : Failed to retrieve information about 'Microsoft.AspNetCore.App' from remote source
```

**Solution:**

1. **Increase timeout:**
   ```bash
   docker build --network host -f FabrikamApi/Dockerfile .
   ```

2. **Use build cache:**
   ```bash
   docker build --cache-from davebirr/fabrikam-api:latest -f FabrikamApi/Dockerfile .
   ```

3. **Check NuGet sources:**
   ```bash
   docker run --rm mcr.microsoft.com/dotnet/sdk:9.0 dotnet nuget list source
   ```

### Multi-Platform Build Issues

**Error:**
```
ERROR: failed to solve: no match for platform in manifest
```

**Solution:**

Ensure buildx is set up:
```bash
# Create builder
docker buildx create --name fabrikam-builder --use

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 \
  -f FabrikamApi/Dockerfile \
  -t davebirr/fabrikam-api:latest \
  --push .
```

## 🔄 Watchtower Issues

### Containers Not Auto-Updating

**Diagnostic Steps:**

```bash
# Check Watchtower is running
docker ps | grep watchtower

# Check Watchtower logs
docker logs watchtower

# Verify poll interval
docker inspect watchtower | jq '.[0].Config.Env' | grep POLL_INTERVAL
```

**Solutions:**

1. **Watchtower Not Running**

   ```bash
   docker compose -f docker-compose.prod.yml up -d watchtower
   ```

2. **Check Update Logs**

   ```bash
   docker logs watchtower | tail -50
   # Look for "Checking" and "Updated" messages
   ```

3. **Manually Trigger Update**

   ```bash
   docker exec watchtower /watchtower --run-once
   ```

4. **Verify Image Tags**

   Watchtower only updates `:latest` or version tags matching current deployment:
   ```bash
   docker images | grep fabrikam
   ```

### Watchtower Updates Wrong Containers

**Solution:**

Use labels to control which containers Watchtower updates:

```yaml
services:
  fabrikam-mcp:
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
```

Update Watchtower config:
```yaml
watchtower:
  environment:
    - WATCHTOWER_LABEL_ENABLE=true  # Only update labeled containers
```

## 💾 Data Persistence

### Data Lost After Restart

**Problem:**
In-memory database (currently used) loses data on restart.

**Solution for Production:**

Add volume mounts for persistent storage:

```yaml
services:
  fabrikam-api:
    volumes:
      - api-data:/app/data

volumes:
  api-data:
    driver: local
```

### Volume Permission Issues

**Error:**
```
Permission denied: '/app/data'
```

**Solution:**

Ensure volume has correct permissions:
```bash
# Create volume with specific permissions
docker volume create --driver local \
  --opt type=none \
  --opt device=/opt/fabrikam/data \
  --opt o=uid=1000,gid=1000 \
  api-data
```

## 🔐 Authentication Errors

### JWT Authentication Failing

**Symptoms:**
- 401 Unauthorized errors
- "Invalid token" messages

**Diagnostic Steps:**

```bash
# Check authentication mode
docker inspect fabrikam-mcp-prod | jq '.[0].Config.Env' | grep AUTH_MODE

# Check JWT secret is set
docker inspect fabrikam-mcp-prod | jq '.[0].Config.Env' | grep JWT_SECRET_KEY
```

**Solutions:**

1. **Verify Environment Variables**

   Check `.env` file:
   ```bash
   cat .env | grep -E "AUTH_MODE|JWT_SECRET_KEY"
   ```

2. **Regenerate JWT Secret**

   ```bash
   openssl rand -base64 32
   # Update .env with new secret
   docker compose -f docker-compose.prod.yml restart fabrikam-mcp
   ```

3. **Disable Authentication for Testing**

   ```bash
   # Edit .env
   AUTH_MODE=Disabled
   
   # Restart
   docker compose -f docker-compose.prod.yml restart fabrikam-mcp
   ```

## 🔬 Advanced Debugging

### Enter Container Shell

```bash
# Enter running container
docker exec -it fabrikam-mcp-prod /bin/bash

# Or use sh if bash not available
docker exec -it fabrikam-mcp-prod /bin/sh

# Run commands inside container
curl http://localhost:8080/status
ps aux
netstat -tulpn
```

### Debug Network Connectivity

```bash
# Test from container to container
docker exec fabrikam-mcp-prod ping fabrikam-api

# Test DNS resolution
docker exec fabrikam-mcp-prod nslookup fabrikam-api

# Test HTTP connectivity
docker exec fabrikam-mcp-prod curl -v http://fabrikam-api:8080/health

# Inspect network
docker network inspect fabrikam-network-prod
```

### Enable Verbose Logging

Temporarily increase logging level:

```bash
# Stop container
docker compose -f docker-compose.prod.yml stop fabrikam-mcp

# Start with verbose logging
docker run -it --rm \
  --network fabrikam-network-prod \
  -e ASPNETCORE_ENVIRONMENT=Development \
  -e Logging__LogLevel__Default=Debug \
  -e FabrikamApi__BaseUrl=http://fabrikam-api:8080 \
  davebirr/fabrikam-mcp:latest
```

### Inspect Container Filesystem

```bash
# Export container filesystem
docker export fabrikam-mcp-prod > container-fs.tar

# Extract and inspect
mkdir container-fs
tar -xf container-fs.tar -C container-fs
ls -la container-fs/app
```

### Debug Image Layers

```bash
# View image history
docker history davebirr/fabrikam-mcp:latest

# Inspect image
docker inspect davebirr/fabrikam-mcp:latest | jq

# Compare image sizes
docker images | grep fabrikam
```

### Capture Network Traffic

```bash
# Install tcpdump in container (if needed)
docker exec -u root fabrikam-mcp-prod apt-get update
docker exec -u root fabrikam-mcp-prod apt-get install -y tcpdump

# Capture traffic
docker exec fabrikam-mcp-prod tcpdump -i any -w /tmp/capture.pcap

# Copy capture file
docker cp fabrikam-mcp-prod:/tmp/capture.pcap ./
```

## 📞 Getting Help

### Collect Diagnostic Information

Create diagnostic bundle:

```bash
#!/bin/bash
echo "Collecting diagnostics..."

mkdir -p diagnostics
cd diagnostics

# System info
uname -a > system-info.txt
docker version > docker-version.txt
docker compose version > compose-version.txt

# Container status
docker compose -f ../docker-compose.prod.yml ps > container-status.txt

# Logs (last 500 lines)
docker compose -f ../docker-compose.prod.yml logs --tail=500 > all-logs.txt

# Resource usage
docker stats --no-stream > resource-usage.txt

# Network info
docker network inspect fabrikam-network-prod > network-info.json

# Environment (sanitized)
docker compose -f ../docker-compose.prod.yml config > compose-config.txt

# Create archive
cd ..
tar -czf diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz diagnostics/

echo "Diagnostics saved to: diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz"
```

### Report Issue

When reporting issues, include:
- Diagnostic bundle (from above script)
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version)
- Recent changes made

## 🔗 Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/
- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/
- **Project Documentation**:
  - [Docker Deployment Strategy](./DOCKER-DEPLOYMENT-STRATEGY.md)
  - [Cloudflare Tunnel Setup](./CLOUDFLARE-TUNNEL-SETUP.md)
  - [Ubuntu Deployment Guide](./UBUNTU-DEPLOYMENT.md)

---

**🔧 Remember:** Most issues can be resolved by:
1. Checking logs: `docker compose -f docker-compose.prod.yml logs`
2. Verifying configuration: `docker compose -f docker-compose.prod.yml config`
3. Restarting services: `docker compose -f docker-compose.prod.yml restart`
4. Rebuilding if needed: `docker compose -f docker-compose.prod.yml up -d --build`
