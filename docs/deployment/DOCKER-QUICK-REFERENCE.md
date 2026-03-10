# 🐋 Docker Quick Reference

Quick reference for common Docker commands used with Fabrikam platform.

## 🚀 Starting Services

```bash
# Development (all services with port mappings)
docker-compose up -d

# Production (API + MCP + Cloudflare Tunnel + Watchtower)
docker-compose -f docker-compose.prod.yml up -d

# Production with optional services
docker-compose -f docker-compose.prod.yml --profile simulator --profile dashboard up -d

# Rebuild images and start
docker-compose up -d --build
```

## 🛑 Stopping Services

```bash
# Stop all services (development)
docker-compose down

# Stop all services (production)
docker-compose -f docker-compose.prod.yml down

# Stop without removing containers
docker-compose stop

# Stop specific service
docker-compose stop fabrikam-mcp
```

## 📊 Viewing Status

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View service status
docker-compose ps
docker-compose -f docker-compose.prod.yml ps

# View resource usage
docker stats

# View resource usage (no stream)
docker stats --no-stream
```

## 📝 Viewing Logs

```bash
# All services (follow)
docker-compose logs -f

# Specific service
docker-compose logs -f fabrikam-mcp

# Last 100 lines
docker-compose logs --tail=100

# Since specific time
docker-compose logs --since 30m

# Production logs
docker-compose -f docker-compose.prod.yml logs -f

# Specific container (by name)
docker logs fabrikam-mcp-prod -f
```

## 🔄 Updating Services

```bash
# Pull latest images
docker-compose pull
docker-compose -f docker-compose.prod.yml pull

# Pull and restart
docker-compose pull && docker-compose up -d

# Update to specific version
# Edit .env: VERSION=v1.2.0
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Restart specific service
docker-compose restart fabrikam-mcp
```

## 🔍 Inspecting Services

```bash
# Inspect container details
docker inspect fabrikam-mcp-prod

# View health status
docker inspect fabrikam-mcp-prod | jq '.[0].State.Health'

# View environment variables
docker inspect fabrikam-mcp-prod | jq '.[0].Config.Env'

# View network configuration
docker inspect fabrikam-mcp-prod | jq '.[0].NetworkSettings'

# View merged docker-compose config
docker-compose config
docker-compose -f docker-compose.prod.yml config
```

## 🐚 Entering Containers

```bash
# Open bash shell
docker exec -it fabrikam-mcp-prod /bin/bash

# Open sh shell (if bash not available)
docker exec -it fabrikam-mcp-prod /bin/sh

# Run single command
docker exec fabrikam-mcp-prod curl http://localhost:8080/status

# Run as root (for installing packages)
docker exec -u root -it fabrikam-mcp-prod /bin/bash
```

## 🔧 Testing Endpoints

```bash
# API health check (internal)
docker exec fabrikam-api-prod curl -f http://localhost:8080/health

# MCP status check (internal)
docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status

# API health check (external - development)
curl http://localhost:7297/health

# MCP status check (external - production)
curl https://fabrikam-mcp.csplevelup.com/status

# Test connectivity between containers
docker exec fabrikam-mcp-prod ping -c 3 fabrikam-api
docker exec fabrikam-mcp-prod curl -v http://fabrikam-api:8080/health
```

## 🌐 Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect fabrikam-network-prod

# Remove unused networks
docker network prune -f

# Create network manually
docker network create fabrikam-network-prod
```

## 🖼️ Image Commands

```bash
# List images
docker images

# List Fabrikam images only
docker images | grep fabrikam

# Pull specific image
docker pull davebirr/fabrikam-mcp:latest

# Pull specific version
docker pull davebirr/fabrikam-mcp:v1.2.0

# Remove image
docker rmi davebirr/fabrikam-mcp:v1.2.0

# Remove all unused images
docker image prune -a -f

# View image layers
docker history davebirr/fabrikam-mcp:latest
```

## 🏗️ Building Images

```bash
# Build from Dockerfile
docker build -f FabrikamApi/Dockerfile -t fabrikam-api:test .

# Build with no cache
docker build --no-cache -f FabrikamApi/Dockerfile -t fabrikam-api:test .

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 \
  -f FabrikamApi/Dockerfile \
  -t davebirr/fabrikam-api:latest \
  --push .

# Build and load into local Docker
docker buildx build --platform linux/amd64 \
  -f FabrikamApi/Dockerfile \
  -t fabrikam-api:test \
  --load .
```

## 🧹 Cleanup Commands

```bash
# Remove stopped containers
docker-compose down

# Remove stopped containers (production)
docker-compose -f docker-compose.prod.yml down

# Remove containers and volumes
docker-compose down -v

# Remove unused containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# Remove unused networks
docker network prune -f

# Full system cleanup
docker system prune -a --volumes -f

# View disk usage
docker system df
```

## ❤️ Health Check Commands

```bash
# Check health status (all containers)
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check specific container health
docker inspect fabrikam-mcp-prod --format='{{.State.Health.Status}}'

# View health check logs
docker inspect fabrikam-mcp-prod --format='{{json .State.Health}}' | jq

# Run health check manually
docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status
```

