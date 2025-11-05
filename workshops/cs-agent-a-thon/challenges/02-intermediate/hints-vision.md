# 💡 Hints: Vision Integration

**Smart hints without spoilers!** Use these progressively as you build your vision-enabled agent.

---

## 🎯 General Strategy Hints

<details>
<summary><strong>Hint 1: Start with Image Description, Then Analysis</strong></summary>

Don't try to build damage assessment AI immediately! Follow this progression:

1. **First**: Get agent to accept and describe images
   - "This is a photo of a wall with visible cracks"
   - Celebrate seeing! 👀

2. **Second**: Add basic categorization
   - Identify issue type (crack, water damage, defect)
   - Assess location (wall, ceiling, floor)

3. **Third**: Add severity assessment
   - Minor, Major, or Critical
   - Size/extent measurements

4. **Finally**: Polish and enhance
   - Safety recommendations
   - Cost estimates
   - Multi-image analysis

**Why**: Early success builds momentum and validates your vision integration works.

</details>

<details>
<summary><strong>Hint 2: Vision Models Can't Do Everything</strong></summary>

**What Vision Models Are Good At**:
- ✅ Identifying objects and structures (walls, ceilings, damage)
- ✅ Describing visual characteristics (size, color, location)
- ✅ Detecting patterns (cracks, stains, defects)
- ✅ Comparing before/after images

**What Vision Models Struggle With**:
- ❌ Precise measurements (can estimate, not measure)
- ❌ Hidden issues (mold inside walls, electrical problems)
- ❌ Material quality (without specialized training)
- ❌ Structural engineering assessments

**Strategy**: Use vision for initial triage, escalate for professional inspection.

</details>

<details>
<summary><strong>Hint 3: Combine Vision with Customer Context</strong></summary>

Images alone aren't enough! Combine with customer information:

**Vision Analysis**:
```
Image shows: 3-foot horizontal crack in drywall, located 2 feet below ceiling
Color: White wall with visible crack separation
Environment: Indoor residential setting
```

**Customer Context** (from conversation):
```
Customer: "This crack appeared last week after heavy rain"
Order: FAB-2025-038 (delivered 4 months ago)
Location: Kitchen
Previous Issues: None reported
```

**Combined Assessment**:
```
Issue: Structural crack in kitchen wall, likely water-related
Severity: MAJOR (horizontal crack > 1ft, possible foundation issue)
Root Cause Hypothesis: Water damage from roof leak during storm
Urgency: High (potential structural compromise)
Action: Immediate inspection required
```

**Why**: Vision + context = better diagnosis than either alone!

</details>

---

## 🔧 Technology-Specific Hints

### Copilot Studio + GPT-4 Vision

<details>
<summary><strong>Hint CS-1: Enable Vision in Copilot Studio</strong></summary>

**Setup Steps**:
1. In your Copilot Studio agent, go to **Settings** → **Generative AI**
2. Under **Model Selection**, choose a vision-capable model:
   - GPT-4 Vision (recommended)
   - GPT-4 Turbo with Vision
3. In your Topics, enable **Image Upload** in the user input node
4. Configure Generative Answers to process images

**System Prompt Addition**:
```
When customers upload images:
1. Analyze the image carefully
2. Describe what you see (damage type, location, severity)
3. Ask clarifying questions if needed
4. Provide appropriate guidance or create support tickets
```

**Why**: Copilot Studio makes vision integration straightforward!

</details>

<details>
<summary><strong>Hint CS-2: Prompt Engineering for Vision Analysis</strong></summary>

**Effective Vision Prompt Pattern**:
```
You are a Fabrikam technical support specialist analyzing customer-submitted photos.

When a customer uploads an image:

STEP 1 - DESCRIBE:
- What do you see? (wall, ceiling, floor, exterior)
- What type of damage or issue? (crack, stain, defect, installation problem)
- Where is it located in the image?
- How large/extensive does it appear?

STEP 2 - ASSESS SEVERITY:
- MINOR: Cosmetic issues, small cracks (<6"), surface stains
- MAJOR: Structural concerns, cracks >1ft, water damage, safety issues
- CRITICAL: Immediate safety hazards, active leaks, severe structural damage

STEP 3 - RECOMMEND:
- For MINOR: Schedule standard service appointment
- For MAJOR: Create priority support ticket, recommend inspection
- For CRITICAL: Create emergency ticket, provide immediate safety guidance

STEP 4 - CREATE TICKET:
Use create_support_ticket tool with:
- Subject: "[Image Analysis] {damage type} - {severity}"
- Description: Detailed analysis from image + customer comments
- Priority: Based on severity assessment
```

