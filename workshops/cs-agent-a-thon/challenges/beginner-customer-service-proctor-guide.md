# 🎓 Beginner Challenge: Customer Service Hero - Proctor Guide
**Facilitator Reference for Evaluating Participant Solutions**

---

## 📋 **Overview**

This guide helps proctors evaluate participant solutions, provide helpful hints without giving away answers, and ensure fair, consistent scoring across all submissions.

### **Your Role as a Proctor**
- 🎯 **Guide, Don't Solve**: Help participants think through problems, don't build for them
- 🔍 **Evaluate Fairly**: Use consistent rubric across all participants
- 💡 **Provide Hints**: Offer progressively detailed hints based on struggle level
- 🎉 **Celebrate Wins**: Recognize creative solutions and learning moments
- ⏱️ **Manage Time**: Help participants prioritize for the 90-120 minute timeframe

---

## 🎯 **Scoring Rubric**

### **Basic Success: 30 Points**

**Requirements:**
- [ ] Agent can look up orders using order number (10 pts)
- [ ] Agent provides product information when requested (10 pts)
- [ ] Agent has clear path to escalate complex issues (10 pts)

**Evaluation Criteria:**

**Order Lookup (10 points):**
- ✅ **Full Credit (10)**: Uses get_orders tool, displays order number, status, and basic details
- ⚠️ **Partial Credit (5)**: Uses tool but only shows raw data or incomplete info
- ❌ **No Credit (0)**: Doesn't use tool or fails to retrieve real data

**Product Information (10 points):**
- ✅ **Full Credit (10)**: Uses get_products tool, provides helpful product details
- ⚠️ **Partial Credit (5)**: Provides generic info without using tools
- ❌ **No Credit (0)**: Cannot answer product questions

**Escalation Path (10 points):**
- ✅ **Full Credit (10)**: Has create_support_ticket implemented with proper parameters
- ⚠️ **Partial Credit (5)**: Mentions escalation but doesn't create actual tickets
- ❌ **No Credit (0)**: No escalation mechanism

**Testing Scenarios for Basic Success:**
1. "What's the status of order FAB-2025-047?"
2. "Tell me about the Family Haven 1800"
3. "My home arrived damaged, what do I do?"

---

### **Good Success: 60 Points**

**Requirements (includes all Basic Success +):**
- [ ] Natural conversation flow with context awareness (10 pts)
- [ ] Handles multiple conversation turns effectively (10 pts)
- [ ] Clear error handling for invalid inputs (5 pts)
- [ ] Professional and empathetic tone (5 pts)

**Evaluation Criteria:**

**Natural Conversation Flow (10 points):**
- ✅ **Full Credit (10)**: Maintains context, remembers previous turns, smooth transitions
- ⚠️ **Partial Credit (5)**: Sometimes maintains context but occasionally loses thread
- ❌ **No Credit (0)**: Treats each message as independent, no context retention

**Multiple Turns (10 points):**
- ✅ **Full Credit (10)**: Handles follow-up questions, clarifications, topic switches
- ⚠️ **Partial Credit (5)**: Handles basic follow-ups but struggles with complexity
- ❌ **No Credit (0)**: Cannot handle multi-turn conversations

**Error Handling (5 points):**
- ✅ **Full Credit (5)**: Gracefully handles invalid order numbers, missing data, malformed requests
- ⚠️ **Partial Credit (3)**: Handles some errors but breaks on others
- ❌ **No Credit (0)**: Crashes or provides unhelpful responses to errors

**Tone (5 points):**
- ✅ **Full Credit (5)**: Consistently professional, empathetic, solution-focused
- ⚠️ **Partial Credit (3)**: Mostly professional but occasionally robotic or curt
- ❌ **No Credit (0)**: Unprofessional, defensive, or unhelpful tone

**Testing Scenarios for Good Success:**
1. Multi-turn: "Check order 47" → "When will it arrive?" → "Can I change the delivery address?"
2. Error: "Look up order XYZ-999-ABC" (invalid format)
3. Follow-up: "Tell me about products" → "Which is best for a family of 4?"
4. Upset customer: "This is taking forever! Where's my order?"

---

### **Excellent Success: 100 Points**

**Requirements (includes all Good Success +):**
- [ ] Proactive assistance and anticipation (15 pts)
- [ ] Demonstrates business context understanding (15 pts)
- [ ] Seamless integration with business processes (10 pts)

**Evaluation Criteria:**

