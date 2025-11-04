# 🚨 Full Solution: Vision Integration

**Complete Implementation Guide**

---

## ⚠️ Important Note

This full solution provides a comprehensive reference for adding vision capabilities to your customer service agent. We'll cover three implementation approaches with complete examples.

---

## 📋 Solution Overview

This solution demonstrates vision integration where:
- Agent accepts image uploads from customers
- Vision model analyzes damage photos
- Severity is assessed (Minor, Major, Critical)
- Support tickets are created with vision analysis
- Safety guidance is provided for critical issues
- Cost estimates are included

---

## 🎯 Approach 1: Copilot Studio + GPT-4 Vision

**This is the recommended approach for most users - no coding required!**

### **Setup Steps**

**Step 1: Enable Vision in Your Agent**

1. Go to your Fabrikam Customer Service agent in Copilot Studio
2. Navigate to **Settings** → **Generative AI**
3. Under **Model**, select a vision-capable model:
   - **GPT-4 Turbo with Vision** (recommended)
   - GPT-4 Vision Preview

4. Save settings

**Step 2: Update System Prompt with Vision Analysis Instructions**

Update your agent's system prompt to include vision capabilities:

```markdown
# ROLE
You are a Fabrikam customer service agent with image analysis capabilities.

# CORE RESPONSIBILITIES
- Help customers with product questions, orders, and support
- **Analyze photos of damage or issues when customers upload images**
- Create support tickets for issues
- Provide guidance and cost estimates

# VISION ANALYSIS PROTOCOL

When a customer uploads an image:

## STEP 1: ANALYZE THE IMAGE
Carefully examine the image and identify:
- **Subject**: What is shown (wall, ceiling, floor, exterior, etc.)
- **Issue Type**: Crack | Water Damage | Structural Defect | Installation Problem | Other
- **Location**: Where in the image and in the home
- **Characteristics**: Size (estimate in feet/inches), color, pattern, extent
- **Environment**: Indoor/outdoor, room type if visible

## STEP 2: ASSESS SEVERITY

Classify as MINOR, MAJOR, or CRITICAL:

### MINOR (Low Priority):
- Small cracks < 6 inches
- Hairline cracks (< 1/16")
- Minor cosmetic damage
- Surface stains with no active moisture
- Small dents or scratches

### MAJOR (High Priority):
- Cracks > 1 foot or multiple cracks
- Horizontal cracks (potential structural issue)
- Water stains with evidence of moisture
- Door/window alignment problems
- Visible structural concerns
- Damage affecting functionality

### CRITICAL (Emergency):
- Horizontal cracks > 2 feet (foundation risk)
- Active water leaks or flooding
- Sagging ceilings or floors
- Visible electrical hazards
- Severe structural damage
- Safety hazards

## STEP 3: ASK CLARIFYING QUESTIONS

After initial analysis, ask:
1. "When did you first notice this issue?"
2. "Has it changed in size or appearance since you first saw it?"
3. "Have you noticed any related issues (doors sticking, new cracks, etc.)?"
4. For water damage: "Do you know the source? Is it still active?"

## STEP 4: PROVIDE ASSESSMENT & GUIDANCE

**For CRITICAL issues:**
```
⚠️ IMMEDIATE SAFETY ALERT

I can see [describe issue]. This requires immediate attention.

IMMEDIATE ACTIONS:
1. [Specific safety action]
2. [Specific safety action]
3. DO NOT [dangerous action to avoid]

I'm creating an EMERGENCY priority ticket (TKT-###) for immediate dispatch.
A technician will contact you within 2 hours.

If [escalation condition], please call 911 immediately.
```

**For MAJOR issues:**
```
I can see [describe issue]. This is a MAJOR concern that requires professional inspection.

RECOMMENDED PRECAUTIONS:
• [Safety precaution]
• [Monitoring guidance]

NEXT STEPS:
I'm creating a HIGH-PRIORITY support ticket (TKT-###). Our structural 
specialist will contact you within 24-48 hours.

ESTIMATED REPAIR COST:
Based on similar issues, typical repair costs range from $X,XXX to $X,XXX.
Final cost will be determined after inspection.

[Additional guidance based on issue type]
```

**For MINOR issues:**
```
I can see [describe issue]. This appears to be a cosmetic/minor issue that 
can be addressed during a standard service appointment.

I'm creating a service ticket (TKT-###). We'll schedule a convenient 
appointment within 7-14 days.

ESTIMATED REPAIR COST: $XXX to $XXX

