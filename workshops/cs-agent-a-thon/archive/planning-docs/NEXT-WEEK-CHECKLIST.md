# ⚡ URGENT: Next Week Implementation Checklist
**Daily Action Items for cs-agent-a-thon Nov 6**

---

## 📅 **MONDAY OCT 28 - FOUNDATION DAY**

### **Morning (9 AM - 12 PM): Infrastructure Setup**
```bash
Priority: Get basic infrastructure running

☐ Request BAMI tenant + Azure subscription
☐ Set up basic security groups (A01-A05 teams)
☐ Create resource groups for 5 Fabrikam instances
☐ Deploy first Fabrikam instance manually (A01)
☐ Verify instance health and accessibility

Quick Commands:
# Create resource groups
az group create --name rg-fabrikam-a01-workshop --location eastus2
az group create --name rg-fabrikam-a02-workshop --location eastus2
# ... repeat for A03-A05
```

### **Afternoon (1 PM - 5 PM): Instance Deployment**
```bash
☐ Deploy remaining 4 Fabrikam instances (A02-A05)
☐ Configure SQL databases with seed data
☐ Test API endpoints for all instances
☐ Verify MCP servers are accessible
☐ Basic smoke test of each instance

Health Check URLs:
https://fabrikam-api-a01.azurewebsites.net/api/health
https://fabrikam-api-a02.azurewebsites.net/api/health
https://fabrikam-api-a03.azurewebsites.net/api/health
https://fabrikam-api-a04.azurewebsites.net/api/health
https://fabrikam-api-a05.azurewebsites.net/api/health
```

### **Evening (After Hours): Business Simulator**
```csharp
☐ Implement basic BusinessSimulatorService
☐ Add workshop mode configuration
☐ Test order generation (1 every 5 minutes)
☐ Test ticket generation (1 every 7 minutes)
☐ Verify background service is running

// Quick implementation priority:
// 1. Simple order generation
// 2. Basic support ticket creation
// 3. Workshop mode toggle
// 4. Manual trigger endpoints
```

---

## 📅 **TUESDAY OCT 29 - CORE FEATURES**

### **Morning (9 AM - 12 PM): Workshop Management**
```csharp
☐ Implement WorkshopController API
☐ Add start/stop workshop endpoints
☐ Test workshop mode activation
☐ Verify simulation speed changes
☐ Create workshop status endpoint

// Essential endpoints:
POST /api/workshop/start
POST /api/workshop/stop  
GET  /api/workshop/status
```

### **Afternoon (1 PM - 5 PM): B2B Guest Setup**
```powershell
☐ Configure B2B guest invitation policies
☐ Create team security groups (A01-A05)
☐ Test B2B invitation with 5 test accounts
☐ Verify guest access to Azure portal
☐ Test guest access to Copilot Studio

# Test command:
New-AzureADMSInvitation -InvitedUserEmailAddress "test@microsoft.com" `
  -InviteRedirectUrl "https://fabrikam-api-a01.azurewebsites.net"
```

### **Evening: Copilot Studio Integration**
```yaml
☐ Set up Copilot Studio environment
☐ Test custom connector to Fabrikam API
☐ Verify B2B guests can create agents
☐ Test basic agent → API integration
☐ Document any guest user limitations
```

---

## 📅 **WEDNESDAY OCT 30 - PARTICIPANT EXPERIENCE**

### **Morning (9 AM - 12 PM): User Management**
```powershell
☐ Create participant invitation script
☐ Define team assignments (20 per instance)
☐ Test bulk B2B invitation process
☐ Verify team access permissions
☐ Create participant welcome materials

# Participant distribution:
# A01: Participants 1-20 (Beginner focus)
# A02: Participants 21-40 (Intermediate focus)  
# A03: Participants 41-60 (Advanced focus)
# A04: Participants 61-80 (Mixed scenarios)
# A05: Participants 81-100 (Experimental)
```

### **Afternoon (1 PM - 5 PM): End-to-End Testing**
```yaml
☐ Test complete participant flow (5 volunteers)
☐ Time from invitation to building agent
☐ Verify business simulation is engaging
☐ Test team collaboration scenarios
☐ Document common issues and solutions