**Why**: Structured prompts yield consistent, actionable analysis.

</details>

<details>
<summary><strong>Hint CS-3: Handling Non-Damage Images</strong></summary>

Customers might upload irrelevant images. Handle gracefully:

```
Vision Analysis:
Image contains: A cat sitting on a couch

Agent Response:
"I can see you've uploaded a lovely photo! However, to help with your home 
issue, I'll need an image that shows the specific problem area you're 
concerned about. Could you please upload a photo of the damage or defect 
you mentioned?"
```

**Detection patterns**:
```
If image contains animals, people, unrelated objects:
  → Politely ask for relevant damage photo

If image is too blurry or dark:
  → "I'm having trouble seeing details clearly. Could you upload a clearer 
      photo with good lighting?"

If image shows multiple issues:
  → "I can see several areas of concern. Let's address them one at a time. 
      Which issue is most urgent?"
```

</details>

---

### Azure AI Vision / Computer Vision

<details>
<summary><strong>Hint AZ-1: Using Azure AI Vision API</strong></summary>

For more control, use Azure AI Vision directly:

**Setup**:
1. Create Azure AI Services resource (or use existing)
2. Get endpoint and API key
3. Use the **Image Analysis 4.0** API

**Basic Image Analysis**:
```http
POST https://<resource>.cognitiveservices.azure.com/computervision/imageanalysis:analyze?api-version=2023-10-01
Ocp-Apim-Subscription-Key: <your-key>
Content-Type: application/json

{
  "url": "https://example.com/damage-photo.jpg",
  "features": ["Caption", "Objects", "Tags", "Read"]
}
```

**Response Includes**:
```json
{
  "captionResult": {
    "text": "a crack in a white wall",
    "confidence": 0.87
  },
  "objectsResult": {
    "values": [
      { "tags": [{"name": "wall", "confidence": 0.94}] },
      { "tags": [{"name": "crack", "confidence": 0.82}] }
    ]
  },
  "tagsResult": {
    "values": [
      {"name": "indoor", "confidence": 0.99},
      {"name": "damage", "confidence": 0.76}
    ]
  }
}
```

**Use in your agent**:
```csharp
var analysis = await AnalyzeImageWithAzureVision(imageUrl);
var damageType = IdentifyDamageType(analysis.Tags);
var severity = AssessSeverity(analysis.Caption, damageType);
```

</details>

<details>
<summary><strong>Hint AZ-2: Custom Vision for Damage Classification</strong></summary>

For specialized damage detection, train a Custom Vision model:

**Setup**:
1. Create Custom Vision project (Classification or Object Detection)
2. Upload training images:
   - Cracks (50+ images)
   - Water damage (50+ images)
   - Structural defects (50+ images)
   - Normal/no damage (50+ images)
3. Tag and train model
4. Test and publish

**In your agent**:
```http
POST https://<project>.cognitiveservices.azure.com/customvision/v3.0/Prediction/<projectId>/classify/iterations/<iteration>
Prediction-Key: <your-key>
Content-Type: application/json

{
  "Url": "https://example.com/customer-photo.jpg"
}
```

**Response**:
```json
{
  "predictions": [
    {"tagName": "Water Damage", "probability": 0.92},
    {"tagName": "Cracks", "probability": 0.15},
    {"tagName": "Structural Defect", "probability": 0.08}
  ]
}
```

**Why**: Custom models can be more accurate for specific damage types.

</details>

---

### OpenAI Vision API / GPT-4V

<details>
<summary><strong>Hint OAI-1: Direct GPT-4 Vision API Calls</strong></summary>

Use OpenAI's Vision API for flexible image analysis:

**API Call**:
```http
POST https://api.openai.com/v1/chat/completions
Authorization: Bearer <your-api-key>
Content-Type: application/json

{
  "model": "gpt-4-vision-preview",
  "messages": [
    {
      "role": "system",
      "content": "You are a home damage assessment specialist. Analyze images and provide severity ratings."
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Analyze this damage photo. Identify the issue type, assess severity (Minor/Major/Critical), and recommend actions."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "https://example.com/damage.jpg"
          }
        }
      ]
    }
  ],
  "max_tokens": 500
}
```

