# ⚠️ Partial Solution: Vision Integration

**Architecture & Patterns Without Full Code**

This guide provides architectural guidance and key patterns for integrating vision capabilities into your customer service agent. Use this when you want direction without seeing complete implementations.

---

## 🏗️ Architecture Overview

### **Vision-Enhanced Agent Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                   Customer Interface                         │
│         (Chat with Image Upload Capability)                  │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              CUSTOMER SERVICE AGENT                          │
│                   (Vision-Enabled)                           │
│                                                              │
│  Capabilities:                                               │
│  • Accept text + image inputs                                │
│  • Analyze images with vision model                          │
│  • Extract damage information                                │
│  • Assess severity                                           │
│  • Create detailed support tickets                           │
│  • Provide safety guidance                                   │
└───────┬──────────────────────────┬──────────────────────────┘
        │                          │
        ▼                          ▼
┌──────────────────┐     ┌──────────────────────┐
│  Vision Analysis │     │   MCP Tools          │
│                  │     │                      │
│ • GPT-4 Vision   │     │ • create_ticket      │
│ • Azure AI Vision│     │ • get_customers      │
│ • Custom Vision  │     │ • get_orders         │
└──────────────────┘     └──────────────────────┘
```

---

## 🎯 Vision Analysis Workflow

### **Standard Image Processing Flow**

```
1. Customer uploads image + optional description
   ↓
2. Agent receives image and text
   ↓
3. Vision model analyzes image
   - Describe what's visible
   - Identify damage type
   - Estimate size/extent
   - Assess location
   ↓
4. Agent extracts structured data
   - Damage type (crack, water damage, defect)
   - Location (wall, ceiling, floor)
   - Severity (Minor, Major, Critical)
   - Size estimate
   ↓
5. Agent asks clarifying questions
   - "When did you first notice this?"
   - "Has it changed over time?"
   - "Any recent events?"
   ↓
6. Agent assesses severity + provides guidance
   - Safety instructions (if critical)
   - Cost estimate
   - Timeline expectations
   ↓
7. Agent creates support ticket
   - Include vision analysis
   - Add customer context
   - Set appropriate priority
   ↓
8. Agent confirms with customer
   - Ticket number
   - Next steps
   - Timeline
```

---

## 🧠 Vision Analysis Prompt Patterns

### **Pattern 1: Structured Analysis Prompt** (Recommended)

```markdown
System Prompt for Vision Analysis:

You are analyzing a photo of potential home damage for Fabrikam modular homes customer support.

ANALYSIS FRAMEWORK:

1. DESCRIPTION:
   - What do you see in the image?
   - What is the primary subject?
   - What is the setting/environment?

2. DAMAGE IDENTIFICATION:
   - Type: Crack | Water Damage | Structural Defect | Installation Issue | Other
   - Location: Wall | Ceiling | Floor | Exterior | Roof | Other
   - Characteristics: Size, color, pattern, extent

