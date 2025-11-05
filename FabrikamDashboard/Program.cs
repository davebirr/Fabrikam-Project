using FabrikamDashboard.Components;
using FabrikamDashboard.Services;
using FabrikamDashboard.BackgroundServices;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Add SignalR for real-time updates
builder.Services.AddSignalR();

// Add JWT token service for API authentication
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
builder.Services.AddTransient<JwtAuthenticationHandler>();

// Configure HTTP clients for FabrikamApi with JWT authentication
builder.Services.AddHttpClient<FabrikamApiClient>(client =>
{
    var baseUrl = builder.Configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
})
.AddHttpMessageHandler<JwtAuthenticationHandler>();

// Configure HTTP clients for FabrikamSimulator
builder.Services.AddHttpClient<SimulatorClient>(client =>
{
    var baseUrl = builder.Configuration["FabrikamSimulator:BaseUrl"] ?? "https://localhost:5000";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Add background service for polling and broadcasting updates
builder.Services.AddHostedService<DataPollingService>();

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

app.UseHttpsRedirection();
app.UseCors();
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

// Map SignalR hub endpoint
app.MapHub<DashboardHub>("/dashboardHub");

app.Run();