**Response**:
```json
{
  "choices": [{
    "message": {
      "content": "This image shows a horizontal crack in drywall, approximately 3 feet long, located near the ceiling junction. \n\nSeverity: MAJOR\n- Horizontal cracks indicate potential structural issues\n- Length >1ft requires professional inspection\n- Located at ceiling junction suggests settling or foundation problem\n\nRecommended Actions:\n1. Schedule structural inspection within 7 days\n2. Monitor for crack expansion\n3. Check for similar cracks in adjacent rooms\n4. Estimated repair cost: $2,000-$4,000"
    }
  }]
}
```

</details>

<details>
<summary><strong>Hint OAI-2: Multi-Image Comparison</strong></summary>

GPT-4 Vision can analyze multiple images simultaneously:

**Use Case: Before/After Analysis**
```json
{
  "model": "gpt-4-vision-preview",
  "messages": [{
    "role": "user",
    "content": [
      {
        "type": "text",
        "text": "Compare these before and after photos. Has the damage worsened?"
      },
      {
        "type": "image_url",
        "image_url": { "url": "https://example.com/before.jpg" }
      },
      {
        "type": "image_url",
        "image_url": { "url": "https://example.com/after.jpg" }
      }
    ]
  }]
}
```

**Use Case: Multiple Angles**
```
Customer uploads 3 photos of the same crack from different angles

Agent: "Thank you for the multiple angles! I can see:
- Front view: 3ft horizontal crack, 1/4" separation
- Side view: Crack extends through drywall, visible depth
- Close-up: Clean edges suggest recent formation

This confirms a structural issue requiring immediate inspection."
```

</details>

---

## 📊 Damage Assessment Hints

<details>
<summary><strong>Hint DA-1: Severity Classification Guidelines</strong></summary>

Provide clear criteria for severity assessment:

**MINOR (Low Priority)**:
- Small cracks < 6 inches
- Hairline cracks (< 1/16")
- Minor cosmetic damage (small dents, scratches)
- Surface stains with no water source
- **Action**: Schedule standard service (7-14 days)

**MAJOR (High Priority)**:
- Cracks > 1 foot or multiple cracks
- Water stains with active moisture
- Door/window alignment issues
- Visible structural concerns
- **Action**: Priority inspection (2-3 days), create support ticket

**CRITICAL (Emergency)**:
- Horizontal cracks > 2 feet (foundation risk)
- Active water leaks or flooding
- Sagging ceilings/floors
- Electrical hazards visible
- Gas line concerns
- **Action**: Immediate response (<24 hours), safety instructions

**Implementation**:
```csharp
string AssessSeverity(string damageDescription, double? sizeEstimate)
{
    if (damageDescription.Contains("active leak") || 
        damageDescription.Contains("sagging") ||
        damageDescription.Contains("electrical"))
    {
        return "CRITICAL";
    }
    
    if (sizeEstimate > 12.0 || // > 1 foot
        damageDescription.Contains("horizontal crack") ||
        damageDescription.Contains("water damage"))
    {
        return "MAJOR";
    }
    
    return "MINOR";
}
```

</details>

<details>
<summary><strong>Hint DA-2: Safety Guidance for Critical Issues</strong></summary>

For critical issues, provide immediate safety instructions:

**Active Water Leak**:
```
Agent: "This is an active water leak which requires immediate attention!

IMMEDIATE ACTIONS:
1. Turn off water supply to affected area (look for shut-off valve)
2. Place buckets/towels to catch water
3. Move furniture and valuables away from affected area
4. Do NOT touch electrical outlets near water
5. Take photos of progression if safe to do so

I'm creating an EMERGENCY support ticket (TKT-###) for immediate dispatch.
A technician will contact you within 2 hours. Stay safe!"
```

**Structural Concern**:
```
Agent: "This crack pattern suggests possible structural movement.

SAFETY PRECAUTIONS:
1. Avoid placing heavy items near the affected wall
2. Monitor for changes (take daily photos)
3. Check for similar cracks in adjacent rooms
4. Look for doors/windows that won't close properly

I've created a HIGH-PRIORITY inspection ticket (TKT-###).
A structural specialist will contact you within 24 hours."
```

</details>

<details>
<summary><strong>Hint DA-3: Cost Estimation Guidelines</strong></summary>

Provide realistic cost ranges based on damage type:

**Estimation Table**:
```
Crack Repair:
- Minor hairline crack (<6"): $150-$300
- Wall crack (6"-12"): $300-$800
- Major structural crack (>12"): $2,000-$5,000+

Water Damage:
- Small ceiling stain: $500-$1,200
- Large water damage repair: $2,500-$8,000
- Complete ceiling replacement: $5,000-$15,000

General Defects:
- Door realignment: $200-$500
- Window seal replacement: $300-$700
- Drywall patch (small): $150-$400
```

**Agent Response**:
```
"Based on the image analysis showing a 2-foot horizontal crack, typical repair 
costs range from $2,000 to $4,000. This includes:
- Structural assessment ($500-$800)
- Crack repair and reinforcement ($1,200-$2,500)
- Drywall repair and repainting ($300-$700)

Final cost will depend on the structural engineer's findings. I recommend 
scheduling an inspection to get an accurate quote."
```

**Disclaimer**: Always include:
```
"This is an estimate based on visual analysis. Actual costs will be determined 
after professional inspection."
```

</details>

---

## 🔄 Workflow Integration Hints

<details>
<summary><strong>Hint WF-1: Image Upload → Analysis → Ticket Creation Flow</strong></summary>

**Complete Workflow**:
```
1. Customer uploads image
   ↓
2. Agent analyzes with vision model
   - Identify damage type
   - Assess severity
   - Extract details (size, location)
   ↓
3. Agent asks clarifying questions
   - "When did you first notice this?"
   - "Has it changed since it appeared?"
   - "Any recent events (storms, settling)?"
   ↓
4. Agent creates support ticket
   - Subject: "[Image Analysis] Water Damage - MAJOR"
   - Description: Vision analysis + customer context
   - Priority: Based on severity
   - Attachments: Reference to uploaded image
   ↓
5. Agent provides guidance
   - Safety instructions if needed
   - Timeline expectations
   - Cost estimate
   - Next steps
```

**Implementation**:
```csharp
[McpServerTool, Description("Analyze damage photo and create support ticket")]
public async Task<object> AnalyzeDamagePhoto(
    string imageUrl,
    int customerId,
    string? customerComments = null)
{
    // Step 1: Analyze image with vision
    var analysis = await AnalyzeWithVision(imageUrl, 
        "Analyze this home damage photo. Identify issue type, location, and severity.");
    
    // Step 2: Extract structured data
    var damageType = ExtractDamageType(analysis);
    var severity = ExtractSeverity(analysis);
    var location = ExtractLocation(analysis);
    
    // Step 3: Create support ticket
    var ticket = await CreateSupportTicket(new {
        customerId = customerId,
        subject = $"[Image Analysis] {damageType} - {severity}",
        description = $@"
            VISION ANALYSIS:
            {analysis}
            
            CUSTOMER COMMENTS:
            {customerComments ?? "None provided"}
            
            SEVERITY: {severity}
            LOCATION: {location}
            IMAGE: {imageUrl}
        ",
        priority = severity == "CRITICAL" ? "Critical" : 
                   severity == "MAJOR" ? "High" : "Normal",
        category = "ProductDefect"
    });
    
    // Step 4: Return comprehensive response
    return new {
        analysis = analysis,
        severity = severity,
        ticket = ticket.TicketNumber,
        estimatedCost = EstimateRepairCost(damageType, severity),
        safetyInstructions = GetSafetyInstructions(severity, damageType),
        timeline = GetResponseTimeline(severity)
    };
}
```

</details>

<details>
<summary><strong>Hint WF-2: Multi-Turn Vision Conversations</strong></summary>

Support follow-up questions about images:

```
Customer: [uploads crack photo]

Agent: "I can see a horizontal crack in your wall, approximately 3 feet long. 
This appears to be a MAJOR issue requiring inspection. Can you tell me when 
you first noticed this crack?"

Customer: "It appeared last week after the storm"

Agent: "Thank you. Storm-related cracks can indicate foundation movement or 
water intrusion. A few more questions:
1. Do you see similar cracks in other rooms?
2. Have you noticed any doors or windows sticking?
3. Is there any water damage near this crack?"

Customer: "Yes, the door to this room won't close properly now"

Agent: "That's an important detail - the door alignment issue confirms 
structural movement. I'm creating a HIGH-PRIORITY structural inspection 
ticket (TKT-###). Based on the crack size and door misalignment, estimated 
repair cost is $3,500-$6,000..."
```

**Implementation**: Store image analysis in conversation context:
```csharp
context.Add("image_analysis", analysis);
context.Add("damage_type", "horizontal_crack");
context.Add("severity", "MAJOR");

// On follow-up questions, reference context
var previousAnalysis = context["image_analysis"];
```

</details>

---

## 🧪 Testing Hints

<details>
<summary><strong>Hint T-1: Use Test Images with Known Issues</strong></summary>

Create or find test images for each damage type:

**Test Image Set**:
1. **Minor crack**: Hairline crack in wall (3-4 inches)
2. **Major crack**: Horizontal crack (2+ feet)
3. **Water damage**: Ceiling stain (brown discoloration)
4. **Critical**: Active water leak or severe structural damage
5. **Multiple issues**: Photo showing several problems
6. **Non-damage**: Irrelevant photo (to test graceful handling)

**Test Each Image**:
```
1. Upload image
2. Verify agent describes correctly ✅
3. Verify severity assessment matches expected ✅
4. Verify appropriate ticket priority ✅
5. Verify safety instructions provided if needed ✅
```

**Create synthetic test images**:
- Use AI image generation (DALL-E, Midjourney)
- Search for "home damage photos" (respect copyright)
- Take photos of intentional cosmetic "damage" (safe props)

</details>

<details>
<summary><strong>Hint T-2: Test Edge Cases</strong></summary>

**Edge Case 1: Blurry/Low-Quality Image**
```
Agent: "I'm having trouble seeing clear details in this image. For the best 
assessment, please upload a photo with:
- Good lighting (natural light or bright indoor lighting)
- Clear focus (tap to focus on phone cameras)
- Close enough to see damage details
- Multiple angles if possible"
```

**Edge Case 2: Multiple Damages in One Image**
```
Agent: "I can see multiple areas of concern in this photo:
1. Water stain on ceiling (upper right)
2. Wall crack (center)
3. Floor damage (bottom left)

Which issue is most urgent for you right now? Let's address them one at a time."
```

**Edge Case 3: No Visible Damage**
```
Agent: "I've analyzed the image but don't see obvious damage. Could you:
- Circle or point out the specific area you're concerned about
- Upload a closer photo of the problem area
- Describe what you're seeing that concerns you"
```

</details>

---

## 🚀 Quick Wins

<details>
<summary><strong>Quick Win 1: Add Vision to Existing Agent</strong></summary>

Enhance your beginner challenge agent with vision:

**Modification**:
```
Original agent prompt:
"You are a Fabrikam customer service agent..."

Enhanced with vision:
"You are a Fabrikam customer service agent with image analysis capabilities.

When customers upload photos of damage:
1. Analyze the image using your vision capabilities
2. Describe what you see (damage type, severity, location)
3. Ask clarifying questions
4. Create appropriate support tickets with image analysis

Use the create_support_ticket tool with:
- Subject: Include "[Image Analysis]" prefix
- Description: Include vision analysis + customer context
- Priority: Based on assessed severity"
```

**Test**:
```
Customer: "My wall is cracked" [uploads photo]
Agent: ✅ Analyzes image, describes crack, creates ticket
```

</details>

<details>
<summary><strong>Quick Win 2: Severity-Based Auto-Routing</strong></summary>

Automatically adjust response based on severity:

```csharp
var severity = AssessSeverity(visionAnalysis);

return severity switch
{
    "CRITICAL" => 
        $"EMERGENCY: {analysis}\n\n" +
        $"IMMEDIATE ACTIONS:\n{safetyInstructions}\n\n" +
        $"Emergency ticket created: {ticketNumber}\n" +
        $"Technician will contact you within 2 hours.",
    
    "MAJOR" =>
        $"URGENT: {analysis}\n\n" +
        $"Priority ticket created: {ticketNumber}\n" +
        $"Inspector will contact you within 24-48 hours.\n" +
        $"Estimated cost: {costEstimate}",
    
    "MINOR" =>
        $"{analysis}\n\n" +
        $"Service ticket created: {ticketNumber}\n" +
        $"We'll schedule a convenient appointment within 7-14 days.\n" +
        $"Estimated cost: {costEstimate}",
    
    _ => "Unable to assess severity. Please provide more details."
};
```

</details>

<details>
<summary><strong>Quick Win 3: Before/After Comparison Feature</strong></summary>

Let customers upload multiple images for comparison:

```
Agent: "I see you've mentioned the crack is getting worse. Do you have any 
earlier photos of this crack? I can compare them to see how much it's progressed."

Customer: [uploads original photo from 2 weeks ago]

Agent: "Comparing the images:

BEFORE (2 weeks ago):
- Crack length: ~1.5 feet
- Width: Hairline (<1/16")
- No visible separation

AFTER (today):
- Crack length: ~3 feet (doubled!)
- Width: 1/4" (significant widening)
- Visible wall separation

ASSESSMENT: This crack is actively expanding, indicating ongoing structural 
movement. This is now a MAJOR priority requiring immediate inspection. 
Creating high-priority ticket..."
```

</details>

---

## 🤔 Common Pitfalls

<details>
<summary><strong>Pitfall 1: Over-Promising Diagnosis Accuracy</strong></summary>

**Problem**: "Our AI has determined this is a foundation issue requiring $5,000 in repairs"

**Why it's bad**:
- Vision can't see inside walls
- Liability if diagnosis is wrong
- Customers may expect guaranteed pricing

**Solution**: Frame as "preliminary assessment":
```
"Based on visual analysis, this appears to be a structural crack that may 
indicate foundation movement. This is a preliminary assessment - accurate 
diagnosis requires professional inspection. Typical repairs for this type 
of issue range from $2,000-$5,000, but final cost depends on the inspector's 
findings."
```

**Always include**:
- "Appears to be" instead of "is"
- "May indicate" instead of "caused by"
- "Estimated cost" instead of "will cost"
- "Requires professional inspection" disclaimer

</details>

<details>
<summary><strong>Pitfall 2: Ignoring Customer Safety</strong></summary>

**Problem**: Agent analyzes active water leak, creates ticket, moves on

**Why it's bad**:
- Customer may not know immediate actions needed
- Safety hazards (water + electricity)
- Agent has responsibility to warn

**Solution**: ALWAYS provide safety guidance for critical issues
```
For water leaks:
"⚠️ SAFETY FIRST:
1. Turn off water supply if possible
2. Move valuables away from water
3. DO NOT touch electrical outlets near water
4. Place buckets/towels to contain water

Emergency ticket created - technician dispatched."
```

**Safety categories**:
- **Water + Electrical**: Immediate danger, shut off water/power
- **Structural**: Avoid area, don't place weight
- **Chemical/Mold**: Ventilate, avoid contact
- **Gas**: Evacuate, call emergency services

</details>

<details>
<summary><strong>Pitfall 3: Not Handling Image Upload Failures</strong></summary>

**Problem**: Customer tries to upload image, fails, agent doesn't acknowledge

**Solution**: Handle upload edge cases
```csharp
try
{
    var analysis = await AnalyzeImage(imageUrl);
    return analysis;
}
catch (ImageNotFoundException)
{
    return "I couldn't access that image. Please try uploading again or check your internet connection.";
}
catch (InvalidImageFormatException)
{
    return "This file format isn't supported. Please upload a .jpg, .png, or .webp image.";
}
catch (ImageTooLargeException)
{
    return "This image is too large. Please upload an image under 20MB.";
}
catch (VisionAPIException ex)
{
    _logger.LogError(ex, "Vision API error");
    return "I'm having trouble analyzing this image right now. Could you describe the issue in words while I work on the technical problem?";
}
```

**Fallback**: If vision fails, don't block customer - collect description verbally!

</details>

---

## 📚 Additional Resources

- **GPT-4 Vision Guide**: [OpenAI Vision Documentation](https://platform.openai.com/docs/guides/vision)
- **Azure AI Vision**: [Microsoft Documentation](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/)
- **Beginner Challenge**: Foundation agent to enhance with vision
- **Fabrikam MCP Tools**: Same tools work with vision-enhanced agent

---

**Remember**: Vision is powerful but not perfect. Use it for initial triage, always recommend professional inspection for important decisions! 👁️

**Need more help?** Check the [Partial Solution](./partial-solution-vision.md) for architecture guidance.

**Ready to peek?** See the [Full Solution](./full-solution-vision.md) for complete implementations.