**Proactive Assistance (15 points):**
- ✅ **Full Credit (15)**: Offers next steps before asked, suggests related help, anticipates needs
  - Example: After order lookup, offers to explain production timeline
  - Example: After product question, offers sales specialist connection
- ⚠️ **Partial Credit (8)**: Sometimes proactive but inconsistent
- ❌ **No Credit (0)**: Only responds to direct questions, never volunteers help

**Business Context (15 points):**
- ✅ **Full Credit (15)**: References policies, timelines, processes accurately
  - Knows production takes 8-10 weeks
  - Understands warranty coverage
  - Explains delivery guarantee
  - References specific team members/departments
- ⚠️ **Partial Credit (8)**: Shows some business knowledge but generic
- ❌ **No Credit (0)**: No demonstration of business understanding

**Process Integration (10 points):**
- ✅ **Full Credit (10)**: Creates tickets with proper priority, categories, and complete info
  - Sets appropriate urgency (Critical for damage, High for delays)
  - Includes order numbers and relevant details
  - Names specific people who will follow up
  - Provides ticket numbers for reference
- ⚠️ **Partial Credit (5)**: Creates tickets but missing key details or context
- ❌ **No Credit (0)**: Generic escalation without real process integration

**Testing Scenarios for Excellent Success:**
1. Order lookup → Watch for proactive timeline explanation
2. Product comparison → Watch for unprompted sales referral
3. Quality issue → Watch for proper ticket priority and detailed escalation
4. Delayed order → Watch for warranty/policy knowledge
5. Complex multi-issue conversation → Watch for holistic problem-solving

---

## 💡 **Hint System (Progressive Disclosure)**

### **Level 1 Hints: Gentle Nudge** (Give first when stuck)

**Problem**: "I can't connect to the MCP server"
- 💬 **Hint**: "Double-check that you're using the correct URL format for your deployed instance. Does it start with https:// and end with /mcp?"

**Problem**: "My agent doesn't use the tools"
- 💬 **Hint**: "Try being more explicit in your system prompt about *when* to use each tool. Give examples of trigger phrases like 'check order', 'look up', etc."

**Problem**: "The order lookup returns too much data"
- 💬 **Hint**: "The get_orders tool has parameters. Have you tried using orderId to get a specific order instead of retrieving all orders?"

**Problem**: "I don't know what to put in the system prompt"
- 💬 **Hint**: "Think about three things: 1) Who is the agent? (Role), 2) What can they do? (Capabilities), 3) How should they behave? (Personality)"

---

### **Level 2 Hints: More Specific** (Give if Level 1 doesn't help)

**Problem**: "I can't connect to the MCP server"
- 💬 **Hint**: "Make sure your MCP connection has these settings: Type=MCP, URL=https://[your-instance].azurewebsites.net/mcp, Authentication=Disabled, X-User-GUID header set to a valid GUID"

**Problem**: "My agent doesn't use the tools"
- 💬 **Hint**: "Your system prompt should explicitly list available tools and when to use them. For example: 'When a customer asks about their order, use the get_orders tool. When they ask about products, use the get_products tool.'"

**Problem**: "The order lookup returns too much data"
- 💬 **Hint**: "The get_orders tool accepts an orderId parameter. Extract the order number from the customer's message (like FAB-2025-047) and pass just the numeric part (47) as orderId."

**Problem**: "I don't know what to put in the system prompt"
- 💬 **Hint**: "Here's a structure: Start with 'You are a [role] for Fabrikam...', then list 'You can: 1) Look up orders using get_orders, 2) Provide product info using get_products, 3) Create tickets using create_support_ticket'. Add personality: 'Be empathetic and professional.'"

---

### **Level 3 Hints: Almost There** (Give if still stuck after Level 2)

**Problem**: "I can't connect to the MCP server"
- 💬 **Hint**: "Go to Settings → Knowledge → Add Source → MCP. The production URL is `https://fabrikam-mcp-development-tzjeje.azurewebsites.net/mcp`. For Authentication, select 'Disabled' and add a custom header: X-User-GUID = 00000000-0000-0000-0000-000000000001"

**Problem**: "My agent doesn't use the tools"
- 💬 **Hint**: "Try this pattern: 'When a customer mentions an order number like FAB-2025-XXX, immediately use get_orders with the numeric part as orderId. Do not make up information - always use the tool to get real data.' Test with: 'Check order FAB-2025-047'"