3. SEVERITY ASSESSMENT:
   - MINOR: Cosmetic issues, small cracks (<6"), surface stains
   - MAJOR: Significant cracks (>1ft), water damage, structural concerns
   - CRITICAL: Safety hazards, active leaks, severe structural damage

4. MEASUREMENTS (Estimate):
   - Length: Approximate measurement
   - Width/Depth: If visible
   - Affected area: Square footage estimate

5. INDICATORS:
   - Age of damage (new vs old)
   - Activity (stable vs growing)
   - Secondary issues (related problems visible)

6. SAFETY CONSIDERATIONS:
   - Any immediate safety concerns?
   - Recommended immediate actions?

Provide analysis in structured format for ticket creation.
```

**Example Output**:
```
DESCRIPTION:
Image shows an interior wall with a horizontal crack running approximately 3 feet across, located about 2 feet below the ceiling junction.

DAMAGE IDENTIFICATION:
- Type: Structural crack
- Location: Interior wall, near ceiling
- Characteristics: Horizontal orientation, visible separation, clean edges suggesting recent formation

SEVERITY ASSESSMENT: MAJOR
- Crack length exceeds 1 foot (approximately 3 feet)
- Horizontal cracks may indicate structural movement
- Located at ceiling junction (stress point)

MEASUREMENTS:
- Length: ~3 feet (36 inches)
- Width: Approximately 1/4 inch separation
- Affected area: Single wall section

INDICATORS:
- Appears recent (clean edges, no aging)
- Potentially active (visible separation)
- No secondary water damage visible

SAFETY CONSIDERATIONS:
- Not an immediate safety hazard
- Requires professional structural inspection
- Monitor for expansion
```

### **Pattern 2: Comparison Analysis Prompt**

```markdown
For multi-image analysis (before/after):

You are comparing two images of the same damage over time.

IMAGE 1 (Earlier): [timestamp]
IMAGE 2 (Current): [timestamp]

COMPARISON ANALYSIS:

1. HAS IT CHANGED?
   - Size change: Longer/wider/stable?
   - Severity change: Worse/same/better?
   - New characteristics appeared?

2. RATE OF PROGRESSION:
   - Time between images: [duration]
   - Growth rate: Rapid/moderate/slow/stable
   - Urgency implication: Increasing/stable

3. UPDATED SEVERITY:
   - Original assessment: [MINOR/MAJOR/CRITICAL]
   - Current assessment: [MINOR/MAJOR/CRITICAL]
   - Change reason: [explanation]

4. RECOMMENDATIONS:
   - Based on progression
   - Timeline for inspection
   - Monitoring guidance

Provide comparative analysis highlighting changes and implications.
```

---

## 📊 Severity Assessment Logic

### **Severity Classification Algorithm**

```
INPUT: Vision analysis description, damage type, measurements

CRITICAL SEVERITY triggers:
├─ Keywords: "active leak", "flooding", "sagging", "collapse", "electrical"
├─ Safety: Any mention of immediate danger
├─ Size: Horizontal crack > 2 feet
├─ Activity: "Growing", "expanding", "worsening"
└─ Output: Priority = Emergency, Timeline < 24 hours

MAJOR SEVERITY triggers:
├─ Size: Crack > 1 foot, stain > 2 sq ft
├─ Type: Horizontal crack, structural concern, water damage with moisture
├─ Location: Ceiling, foundation, load-bearing areas
├─ Pattern: Multiple cracks, spreading issues
└─ Output: Priority = High, Timeline = 2-3 days

MINOR SEVERITY (default):
├─ Size: Crack < 6 inches, small stains
├─ Type: Cosmetic, surface-level
├─ Location: Non-structural areas
├─ Stable: No signs of progression
└─ Output: Priority = Normal, Timeline = 7-14 days

SPECIAL CASES:
├─ Ambiguous → Ask clarifying questions, err on side of caution (upgrade severity)
├─ Multiple issues → Assess each, use highest severity
├─ Customer safety concern → Upgrade to at least MAJOR
```

### **Implementation Pattern**

```csharp
public enum DamageSeverity
{
    Minor,
    Major,
    Critical
}

public DamageSeverity AssessSeverity(
    string visionAnalysis,
    string damageType,
    double? sizeEstimateInches = null,
    string? customerComments = null)
{
    var analysisLower = visionAnalysis.ToLower();
    
    // CRITICAL checks (highest priority)
    if (analysisLower.Contains("active leak") ||
        analysisLower.Contains("flooding") ||
        analysisLower.Contains("sagging") ||
        analysisLower.Contains("electrical") ||
        analysisLower.Contains("immediate danger"))
    {
        return DamageSeverity.Critical;
    }
    
    // Horizontal cracks are serious
    if (damageType == "Crack" && 
        analysisLower.Contains("horizontal") &&
        sizeEstimateInches > 24) // > 2 feet
    {
        return DamageSeverity.Critical;
    }
    
    // MAJOR checks
    if (sizeEstimateInches > 12 || // > 1 foot
        (damageType == "Water Damage" && analysisLower.Contains("moisture")) ||
        analysisLower.Contains("structural") ||
        analysisLower.Contains("foundation"))
    {
        return DamageSeverity.Major;
    }
    
    // Customer expressed urgent concern
    if (customerComments != null &&
        (customerComments.ToLower().Contains("urgent") ||
         customerComments.ToLower().Contains("getting worse")))
    {
        return DamageSeverity.Major;
    }
    
    // Default to MINOR for cosmetic/small issues
    return DamageSeverity.Minor;
}
```

---

## 💬 Conversation Flow Patterns

### **Pattern 1: Image with Customer Description**

```
Customer: "There's a crack in my wall" [uploads image]

Agent Workflow:
1. Receive image + text
2. Analyze image with vision
3. Correlate vision analysis with customer description
4. Ask follow-up questions
5. Provide assessment

Agent Response:
"I can see the crack you're describing. Based on the image, this appears to be 
a horizontal crack approximately 3 feet long, located near the ceiling junction. 
This is a MAJOR issue that requires professional inspection.

To help me create the right support ticket, could you tell me:
1. When did you first notice this crack?
2. Has it changed in size since you first saw it?
3. Have you noticed any doors or windows in this room sticking or misaligning?"
```

### **Pattern 2: Image Without Description**

```
Customer: [uploads image without text]

Agent Workflow:
1. Receive image
2. Analyze with vision
3. Describe what you see
4. Ask customer to confirm and provide context

Agent Response:
"Thank you for the image. I can see what appears to be a crack in an interior 
wall. To provide the best assistance, could you tell me more about this?

- Where in your home is this located (which room)?
- When did you first notice it?
- Is this what you wanted me to look at, or is there a specific area I should focus on?"
```

### **Pattern 3: Unclear or Low-Quality Image**

```
Customer: [uploads blurry image]

Agent Workflow:
1. Attempt vision analysis
2. If confidence low or details unclear
3. Request better image

Agent Response:
"I'm having trouble seeing clear details in this photo. For the best assessment, 
could you upload a new image with:

✅ Good lighting (natural light or bright indoor lights)
✅ Clear focus (tap the area on your phone to focus)
✅ Close enough to see details
✅ Multiple angles if possible

In the meantime, could you describe what you're seeing?"
```

### **Pattern 4: Multi-Image Comparison**

```
Customer: "The crack is getting worse" [uploads 2 images - before and after]

Agent Workflow:
1. Analyze both images
2. Identify which is earlier/later
3. Compare measurements and characteristics
4. Assess progression
5. Update severity if needed

Agent Response:
"Thank you for the before and after photos. I can see the progression:

BEFORE (2 weeks ago):
- Crack length: ~1.5 feet
- Width: Hairline (<1/16 inch)

AFTER (today):
- Crack length: ~3 feet (DOUBLED)
- Width: 1/4 inch (significant widening)

This active expansion indicates ongoing structural movement. I'm upgrading 
this to HIGH PRIORITY and creating an urgent inspection ticket..."
```

---

## 🎫 Support Ticket Creation with Vision

### **Ticket Structure for Vision-Analyzed Issues**

```json
{
  "subject": "[Image Analysis] {DamageType} - {Severity}",
  "description": "VISION ANALYSIS:\n{visionOutput}\n\nCUSTOMER CONTEXT:\n{customerComments}\n\nSEVERITY: {severity}\nLOCATION: {location}\nESTIMATED SIZE: {measurements}",
  "priority": "{severity-mapped-priority}",
  "category": "ProductDefect",
  "metadata": {
    "imageUrl": "{imageUrl}",
    "analysisConfidence": "{confidence}",
    "damageType": "{type}",
    "assessedSeverity": "{severity}"
  }
}
```

**Example**:
```
Subject: [Image Analysis] Structural Crack - MAJOR

Description:
VISION ANALYSIS:
Image shows an interior wall with a horizontal crack running approximately 
3 feet across, located about 2 feet below the ceiling junction. The crack 
shows visible separation of approximately 1/4 inch with clean edges suggesting 
recent formation. No secondary water damage visible. Assessed as MAJOR severity 
due to horizontal orientation and length exceeding 1 foot.

CUSTOMER CONTEXT:
Customer reports crack appeared last week after heavy rainstorm. Noticed door 
to this room is now sticking and won't close properly. Kitchen location.

SEVERITY: MAJOR
LOCATION: Kitchen interior wall, near ceiling junction
ESTIMATED SIZE: 3 feet long x 1/4 inch wide

RECOMMENDED ACTION:
Structural inspection within 48-72 hours. Door misalignment confirms potential 
foundation movement. Estimated repair cost: $2,500-$4,500.

IMAGE REFERENCE: [URL]

Priority: High
Category: ProductDefect
Requested By: Diego Siciliani (Customer ID: 17)
Order: FAB-2025-038
```

---

## 🛡️ Safety Guidance Patterns

### **Critical Issue Response Template**

```markdown
For CRITICAL severity issues:

⚠️ IMMEDIATE SAFETY ALERT

{Acknowledgment of issue}

IMMEDIATE ACTIONS REQUIRED:
1. {Specific action 1}
2. {Specific action 2}
3. {Specific action 3}
4. DO NOT {dangerous action}

{Additional safety context}

EMERGENCY SUPPORT:
I'm creating an EMERGENCY priority ticket ({ticketNumber}) for immediate 
dispatch. A technician will contact you within {timeline}.

If the situation worsens or you feel unsafe, please {escalation guidance}.
```

**Example - Active Water Leak**:
```
⚠️ IMMEDIATE SAFETY ALERT

I can see active water intrusion in your ceiling. This requires immediate action.

IMMEDIATE ACTIONS REQUIRED:
1. Turn off water supply if possible (look for main shut-off valve)
2. Place buckets/towels to catch dripping water
3. Move furniture and valuables away from affected area
4. DO NOT touch any electrical outlets or switches near the water
5. Turn off electricity to that room if you can safely access the breaker

Water and electricity are a dangerous combination. Safety is the priority.

EMERGENCY SUPPORT:
I'm creating an EMERGENCY priority ticket (TKT-20251104-0050) for immediate 
dispatch. A technician will contact you within 2 hours.

If water flow increases significantly or you see any sparking/electrical 
issues, evacuate the area and call 911 immediately.
```

### **Major Issue Response Template**

```markdown
For MAJOR severity issues:

{Professional acknowledgment}

ASSESSMENT:
{Vision analysis summary}
Severity: MAJOR
{Explanation of why it's major}

RECOMMENDED PRECAUTIONS:
• {Safety precaution 1}
• {Safety precaution 2}
• {Monitoring guidance}

NEXT STEPS:
I've created a HIGH-PRIORITY support ticket ({ticketNumber}) for professional 
inspection. Our structural specialist will contact you within {timeline}.

ESTIMATED REPAIR:
Based on similar cases, typical repair costs range from {low} to {high}. 
Final cost will be determined after inspection.

In the meantime, {monitoring or prevention guidance}.
```

---

## 💰 Cost Estimation Patterns

### **Cost Estimation Database**

```json
{
  "costEstimates": {
    "crack_minor": {
      "range": [150, 300],
      "description": "Hairline crack repair (<6 inches)",
      "includes": ["Crack sealing", "Touch-up paint"]
    },
    "crack_wall": {
      "range": [300, 800],
      "description": "Wall crack repair (6-12 inches)",
      "includes": ["Structural assessment", "Crack repair", "Drywall patch", "Painting"]
    },
    "crack_structural": {
      "range": [2000, 5000],
      "description": "Major structural crack (>12 inches)",
      "includes": ["Structural engineer assessment", "Foundation repair if needed", "Wall reconstruction", "Finishing"]
    },
    "water_damage_small": {
      "range": [500, 1200],
      "description": "Small ceiling water stain",
      "includes": ["Leak source identification", "Drywall replacement", "Painting"]
    },
    "water_damage_large": {
      "range": [2500, 8000],
      "description": "Extensive water damage",
      "includes": ["Leak repair", "Structural drying", "Mold remediation", "Drywall replacement", "Repainting"]
    }
  }
}
```

### **Cost Presentation Pattern**

```
Agent Response Format:

"Based on the image analysis showing {damage description}, typical repair 
costs range from ${low} to ${high}. This estimate includes:

• {Component 1}: ${est}
• {Component 2}: ${est}
• {Component 3}: ${est}

Final cost will depend on the structural engineer's findings and any hidden 
issues discovered during inspection. This is an estimate based on visual 
analysis only.

Our inspection team will provide a detailed quote after their assessment."
```

**Always include disclaimer**:
```
"This is a preliminary estimate based on visual analysis. Actual costs will 
be determined after professional inspection reveals the full extent of damage 
and required repairs."
```

---

## 🛠️ Implementation Approaches

### **Approach A: Copilot Studio + GPT-4 Vision** (Easiest)

**Setup**:
```
1. In Copilot Studio agent settings:
   - Go to Settings → Generative AI
   - Select vision-capable model (GPT-4 Vision)

2. In Topics/Generative Answers:
   - Enable image upload in user input nodes
   - System prompt includes vision analysis instructions
   
3. Agent automatically handles image + text inputs
```

**Pros**:
- No code required
- Built-in vision integration
- Works with existing agent structure

**Cons**:
- Limited control over vision prompts
- Can't easily switch vision models
- Cost per image analysis

### **Approach B: Azure AI Vision API** (More Control)

**Setup**:
```
1. Create Azure AI Services resource
2. Get endpoint and API key
3. Call Image Analysis API from your agent
```

**API Call Pattern**:
```http
POST https://{resource}.cognitiveservices.azure.com/computervision/imageanalysis:analyze?api-version=2023-10-01
Ocp-Apim-Subscription-Key: {key}
Content-Type: application/json

{
  "url": "{imageUrl}",
  "features": ["Caption", "Objects", "Tags", "Read"]
}
```

**Pros**:
- Purpose-built for image analysis
- Structured output (tags, objects, captions)
- Confidence scores
- Faster than LLM vision

**Cons**:
- Requires API integration code
- May need LLM for interpretation
- Separate service to manage

### **Approach C: Custom Vision Model** (Most Specialized)

**Setup**:
```
1. Create Custom Vision project
2. Upload training images (50+ per category)
3. Train damage classification model
4. Integrate trained model endpoint
```

**Use When**:
- Need high accuracy for specific damage types
- Have training data available
- Want specialized detection (e.g., crack detection)

**Pros**:
- Highest accuracy for trained categories
- Fast inference
- Domain-specific

**Cons**:
- Requires training data and effort
- Limited to trained categories
- Additional Azure service

---

## 📊 Decision Matrix: Which Approach?

| Requirement | Copilot + GPT-4V | Azure AI Vision | Custom Vision |
|-------------|------------------|-----------------|---------------|
| **No coding required** | ✅ Best | ⚠️ API integration | ⚠️ API integration |
| **Quick setup** | ✅ Best | ✅ Good | ❌ Requires training |
| **Flexibility** | ✅ Best | ⚠️ Structured only | ❌ Limited |
| **Cost efficiency** | ⚠️ Per call | ✅ Good | ✅ Best |
| **Accuracy (general)** | ✅ Excellent | ✅ Good | ⚠️ Training dependent |
| **Accuracy (specialized)** | ⚠️ Good | ⚠️ Good | ✅ Best |
| **Control over prompts** | ⚠️ Limited | ❌ No prompts | ❌ No prompts |

**Recommendation**:
- **Start with**: Copilot Studio + GPT-4 Vision (fastest path)
- **Upgrade to**: Azure AI Vision if you need structured output
- **Advanced**: Custom Vision if you have specific damage detection needs

---

## 🧪 Testing Strategy

### **Phase 1: Basic Vision Integration**

```
Test that vision works:

✅ Upload image → Agent acknowledges and describes
✅ Upload + text → Agent combines both inputs
✅ Upload unclear image → Agent requests clearer photo
✅ Upload non-damage image → Agent handles gracefully
```

### **Phase 2: Damage Analysis Accuracy**

```
Test damage identification:

✅ Crack photo → Correctly identifies as crack
✅ Water damage → Correctly identifies as water damage
✅ Multiple issues → Identifies all issues
✅ Normal/no damage → Doesn't hallucinate problems
```

### **Phase 3: Severity Assessment**

```
Test severity classification:

✅ Small crack (< 6") → MINOR
✅ Large crack (> 1 ft) → MAJOR
✅ Horizontal crack (> 2 ft) → CRITICAL (or MAJOR with upgrade)
✅ Active leak → CRITICAL
✅ Cosmetic issue → MINOR
```

### **Phase 4: End-to-End Workflow**

```
Complete scenarios:

✅ Upload damage photo → Analysis → Questions → Ticket created → Guidance provided
✅ Upload before/after → Comparison → Severity updated → Urgent ticket
✅ Upload critical issue → Safety instructions → Emergency ticket
✅ Upload unclear photo → Request better image → Re-analyze
```

---

## 🎯 Success Metrics

**Basic Success** (30 points):
- Agent accepts and describes images
- Basic damage identification
- Creates tickets with image reference

**Good Success** (60 points):
- Categorizes damage severity correctly
- Provides appropriate guidance
- Handles edge cases gracefully

**Excellent Success** (100 points):
- Accurate severity assessment
- Cost estimates provided
- Safety instructions for critical issues
- Multi-image comparison

---

## 🚀 Next Steps

Ready to implement:

1. **Choose approach** (Copilot + Vision, Azure AI, or Custom)
2. **Enable image upload** in your agent
3. **Add vision analysis prompts** to system message
4. **Test with sample images** (cracks, water damage)
5. **Enhance ticket creation** with vision insights
6. **Add safety guidance** for critical issues

**Need complete code?** See the [Full Solution](./full-solution-vision.md) for implementation details.

**Need clarification?** Review the [Hints](./hints-vision.md) for specific guidance.

---

**Remember**: Vision adds incredible value but isn't perfect. Use it for initial triage, always recommend professional inspection for important decisions! 👁️✨
