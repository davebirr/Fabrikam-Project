using FabrikamMcp.Tools;
using FabrikamMcp.Models;
using FabrikamMcp.Models.Authentication; // Add MCP-specific authentication settings
using FabrikamMcp.Services;
using FabrikamContracts.DTOs; // Import consolidated authentication models
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using ModelContextProtocol;
using ModelContextProtocol.Server;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add HttpClient for API calls
builder.Services.AddHttpClient();

// Add HTTP context accessor for authentication
builder.Services.AddHttpContextAccessor();

// Add memory cache for GUID validation caching
builder.Services.AddMemoryCache();

// Add distributed cache for MCP protocol negotiation state
// MCP business logic is stateless, but protocol negotiation (capabilities, tool schemas)
// requires minimal session tracking for Copilot Studio compatibility
// Using in-memory for single-instance, should use Redis for multi-instance production
builder.Services.AddDistributedMemoryCache();

// Add Data Protection for secure session cookies
builder.Services.AddDataProtection();

// Configure minimal session for MCP protocol negotiation only
// NOT for business state - business logic remains stateless
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(10); // Short timeout for protocol negotiation
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true; // Required for MCP capabilities negotiation
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    options.Cookie.Name = ".Fabrikam.McpProtocol"; // Explicit name for MCP protocol session
});

// Configure authentication settings
var contractAuthSettings = builder.Configuration.GetSection(AuthenticationSettings.SectionName).Get<AuthenticationSettings>() ?? new AuthenticationSettings();
builder.Services.Configure<AuthenticationSettings>(builder.Configuration.GetSection(AuthenticationSettings.SectionName));

// Configure MCP-specific authentication settings
var mcpAuthSettings = builder.Configuration.GetSection(McpAuthenticationSettings.SectionName).Get<McpAuthenticationSettings>();
if (mcpAuthSettings == null)
{
    // Fallback: create from contract settings if new section doesn't exist yet
    mcpAuthSettings = new McpAuthenticationSettings
    {
        Mode = contractAuthSettings.Mode,
        ServiceJwt = contractAuthSettings.ServiceJwt,
        GuidValidation = contractAuthSettings.GuidValidation
    };
    Console.WriteLine($"Using fallback MCP authentication settings with mode: {mcpAuthSettings.Mode}");
}
else
{
    Console.WriteLine($"Using dedicated MCP authentication settings with mode: {mcpAuthSettings.Mode}");
}
builder.Services.AddSingleton(mcpAuthSettings);

// Add Entity Framework with in-memory database (for development)
builder.Services.AddDbContext<FabrikamDbContext>(options =>
    options.UseInMemoryDatabase("FabrikamMcpDb"));

// Register our services
builder.Services.AddScoped<IUserRegistrationService, UserRegistrationService>();
builder.Services.AddScoped<IServiceJwtService, ServiceJwtService>();

// Add controllers for user registration endpoints
builder.Services.AddControllers();

var jwtSettings = mcpAuthSettings.Jwt;

if (mcpAuthSettings.Mode == AuthenticationMode.BearerToken && !string.IsNullOrEmpty(jwtSettings.SecretKey))
{
    builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.SaveToken = true;
        options.RequireHttpsMetadata = jwtSettings.RequireHttpsMetadata;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = jwtSettings.ValidateIssuer,
            ValidateAudience = jwtSettings.ValidateAudience,
            ValidateLifetime = jwtSettings.ValidateLifetime,
            ValidateIssuerSigningKey = jwtSettings.ValidateIssuerSigningKey,
            ValidIssuer = jwtSettings.Issuer,
            ValidAudience = jwtSettings.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),
            ClockSkew = TimeSpan.FromMinutes(jwtSettings.ClockSkewInMinutes)
        };

        // Configure JWT events for better error handling
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogWarning("MCP JWT Authentication failed: {Exception}", context.Exception.Message);
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogDebug("MCP JWT token validated for user: {User}", context.Principal?.Identity?.Name);
                return Task.CompletedTask;
            }
        };
    });

    // Add authorization services
    builder.Services.AddAuthorization();
    
    // Add authentication service based on mode
    switch (mcpAuthSettings.Mode)
    {
        case AuthenticationMode.BearerToken:
            builder.Services.AddScoped<IAuthenticationService, AuthenticationService>();
            break;
        case AuthenticationMode.Disabled:
            builder.Services.AddScoped<IAuthenticationService, DisabledAuthenticationService>();
            break;
        case AuthenticationMode.EntraExternalId:
            // TODO: Add Entra External ID authentication service when implemented
            builder.Services.AddScoped<IAuthenticationService, AuthenticationService>();
            break;
        default:
            throw new InvalidOperationException($"Unsupported authentication mode: {mcpAuthSettings.Mode}");
    }
}
else
{
    // Add a dummy authentication service when authentication is disabled or not configured
    builder.Services.AddScoped<IAuthenticationService, DisabledAuthenticationService>();
}