Success Metrics:
- B2B login: < 2 minutes
- Agent creation: < 10 minutes  
- API integration: < 5 minutes
- Fresh scenarios available throughout
```

### **Evening: Workshop Materials**
```markdown
☐ Update workshop challenge guides
☐ Create participant quick-start instructions
☐ Prepare proctor facilitation materials
☐ Test all technology option paths
☐ Finalize team assignment strategy
```

---

## 📅 **THURSDAY OCT 31 - PROCTOR TESTING**

### **Morning (9 AM - 12 PM): Proctor Session #1**
```yaml
☐ 3 proctors test complete workshop flow
☐ Each tests different challenge path:
  - Proctor 1: Beginner (Customer Service)
  - Proctor 2: Intermediate (Sales Intelligence)
  - Proctor 3: Advanced (Executive Assistant)
☐ Document all issues and friction points
☐ Time each challenge completion
☐ Test proctor support scenarios

Critical Questions:
- Can proctors complete challenges in time?
- Are instructions clear and actionable?
- Does simulation provide enough content?
- Are there blocking technical issues?
```

### **Afternoon (1 PM - 5 PM): Issue Resolution**
```yaml
☐ Fix all critical issues identified
☐ Improve participant instructions
☐ Adjust simulation timing if needed
☐ Test fixes with affected proctors
☐ Update workshop day procedures

Priority Fixes:
1. Authentication blocking issues
2. API connectivity problems  
3. Unclear instructions
4. Performance bottlenecks
5. Missing scenarios
```

### **Evening: Validation Testing**
```yaml
☐ Proctor validation session #2
☐ Test all fixes are working
☐ Final proctor confidence check
☐ Workshop day dry run
☐ Emergency contact procedures
```

---

## 📅 **FRIDAY NOV 1 - FINAL PREP**

### **Morning (9 AM - 12 PM): Polish & Documentation**
```markdown
☐ Final bug fixes from Thursday testing
☐ Complete workshop day runbook
☐ Test infrastructure health monitoring
☐ Prepare emergency contact list
☐ Create workshop day timeline

Workshop Day Runbook Must Include:
- 7:00 AM health check procedures
- 7:30 AM simulation activation
- 8:00 AM proctor briefing points
- 8:15 AM workshop start procedures
- Emergency troubleshooting guide
```

### **Afternoon (1 PM - 5 PM): Final Validation**
```yaml
☐ Complete infrastructure stress test
☐ Verify all 5 instances handle load
☐ Test workshop start/stop procedures
☐ Validate all participant access
☐ Final proctor readiness confirmation

Load Test: 20 concurrent users per instance
- API response times < 2 seconds
- Database performance acceptable
- No memory/CPU issues
- Business simulation continues
```

### **Evening: Workshop Ready State**
```yaml
☐ All systems in production-ready state
☐ Workshop materials finalized
☐ Proctor confidence confirmed
☐ Day-of procedures documented
☐ Emergency plans prepared

Ready State Checklist:
✅ 5 Fabrikam instances healthy
✅ B2B guest access validated
✅ Business simulation running
✅ Workshop controls functional
✅ Proctors trained and confident
```

---

## 🚨 **Daily Blocker Escalation**

### **If Blocked on Monday**
```yaml
B2B Policy Issues: Escalate to tenant admin immediately
Instance Deployment Fails: Use manual Azure portal deployment
Simulation Bugs: Focus on manual scenario generation
```

### **If Blocked on Tuesday**
```yaml
Copilot Studio Access: Test with native users as backup
API Integration Issues: Create manual test endpoints
Workshop Controls Fail: Prepare manual simulation control
```

### **If Blocked on Wednesday**
```yaml
Mass B2B Invitation Fails: Prepare manual invitation list
Team Access Issues: Use broader permission groups
Performance Problems: Scale up App Service plans
```

### **If Blocked on Thursday**
```yaml
Proctor Testing Fails: Reduce scope to essential features
Major Technical Issues: Prepare simplified workshop version
Authentication Problems: Create shared accounts backup
```

### **Friday: No Major Changes**
```yaml
Only fix critical bugs
No new features or experiments
Focus on stability and confidence
Prepare for workshop success
```

---

## 📞 **Emergency Contacts & Resources**

### **Technical Escalation**
- BAMI tenant issues: [Internal IT Contact]
- Azure subscription: [Azure Support]
- Copilot Studio: [Power Platform Team]
- Infrastructure problems: [Cloud Engineering]

### **Workshop Day Support**
- Primary technical contact: [Your phone]
- Backup technical support: [Proctor lead]
- Participant issues: [Registration team]
- Facility/logistics: [Event coordinator]

---

**This week is all about execution and validation. Focus on getting the basics rock-solid rather than perfect features. The participants will have a great experience if the core flow works smoothly! 🎯**