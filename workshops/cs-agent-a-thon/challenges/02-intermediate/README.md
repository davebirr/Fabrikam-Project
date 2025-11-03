# 🟡 Intermediate Challenge: Multi-Agent Orchestration

**Level Up with Specialist Agents** | 90 minutes | Self-Directed

---

## 🎯 Challenge Overview

You've built a solid foundation agent. Now it's time to scale! Real customer service organizations have **specialists** for different domains. Your challenge: build a multi-agent system where an orchestrator routes customers to the right specialist.

**The Evolution**:
- **Beginner**: One agent does everything
- **Intermediate**: Orchestrator + specialist agents working together
- **Advanced**: Production-grade enterprise system

---

## 🎪 Choose Your Path

Pick the challenge that excites you most, or tackle multiple if you're ambitious!

### **🌟 Option A: Multi-Agent Orchestration** (Recommended)
Build an orchestrator that routes to specialist agents

**Difficulty**: ⭐⭐⭐  
**Time Estimate**: 75-90 minutes  
**Coolness Factor**: 🔥🔥🔥

### **🖼️ Option B: Vision Integration**
Add image analysis for damage assessment

**Difficulty**: ⭐⭐  
**Time Estimate**: 60-75 minutes  
**Coolness Factor**: 🔥🔥

### **🤖 Option C: Proactive Automation**
Build an agent that monitors and acts autonomously

**Difficulty**: ⭐⭐⭐⭐  
**Time Estimate**: 90+ minutes  
**Coolness Factor**: 🔥🔥🔥🔥

---

## 🌟 Option A: Multi-Agent Orchestration (Primary Challenge)

### **The Scenario**

Fabrikam is growing fast! They now have specialized departments:
- **Sales Team**: Product recommendations, pricing, customization
- **Technical Team**: Installation, repairs, warranty claims
- **Billing Team**: Payments, refunds, financing options
- **Escalation Team**: Complaints, legal issues, executive review

**Your Mission**: Build an **Orchestrator Agent** that intelligently routes customers to the right specialist, maintains context, and delivers seamless experiences.

---

### **Architecture**

```
Customer Request
      ↓
┌─────────────────────┐
│  Orchestrator Agent │  ← Main entry point
│  "Customer Service  │
│       Hub"          │
└─────────────────────┘
      ↓ Routes to
      ├─→ 🛒 Sales Specialist Agent
      ├─→ 🔧 Technical Specialist Agent
      ├─→ 💰 Billing Specialist Agent
      └─→ 🚨 Escalation Specialist Agent
```

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Orchestrator correctly identifies which specialist to route to
- ✅ At least 2 specialist agents working
- ✅ Basic context passed between agents
- ✅ Customer can complete simple requests

#### **Good Success (60 points)**
- ✅ All 4 specialist agents implemented
- ✅ Seamless handoffs with full context
- ✅ Multi-turn conversations within specialists
- ✅ Natural transitions ("Let me connect you to...")
- ✅ Orchestrator can route to multiple specialists in sequence

#### **Excellent Success (100 points)**
- ✅ Intelligent intent classification (handles ambiguous requests)
- ✅ Context summarization between handoffs
- ✅ Specialists can escalate back to orchestrator
- ✅ Conversation history maintained across specialists
- ✅ Orchestrator makes smart routing decisions based on conversation flow
- ✅ Professional handoff language and experience

#### **Bonus Features (up to 20 points)**
- 🌟 Parallel specialist consultation (orchestrator asks multiple specialists)
- 🌟 Learning from past routing decisions
- 🌟 Sentiment-based routing (frustrated → escalation)
- 🌟 Conversation summarization at end
- 🌟 Proactive specialist suggestions

---

### **🧪 Test Scenarios**

#### **Scenario 1: Simple Single-Specialist Routing**
```
Customer: "I want to buy the Family Haven 1800. What financing do you offer?"

Expected Flow:
1. Orchestrator: Identifies "buy" + "financing" → Route to Sales
2. Sales Agent: Provides product info + financing options
3. Sales Agent: Can answer follow-up questions
```

