using FabrikamDashboard.Components;
using FabrikamDashboard.Services;
using FabrikamDashboard.BackgroundServices;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Add SignalR for real-time updates
builder.Services.AddSignalR();

// Configure HTTP clients for FabrikamApi
builder.Services.AddHttpClient<FabrikamApiClient>(client =>
{
    var baseUrl = builder.Configuration["FabrikamApi:BaseUrl"] ?? "https://localhost:7297";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
    
    // Add X-Tracking-Guid header for API authentication in Disabled mode
    // This allows the API to track the dashboard as a client
    var dashboardGuid = builder.Configuration["Dashboard:TrackingGuid"] ?? "dashboard-00000000-0000-0000-0000-000000000001";
    client.DefaultRequestHeaders.Add("X-Tracking-Guid", dashboardGuid);
});

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
