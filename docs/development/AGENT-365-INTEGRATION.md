# Microsoft Agent 365 (A365) Integration

## Overview

**Microsoft Agent 365** is Microsoft's **control plane for AI agents** — a unified platform to **observe, govern, and secure** every agent across an organization. GA: **May 1, 2026**.

This branch (`feature/a365-integration`) integrates Fabrikam's MCP server with Agent 365 to:
- Give the FabrikamMcp server an **Entra Agent ID** (agent-specific identity)
- Add **A365 Observability SDK** instrumentation for enterprise-grade telemetry
- Enable monitoring in **Microsoft Defender** and **Microsoft Purview**
- Introduce **intentional risky behaviors** for A365 security testing and CoE learning
- Deploy to a separate tenant for M365 Center of Excellence experimentation

---

## What Agent 365 Does

| Capability | Description | Microsoft Product |
|---|---|---|
| **Agent Registry** | Centralized inventory of all agents (Microsoft + third-party) | M365 Admin Center |
| **Observability** | Monitor agent sessions, tool calls, inference events in real time | M365 Admin Center + Defender |
| **Identity** | Unique Entra-backed identities for agents (like user identities) | Microsoft Entra Agent ID |
| **Access Control** | Conditional Access, least-privilege, lifecycle governance for agents | Microsoft Entra |
| **Threat Protection** | Detect anomalies, misuse, risky agent behaviors | Microsoft Defender |
| **Data Governance** | Protect data agents create and use, prevent oversharing | Microsoft Purview |
| **Tooling (MCP)** | Governed MCP servers for M365 workloads (Mail, Calendar, Teams, SharePoint) | Agent 365 Tooling |

---

## A365 SDK for .NET

The Fabrikam MCP server uses the **.NET Agent 365 SDK** packages:

### Core Packages

```xml
<!-- Observability - required for A365 integration -->
<PackageReference Include="Microsoft.Agents.A365.Observability" Version="0.1.*-beta.*" />
<PackageReference Include="Microsoft.Agents.A365.Observability.Runtime" Version="0.1.*-beta.*" />

<!-- Runtime - agent execution and lifecycle -->
<PackageReference Include="Microsoft.Agents.A365.Runtime" Version="0.1.*-beta.*" />
```

### Extension Packages (add as needed)

```xml
<!-- If using Semantic Kernel -->
<PackageReference Include="Microsoft.Agents.A365.Observability.Extensions.SemanticKernel" Version="0.1.*-beta.*" />

<!-- If using OpenAI directly -->
<PackageReference Include="Microsoft.Agents.A365.Observability.Extensions.OpenAI" Version="0.1.*-beta.*" />

<!-- Notifications (Teams, Outlook, Word) -->
<PackageReference Include="Microsoft.Agents.A365.Notifications" Version="0.1.*-beta.*" />

<!-- Governed MCP tooling (Mail, Calendar, SharePoint) -->
<PackageReference Include="Microsoft.Agents.A365.Tooling" Version="0.1.*-beta.*" />
```