#### **Scenario 2: Multi-Specialist Complex Request**
```
Customer: "My order is delayed and I want a refund"

Expected Flow:
1. Orchestrator: Identifies "order delayed" + "refund"
2. Orchestrator: Routes to Technical (check order status first)
3. Technical: Looks up order, confirms delay, creates ticket
4. Technical: Hands off to Billing
5. Billing: Explains refund policy, processes request
6. Orchestrator: Confirms resolution with customer
```

#### **Scenario 3: Ambiguous Intent Clarification**
```
Customer: "I have a problem with my home"

Expected Flow:
1. Orchestrator: Recognizes ambiguity
2. Orchestrator: Asks clarifying questions
   - "Can you describe the issue? Is it structural, billing, or delivery-related?"
3. Customer: "The walls are cracking"
4. Orchestrator: Routes to Technical (structural issue)
```

#### **Scenario 4: Escalation Path**
```
Customer: "This is the third time I've called! I want to speak to a manager!"

Expected Flow:
1. Orchestrator: Detects frustration + "manager"
2. Orchestrator: Immediately routes to Escalation
3. Escalation: Empathetic acknowledgment, gathers history
4. Escalation: Creates high-priority ticket with manager assignment
```

---

### **🏗️ Implementation Approaches**

#### **Approach 1: Multiple Copilot Studio Agents** (Easiest)
Create 5 separate agents in Copilot Studio:
- Orchestrator Agent (main entry point)
- Sales Specialist Agent
- Technical Specialist Agent
- Billing Specialist Agent
- Escalation Specialist Agent

**Handoff Method**: Use Copilot Studio's built-in handoff features or topics that redirect

#### **Approach 2: Single Agent with Specialized Topics** (Simpler Setup)
One agent with different Topics acting as "specialists":
- Main Topic: Orchestration and routing
- Sales Topic: Product and pricing
- Technical Topic: Orders and support
- Billing Topic: Payments and refunds
- Escalation Topic: Complaints

**Handoff Method**: Topic transitions within same agent

#### **Approach 3: Agent + Functions** (Most Flexible)
Orchestrator agent that calls specialist "functions" (tools):
- Each specialist is a custom MCP tool
- Orchestrator decides which tool to call
- Tools return specialized responses

---

### **💡 Hints & Tips**

**Available Without Spoilers!** [→ View Hints](./hints-multi-agent.md)

---

### **⚠️ Partial Solution**

**Architecture & Patterns** [→ View Partial Solution](./partial-solution-multi-agent.md)

---

### **🚨 SPOILER ALERT - Full Solution**

**Complete Implementation** [→ View Full Solution](./full-solution-multi-agent.md)

---

## 🖼️ Option B: Vision Integration

### **The Scenario**

Customers often send photos of damage, installation issues, or questions about their homes. Your beginner agent can't see images—time to add vision!

**Your Mission**: Enhance your customer service agent to accept and analyze photos, automatically assessing damage severity and creating detailed tickets.

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Agent accepts image uploads
- ✅ Uses GPT-4 Vision to analyze images
- ✅ Provides basic description of what's in the image
- ✅ Creates support ticket with image analysis

#### **Good Success (60 points)**
- ✅ Categorizes damage severity (Minor/Major/Critical)
- ✅ Identifies specific issue types (cracks, water damage, defects)
- ✅ Suggests immediate actions for safety issues
- ✅ Generates detailed ticket descriptions from images
- ✅ Handles non-damage images gracefully

#### **Excellent Success (100 points)**
- ✅ Estimates repair costs based on visual assessment
- ✅ Compares to similar past issues
- ✅ Asks clarifying questions about the image
- ✅ Provides step-by-step safety instructions for critical issues
- ✅ Multi-image analysis (before/after, multiple angles)

---

### **🧪 Test Scenarios**