**Problem**: "The order lookup returns too much data"
- 💬 **Hint**: "You need to parse the order number. If customer says 'FAB-2025-047', extract the '47' and call get_orders(orderId=47). The tool will return just that one order with full details instead of paginated results."

**Problem**: "I don't know what to put in the system prompt"
- 💬 **Show Example** (from example solution - simplified):
```
You are a customer service agent for Fabrikam modular homes.
You can:
- Look up orders: get_orders tool
- Show products: get_products tool  
- Create tickets: create_support_ticket tool
Be professional and empathetic. Always use tools to get real data.
```

---

### **Common Participant Mistakes & Hints**

| **Mistake** | **What They're Doing Wrong** | **Hint to Give** |
|-------------|------------------------------|------------------|
| Making up data | Agent invents order statuses instead of using tools | "How can you be sure the information is accurate if you're not checking the real database?" |
| Over-complicated prompts | System prompt is 500+ words | "Start simple - get the basic lookup working first, then add personality and edge cases" |
| Ignoring tool results | Tool returns data but agent doesn't reference it | "After calling a tool, make sure to use the data it returns in your response" |
| No error handling | Agent breaks when order not found | "What should happen if the order number doesn't exist? Add handling for that scenario" |
| Generic responses | All responses sound the same | "Read the customer's emotional state - frustrated vs curious vs happy. Should your tone match?" |
| Not testing edge cases | Only tests happy path | "Try these: wrong order number, misspelled order, angry customer, multiple requests" |

---

## 🧪 **Testing Protocol**

### **Quick Validation Tests** (Use these to spot-check progress)

**Test 1: Basic Order Lookup**
```
Input: "What's the status of order FAB-2025-047?"
Expected: Agent uses get_orders, returns order status "InProduction"
Validates: Tool integration, basic functionality
```

**Test 2: Product Question**
```
Input: "Tell me about the Family Haven 1800"
Expected: Agent uses get_products, provides size, price, features
Validates: Product tool integration, information presentation
```

**Test 3: Error Handling**
```
Input: "Check order FAB-2025-999"
Expected: Agent handles gracefully, asks for correct order number
Validates: Error handling, user experience
```

**Test 4: Multi-Turn**
```
Turn 1: "Check my order"
Turn 2: "It's order number 47"
Turn 3: "When will it arrive?"
Expected: Agent maintains context across turns
Validates: Conversation flow, context management
```

**Test 5: Escalation**
```
Input: "My home arrived damaged!"
Expected: Agent creates support ticket with appropriate priority
Validates: Ticket creation, escalation logic
```

### **Comprehensive Demo Evaluation** (Use for final scoring)

**Preparation:**
- [ ] Participant has agent ready to demo
- [ ] MCP connection is confirmed working
- [ ] 10-minute time limit explained
- [ ] Scoring rubric visible to participant

**Evaluation Sequence:**

**1. Basic Functionality (5 minutes)**
- Ask participant to demonstrate order lookup
- Ask participant to demonstrate product information
- Ask participant to demonstrate escalation
- **Score**: Basic Success criteria (0-30 points)

**2. Conversation Quality (3 minutes)**
- Have participant role-play multi-turn conversation
- Test error handling with invalid input
- Evaluate tone and professionalism
- **Score**: Good Success criteria (0-60 points)

**3. Advanced Features (2 minutes)**
- Ask about proactive assistance examples
- Ask about business knowledge incorporated
- Ask about process integration details
- **Score**: Excellent Success criteria (0-100 points)

**4. Q&A and Feedback**
- What was hardest part?
- What would you add with more time?
- Provide constructive feedback

---

## 📊 **Scoring Examples**

### **Example 1: Basic Success (30 points)**

**What They Built:**
- Agent looks up orders when given order number
- Agent returns product info from catalog
- Agent mentions "contact support" for complex issues

**Strengths:**
- ✅ Tools are integrated
- ✅ Basic functionality works

**Missing for Higher Score:**
- ❌ Tone is robotic and transactional
- ❌ No error handling
- ❌ No multi-turn conversation support
- ❌ Doesn't create actual tickets

**Feedback to Give:**
"Great job getting the core tools working! To reach 60 points, focus on making the conversation feel more natural and add error handling for cases like 'order not found'. Think about how a real customer service agent would respond."

---

### **Example 2: Good Success (60 points)**

**What They Built:**
- Everything from Basic Success
- Pleasant conversational tone
- Handles follow-up questions
- Graceful error messages
- Creates actual support tickets