NuGet: All packages start with `Microsoft.Agents.A365` — [Browse on NuGet](https://www.nuget.org/packages?q=Microsoft.Agents.A365)

---

## Observability Integration

### Three Instrumentation Scopes

The A365 Observability SDK provides three scopes that map directly to Fabrikam MCP operations:

| Scope | Purpose | Fabrikam Use |
|---|---|---|
| `InvokeAgentScope` | Captures the overall agent invocation | Top of each MCP tool call |
| `ExecuteToolScope` | Tracks individual tool execution | Each API call to FabrikamApi |
| `InferenceScope` | Records AI model interactions | Any LLM calls (future) |

### Baggage Attributes

```csharp
using var baggageScope = new BaggageBuilder()
    .TenantId("your-tenant-id")
    .AgentId("fabrikam-mcp-agent-id")
    .CorrelationId(correlationId)
    .Build();
// All spans in this context inherit these attributes
```

### Local Validation

Set `EnableAgent365Exporter` to `false` in `appsettings.json` to export spans to console for local testing:

```json
{
  "Agent365": {
    "EnableAgent365Exporter": false
  }
}
```

Then check console output for `InvokeAgentScope`, `ExecuteToolScope`, and `InferenceScope` spans.

### Production Validation

Once deployed with exporter enabled:
1. Go to: `https://admin.cloud.microsoft/#/agents/all`
2. Select your agent → **Activity**
3. Verify sessions and tool calls appear

---

## Deployment Strategy

### Branch: `feature/a365-integration`

This branch deploys to a **separate tenant** for CoE experimentation:

1. **Deploy to Azure** using the standard "Deploy to Azure" button in [DEPLOY-TO-AZURE.md](DEPLOY-TO-AZURE.md)
2. Azure auto-creates CI/CD workflow YAML files
3. Fix the workflow YAML for monorepo structure (path filters, project flags)
4. Workflow triggers on push to `feature/a365-integration`

### Parameters

- `deployment/parameters.a365.json` — A365-specific deployment parameters
- Authentication mode will evolve from `Disabled` → `EntraExternalId` → Agent ID

---

## Risky Behavior Scenarios (for A365 Testing)

Intentional scenarios to validate Agent 365 detection capabilities:

| Scenario | What It Tests | A365 Signal |
|---|---|---|
| Data exfiltration via tool | Tool reads sensitive data and returns it to unauthorized context | Defender anomaly detection |
| Excessive permission requests | Agent requests access beyond its scope | Entra access control alerts |
| Rapid-fire API calls | Agent makes abnormal volume of requests | Observability rate anomalies |
| PII in tool responses | Tool returns personally identifiable information | Purview data governance |
| Shadow agent behavior | Unregistered agent attempts operations | Registry detection |

---

## Key Resources

### Official Documentation

- [Agent 365 Overview](https://learn.microsoft.com/microsoft-agent-365/overview)
- [Agent 365 Developer Docs](https://learn.microsoft.com/microsoft-agent-365/developer/)
- [Agent 365 SDK Overview (.NET)](https://learn.microsoft.com/dotnet/api/agent365-sdk-dotnet/agent365-overview?view=agent365-sdk-dotnet-latest)
- [Agent 365 Development Lifecycle](https://learn.microsoft.com/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Observability SDK Guide](https://learn.microsoft.com/microsoft-agent-365/developer/observability)
- [Agent Identity (Entra Agent ID)](https://learn.microsoft.com/microsoft-agent-365/developer/identity)
- [Notifications SDK](https://learn.microsoft.com/microsoft-agent-365/developer/notification)
- [Tooling SDK (MCP Servers)](https://learn.microsoft.com/microsoft-agent-365/developer/tooling)
- [Mock Tooling Servers (local dev)](https://learn.microsoft.com/microsoft-agent-365/developer/mock-tooling-server)
- [Testing Agents Locally](https://learn.microsoft.com/microsoft-agent-365/developer/testing)
- [Test with Dev Tunnels](https://learn.microsoft.com/microsoft-agent-365/developer/test-with-devtunnels)

### Source Code & Samples

- **Samples Repo**: [microsoft/Agent365-Samples](https://github.com/microsoft/Agent365-Samples) — Production-ready examples in C#/.NET, Python, Node.js
  - [.NET Semantic Kernel sample](https://github.com/microsoft/Agent365-Samples/tree/main/dotnet/semantic-kernel)
  - [.NET Agent Framework sample](https://github.com/microsoft/Agent365-Samples/tree/main/dotnet/agent-framework)
  - [Design docs](https://github.com/microsoft/Agent365-Samples/tree/main/dotnet/docs)
- **SDK Source Repos**:
  - [Agent365-dotnet](https://github.com/microsoft/Agent365-dotnet) — .NET SDK source
  - [Agent365-python](https://github.com/microsoft/Agent365-python) — Python SDK source
  - [Agent365-nodejs](https://github.com/microsoft/Agent365-nodejs) — Node.js SDK source

### Admin & Security

- [Agent 365 Security](https://learn.microsoft.com/security/security-for-ai/agent-365-security)
- [Agent Registry Convergence](https://learn.microsoft.com/entra/agent-id/identity-platform/agent-registry-convergence)
- [Agent Overview in M365 Admin Center](https://learn.microsoft.com/microsoft-365/admin/manage/agent-365-overview)
- [Governance & Security Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/ai-agents/governance-security-across-organization)
- [Responsible AI FAQ](https://learn.microsoft.com/microsoft-agent-365/admin/responsible-ai-faq)
- [Work IQ MCP Overview](https://learn.microsoft.com/microsoft-agent-365/tooling-servers-overview)

### Prerequisites

- **Frontier Preview Program**: [Join here](https://adoption.microsoft.com/copilot/frontier-program/) (required for pre-GA access; likely already enrolled as MSFT)
- **M365 E7 or Agent 365 license** in the target tenant
- **Azure subscription** in the target tenant for hosting
- **Entra ID** configured for Agent ID registration

---

## Integration Roadmap

### Phase 1: Observability (Current) ✅
- [x] Create `feature/a365-integration` branch
- [x] Add A365 Observability NuGet packages
- [x] Add observability configuration to `appsettings.json`
- [ ] Instrument MCP tools with `InvokeAgentScope` / `ExecuteToolScope`
- [ ] Deploy to A365 tenant
- [ ] Validate telemetry in M365 Admin Center

### Phase 2: Agent Identity
- [ ] Register FabrikamMcp as Entra Agent ID
- [ ] Configure agent authentication flow
- [ ] Switch from `Disabled` auth to Agent ID

### Phase 3: Governed Tooling
- [ ] Expose MCP tools via A365 governed MCP servers
- [ ] Add Work IQ MCP tooling (Mail, Calendar, Teams)
- [ ] Test admin controls in M365 Admin Center

### Phase 4: Security Testing
- [ ] Implement risky behavior scenarios
- [ ] Validate Defender detection
- [ ] Validate Purview data governance alerts
- [ ] Document findings for CoE

### Phase 5: Notifications
- [ ] Add Teams/Outlook notification integration
- [ ] Enable @mention invocation in M365 apps
