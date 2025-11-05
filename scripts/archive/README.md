# Archived Scripts

This directory contains scripts that are no longer actively used but retained for reference.

## Archived Files

### Testing Scripts (Replaced by test.ps1)
- **Test-Modular.ps1** - Early modular testing approach
- **Test-Modular-Enhanced.ps1** - Iteration on modular testing
- **Test-Modular-Final.ps1** - Final version before consolidation
- **Test-Development-Modular.ps1** - Development-specific testing
- **Test-SupportTickets.ps1** - Specific support ticket API testing (now in test.ps1)
- **test-sequential-calls.ps1** - MCP sequential call testing (now integrated)

### Migration Scripts (Completed)
- **apply-issue4-migration.ps1** - Applied database schema migration for Issue #4
- **quick-migration-fix.ps1** - Quick fix for migration issues
- **Migrate-Project.ps1** - Project migration utilities

### Management Scripts (Replaced)
- **Manage-Deployments.ps1** - Deployment management (replaced by GitHub Actions)
- **Manage-Project.ps1** - Project management utilities
- **Monitor-Simulator.ps1** - Simulator monitoring (FabrikamSimulator archived)

### Configuration Files
- **deployment-config.json** - Old deployment configuration (replaced by azure.yaml and GitHub workflows)

## Current Testing Approach

Use **test.ps1** in the root directory for all testing needs:
```powershell
.\test.ps1 -Quick     # Fast health check
.\test.ps1 -ApiOnly   # API endpoint testing  
.\test.ps1 -McpOnly   # MCP tool testing
.\test.ps1 -Verbose   # Full detailed testing
```

## Active Scripts

See the main **scripts/** directory for currently maintained scripts:
- **Fix-Verification.ps1** - Quick verification after fixes
- **Setup-Instance.ps1** - Workshop instance setup
- **Provision-Workshop-Instances.ps1** - Workshop provisioning
- **Deploy-Workshop-Team.ps1** - Team deployment
- **Inject-Orders.ps1** - Sample data injection
- And others in the scripts directory

---

**Note**: These files are kept for historical reference and troubleshooting. Do not modify unless needed for archaeology purposes.