**Strengths:**
- ✅ Professional user experience
- ✅ Reliable functionality
- ✅ Good error handling

**Missing for Higher Score:**
- ❌ Doesn't anticipate customer needs
- ❌ Limited business context knowledge
- ❌ Tickets lack detail and proper categorization

**Feedback to Give:**
"Excellent work! Your agent feels professional and reliable. To reach 100 points, think about being more proactive - after looking up an order, what else might the customer want to know? Also, show deeper understanding of Fabrikam's business by mentioning specific timelines, policies, or team members."

---

### **Example 3: Excellent Success (100 points)**

**What They Built:**
- Everything from Good Success
- Proactively offers next steps
- References specific business policies
- Creates detailed, well-categorized tickets
- Demonstrates empathy and business savvy

**Strengths:**
- ✅ Feels like talking to an expert human
- ✅ Anticipates needs before asked
- ✅ Shows deep business understanding
- ✅ Seamless escalation with complete context

**Feedback to Give:**
"Outstanding work! Your agent demonstrates both technical excellence and business understanding. The proactive assistance and attention to detail really set this apart. Consider: what analytics or reporting could make this even more valuable to the business?"

---

## ⚠️ **Common Proctor Pitfalls to Avoid**

### **Don't Do This:**
- ❌ **Debugging for them**: "Here, let me fix that code..."
- ❌ **Giving complete answers**: "Just copy this system prompt..."
- ❌ **Inconsistent scoring**: Different standards for different teams
- ❌ **Rushing evaluation**: Not testing all scenarios
- ❌ **Being discouraging**: "This won't work..."

### **Do This Instead:**
- ✅ **Ask guiding questions**: "What happens when the order isn't found?"
- ✅ **Point to resources**: "The example doc has a pattern you might find helpful..."
- ✅ **Use rubric consistently**: Same tests for everyone
- ✅ **Take time**: Thorough 10-minute demos
- ✅ **Be encouraging**: "You're on the right track, let's think about..."

---

## 🎯 **Time Management Guide**

**If Participant is Struggling After 30 Minutes:**
- Suggest focusing on just order lookup first
- Offer Level 1 hints to unblock
- Consider pair programming with another participant

**If Participant is Ahead After 60 Minutes:**
- Suggest bonus features: warranty lookup, installation scheduling
- Challenge them to add personality/character to agent
- Ask them to document their approach for others

**If Participant is Stuck on Same Issue for 15+ Minutes:**
- Escalate to Level 2 hints immediately
- Consider showing relevant part of example solution
- Pair with proctor for 5-minute troubleshooting session

---

## 📝 **Proctor Checklist**

**Before Workshop:**
- [ ] Test example solution in Copilot Studio
- [ ] Verify MCP connection URL works
- [ ] Print scoring rubric (3 copies)
- [ ] Prepare test scenarios on cards
- [ ] Review common mistakes section

**During Workshop:**
- [ ] Introduce challenge and timing
- [ ] Clarify questions about requirements
- [ ] Circulate to check progress every 20 minutes
- [ ] Provide hints when requested
- [ ] Keep track of time remaining

**During Demos:**
- [ ] Use consistent evaluation sequence
- [ ] Take notes on strengths/weaknesses
- [ ] Provide immediate verbal feedback
- [ ] Record final scores

**After Workshop:**
- [ ] Share example solution with all participants
- [ ] Collect feedback on challenge difficulty
- [ ] Document any issues for future iterations

---

## 🎓 **Facilitator Notes**

### **This Challenge Teaches:**
1. **MCP Integration**: How to connect external data sources to Copilot Studio
2. **Tool Usage**: When and how to invoke programmatic tools
3. **Conversation Design**: Creating natural, multi-turn dialogues
4. **Business Context**: Understanding domain knowledge matters
5. **Error Handling**: Building resilient agents
6. **Escalation**: Knowing when humans are needed

### **Success Indicators:**
- Participants demonstrate understanding of when to use tools vs conversation
- Solutions show empathy and business understanding, not just technical functionality
- Participants can explain trade-offs and design decisions
- Teams collaborate and help each other

### **Red Flags:**
- Participant is completely stuck on MCP connection after 45 minutes → Pair with proctor
- Participant is building overly complex solution → Redirect to basics
- Participant is copying example solution directly → Discuss learning objectives

---

**Remember**: The goal is learning, not perfection. A participant who scores 60 points but understands why has succeeded more than one who scores 100 by copying without understanding. Guide, encourage, and celebrate learning! 🎉
