# 🐧 Ubuntu Deployment Guide

This guide covers deploying the Fabrikam platform to Ubuntu nodes using Docker Compose with Cloudflare Tunnel for secure HTTPS access.

## 📋 Table of Contents

- [System Requirements](#system-requirements)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Step 1: Prepare Ubuntu Server](#step-1-prepare-ubuntu-server)
- [Step 2: Install Docker](#step-2-install-docker)
- [Step 3: Clone Repository](#step-3-clone-repository)
- [Step 4: Configure Environment](#step-4-configure-environment)
- [Step 5: Deploy Services](#step-5-deploy-services)
- [Step 6: Verify Deployment](#step-6-verify-deployment)
- [Step 7: Configure Auto-Updates](#step-7-configure-auto-updates)
- [Maintenance Operations](#maintenance-operations)
- [Monitoring and Logs](#monitoring-and-logs)
- [Security Hardening](#security-hardening)
- [Backup and Recovery](#backup-and-recovery)

## 💻 System Requirements

### Minimum Specifications

- **OS**: Ubuntu 20.04 LTS or newer (22.04 LTS recommended)
- **CPU**: 2 cores (4 cores recommended for production)
- **RAM**: 4 GB (8 GB recommended)
- **Disk**: 20 GB free space (50 GB recommended)
- **Network**: Internet connection with outbound HTTPS (443)

### Supported Architectures

- ✅ AMD64 (x86_64) - Intel/AMD processors
- ✅ ARM64 (AArch64) - Raspberry Pi 4, AWS Graviton, etc.

### Port Requirements

**NO inbound ports needed** - Cloudflare Tunnel uses outbound connections only!

Optional internal ports (localhost only):
- `5173` - Dashboard (if enabled with `--profile dashboard`)

## ✅ Pre-Deployment Checklist

Before starting deployment:

- [ ] Ubuntu server installed and updated
- [ ] SSH access configured
- [ ] Domain configured in Cloudflare
- [ ] Cloudflare Tunnel created and token obtained
- [ ] Docker Hub account (if using private registry)
- [ ] `.env` file prepared with secrets

## Step 1: Prepare Ubuntu Server

### 1.1 Update System

```bash
# Update package lists
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Reboot if kernel updated
sudo reboot
```

### 1.2 Install Prerequisites

```bash
# Install required packages
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    htop \
    net-tools
```

### 1.3 Configure Firewall (Optional)

```bash
# Install UFW if not present
sudo apt install -y ufw

# Allow SSH (change port if using non-standard)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

**Note**: No need to open HTTP/HTTPS ports - Cloudflare Tunnel handles external access!

### 1.4 Create Deployment User (Optional)

```bash
# Create dedicated user for Fabrikam services
sudo adduser fabrikam

# Add to docker group (we'll create this in next step)
# This will be done after Docker installation
```

## Step 2: Install Docker

### 2.1 Install Docker Engine

```bash
# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine, CLI, and Compose
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

Expected output:
```
Docker version 24.0.7, build afdd53b
Docker Compose version v2.23.0
```

### 2.2 Configure Docker

```bash
# Enable Docker service to start on boot
sudo systemctl enable docker

# Start Docker service
sudo systemctl start docker

# Verify Docker is running
sudo systemctl status docker
```

### 2.3 Add User to Docker Group (Optional)

```bash
# Add your user to docker group (avoid using sudo for docker commands)
sudo usermod -aG docker $USER

# Add fabrikam user if created
sudo usermod -aG docker fabrikam

# Log out and back in for group changes to take effect
# Or use: newgrp docker
```

### 2.4 Configure Docker Daemon (Recommended)

Create/edit `/etc/docker/daemon.json`:

```bash
sudo nano /etc/docker/daemon.json
```

Add configuration:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

Restart Docker:

```bash
sudo systemctl restart docker
```

## Step 3: Clone Repository

### 3.1 Choose Deployment Directory

```bash
# Create deployment directory
sudo mkdir -p /opt/fabrikam
sudo chown $USER:$USER /opt/fabrikam
cd /opt/fabrikam
```

Or use home directory:

```bash
mkdir -p ~/fabrikam-project
cd ~/fabrikam-project
```

### 3.2 Clone Repository

```bash
# Clone from GitHub
git clone https://github.com/{owner}/Fabrikam-Project.git .

# Or download specific release
VERSION=v1.2.0
wget https://github.com/{owner}/Fabrikam-Project/archive/refs/tags/${VERSION}.tar.gz
tar -xzf ${VERSION}.tar.gz --strip-components=1
rm ${VERSION}.tar.gz
```

### 3.3 Verify Files

```bash
# Check required files exist
ls -la docker-compose.prod.yml
ls -la FabrikamApi/Dockerfile
ls -la FabrikamMcp/Dockerfile

# Verify structure
tree -L 2
```

## Step 4: Configure Environment

### 4.1 Create Environment File

```bash
# Create .env file
nano .env
```

Add configuration:

```bash
# ============================================================================
# Docker Registry Configuration
# ============================================================================
DOCKER_REGISTRY=davebirr  # Your Docker Hub username or registry

# ============================================================================
# Version Configuration
# ============================================================================
VERSION=latest  # Or specific version like v1.2.0

# ============================================================================
# Cloudflare Tunnel Configuration (REQUIRED)
# ============================================================================
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiNGE4YjZlMWQtZTBjYi00ZTBkLWJkNGMtYjk2ZjQyZTU4YmQ5IiwidCI6IjdmYmY0ZTZiLTNmMzYtNGQyZi1hNzM1LWQ0YjVjNjE4ZDQ1YyIsInMiOiJZVFE0TXpJek16QT0ifQ==

# ============================================================================
# Authentication Configuration (Optional)
# ============================================================================
AUTH_MODE=Disabled  # Options: Disabled, BearerToken

# JWT Configuration (only if AUTH_MODE=BearerToken)
# JWT_SECRET_KEY=your-secret-key-here
# JWT_ISSUER=https://fabrikam-mcp.csplevelup.com
# JWT_AUDIENCE=FabrikamMcp

# ============================================================================
# Additional Configuration (Optional)
# ============================================================================
# ASPNETCORE_ENVIRONMENT=Production
# LOGGING_LEVEL=Warning
```

### 4.2 Secure Environment File

```bash
# Set restrictive permissions
chmod 600 .env

# Verify permissions
ls -la .env
# Should show: -rw------- (only owner can read/write)
```

### 4.3 Verify Configuration

```bash
# Test environment file syntax
docker compose -f docker-compose.prod.yml config

# Should show merged configuration without errors
```

## Step 5: Deploy Services

### 5.1 Pull Docker Images

```bash
# Pull all service images
docker compose -f docker-compose.prod.yml pull

# Verify images downloaded
docker images | grep fabrikam
```

Expected output:
```
davebirr/fabrikam-api          latest    abc123...   2 minutes ago   200MB
davebirr/fabrikam-mcp          latest    def456...   2 minutes ago   195MB
davebirr/fabrikam-simulator    latest    ghi789...   2 minutes ago   198MB
davebirr/fabrikam-dashboard    latest    jkl012...   2 minutes ago   205MB
```

### 5.2 Start Core Services

```bash
# Start API, MCP, Cloudflare Tunnel, and Watchtower
docker compose -f docker-compose.prod.yml up -d

# Verify services started
docker compose -f docker-compose.prod.yml ps
```

Expected output:
```
NAME                     STATUS              PORTS
fabrikam-api-prod       Up 30s (healthy)     
fabrikam-mcp-prod       Up 25s (healthy)     
cloudflare-tunnel       Up 20s               
watchtower              Up 30s               
```

### 5.3 Start Optional Services

```bash
# Start with Simulator
docker compose -f docker-compose.prod.yml --profile simulator up -d

# Start with Dashboard (localhost access only)
docker compose -f docker-compose.prod.yml --profile dashboard up -d

# Start with both
docker compose -f docker-compose.prod.yml --profile simulator --profile dashboard up -d
```

### 5.4 View Startup Logs

```bash
# Follow logs for all services
docker compose -f docker-compose.prod.yml logs -f

# Follow logs for specific service
docker compose -f docker-compose.prod.yml logs -f fabrikam-mcp

# View Cloudflare Tunnel connection
docker compose -f docker-compose.prod.yml logs cloudflared | grep "Connection registered"
```

## Step 6: Verify Deployment

### 6.1 Check Container Health

```bash
# View container status
docker compose -f docker-compose.prod.yml ps

# All services should show "healthy" or "Up"
```

### 6.2 Test Internal Connectivity

```bash
# Test API health endpoint
docker exec fabrikam-api-prod curl -f http://localhost:8080/health

# Test MCP status endpoint
docker exec fabrikam-mcp-prod curl -f http://localhost:8080/status

# Expected responses: {"status":"OK",...}
```

### 6.3 Test External HTTPS Access

```bash
# Test from deployment server
curl -I https://fabrikam-mcp.csplevelup.com/status

# Expected: HTTP/2 200

# Test from another machine
curl https://fabrikam-mcp.csplevelup.com/status | jq
```

Expected response:
```json
{
  "status": "OK",
  "environment": "Production",
  "version": "1.2.0"
}
```

### 6.4 Verify Cloudflare Tunnel

```bash
# Check tunnel logs
docker logs cloudflare-tunnel | tail -20

# Look for "Connection registered" messages
# Should see 4 connections to different Cloudflare locations
```

### 6.5 Test MCP Protocol

```bash
# List available tools
curl -X POST https://fabrikam-mcp.csplevelup.com/mcp/v1/tools/list \
  -H "Content-Type: application/json" \
  -d '{}' | jq

# Should return JSON array of available tools
```

## Step 7: Configure Auto-Updates

Watchtower is already running and will automatically update containers every 5 minutes.

### 7.1 Verify Watchtower

```bash
# Check Watchtower is running
docker ps | grep watchtower

# View Watchtower logs
docker logs watchtower
```

### 7.2 Customize Update Schedule (Optional)

Edit `docker-compose.prod.yml`:

```yaml
watchtower:
  environment:
    - WATCHTOWER_POLL_INTERVAL=600  # Check every 10 minutes instead of 5
```

Apply changes:

```bash
docker compose -f docker-compose.prod.yml up -d watchtower
```

### 7.3 Manual Update

```bash
# Pull latest images
docker compose -f docker-compose.prod.yml pull

# Restart services with new images
docker compose -f docker-compose.prod.yml up -d

# Verify new versions
docker images | grep fabrikam
```

## 🔧 Maintenance Operations

### Start Services

```bash
docker compose -f docker-compose.prod.yml up -d
```

### Stop Services

```bash
docker compose -f docker-compose.prod.yml down
```

### Restart Services

```bash
# Restart all services
docker compose -f docker-compose.prod.yml restart

# Restart specific service
docker compose -f docker-compose.prod.yml restart fabrikam-mcp
```

### Update to Specific Version

```bash
# Edit .env file
nano .env
# Change: VERSION=v1.3.0

# Pull and restart
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Rollback to Previous Version

```bash
# Edit .env file
nano .env
# Change: VERSION=v1.2.0

# Pull and restart
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Clean Up Unused Resources

```bash
# Remove stopped containers
docker compose -f docker-compose.prod.yml down

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# Remove unused networks
docker network prune -f

# Full cleanup
docker system prune -a --volumes -f
```

## 📊 Monitoring and Logs

### View Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f fabrikam-mcp

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail=100

# Since specific time
docker compose -f docker-compose.prod.yml logs --since 30m
```

### Monitor Resources

```bash
# Container resource usage
docker stats

# Specific container
docker stats fabrikam-mcp-prod
```

### Health Checks

```bash
# Check all container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Inspect health check details
docker inspect fabrikam-mcp-prod | jq '.[0].State.Health'
```

### Log Files Location

Logs are stored in JSON format by Docker:

```bash
# View log file location
docker inspect fabrikam-mcp-prod | jq '.[0].LogPath'

# Example: /var/lib/docker/containers/{container-id}/{container-id}-json.log
```

## 🔒 Security Hardening

### Enable UFW Logging

```bash
sudo ufw logging on
```

### Configure Automatic Security Updates

```bash
# Install unattended-upgrades
sudo apt install -y unattended-upgrades

# Enable automatic security updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Harden SSH Access

Edit `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended settings:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:

```bash
sudo systemctl restart sshd
```

### Enable Fail2Ban

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 💾 Backup and Recovery

### Backup Configuration

```bash
# Create backup directory
mkdir -p ~/backups

# Backup .env file
cp .env ~/backups/env-$(date +%Y%m%d-%H%M%S).backup

# Backup docker-compose.prod.yml
cp docker-compose.prod.yml ~/backups/compose-$(date +%Y%m%d-%H%M%S).backup
```

### Automated Backup Script

Create `~/backup-fabrikam.sh`:

```bash
#!/bin/bash
BACKUP_DIR=~/backups
mkdir -p $BACKUP_DIR

# Backup files
cp /opt/fabrikam/.env $BACKUP_DIR/env-$(date +%Y%m%d).backup
cp /opt/fabrikam/docker-compose.prod.yml $BACKUP_DIR/compose-$(date +%Y%m%d).backup

# Keep last 7 days
find $BACKUP_DIR -name "*.backup" -mtime +7 -delete

echo "Backup completed: $(date)"
```

Make executable and schedule:

```bash
chmod +x ~/backup-fabrikam.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * ~/backup-fabrikam.sh >> ~/backup-fabrikam.log 2>&1
```

### Disaster Recovery

```bash
# 1. Restore .env file
cp ~/backups/env-YYYYMMDD.backup /opt/fabrikam/.env

# 2. Restore docker-compose file
cp ~/backups/compose-YYYYMMDD.backup /opt/fabrikam/docker-compose.prod.yml

# 3. Pull images and start
cd /opt/fabrikam
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## 🔗 Next Steps

- **Configure Authentication**: [CLOUDFLARE-TUNNEL-SETUP.md](./CLOUDFLARE-TUNNEL-SETUP.md#security-configuration)
- **Troubleshooting**: [DOCKER-TROUBLESHOOTING.md](./DOCKER-TROUBLESHOOTING.md)
- **Monitoring**: Set up external monitoring (UptimeRobot, Pingdom, etc.)
- **Alerts**: Configure alerts for service failures

## 📞 Support Resources

- **GitHub Issues**: Report bugs and request features
- **Docker Documentation**: https://docs.docker.com/
- **Ubuntu Server Guide**: https://ubuntu.com/server/docs
- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/

---

**✅ Deployment Complete!**

Your Fabrikam platform is now running on Ubuntu with:
- ✅ Docker containerization
- ✅ HTTPS via Cloudflare Tunnel
- ✅ Automatic updates via Watchtower
- ✅ Production-grade logging and monitoring
- ✅ Secure configuration management

**Access your MCP server at:**
```
https://fabrikam-mcp.csplevelup.com
```
