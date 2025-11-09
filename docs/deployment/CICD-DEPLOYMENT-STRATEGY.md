# CI/CD Deployment Strategy

This document explains the CI/CD deployment setup for Fabrikam workshop instances.

## Overview

The project uses GitHub Actions to automatically deploy to Azure when code is pushed to specific branches.

## Deployment Workflows

### 1. **Workshop Instances (Teams 00-23)** - `workshop-stable` branch
**Workflow:** `.github/workflows/deploy-workshop-instances.yml`

- **Trigger:** Push to `workshop-stable` branch or manual workflow dispatch
- **Deploys to:** Teams 00-23
  - Team 00: Proctor instance (demo/testing)
  - Teams 01-23: Participant instances (most deleted to save costs)
- **Resource Groups:** `rg-fabrikam-team-00` through `rg-fabrikam-team-23`

**Usage:**
```bash
# Automatic: Push to workshop-stable branch
git push origin workshop-stable

# Manual: Trigger via GitHub Actions UI
# Select specific teams: "01,05,12" or "all"
```

### 2. **Team-24 (Testing)** - `main` branch
**Workflow:** `.github/workflows/deploy-team-24-main.yml`

- **Trigger:** Push to `main` branch or manual workflow dispatch
- **Deploys to:** Team 24 only
- **Resource Group:** `rg-fabrikam-team-24`
- **Purpose:** Testing/validation instance that tracks latest main branch development

**Usage:**
```bash
# Automatic: Push to main branch
git push origin main
```

## Branch Strategy

| Branch | Deploys To | Purpose |
|--------|-----------|---------|
| `main` | Team-24 | Latest development, testing new features |
| `workshop-stable` | Teams 00-23 | Stable version for workshops and demos |

## Resource Group Assignment

| Resource Group | Branch | Status | Purpose |
|---------------|--------|--------|---------|
| `rg-fabrikam-team-00` | `workshop-stable` | ✅ Active | Proctor/demo instance |
| `rg-fabrikam-team-01` to `rg-fabrikam-team-23` | `workshop-stable` | ❌ Deleted | Former participant instances (cost savings) |
| `rg-fabrikam-team-24` | `main` | ✅ Active | Testing instance |

## Deployment Components

Each deployment includes:
- **API** - FabrikamApi (ASP.NET Core Web API)
- **MCP** - FabrikamMcp (Model Context Protocol server)
- **Simulator** - FabrikamSimulator (order/customer simulator)
- **Dashboard** - FabrikamDashboard (Blazor monitoring dashboard)

## Health Checks

Each workflow includes post-deployment health checks:
- **API:** `GET /health` → HTTP 200
- **MCP:** `GET /status` → HTTP 200
- **Simulator:** `GET /api/simulator/status` → HTTP 200
- **Dashboard:** `GET /` → HTTP 200

## Manual Deployment

If you need to manually deploy to a specific team:

```bash
# Deploy dashboard to team-00
.\workshops\cs-agent-a-thon\infrastructure\scripts\Deploy-Dashboard.ps1 -TeamNumber "00"

# Use workflow dispatch in GitHub Actions UI
# Select workflow and choose team number(s)
```

## Switching a Team's Branch

To change which branch deploys to a specific team:

1. Edit the workflow file that currently deploys to that team
2. Remove the team from the matrix
3. Create/modify a workflow for the target branch
4. Add the team to the new workflow's matrix

Example: Team-24 was moved from `workshop-stable` to `main`:
- Removed `"24"` from `deploy-workshop-instances.yml` matrix
- Created `deploy-team-24-main.yml` with `main` branch trigger

## Cost Management

To reduce Azure costs:
- Teams 01-23 have been deleted (no longer needed post-workshop)
- Only Team-00 (proctor) and Team-24 (testing) remain active
- Each team consumes ~4 web apps + supporting resources

## Future Entra Tenant

When the current Entra External ID tenant expires (~90 days):
- A new tenant will be created
- Team-00 will be reconfigured with new tenant
- Participants who opted in will receive new credentials
- CI/CD workflows remain unchanged
