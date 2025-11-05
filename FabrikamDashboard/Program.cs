using FabrikamDashboard.Components;
using FabrikamDashboard.Services;
using FabrikamDashboard.BackgroundServices;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Add SignalR for real-time updates
builder.Services.AddSignalR(options =>
{
    // Configure for Azure App Service
    options.EnableDetailedErrors = true;
    options.HandshakeTimeout = TimeSpan.FromSeconds(30);
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
});

// Determine authentication mode from configuration
var authMode = builder.Configuration.GetValue<string>("Authentication:Mode", "Disabled");
var dashboardGuid = builder.Configuration["Dashboard:ServiceGuid"] ?? "dashboard-00000000-0000-0000-0000-000000000001";

// Configure API client based on authentication mode
if (authMode.Equals("BearerToken", StringComparison.OrdinalIgnoreCase))
{
    // BearerToken mode: Use JWT authentication
    builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
    builder.Services.AddTransient<JwtAuthenticationHandler>();
    
    builder.Services.AddHttpClient<FabrikamApiClient>(client =>
    {
        var baseUrl = builder.Configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
        client.BaseAddress = new Uri(baseUrl);
        client.Timeout = TimeSpan.FromSeconds(30);
    })
    .AddHttpMessageHandler<JwtAuthenticationHandler>();
    
    Console.WriteLine($"Dashboard configured for BearerToken authentication mode");
}
else
{
    // Disabled mode: Use X-Tracking-Guid header
    builder.Services.AddHttpClient<FabrikamApiClient>(client =>
    {
        var baseUrl = builder.Configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
        client.BaseAddress = new Uri(baseUrl);
        client.Timeout = TimeSpan.FromSeconds(30);
        
        // Note: X-Tracking-Guid will be set per-request by FabrikamApiClient
        // to allow user-specific GUIDs from browser sessions
    });
    
    Console.WriteLine($"Dashboard configured for Disabled authentication mode");
}

// Configure HTTP clients for FabrikamSimulator
builder.Services.AddHttpClient<SimulatorClient>(client =>
{
    var baseUrl = builder.Configuration["FabrikamSimulator:BaseUrl"] ?? "https://localhost:5000";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Add background service for polling and broadcasting updates
builder.Services.AddHostedService<DataPollingService>();

// Configure forwarded headers for Azure App Service
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

// Add CORS for development (optional, useful for testing)
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
else
{
    app.UseDeveloperExceptionPage();
}

// Use forwarded headers for Azure App Service
app.UseForwardedHeaders();

// Don't use HTTPS redirection on Azure (it handles SSL termination)
// app.UseHttpsRedirection();
app.UseCors();
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Map SignalR hub endpoint
app.MapHub<DashboardHub>("/dashboardHub");

app.Run();
