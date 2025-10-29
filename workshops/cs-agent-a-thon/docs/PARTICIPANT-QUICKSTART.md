# 🚀 Workshop Participant Quick Start Guide
**CS Agent-A-Thon - November 6, 2025**

---

## ✅ **Before Workshop Day**

### Step 1: Accept B2B Invitation
- Check your **@microsoft.com** email inbox
- Look for email: **"Invitation to access CS-Agent-A-Thon Workshop"**
- Click **"Accept invitation"** button
- Complete one-time acceptance process

**Status**: ⬜ Not yet accepted | ✅ Accepted

---

## 🔗 **Workshop Access URLs** ⚠️ **BOOKMARK THESE**

### **Primary Environment** (Use These by Default)

#### **Copilot Studio** (Primary Workshop Tool)
```
https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971
```
> 🚨 **CRITICAL**: You MUST use the `?tenant=` parameter or you'll access your personal Microsoft tenant instead!

#### **Azure Portal**
```
https://portal.azure.com
```
> Switch to workshop tenant: Top-right → Directory + Subscription → Select "levelupcspfy26cs01"

#### **Azure AI Foundry**
```
https://ai.azure.com
```
> Switch to workshop subscription if needed

---

### **Backup Environment** (Use Only If Directed by Proctors)

In case of technical issues with the primary environment, proctors may direct you to use the backup tenant:

#### **Copilot Studio (BACKUP)**
```
https://copilotstudio.microsoft.com/?tenant=26764e2b-92cb-448e-a938-16ea018ddc4c
```
> ⚠️ **Only use this if proctors announce a failover**

#### **Notes on Backup Environment**
- Same @microsoft.com login credentials
- Same team assignments and resources
- Identical workshop experience
- Proctors will announce if/when to switch

---

## 📋 **Day-of Workshop Checklist**

### Login Process
1. ✅ Navigate to Copilot Studio URL (with tenant parameter)
2. ✅ Login with your **alias@microsoft.com** credentials
3. ✅ Verify you're in the **levelupcspfy26cs01** tenant
4. ✅ Locate your team's workspace/resources

### Verify Access
- [ ] Can you access Copilot Studio?
- [ ] Can you see your team's resource group in Azure Portal?
- [ ] Do you have Contributor permissions on your team RG?
- [ ] Can you access Azure AI Foundry?

### Team Information
Find your team assignment in the [Team Roster](../docs/team-roster.md)

---

## 🆘 **Troubleshooting**

### "I don't see any resources"
**Solution**: Verify you're in the correct tenant
- Azure Portal: Top-right corner → Check tenant name
- Look for: **"levelupcspfy26cs01.onmicrosoft.com"**
- If different: Click Directory filter → Switch to workshop tenant

### "Copilot Studio shows my personal tenant"
**Solution**: You didn't use the tenant parameter in URL
- ❌ Wrong: `https://copilotstudio.microsoft.com`
- ✅ Correct: `https://copilotstudio.microsoft.com/?tenant=fd268415-22a5-4064-9b5e-d039761c5971`

### "I can't accept the B2B invitation"
**Solution**: Contact workshop proctors
- Invitation may have expired
- Email may have been filtered
- Proctors can resend invitation

### "Access Denied" errors
**Solution**: Check your role assignment
- You should have **Contributor** on your team's resource group
- Contact proctors if permissions are missing
- Verify you accepted B2B invitation

---

## 🎯 **Your Workshop Environment**

### What You Have Access To:
- ✅ Your team's Azure resource group (Contributor)
- ✅ Azure OpenAI models (GPT-4, GPT-4o)
- ✅ Azure AI Foundry workspace
- ✅ Copilot Studio (in workshop tenant)
- ✅ Fabrikam API endpoint (your team instance)
- ✅ Sample business data and scenarios

### What You DON'T Have Access To:
- ❌ Other teams' resource groups
- ❌ Tenant-wide settings (proctors only)
- ❌ Subscription-level changes
- ❌ User management

---

## 📖 **Workshop Resources**

| Resource | Location |
|----------|----------|
| Team Roster | [docs/team-roster.md](../docs/team-roster.md) |
| Challenge Documentation | [challenges/](../challenges/) |
| Fabrikam API Documentation | [FabrikamApi/README.md](../../FabrikamApi/README.md) |
| MCP Server Documentation | [FabrikamMcp/README.md](../../FabrikamMcp/README.md) |
| MCP Connector Setup (B2B) | [docs/MCP-CONNECTOR-B2B-SETUP.md](MCP-CONNECTOR-B2B-SETUP.md) |

---

## 🏆 **Workshop Goals**

Build AI agents that help Fabrikam Modular Homes with:
1. **Sales Automation** - Process orders, track inventory, generate quotes
2. **Customer Service** - Handle support tickets, answer questions
3. **Business Intelligence** - Analyze sales data, generate insights

**Tools Available**:
- Copilot Studio (build conversational agents)
- Azure OpenAI (GPT-4, GPT-4o)
- Model Context Protocol (connect to Fabrikam API)
- Python/TypeScript (custom development)

---

## 💬 **Getting Help**

### During Workshop:
- **Proctors**: Available in-person for assistance
- **Team Channel**: Collaborate with your team members
- **Documentation**: Reference Fabrikam API docs

### Technical Issues:
- **Can't access tenant**: Contact proctors immediately
- **Permission errors**: Verify B2B invitation accepted
- **Service outages**: Check Azure status dashboard

---

## ⏰ **Timeline**

**Pre-Workshop (By Nov 5)**:
- ✅ Accept B2B invitation
- ✅ Bookmark access URLs
- ✅ Verify you can login to Azure Portal

**Workshop Day (Nov 6)**:
- 🕐 9:00 AM - Registration & Setup
- 🕐 9:30 AM - Kickoff & Challenge Overview
- 🕐 10:00 AM - Start Building!
- 🕐 12:00 PM - Lunch (working)
- 🕐 3:00 PM - Demos & Presentations
- 🕐 4:00 PM - Winners Announced

---

## ✅ **Pre-Workshop Readiness**

Complete this checklist before November 6:

- [ ] Accepted B2B invitation email
- [ ] Bookmarked Copilot Studio URL (with tenant parameter)
- [ ] Tested login to Azure Portal
- [ ] Verified access to workshop tenant
- [ ] Located my team in roster
- [ ] Read challenge documentation
- [ ] Reviewed Fabrikam API docs

---

**Questions?** Contact workshop organizers or your team proctor.

**Ready to build?** See you on November 6! 🚀
