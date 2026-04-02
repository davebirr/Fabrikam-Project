using System.Diagnostics;
using Microsoft.Agents.A365.Observability.Runtime.Common;

namespace FabrikamMcp.Services;

/// <summary>
/// Service that wraps A365 Observability SDK to instrument MCP tool calls.
/// Uses BaggageBuilder for A365 context propagation and ActivitySource for OpenTelemetry tracing.
/// The A365 exporter picks up these traces when enabled.
/// </summary>
public class A365ObservabilityService
{
    private static readonly ActivitySource ActivitySource = new("FabrikamMcp.A365", "1.0.0");

    private readonly IConfiguration _configuration;
    private readonly ILogger<A365ObservabilityService> _logger;
    private readonly bool _enabled;
    private readonly string _agentId;
    private readonly string _agentName;
    private readonly string _tenantId;

    public A365ObservabilityService(
        IConfiguration configuration,
        ILogger<A365ObservabilityService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        _enabled = configuration.GetValue("Agent365:Enabled", false);
        _agentId = configuration.GetValue("Agent365:AgentId", "fabrikam-mcp-server") ?? "fabrikam-mcp-server";
        _agentName = configuration.GetValue("Agent365:AgentName", "Fabrikam MCP Server") ?? "Fabrikam MCP Server";
        _tenantId = configuration.GetValue("Agent365:TenantId", "") ?? "";

        if (_enabled)
        {
            _logger.LogInformation("A365 Observability enabled for agent {AgentId}", _agentId);
        }
        else
        {
            _logger.LogInformation("A365 Observability disabled. Set Agent365:Enabled=true to enable.");
        }
    }

    public bool IsEnabled => _enabled;

    /// <summary>
    /// Create a BaggageScope with tenant and agent context.
    /// Returns null if A365 observability is disabled.
    /// </summary>
    public IDisposable? CreateBaggageScope(string? sessionId = null)
    {
        if (!_enabled) return null;

        try
        {
            var builder = new BaggageBuilder()
                .AgentId(_agentId)
                .AgentName(_agentName);

            if (!string.IsNullOrEmpty(_tenantId))
            {
                builder.TenantId(_tenantId);
            }

            if (!string.IsNullOrEmpty(sessionId))
            {
                builder.SessionId(sessionId);
            }

            return builder.Build();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to create A365 baggage scope");
            return null;
        }
    }

    /// <summary>
    /// Start an Activity (OpenTelemetry span) for an MCP tool invocation.
    /// The A365 exporter picks these up via the OpenTelemetry pipeline.
    /// Returns null if A365 observability is disabled or no listener is attached.
    /// </summary>
    public Activity? StartToolInvocation(string toolName, string? userId = null)
    {
        if (!_enabled) return null;

        var activity = ActivitySource.StartActivity(
            $"invoke_agent.{toolName}",
            ActivityKind.Server);

        if (activity != null)
        {
            activity.SetTag("a365.agent.id", _agentId);
            activity.SetTag("a365.agent.name", _agentName);
            activity.SetTag("a365.tool.name", toolName);

            if (!string.IsNullOrEmpty(_tenantId))
                activity.SetTag("a365.tenant.id", _tenantId);

            if (!string.IsNullOrEmpty(userId))
                activity.SetTag("a365.caller.id", userId);

            _logger.LogDebug("A365: Started tool invocation trace for {ToolName}", toolName);
        }

        return activity;
    }

    /// <summary>
    /// Start an Activity for an API call made by an MCP tool.
    /// Returns null if A365 observability is disabled.
    /// </summary>
    public Activity? StartToolExecution(string toolName, string? targetUrl = null)
    {
        if (!_enabled) return null;

        var activity = ActivitySource.StartActivity(
            $"execute_tool.{toolName}",
            ActivityKind.Client);

        if (activity != null)
        {
            activity.SetTag("a365.tool.name", toolName);
            activity.SetTag("a365.tool.type", "mcp");

            if (!string.IsNullOrEmpty(targetUrl))
                activity.SetTag("a365.tool.endpoint", targetUrl);

            _logger.LogDebug("A365: Started tool execution trace for {ToolName}", toolName);
        }

        return activity;
    }
}