#### **Scenario 1: Cracked Wall Analysis**
```
Customer: "There are cracks in my wall" [uploads photo]

Expected Behavior:
✅ Analyze image
✅ Identify crack type (horizontal/vertical, length, location)
✅ Assess severity (Major - spans 3ft, structural concern)
✅ Create ticket with detailed description
✅ Provide safety guidance if needed
✅ Estimate: $2,500-$4,000 repair cost
```

#### **Scenario 2: Water Damage Detection**
```
Customer: [uploads photo of ceiling stain]

Expected Behavior:
✅ Identify water damage
✅ Assess severity (size, color, location)
✅ Ask about water source (roof leak, plumbing, etc.)
✅ Create CRITICAL ticket if active leak detected
✅ Provide immediate action steps (turn off water, place bucket)
```

---

### **💡 Hints & Tips**

[→ View Vision Hints](./hints-vision.md)

---

### **⚠️ Partial Solution**

[→ View Partial Solution](./partial-solution-vision.md)

---

### **🚨 SPOILER ALERT - Full Solution**

[→ View Full Solution](./full-solution-vision.md)

---

## 🤖 Option C: Proactive Automation

### **The Scenario**

What if your agent didn't wait for customers to complain? What if it **actively monitored** orders and reached out proactively?

**Your Mission**: Build a "computer use" style agent that autonomously monitors the Fabrikam system and takes action.

---

### **✅ Success Criteria**

#### **Basic Success (30 points)**
- ✅ Agent checks orders on schedule
- ✅ Detects orders approaching delay threshold
- ✅ Creates "heads up" tickets for potential issues
- ✅ Logs monitoring activity

#### **Good Success (60 points)**
- ✅ Sends proactive customer notifications
- ✅ Escalates delays before customers notice
- ✅ Monitors multiple criteria (delays, inventory, shipping)
- ✅ Generates daily summary reports
- ✅ Handles errors and retries gracefully

#### **Excellent Success (100 points)**
- ✅ Predictive delay detection (identifies patterns)
- ✅ Automated customer updates (email/SMS integration)
- ✅ Coordinated workflows (production → shipping → installation)
- ✅ Smart throttling (doesn't spam customers)
- ✅ Dashboard of proactive interventions

---

### **🧪 Test Scenarios**

#### **Scenario 1: Morning Monitoring Sweep**
```
8:00 AM Daily Run

Expected Behavior:
✅ Query all orders in "In Production" status
✅ Calculate days for each order
✅ For orders at 25-29 days: Log "watch list"
✅ For orders at 30+ days: Create ticket, notify customer
✅ Generate summary: "Checked 47 orders, 3 need attention"
```

#### **Scenario 2: Proactive Customer Outreach**
```
Order #FAB-2025-042 at 27 days (approaching 30-day threshold)

Expected Behavior:
✅ Send proactive email: "Your order is on track, should complete in 3-5 days"
✅ Include estimated completion date
✅ Provide contact for questions
✅ Don't create ticket yet (not actually delayed)
```

---

### **💡 Hints & Tips**

[→ View Automation Hints](./hints-automation.md)

---

### **⚠️ Partial Solution**

[→ View Partial Solution](./partial-solution-automation.md)

---

### **🚨 SPOILER ALERT - Full Solution**

[→ View Full Solution](./full-solution-automation.md)

---

## 🎓 What You'll Learn

Across all options, you'll master:
- ✅ **Advanced agent patterns** - Orchestration, vision, automation
- ✅ **Multi-agent coordination** - Context handoff, routing, collaboration
- ✅ **Specialized capabilities** - Vision analysis, scheduled tasks
- ✅ **Production thinking** - Error handling, monitoring, reporting

---

## 📊 Evaluation

**Time Check**: You have 90 minutes!

- **60 points**: Good stopping point if time is short
- **80 points**: Solid intermediate-level achievement
- **100 points**: Excellent work!
- **100+ points**: Above and beyond!

---

## ⏭️ Next Steps

Ready for the ultimate challenge?

[**→ Proceed to Advanced Challenge**](../03-advanced/README.md)

Build production-ready agents with code using Azure AI Agent Framework!

---

**Remember: You can choose any option or tackle multiple! Focus on learning, not perfection.** 🚀