[Monitoring guidance if applicable]
```

## STEP 5: CREATE SUPPORT TICKET

Use create_support_ticket tool with:
- **Subject**: `"[Image Analysis] {DamageType} - {Severity}"`
- **Description**: Include:
  ```
  VISION ANALYSIS:
  [Your detailed analysis]
  
  CUSTOMER CONTEXT:
  [Customer's comments and answers to questions]
  
  SEVERITY: {MINOR/MAJOR/CRITICAL}
  LOCATION: {location description}
  ESTIMATED SIZE: {measurements}
  
  SAFETY CONSIDERATIONS:
  [Any safety concerns]
  
  IMAGE REFERENCE: [Note that image was analyzed]
  ```
- **Priority**: 
  - CRITICAL → "Critical"
  - MAJOR → "High"  
  - MINOR → "Normal"
- **Category**: "ProductDefect"

## COST ESTIMATION GUIDELINES

**Crack Repairs:**
- Hairline crack (<6"): $150-$300
- Wall crack (6"-12"): $300-$800
- Major structural crack (>12"): $2,000-$5,000+

**Water Damage:**
- Small ceiling stain: $500-$1,200
- Large water damage: $2,500-$8,000
- Complete ceiling replacement: $5,000-$15,000

**General Repairs:**
- Door realignment: $200-$500
- Window seal: $300-$700
- Drywall patch (small): $150-$400

ALWAYS INCLUDE DISCLAIMER:
"This is a preliminary estimate based on visual analysis. Actual costs will 
be determined after professional inspection."

## HANDLING UNCLEAR/POOR QUALITY IMAGES

If image is blurry, dark, or unclear:
```
I'm having trouble seeing clear details in this photo. For the best assessment, 
could you upload a new image with:

✅ Good lighting (natural light or bright indoor lights)
✅ Clear focus (tap the area on your phone to focus)
✅ Close enough to see details
✅ Multiple angles if possible

In the meantime, could you describe what you're seeing?
```

## HANDLING NON-DAMAGE IMAGES

If customer uploads irrelevant image:
```
Thank you for the image! However, to help with your home issue, I'll need a 
photo that shows the specific problem area. Could you upload a photo of 
[the damage/issue you mentioned]?
```

## MULTI-IMAGE COMPARISON

If customer uploads before/after or multiple angles:
```
Thank you for the multiple images! Let me compare them:

BEFORE [date/timeframe]:
- [Analysis of earlier image]

AFTER [date/current]:
- [Analysis of current image]

CHANGE ASSESSMENT:
[Describe progression, rate of change, updated severity if applicable]

[Proceed with appropriate severity response]
```

# TOOLS AVAILABLE
- get_orders(orderId): Look up order details
- get_products(): Get product catalog
- get_customers(customerId): Get customer information
- create_support_ticket(...): Create support tickets

# IMPORTANT: CUSTOMER NAME USAGE
ALWAYS use the customer name from ORDER DATA when creating tickets or addressing 
customers, NOT the logged-in user's name.
```

**Step 3: Enable Image Upload in Conversation**

The vision model automatically handles image inputs when customers upload them in the chat. No additional configuration needed - customers can simply attach images!

**Step 4: Test Your Vision-Enabled Agent**

```
User: "My wall has a crack" [uploads crack photo]

Expected Agent Response:
"I can see a horizontal crack in your wall, approximately 3 feet long, located 
near the ceiling junction. This appears to be a MAJOR issue requiring professional 
inspection.

To help me create the right support ticket, could you tell me:
1. When did you first notice this crack?
2. Has it changed in size since you first saw it?
3. Have you noticed any doors or windows in this room sticking?"

[After customer answers]

"Thank you for that information. Based on the crack length and horizontal 
orientation, this indicates potential structural movement. I'm creating a 
HIGH-PRIORITY inspection ticket.

I've created support ticket TKT-20251104-0055 for structural inspection. 
Our specialist will contact you within 24-48 hours.

ESTIMATED REPAIR COST: $2,500 - $4,500
This includes structural assessment, crack repair, and finishing.

RECOMMENDED: Monitor the crack daily and take photos if it expands."
```

---

## 🎯 Approach 2: Azure AI Vision Integration

**For users wanting structured vision analysis via API**

### **Setup**

**Step 1: Create Azure AI Services Resource**

```bash
# Azure CLI
az cognitiveservices account create \
  --name fabrikam-vision \
  --resource-group rg-fabrikam-dev \
  --kind ComputerVision \
  --sku S1 \
  --location eastus
```

**Step 2: Get Credentials**

```bash
# Get endpoint
az cognitiveservices account show \
  --name fabrikam-vision \
  --resource-group rg-fabrikam-dev \
  --query properties.endpoint

# Get key
az cognitiveservices account keys list \
  --name fabrikam-vision \
  --resource-group rg-fabrikam-dev \
  --query key1
```

**Step 3: Create MCP Tool for Vision Analysis**

Add to your Fabrikam MCP server:

```csharp
// FabrikamVisionTools.cs
using System.Net.Http.Headers;
using System.Text.Json;

[McpServerTool, Description("Analyze damage photos and create support tickets")]
public class FabrikamVisionTools
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FabrikamVisionTools> _logger;

    public FabrikamVisionTools(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<FabrikamVisionTools> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    [McpServerTool, Description("Analyze damage photo using Azure AI Vision")]
    public async Task<object> AnalyzeDamagePhoto(
        string imageUrl,
        int customerId,
        string? customerComments = null)
    {
        try
        {
            // Step 1: Analyze image with Azure AI Vision
            var visionAnalysis = await AnalyzeWithAzureVision(imageUrl);
            
            // Step 2: Extract structured data
            var damageType = ExtractDamageType(visionAnalysis);
            var severity = AssessSeverity(visionAnalysis, damageType);
            var sizeEstimate = ExtractSizeEstimate(visionAnalysis);
            
            // Step 3: Generate detailed description
            var detailedAnalysis = await GenerateDetailedAnalysis(
                visionAnalysis,
                damageType,
                severity,
                customerComments);
            
            // Step 4: Create support ticket
            var ticket = await CreateSupportTicket(new
            {
                customerId = customerId,
                subject = $"[Image Analysis] {damageType} - {severity}",
                description = FormatTicketDescription(
                    detailedAnalysis,
                    customerComments,
                    severity,
                    sizeEstimate,
                    imageUrl),
                priority = MapSeverityToPriority(severity),
                category = "ProductDefect"
            });
            
            // Step 5: Return comprehensive response
            return new
            {
                content = new object[]
                {
                    new
                    {
                        type = "text",
                        text = FormatCustomerResponse(
                            detailedAnalysis,
                            severity,
                            ticket.TicketNumber,
                            EstimateRepairCost(damageType, severity))
                    }
                },
                analysis = detailedAnalysis,
                severity = severity.ToString(),
                ticketNumber = ticket.TicketNumber,
                costEstimate = EstimateRepairCost(damageType, severity)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error analyzing damage photo");
            return new
            {
                error = new
                {
                    message = "I encountered an error analyzing the image. Could you describe the issue in words while I investigate the technical problem?"
                }
            };
        }
    }

    private async Task<AzureVisionResponse> AnalyzeWithAzureVision(string imageUrl)
    {
        var endpoint = _configuration["AzureVision:Endpoint"];
        var key = _configuration["AzureVision:Key"];
        
        var requestUrl = $"{endpoint}/computervision/imageanalysis:analyze?api-version=2023-10-01&features=caption,objects,tags,read";
        
        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("Ocp-Apim-Subscription-Key", key);
        request.Content = new StringContent(
            JsonSerializer.Serialize(new { url = imageUrl }),
            System.Text.Encoding.UTF8,
            "application/json");
        
        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<AzureVisionResponse>(json);
    }

    private string ExtractDamageType(AzureVisionResponse analysis)
    {
        var tags = analysis.TagsResult.Values.Select(t => t.Name.ToLower()).ToList();
        
        if (tags.Any(t => t.Contains("crack") || t.Contains("fracture")))
            return "Crack";
        
        if (tags.Any(t => t.Contains("water") || t.Contains("stain") || t.Contains("moisture")))
            return "Water Damage";
        
        if (tags.Any(t => t.Contains("structural") || t.Contains("damage")))
            return "Structural Defect";
        
        if (tags.Any(t => t.Contains("installation") || t.Contains("assembly")))
            return "Installation Issue";
        
        return "General Damage";
    }

    private DamageSeverity AssessSeverity(AzureVisionResponse analysis, string damageType)
    {
        var caption = analysis.CaptionResult.Text.ToLower();
        var tags = analysis.TagsResult.Values.Select(t => t.Name.ToLower()).ToList();
        
        // CRITICAL indicators
        if (caption.Contains("leak") || caption.Contains("flooding") ||
            caption.Contains("sagging") || caption.Contains("severe") ||
            tags.Any(t => t.Contains("water") && t.Contains("damage")))
        {
            return DamageSeverity.Critical;
        }
        
        // MAJOR indicators
        if (damageType == "Crack" && caption.Contains("large") ||
            caption.Contains("structural") ||
            caption.Contains("significant"))
        {
            return DamageSeverity.Major;
        }
        
        // Default to MINOR
        return DamageSeverity.Minor;
    }

    private string ExtractSizeEstimate(AzureVisionResponse analysis)
    {
        // Try to extract size from OCR text or caption
        var caption = analysis.CaptionResult.Text;
        
        // Look for measurements in text
        var sizeRegex = new Regex(@"(\d+)\s*(feet|foot|ft|inches|inch|in)", RegexOptions.IgnoreCase);
        var match = sizeRegex.Match(caption);
        
        if (match.Success)
        {
            return match.Value;
        }
        
        // Estimate based on description
        if (caption.Contains("large"))
            return "Estimated large area (>2 feet)";
        if (caption.Contains("small"))
            return "Estimated small area (<6 inches)";
        
        return "Size estimation requires manual measurement";
    }

    private string FormatTicketDescription(
        string analysis,
        string customerComments,
        DamageSeverity severity,
        string sizeEstimate,
        string imageUrl)
    {
        return $@"
VISION ANALYSIS:
{analysis}

CUSTOMER CONTEXT:
{customerComments ?? "No additional comments provided"}

SEVERITY: {severity}
ESTIMATED SIZE: {sizeEstimate}

IMAGE REFERENCE: {imageUrl}

RECOMMENDED ACTION:
{GetRecommendedAction(severity)}
";
    }

    private string GetRecommendedAction(DamageSeverity severity)
    {
        return severity switch
        {
            DamageSeverity.Critical => "EMERGENCY - Immediate dispatch required. Technician contact within 2 hours.",
            DamageSeverity.Major => "HIGH PRIORITY - Structural inspection within 24-48 hours required.",
            DamageSeverity.Minor => "STANDARD - Schedule service appointment within 7-14 days.",
            _ => "Assessment required"
        };
    }

    private string FormatCustomerResponse(
        string analysis,
        DamageSeverity severity,
        string ticketNumber,
        (decimal low, decimal high) costEstimate)
    {
        var severityResponse = severity switch
        {
            DamageSeverity.Critical => $@"⚠️ IMMEDIATE SAFETY ALERT

{analysis}

EMERGENCY SUPPORT:
I've created an EMERGENCY priority ticket ({ticketNumber}) for immediate dispatch. 
A technician will contact you within 2 hours.

{GetSafetyInstructions(analysis)}",
            
            DamageSeverity.Major => $@"{analysis}

This is a MAJOR concern requiring professional inspection.

NEXT STEPS:
I've created a HIGH-PRIORITY support ticket ({ticketNumber}). Our structural 
specialist will contact you within 24-48 hours.

ESTIMATED REPAIR COST:
Based on similar issues, typical repair costs range from ${costEstimate.low:N2} 
to ${costEstimate.high:N2}. Final cost will be determined after inspection.",
            
            _ => $@"{analysis}

I've created a service ticket ({ticketNumber}). We'll schedule a convenient 
appointment within 7-14 days.

ESTIMATED REPAIR COST: ${costEstimate.low:N2} to ${costEstimate.high:N2}"
        };
        
        return severityResponse;
    }

    private string GetSafetyInstructions(string analysis)
    {
        if (analysis.ToLower().Contains("water") || analysis.ToLower().Contains("leak"))
        {
            return @"IMMEDIATE ACTIONS:
1. Turn off water supply if possible
2. Place buckets/towels to catch water
3. Move valuables away from affected area
4. DO NOT touch electrical outlets near water
5. If situation worsens, evacuate and call 911";
        }
        
        if (analysis.ToLower().Contains("structural") || analysis.ToLower().Contains("crack"))
        {
            return @"SAFETY PRECAUTIONS:
1. Avoid placing heavy items near affected wall
2. Monitor for changes (take daily photos)
3. Check for similar cracks in adjacent rooms
4. Look for doors/windows that won't close properly";
        }
        
        return "Follow technician guidance when they contact you.";
    }

    private (decimal low, decimal high) EstimateRepairCost(string damageType, DamageSeverity severity)
    {
        return (damageType, severity) switch
        {
            ("Crack", DamageSeverity.Minor) => (150m, 300m),
            ("Crack", DamageSeverity.Major) => (300m, 800m),
            ("Crack", DamageSeverity.Critical) => (2000m, 5000m),
            ("Water Damage", DamageSeverity.Minor) => (500m, 1200m),
            ("Water Damage", DamageSeverity.Major) or ("Water Damage", DamageSeverity.Critical) => (2500m, 8000m),
            _ => (300m, 1000m)
        };
    }
}

public enum DamageSeverity
{
    Minor,
    Major,
    Critical
}

public class AzureVisionResponse
{
    public CaptionResult CaptionResult { get; set; }
    public TagsResult TagsResult { get; set; }
    public ObjectsResult ObjectsResult { get; set; }
}

public class CaptionResult
{
    public string Text { get; set; }
    public double Confidence { get; set; }
}

public class TagsResult
{
    public List<Tag> Values { get; set; }
}

public class Tag
{
    public string Name { get; set; }
    public double Confidence { get; set; }
}

public class ObjectsResult
{
    public List<DetectedObject> Values { get; set; }
}

public class DetectedObject
{
    public List<Tag> Tags { get; set; }
}
```

**Step 4: Update appsettings.json**

```json
{
  "AzureVision": {
    "Endpoint": "https://fabrikam-vision.cognitiveservices.azure.com/",
    "Key": "your-vision-api-key-here"
  }
}
```

**Step 5: Register in Program.cs**

```csharp
builder.Services.AddHttpClient<FabrikamVisionTools>();
```

---

## 🧪 Testing the Complete Solution

### **Test Scenarios**

**Test 1: Minor Crack**
```
User: [uploads photo of small hairline crack]

Expected:
✅ Analysis: Identifies as crack, assesses as MINOR
✅ Ticket created with Normal priority
✅ Cost estimate: $150-$300
✅ Timeline: 7-14 days
```

**Test 2: Major Structural Crack**
```
User: [uploads photo of 3-foot horizontal crack]

Expected:
✅ Analysis: Identifies as structural crack, assesses as MAJOR
✅ Ticket created with High priority
✅ Cost estimate: $2,500-$4,500
✅ Safety precautions provided
✅ Timeline: 24-48 hours
```

**Test 3: Active Water Leak (Critical)**
```
User: [uploads photo of ceiling with active water dripping]

Expected:
✅ Analysis: Identifies as active water leak, assesses as CRITICAL
✅ Ticket created with Emergency priority
✅ IMMEDIATE SAFETY ALERT displayed
✅ Safety instructions provided (turn off water, avoid electricity)
✅ Timeline: Within 2 hours
```

**Test 4: Unclear Image**
```
User: [uploads blurry photo]

Expected:
✅ Agent recognizes image quality issue
✅ Requests clearer photo with specific guidance
✅ Asks for verbal description while waiting
```

**Test 5: Before/After Comparison**
```
User: "It's getting worse" [uploads 2 photos - before and after]

Expected:
✅ Agent compares both images
✅ Identifies progression (size increase, severity change)
✅ Updates severity if needed
✅ Creates appropriate priority ticket
```

---

## 📊 Success Metrics Achieved

With this complete vision solution, you should achieve:

✅ **Basic** (30/100):
- Agent accepts and describes images
- Basic damage identification
- Creates tickets with image reference

✅ **Good** (60/100):
- Categorizes damage severity correctly
- Provides appropriate guidance based on severity
- Handles edge cases (unclear images, non-damage photos)
- Cost estimates included

✅ **Excellent** (100/100):
- Accurate severity assessment with clear criteria
- Safety instructions for critical issues
- Cost estimates with disclaimers
- Multi-image comparison capability
- Professional ticket descriptions

✅ **Bonus** (+20):
- Confidence scoring for analysis
- Learning from past assessments
- Interactive clarification for ambiguous damage
- Integration with customer history

---

## 🚀 Deployment & Next Steps

1. **Test with diverse images** - cracks, water damage, various severities
2. **Calibrate severity thresholds** - adjust based on real outcomes
3. **Monitor accuracy** - track how well assessments match inspector findings
4. **Gather feedback** - refine analysis prompts based on user experience
5. **Expand capabilities** - add more damage types, seasonal issues

---

**Congratulations!** You've built a vision-enabled customer service agent! 👁️✨

This solution enables:
- Faster damage assessment
- Better ticket prioritization
- Improved customer safety
- More accurate cost expectations
- Reduced back-and-forth communication

**Next**: Combine with multi-agent orchestration for a complete enterprise solution!
