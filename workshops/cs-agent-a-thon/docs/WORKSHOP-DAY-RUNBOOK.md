# 🎯 Workshop Day Runbook - November 6, 2025
**cs-agent-a-thon Execution Guide**

---

## ⏰ **Timeline & Key Milestones**

### **7:00 AM - Infrastructure Health Check**
```bash
# Critical system validation (30 minutes)

☐ Check all 5 Fabrikam instances
curl -s https://fabrikam-api-a01.azurewebsites.net/api/health
curl -s https://fabrikam-api-a02.azurewebsites.net/api/health
curl -s https://fabrikam-api-a03.azurewebsites.net/api/health
curl -s https://fabrikam-api-a04.azurewebsites.net/api/health
curl -s https://fabrikam-api-a05.azurewebsites.net/api/health

☐ Verify business simulator status
curl -s https://fabrikam-api-a01.azurewebsites.net/api/workshop/status

☐ Test participant B2B access (spot check 3 accounts)

☐ Confirm Copilot Studio environment accessibility

☐ Validate Azure AI Foundry workspace

Expected Results: All green, response times < 2 seconds
```

### **7:30 AM - Workshop Mode Activation**
```bash
# Activate accelerated business simulation

☐ Enable workshop mode on all instances
for instance in a01 a02 a03 a04 a05; do
  curl -X POST https://fabrikam-api-$instance.azurewebsites.net/api/workshop/start
done

☐ Verify increased simulation rate
# Should see: Order every 5 minutes, ticket every 7 minutes

☐ Confirm fresh scenarios available

☐ Test team access to their assigned instances

Expected Results: Active simulation, fresh content generating
```

### **8:00 AM - Final Proctor Briefing**
```markdown
☐ Distribute proctor quick reference cards
☐ Confirm team assignments and participant lists
☐ Review common troubleshooting scenarios
☐ Test proctor access to all instances
☐ Verify backup account credentials

Proctor Responsibilities:
- Instance A01: Beginner/Customer Service guidance
- Instance A02: Intermediate/Sales Intelligence support
- Instance A03: Advanced/Executive Assistant help
- Instance A04: Mixed scenario facilitation
- Instance A05: Experimental/overflow support
```

### **8:15 AM - Workshop Launch**
```markdown
☐ Welcome participants and overview (5 minutes)
☐ Direct participants to their team assignments
☐ Provide instance URLs and access instructions
☐ Begin challenge selection and team formation

Success Metric: All participants logged in and building within 10 minutes
```

---

## 👥 **Participant Assignment Matrix**

### **Team Assignments (100 Participants)**
```yaml
Instance A01 - Beginner Focus (Participants 1-20):
  Challenge: Customer Service Hero
  Proctor: [Name]
  URL: https://fabrikam-api-a01.azurewebsites.net
  Teams: 4 teams of 5 participants each
  
Instance A02 - Intermediate Focus (Participants 21-40):
  Challenge: Sales Intelligence Wizard
  Proctor: [Name] 
  URL: https://fabrikam-api-a02.azurewebsites.net
  Teams: 4 teams of 5 participants each
  
Instance A03 - Advanced Focus (Participants 41-60):
  Challenge: Executive Assistant Ecosystem
  Proctor: [Name]
  URL: https://fabrikam-api-a03.azurewebsites.net
  Teams: 4 teams of 5 participants each
  
Instance A04 - Mixed Scenarios (Participants 61-80):
  Challenge: Choose your own adventure
  Proctor: [Name]
  URL: https://fabrikam-api-a04.azurewebsites.net
  Teams: 4 teams of 5 participants each
  
Instance A05 - Experimental/Overflow (Participants 81-100):
  Challenge: Advanced experiments
  Proctor: [Name]
  URL: https://fabrikam-api-a05.azurewebsites.net
  Teams: 4 teams of 5 participants each
```

### **Access Information Distribution**
```markdown
Each participant receives:
- Team assignment (e.g., "Team A01-1")
- Instance URL for their Fabrikam environment
- Copilot Studio portal link
- Workshop challenge guide URL
- Proctor contact information
- Emergency technical support contact
```

---

## 🔧 **Real-Time Monitoring**

### **Key Metrics Dashboard**
```yaml
Monitor Every 15 Minutes:
☐ Instance response times (< 2 seconds)
☐ Database connection health
☐ Business simulation activity
☐ Participant login success rate
☐ Copilot Studio agent creation rate

Warning Thresholds:
- API response time > 3 seconds
- Database connections > 80% capacity
- No new simulation activity for 10 minutes
- Login failure rate > 10%
- Zero agents created in 15 minutes
```

