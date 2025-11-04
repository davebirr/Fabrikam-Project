# 🏆 Fabrikam Customer Service Agent Challenges

Welcome to the Fabrikam Modular Homes AI Agent Workshop! This workshop takes you on a progressive journey from building your first AI agent to creating production-ready multi-agent systems.

## 🎯 Workshop Overview

**Scenario**: You're building AI-powered customer service solutions for **Fabrikam Modular Homes**, a manufacturer of high-quality prefabricated homes. Each challenge builds on the previous one, creating increasingly sophisticated customer service capabilities.

**Duration**: 270 minutes (3 challenges × 90 minutes each)

**Technologies**: 
- Microsoft Copilot Studio
- Model Context Protocol (MCP)
- Azure AI Agent Framework
- Azure OpenAI / GitHub Models
- Your choice of tools and frameworks!

---

## 📚 Challenge Progression

**Choose Your Starting Point!** Each challenge is designed to work standalone, but they build on each other conceptually:

### 🟢 [Beginner: Customer Service Foundation](./01-beginner/README.md)
**Build Your First AI Agent** | 90 minutes | Guided

Master the fundamentals of AI agent development by building a customer service agent that handles order inquiries, product information, and support ticket creation.

**You'll Learn**:
- ✅ Copilot Studio basics
- ✅ MCP tool integration
- ✅ System prompt engineering
- ✅ Conversational flow design
- ✅ Error handling and empathy

**Success Criteria**: Agent successfully handles order lookups, product comparisons, and creates support tickets with professional, empathetic responses.

**Starting Here?** Perfect for those new to AI agents or wanting a guided foundation!

[**Start Beginner Challenge →**](./01-beginner/README.md)

---

### 🟡 [Intermediate: Multi-Agent Orchestration](./02-intermediate/README.md)
**Level Up with Specialist Agents** | 90 minutes | Self-Directed

Build a multi-agent system where specialist agents handle different aspects of customer service.

**Primary Challenge**: Multi-Agent Orchestration
**Alternative Options**: Vision Integration, Proactive Automation

**You'll Learn**:
- ✅ Agent orchestration patterns
- ✅ Context handoff between agents
- ✅ Intent classification and routing
- ✅ Multi-modal capabilities (vision)
- ✅ Proactive agent automation

**Success Criteria**: Orchestrator agent successfully routes customers to specialist agents, maintains conversation context, and delivers seamless experiences.

**Starting Here?** Use beginner resources for quick foundation, then build your multi-agent system!

[**Start Intermediate Challenge →**](./02-intermediate/README.md)

---

### 🔴 [Advanced: Production-Ready Agent Framework](./03-advanced/README.md)
**Build Enterprise-Grade Solutions** | 90 minutes | Completely Self-Directed

Build a customer service solution using code-first approaches with production patterns.

**Your Choice**: Python, .NET, JavaScript, or any framework you prefer!

**You'll Learn**:
- ✅ Code-first agent development
- ✅ Custom tool registration
- ✅ State management and memory
- ✅ Telemetry and monitoring
- ✅ Testing and deployment
- ✅ Production patterns

**Success Criteria**: Working agent implementation with code, proper error handling, telemetry, and deployment-ready configuration.

**Starting Here?** Leverage beginner/intermediate system prompts and patterns even if you skip those challenges!

[**Start Advanced Challenge →**](./03-advanced/README.md)

---

## 🛠️ Workshop Resources

### **Fabrikam MCP Server**
Your team's MCP server is already deployed and ready to use:
- **Base URL**: Provided by your proctor
- **Authentication**: Disabled mode (workshop)
- **Available Tools**: Orders, Products, Customers, Support Tickets

### **Documentation**
- [MCP Connection Guide](../setup/mcp-connection-guide.md)
- [Fabrikam Business Context](../resources/fabrikam-business-context.md)
- [Common Troubleshooting](../resources/troubleshooting.md)
- [Proctor Notes](../resources/proctor-notes.md)

### **Sample Data**
The Fabrikam system is pre-populated with realistic data:
- **Customers**: 50+ customer records with various scenarios
- **Orders**: Active, completed, delayed, and problematic orders
- **Products**: Full catalog of modular home models
- **Support Tickets**: Examples across all priority levels

---

## 📊 Scoring & Success

### **Scoring System**
Each challenge uses a progressive scoring system:
- **Basic Success (30 points)**: Core functionality working
- **Good Success (60 points)**: Natural conversations, error handling
- **Excellent Success (100 points)**: Proactive assistance, business context awareness
- **Bonus Features (10-20 points)**: Going above and beyond

### **What Success Looks Like**

**✅ Technical Success**:
- Tools are called and responses are used effectively
- Error handling is comprehensive
- Conversations flow naturally

**✅ Business Success**:
- Demonstrates understanding of Fabrikam's business model
- Responses show empathy and professionalism
- Proactively solves problems

**✅ User Experience Success**:
- Customers receive complete answers
- Next steps are always clear
- Emotional state is acknowledged

---

## 💡 Learning Approach

### **The Secret: Use AI to Build AI!** 🤖

**You have powerful tools at your fingertips - use them!**

Building great agents is all about crafting effective system prompts (instructions). Why start from scratch when you have AI assistants to help?

**🎯 Recommended Tools:**