## 🔐 Cloudflare Tunnel Commands

```bash
# View tunnel logs
docker logs cloudflare-tunnel

# Check tunnel connection
docker logs cloudflare-tunnel | grep "Connection registered"

# Restart tunnel
docker-compose -f docker-compose.prod.yml restart cloudflared

# Test tunnel connectivity
docker exec cloudflare-tunnel ping -c 3 1.1.1.1
docker exec cloudflare-tunnel nslookup api.cloudflare.com
```

## 🤖 Watchtower Commands

```bash
# View Watchtower logs
docker logs watchtower

# View recent updates
docker logs watchtower | tail -50

# Manually trigger update check
docker exec watchtower /watchtower --run-once

# Restart Watchtower
docker-compose -f docker-compose.prod.yml restart watchtower
```

## 📦 Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect api-data

# Remove specific volume
docker volume rm api-data

# Remove all unused volumes
docker volume prune -f

# Create volume
docker volume create api-data
```

## 🔍 Troubleshooting Commands

```bash
# Check container exit code
docker inspect fabrikam-mcp-prod | jq '.[0].State.ExitCode'

# View error message
docker inspect fabrikam-mcp-prod | jq '.[0].State.Error'

# Check restart count
docker inspect fabrikam-mcp-prod | jq '.[0].RestartCount'

# View container processes
docker exec fabrikam-mcp-prod ps aux

# Check port bindings
docker port fabrikam-mcp-prod

# Check network connectivity
docker exec fabrikam-mcp-prod netstat -tulpn

# Test DNS resolution
docker exec fabrikam-mcp-prod nslookup fabrikam-api

# Export container filesystem
docker export fabrikam-mcp-prod > container-fs.tar
```

## 📊 Performance Monitoring

```bash
# Real-time stats
docker stats

# Stats for specific containers
docker stats fabrikam-api-prod fabrikam-mcp-prod

# One-time stats snapshot
docker stats --no-stream

# View top processes in container
docker top fabrikam-mcp-prod
```

## 🔄 Version Management

```bash
# Check current version
docker images | grep fabrikam

# Switch to specific version
# Edit .env: VERSION=v1.2.0
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Rollback to previous version
# Edit .env: VERSION=v1.1.0
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# View version history
docker images davebirr/fabrikam-mcp --format "table {{.Tag}}\t{{.CreatedAt}}\t{{.Size}}"
```

## 🚨 Emergency Commands

```bash
# Force stop all containers
docker stop $(docker ps -q)

# Force remove all containers
docker rm -f $(docker ps -aq)

# Emergency restart (production)
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Full reset (DESTRUCTIVE - removes all data)
docker-compose -f docker-compose.prod.yml down -v
docker system prune -a --volumes -f
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 📋 Common Workflows

### First-Time Deployment

```bash
# 1. Clone repository
git clone <repo>
cd Fabrikam-Project

# 2. Configure environment
cp .env.example .env
nano .env  # Add CLOUDFLARE_TUNNEL_TOKEN

# 3. Pull images
docker-compose -f docker-compose.prod.yml pull

# 4. Start services
docker-compose -f docker-compose.prod.yml up -d

# 5. Verify deployment
docker-compose -f docker-compose.prod.yml ps
curl https://fabrikam-mcp.csplevelup.com/status
```

### Version Update

```bash
# 1. Edit version in .env
nano .env  # VERSION=v1.3.0

# 2. Pull new images
docker-compose -f docker-compose.prod.yml pull

# 3. Restart services
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify update
docker images | grep fabrikam
curl https://fabrikam-mcp.csplevelup.com/status
```

### Troubleshooting Workflow

```bash
# 1. Check status
docker-compose -f docker-compose.prod.yml ps

# 2. View logs
docker-compose -f docker-compose.prod.yml logs --tail=100

# 3. Test health checks
docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status

# 4. Restart if needed
docker-compose -f docker-compose.prod.yml restart fabrikam-mcp

# 5. Full restart if still failing
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

## 🔗 Additional Resources

- **Full Documentation**: `docs/deployment/`
- **Troubleshooting Guide**: [DOCKER-TROUBLESHOOTING.md](./DOCKER-TROUBLESHOOTING.md)
- **Deployment Strategy**: [DOCKER-DEPLOYMENT-STRATEGY.md](./DOCKER-DEPLOYMENT-STRATEGY.md)
- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose Reference**: https://docs.docker.com/compose/compose-file/

---

**💡 Tip**: Add commonly used commands to your shell aliases!

```bash
# Add to ~/.bashrc or ~/.zshrc
alias fabup='docker-compose -f docker-compose.prod.yml up -d'
alias fabdown='docker-compose -f docker-compose.prod.yml down'
alias fablogs='docker-compose -f docker-compose.prod.yml logs -f'
alias fabps='docker-compose -f docker-compose.prod.yml ps'
alias fabpull='docker-compose -f docker-compose.prod.yml pull'
```