### **Health Check Commands**
```bash
# Quick health verification
for instance in a01 a02 a03 a04 a05; do
  echo "Checking $instance..."
  curl -w "%{http_code} %{time_total}s" -s -o /dev/null \
    https://fabrikam-api-$instance.azurewebsites.net/api/health
  echo ""
done

# Business simulation status
curl -s https://fabrikam-api-a01.azurewebsites.net/api/workshop/status | jq
```

---

## 🚨 **Troubleshooting Playbook**

### **Authentication Issues**
```yaml
Symptom: Participant can't log in
Quick Fix:
  1. Check B2B guest invitation status
  2. Resend invitation if needed
  3. Use backup proctor account temporarily
  4. Guide to correct login flow

Backup: Pre-created shared accounts
- Username: workshop-backup-01@tenant.com
- Password: [Provided separately]
```

### **Performance Issues**
```yaml
Symptom: Slow response times
Quick Fix:
  1. Scale up App Service plan to next tier
  2. Restart app services if needed
  3. Check database DTU usage
  4. Redistribute load to less busy instances

Azure CLI:
az appservice plan update --name asp-fabrikam-a01 --sku P2v2
```

### **Copilot Studio Access Issues**
```yaml
Symptom: Can't create agents in Copilot Studio
Quick Fix:
  1. Verify guest user permissions
  2. Check Copilot Studio environment access
  3. Use alternative participant account
  4. Fall back to pre-created agent templates

Backup: Pre-built agents participants can modify
```

### **Business Simulation Problems**
```yaml
Symptom: No new orders/tickets appearing
Quick Fix:
  1. Check workshop mode status
  2. Restart business simulator service
  3. Manually trigger scenario generation
  4. Use pre-prepared scenario list

Manual Commands:
curl -X POST https://fabrikam-api-a01.azurewebsites.net/api/workshop/generate-order
curl -X POST https://fabrikam-api-a01.azurewebsites.net/api/workshop/generate-ticket
```

---

## 📊 **Success Tracking**

### **Real-Time Success Metrics**
```yaml
Track Throughout Workshop:
☐ Participant login rate (target: 95% within 10 minutes)
☐ Agent creation rate (target: 80% within 30 minutes)
☐ Team collaboration activity
☐ Challenge completion progress
☐ Technical support ticket volume (target: < 10%)

Success Indicators:
✅ Majority of participants building agents within 15 minutes
✅ Fresh business scenarios appearing regularly
✅ Teams collaborating on shared instances
✅ Minimal technical support required
✅ Positive participant engagement and energy
```

### **Workshop Completion Metrics**
```yaml
End-of-Workshop Goals:
☐ 80+ participants complete working agent
☐ All three challenge paths successfully demonstrated
☐ Business simulation provided engaging scenarios
☐ Participant feedback ratings > 4.0/5.0
☐ Technical issues affected < 5% of participants
```

---

## 🎯 **Proctor Quick Reference**

### **Common Participant Questions**
```yaml
"I can't log in":
- Check email for B2B invitation
- Try incognito/private browser mode
- Use backup account if available

"Copilot Studio won't let me create agents":
- Verify environment access
- Try refreshing browser
- Use pre-built agent template

"My API calls aren't working":
- Check custom connector configuration
- Verify instance URL is correct
- Test with simple GET request first

"I don't see any customer service tickets":
- Refresh the browser/agent
- Check business simulation is active
- Manually generate scenarios if needed
```

### **Escalation Criteria**
```yaml
Escalate to Technical Lead if:
- Multiple participants can't access instance
- API response times consistently > 5 seconds
- Business simulation stops working
- Copilot Studio completely inaccessible
- Database connection failures
```

---

## 📞 **Emergency Contacts**

### **Technical Support Escalation**
```yaml
Primary: [Your Name] - [Phone Number]
Backup: [Proctor Lead] - [Phone Number]
Infrastructure: [Azure Support] - [Contact Info]
Facilities: [Event Coordinator] - [Phone Number]
```

### **Communication Plan**
```yaml
Minor Issues: Handle with proctor team
Major Issues: Notify technical lead immediately
Critical Failures: Implement backup plans
Participant Communication: Use provided channels only
```

---

## ✅ **Post-Workshop Checklist**

### **Immediate (Within 2 Hours)**
```yaml
☐ Disable workshop mode on all instances
☐ Export participant agent artifacts
☐ Collect proctor feedback
☐ Document major issues encountered
☐ Begin participant feedback collection

Commands:
for instance in a01 a02 a03 a04 a05; do
  curl -X POST https://fabrikam-api-$instance.azurewebsites.net/api/workshop/stop
done
```

### **Follow-Up (Within 24 Hours)**
```yaml
☐ Compile workshop success metrics
☐ Analyze participant feedback
☐ Document lessons learned
☐ Plan infrastructure cleanup
☐ Share success stories and outcomes
```

---

**This runbook ensures smooth execution and provides clear procedures for handling any workshop day challenges. Success depends on preparation, monitoring, and quick response to issues! 🚀**