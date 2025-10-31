# 🌿 Workshop Branching Strategy

## **Overview**

The Fabrikam Project uses a two-branch strategy for the Agent-a-thon workshop to balance rapid development with workshop stability.

---

## **Branch Structure**

### **`main` Branch** - Active Development
- **Purpose**: Rapid iteration and improvements
- **Audience**: Development team
- **Stability**: May contain experimental features
- **Update Frequency**: Continuous (multiple commits per day)
- **Deployment**: Automatic to `-development` Azure environments

### **`workshop-stable` Branch** - Workshop Production
- **Purpose**: Stable baseline for workshop proctors and participants
- **Audience**: Workshop facilitators and 20 team instances
- **Stability**: Production-ready, tested features only
- **Update Frequency**: Batched updates (1-2x per day as needed)
- **Deployment**: Manual/triggered to workshop Azure environments

---

## **Workflow**

### **Daily Development Cycle**

```bash
# 1. Work on main (rapid iteration)
git checkout main
# Make changes, commit, push
git add .
git commit -m "feat: new improvement"
git push

# 2. When ready to update workshop-stable
git checkout workshop-stable
git merge main --no-ff -m "chore: merge improvements to workshop-stable"

# 3. Review merged changes
git log --oneline -5

# 4. Push to workshop environments
git push origin workshop-stable
```

### **Emergency Hotfix to Workshop**

```bash
# If workshop-stable needs urgent fix without main changes:
git checkout workshop-stable
git cherry-pick <commit-hash-from-main>
git push origin workshop-stable
```

---

## **Current State** (as of 2025-10-31)

### **`workshop-stable` Created From:**
- Commit: `e10d50d` - "Feat: Auto-lookup customerId from orderId"
- Date: October 31, 2025
- Status: ✅ Workshop-ready

### **Includes:**
- ✅ MCP session management (30-minute timeout)
- ✅ Support ticket validation fixes (dynamic enum values)
- ✅ Auto-lookup customerId from orderId
- ✅ Comprehensive workshop example (beginner-customer-service-example.md)
- ✅ Correct category values (OrderInquiry, DeliveryIssue, ProductDefect, etc.)
- ✅ Topic generation guidance (Copilot-generated Topics)
- ✅ Troubleshooting section for common issues

---

## **Deployment Strategy**

### **Main Branch Deployments**
```yaml
# Automatic via GitHub Actions
Triggers: Push to main
Deploys to:
  - fabrikam-api-development-tzjeje
  - fabrikam-mcp-development-tzjeje
  - fabrikam-sim-development-tzjeje
```

### **Workshop-Stable Branch Deployments**
```yaml
# Manual/triggered deployment
Triggers: Push to workshop-stable
Deploys to:
  - 20 team-specific instances
  - Matrix deployment strategy
  - Isolated per-team environments
```

---

## **Branch Protection Rules**

### **Recommended Settings**

**Main Branch:**
- ✅ Allow direct commits (for rapid development)
- ✅ Automatic deployments enabled
- ⚠️ Consider requiring status checks for production stability

**Workshop-Stable Branch:**
- ✅ Protect from direct commits (merge only)
- ✅ Require pull request reviews for critical changes
- ✅ Require status checks to pass before merge
- ✅ Prevent force pushes

---

## **Communication Protocol**

### **Before Workshop (Nov 4-5, 2025)**
- 🔄 Update `workshop-stable` daily with tested improvements
- 📣 Announce updates to proctor team
- 🧪 Test deployments to at least 2 team instances

### **During Workshop**
- 🛑 Freeze `workshop-stable` (no updates unless critical)
- ⚡ Continue development on `main` (for post-workshop improvements)
- 🚨 Emergency hotfixes only to `workshop-stable` with proctor approval

### **After Workshop**
- 🔄 Merge any workshop-stable hotfixes back to main
- 📝 Document lessons learned
- 🎯 Plan next workshop iteration

---

## **Testing Checklist Before Merging to Workshop-Stable**

Before merging `main` → `workshop-stable`:

- [ ] All tests passing (`.\test.ps1 -Verbose`)
- [ ] API health check returns 200
- [ ] MCP server responds to tool calls
- [ ] At least 5 consecutive MCP calls succeed (session management)
- [ ] Support ticket creation works with orderId only
- [ ] Category validation returns accurate enum values
- [ ] Workshop example scenarios tested in Copilot Studio
- [ ] No breaking changes to existing agent configurations

---

## **Version Tagging**

Use semantic versioning tags on `workshop-stable`:

```bash
# After successful workshop deployment
git checkout workshop-stable
git tag -a v1.0.0-workshop -m "Workshop baseline - Nov 4-5, 2025"
git push origin v1.0.0-workshop

# After improvements
git tag -a v1.1.0-workshop -m "Post-workshop improvements"
git push origin v1.1.0-workshop
```

---

## **Rollback Strategy**

If `workshop-stable` deployment fails:

```bash
# Option 1: Revert last merge
git checkout workshop-stable
git revert -m 1 HEAD
git push origin workshop-stable

# Option 2: Reset to known-good tag
git checkout workshop-stable
git reset --hard v1.0.0-workshop
git push origin workshop-stable --force

# Option 3: Redeploy from specific commit
git checkout workshop-stable
git reset --hard <good-commit-hash>
git push origin workshop-stable --force
```

---

## **Quick Reference Commands**

```bash
# View branch status
git branch -vv

# Compare branches
git diff main..workshop-stable
git log main..workshop-stable --oneline

# Merge main to workshop-stable (safe)
git checkout workshop-stable
git merge main --no-ff

# Cherry-pick specific fix
git checkout workshop-stable
git cherry-pick <commit-hash>

# View deployment history
gh run list --branch workshop-stable --limit 10
```

---

## **Team Responsibilities**

### **Development Team**
- Commit to `main` frequently
- Test changes before requesting workshop-stable merge
- Document breaking changes

### **Workshop Facilitators**
- Review `workshop-stable` updates before approval
- Test critical scenarios after each update
- Communicate deployment status to proctors

### **Proctors**
- Monitor deployments during workshop
- Report issues immediately
- Use `workshop-stable` branch for team instances

---

## **Notes**

- **Workshop Date**: November 4-5, 2025 (4 days from branch creation)
- **Team Count**: ~20 teams with isolated instances
- **Critical Features**: MCP session management, support ticket creation, delay detection
- **Known Issues**: None (as of workshop-stable creation)

---

**Last Updated**: October 31, 2025  
**Status**: ✅ Ready for workshop deployment  
**Next Review**: November 1, 2025 (3 days before workshop)