// Configure authentication settings
builder.Services.Configure<AuthenticationSettings>(builder.Configuration.GetSection(AuthenticationSettings.SectionName));
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));

// Add MCP server services with HTTP transport and Fabrikam business tools
// Note: MCP SDK 0.4.0-preview.3 requires session management - we handle this via DataProtection
// which provides distributed session storage across multiple instances
builder.Services.AddMcpServer()
    .WithHttpTransport()
    .WithTools<FabrikamSalesTools>()
    .WithTools<FabrikamInventoryTools>()
    .WithTools<FabrikamCustomerServiceTools>()
    .WithTools<FabrikamProductTools>()
    .WithTools<FabrikamBusinessIntelligenceTools>();

// Add CORS for HTTP transport support in browsers
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

// Enable CORS
app.UseCors();

// Enable session for MCP protocol negotiation (capabilities, tool schemas)
// This is NOT for business state - business logic remains stateless
// Copilot Studio expects minimal session for protocol handshake continuity
app.UseSession();

// Add authentication and authorization middleware
if (mcpAuthSettings.RequireUserAuthentication && !string.IsNullOrEmpty(jwtSettings.SecretKey))
{
    app.UseAuthentication();
    app.UseAuthorization();
}

// Map controllers for user registration endpoints
app.MapControllers();

// Map MCP endpoints to the standard /mcp path with conditional authentication
if (mcpAuthSettings.Mode == AuthenticationMode.BearerToken && mcpAuthSettings.RequireUserAuthentication)
{
    // BearerToken mode: Require JWT authentication for MCP endpoint
    app.MapMcp("/mcp").RequireAuthorization();
}
else
{
    // Disabled mode or no authentication: Allow anonymous access to MCP endpoint
    app.MapMcp("/mcp");
}

// Add status and info endpoints (always anonymous for discovery)
app.MapGet("/status", (IConfiguration configuration, McpAuthenticationSettings mcpSettings) =>
{
    // Use the dedicated MCP authentication settings
    var authConfig = mcpSettings;
    
    // Determine if MCP endpoint actually requires authentication
    bool mcpRequiresAuth = authConfig.Mode == AuthenticationMode.BearerToken && authConfig.RequireUserAuthentication;
    
    return new
    {
        Status = "Ready",
        Service = "Fabrikam MCP Server",
        Version = "1.1.0",
        Description = "Model Context Protocol server for Fabrikam Modular Homes business operations",
        Transport = "HTTP",
        Authentication = new
        {
            Mode = authConfig.Mode.ToString(),
            Required = mcpRequiresAuth,
            Method = mcpRequiresAuth ? "JWT Bearer Token" : authConfig.Mode == AuthenticationMode.Disabled ? "User GUID Required" : "None",
            Issuer = authConfig.Jwt.Issuer,
            Audience = authConfig.Jwt.Audience
        },
        BusinessModules = new[]
        {
            "Sales - Order management and customer analytics",
            "Inventory - Product catalog and stock monitoring", 
            "Customer Service - Support ticket management and resolution",
            "Products - Product catalog, inventory analytics and management",
            "Business Intelligence - Executive dashboards and performance alerts"
        },
        Timestamp = DateTime.UtcNow,
        Environment = app.Environment.EnvironmentName
    };
}).AllowAnonymous();

// Redirect root path to status for convenience (always anonymous)
app.MapGet("/", () => Results.Redirect("/status")).AllowAnonymous();

app.Run();