- **M365 Copilot Prompt Coach** - Get expert feedback on your agent instructions
  - Ask: "Review this agent system prompt for clarity and completeness"
  - Get suggestions for improving tone, structure, and business logic
  - Iterate based on feedback

- **GitHub Copilot in VS Code** - Generate code, scripts, and advanced logic
  - Write comments describing what you need, let Copilot generate it
  - Great for Advanced challenge implementation
  - Excellent for MCP tool integration code

- **Copilot Chat** - Brainstorm approaches and troubleshoot issues
  - "How should I structure a multi-agent orchestration system?"
  - "What's the best way to detect customer frustration in text?"
  - "Help me debug why my agent isn't calling the get_orders tool"

**💡 Pro Tip**: Copy your agent's conversation into Copilot Chat and ask "What went wrong here? How can I improve the system prompt?"

### **Agent Development is Iterative** 🔄

**Critical mindset shift**: Building great agents requires LOTS of trial and error!

**The Reality**:
- ❌ Your first system prompt won't be perfect
- ❌ Agents will misunderstand requests
- ❌ Tools won't be called when you expect
- ✅ This is completely normal and expected!

**The Winning Process**:
1. **Start simple** - Basic system prompt, test one scenario
2. **Test and observe** - What worked? What didn't?
3. **Analyze failures** - Why did the agent respond that way?
4. **Refine prompts** - Add clarity, examples, or constraints
5. **Test again** - Did it improve? New issues?
6. **Repeat, repeat, repeat** - Each iteration gets better!

**Example Evolution**:
```
Version 1: "You are a customer service agent"
↓ (Agent is too generic)

Version 2: "You are a friendly Fabrikam customer service agent. Help with orders."
↓ (Agent doesn't use tools)

Version 3: "You are a Fabrikam agent. When customers ask about orders, use get_orders tool."
↓ (Agent uses tool but doesn't analyze results)

Version 4: "You are a Fabrikam agent. Use get_orders to check order status. If delivery 
is over 30 days past order date, apologize and create a support ticket."
✅ (Now it works!)
```

**🎯 Success comes from iteration, not perfection!** Test frequently, fail fast, improve continuously.

### **Progressive Reveal System**

Each challenge includes multiple levels of guidance:

1. **📋 Challenge Description** - What to build (start here!)
2. **💡 Hints & Tips** - Guidance without giving away the solution
3. **⚠️ Partial Solution** - Architecture and approach (if you're stuck)
4. **🚨 SPOILER ALERT - Full Solution** - Complete implementation (last resort!)

**Our Philosophy**: Try it yourself first! Use hints when stuck, partial solutions for inspiration, and full solutions only when you want to compare approaches or are completely blocked.

### **Collaboration is Encouraged**
- Discuss approaches with your table
- Ask proctors for help anytime
- Share insights (not code) with others
- Learn from different implementation styles

### **Choose Your Own Adventure**
- **New to AI Agents?** Start with Beginner for a guided experience
- **Some Experience?** Jump to Intermediate and use beginner resources as needed
- **Code Wizard?** Go straight to Advanced and leverage all workshop materials
- **Explorers Welcome**: Try different challenges, switch between them, or deep-dive into one

Each challenge is designed to work standalone while offering cross-references to help you succeed!

---

## 🚀 Getting Started

### **Pre-Workshop Checklist**
- [ ] Access to Microsoft Copilot Studio
- [ ] Your team's MCP server URL (from proctor)
- [ ] Development environment for Advanced challenge (optional)
- [ ] GitHub Copilot access (recommended)
- [ ] Enthusiasm and curiosity! 🎉

### **Workshop Flow**
1. **Introduction** (15 min): Workshop overview, Fabrikam context, choose your challenge
2. **Challenge Block 1** (90 min): Work on your selected challenge
3. **Break** (15 min): Recharge and network
4. **Challenge Block 2** (90 min): Continue or move to next challenge
5. **Break** (15 min): Coffee and conversations
6. **Challenge Block 3** (90 min): Polish your work or tackle another challenge
7. **Showcase & Wrap-Up** (30 min): Share your creations!

**Note**: You can tackle challenges in any order, repeat challenges with different approaches, or spend all 3 blocks perfecting one solution. Your choice!

---

## 🎓 Learning Outcomes

By the end of this workshop, you will:
- ✅ Understand AI agent architecture and design patterns
- ✅ Know how to integrate external tools via MCP
- ✅ Master conversational design for natural interactions
- ✅ Implement multi-agent orchestration
- ✅ Build production-ready agents with proper telemetry
- ✅ Have hands-on experience with Microsoft's AI agent stack

---

## 🆘 Need Help?

**Proctors are here to help!** Don't hesitate to:
- 🙋 Ask questions anytime
- 💬 Request clarification on challenges
- 🔍 Get troubleshooting assistance
- 💡 Discuss architecture decisions

**Common Questions**: Check the [FAQ](../resources/faq.md) first!

---

## 📝 Feedback

We're constantly improving this workshop! Please share:
- What worked well
- What was confusing
- Ideas for future challenges
- Your favorite "aha!" moments

---

**Ready to build some amazing AI agents? Let's get started!** 🚀

[**Begin with Beginner Challenge →**](./01-beginner/README.md)
