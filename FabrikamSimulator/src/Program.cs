using FabrikamSimulator.Services;
using FabrikamSimulator.Workers;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { 
        Title = "Fabrikam Business Simulator API", 
        Version = "v1",
        Description = "API for controlling business activity simulators"
    });
});

// Add HttpClient for calling FabrikamApi
builder.Services.AddHttpClient();

// Add singleton state service for worker coordination
builder.Services.AddSingleton<WorkerStateService>();

// Add background workers
builder.Services.AddHostedService<OrderProgressionWorker>();
builder.Services.AddHostedService<OrderGeneratorWorker>();
builder.Services.AddHostedService<TicketGeneratorWorker>();

// Add CORS for dashboard integration
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

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();
app.MapControllers();

app.Logger.LogInformation("Fabrikam Simulator starting...");
app.Logger.LogInformation("FabrikamApi URL: {ApiUrl}", builder.Configuration["FabrikamApi:BaseUrl"]);

app.Run();
