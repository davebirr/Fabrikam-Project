using FabrikamApi.Data;
using FabrikamApi.Services;
using FabrikamApi.Services.Authentication;
using FabrikamApi.Models.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

// Configure Entity Framework with explicit database provider configuration
// Supports both SQL Server (production) and In-Memory (testing/development)
builder.Services.AddDbContext<FabrikamIdentityDbContext>(options =>
{
    var databaseProvider = builder.Configuration.GetValue<string>("Database:Provider", "Auto");
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

    switch (databaseProvider.ToUpperInvariant())
    {
        case "INMEMORY":
            options.UseInMemoryDatabase("FabrikamDb");
            break;

        case "SQLSERVER":
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("Database:Provider is set to 'SqlServer' but no DefaultConnection string is configured");
            }
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(10),
                    errorNumbersToAdd: null);
            });
            break;

        case "AUTO":
        default:
            if (string.IsNullOrEmpty(connectionString))
            {
                // Auto-fallback to in-memory database for development/testing
                options.UseInMemoryDatabase("FabrikamDb");
            }
            else
            {
                options.UseSqlServer(connectionString, sqlOptions =>
                {
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 3,
                        maxRetryDelay: TimeSpan.FromSeconds(10),
                        errorNumbersToAdd: null);
                });
            }
            break;
    }
});

// Configure ASP.NET Identity
builder.Services.AddIdentity<FabrikamUser, FabrikamRole>(options =>
{
    // Configure password requirements
    var passwordSettings = builder.Configuration.GetSection("Authentication:AspNetIdentity:Password").Get<PasswordSettings>() ?? new PasswordSettings();
    options.Password.RequiredLength = passwordSettings.RequiredLength;
    options.Password.RequireUppercase = passwordSettings.RequireUppercase;
    options.Password.RequireLowercase = passwordSettings.RequireLowercase;
    options.Password.RequireDigit = passwordSettings.RequireDigit;
    options.Password.RequireNonAlphanumeric = passwordSettings.RequireNonAlphanumeric;
    options.Password.RequiredUniqueChars = passwordSettings.RequiredUniqueChars;

    // Configure lockout settings
    var lockoutSettings = builder.Configuration.GetSection("Authentication:AspNetIdentity:Lockout").Get<LockoutSettings>() ?? new LockoutSettings();
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(lockoutSettings.DefaultLockoutTimeSpanInMinutes);
    options.Lockout.MaxFailedAccessAttempts = lockoutSettings.MaxFailedAccessAttempts;
    options.Lockout.AllowedForNewUsers = lockoutSettings.AllowedForNewUsers;

    // Configure user settings
    var authSettings = builder.Configuration.GetSection("Authentication:AspNetIdentity").Get<AspNetIdentitySettings>() ?? new AspNetIdentitySettings();
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = authSettings.RequireConfirmedEmail;
    options.SignIn.RequireConfirmedPhoneNumber = authSettings.RequireConfirmedPhoneNumber;
})
.AddEntityFrameworkStores<FabrikamIdentityDbContext>()
.AddDefaultTokenProviders();

// Configure JWT Authentication
var jwtSettings = builder.Configuration.GetSection(JwtSettings.SectionName).Get<JwtSettings>() ?? new JwtSettings();
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection(JwtSettings.SectionName));

if (!string.IsNullOrEmpty(jwtSettings.SecretKey))
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
        options.RequireHttpsMetadata = false; // Set to true in production
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
                logger.LogWarning("JWT Authentication failed: {Exception}", context.Exception.Message);
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogDebug("JWT token validated for user: {User}", context.Principal?.Identity?.Name);
                return Task.CompletedTask;
            }
        };
    });
}

// Add authentication services
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthenticationService, AuthenticationService>();

// Add data seeding services - JSON as primary, hardcoded as fallback
builder.Services.AddScoped<JsonDataSeedService>();
builder.Services.AddScoped<DataSeedService>();
builder.Services.AddScoped<AuthenticationSeedService>();

// Configure seed data options
builder.Services.Configure<SeedDataOptions>(
    builder.Configuration.GetSection(SeedDataOptions.SectionName));

// Use JSON seed service as the primary implementation (configurable)
builder.Services.AddScoped<ISeedService>(provider =>
{
    var configuration = provider.GetRequiredService<IConfiguration>();
    var seedMethod = configuration.GetValue<string>("SeedData:Method", "Json");

    return seedMethod.ToLowerInvariant() switch
    {
        "hardcoded" => provider.GetRequiredService<DataSeedService>(),
        "json" or _ => provider.GetRequiredService<JsonDataSeedService>()
    };
});

// Add authorization services
builder.Services.AddAuthorization(options =>
{
    // Define custom authorization policies
    options.AddPolicy("RequireAdminRole", policy => policy.RequireRole("Administrator"));
    options.AddPolicy("RequireManagerRole", policy => policy.RequireRole("Administrator", "Manager"));
    options.AddPolicy("RequireUserRole", policy => policy.RequireRole("Administrator", "Manager", "User"));

    // Custom claim-based policies
    options.AddPolicy("CanManageUsers", policy => policy.RequireClaim("permission", "manage-users"));
    options.AddPolicy("CanViewReports", policy => policy.RequireClaim("permission", "view-reports"));
});

// Configure Swagger/OpenAPI for .NET 8
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS for development
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
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Fabrikam API v1");
        c.RoutePrefix = "swagger"; // Serve Swagger UI at /swagger
        c.DocumentTitle = "Fabrikam API Documentation";
        c.DefaultModelsExpandDepth(-1); // Hide models section by default
        c.DisplayRequestDuration(); // Show request duration
        c.EnableDeepLinking(); // Enable deep linking
        c.EnableFilter(); // Enable filter box
        c.ShowExtensions(); // Show vendor extensions
    });
}

// Enable CORS
app.UseCors();

app.UseHttpsRedirection();

// Add authentication and authorization middleware
app.UseAuthentication();
app.UseAuthorization();

// Map controllers
app.MapControllers();

// Add a simple root endpoint that redirects to Swagger UI
app.MapGet("/", () => Results.Redirect("/swagger"))
    .WithName("Root")
    .WithSummary("Redirects to Swagger UI");

// Add a health check endpoint
app.MapGet("/health", () => new
{
    Status = "Healthy",
    Timestamp = DateTime.UtcNow,
    Version = "1.0.0",
    Environment = app.Environment.EnvironmentName
});

// Seed data on startup (configurable)
using (var scope = app.Services.CreateScope())
{
    try
    {
        var context = scope.ServiceProvider.GetRequiredService<FabrikamIdentityDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<FabrikamUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<FabrikamRole>>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        // Ensure database is created
        await context.Database.EnsureCreatedAsync();

        logger.LogInformation("Database initialized successfully");

        // Seed authentication users from JSON (demo users with predefined roles)
        var authSeedService = scope.ServiceProvider.GetRequiredService<AuthenticationSeedService>();
        await authSeedService.SeedAuthenticationDataAsync();

        // Seed business data if enabled
        var enableSeed = configuration.GetValue<bool>("SeedData:EnableSeedOnStartup", true);
        if (enableSeed)
        {
            var seedService = scope.ServiceProvider.GetRequiredService<ISeedService>();
            await seedService.SeedDataAsync();
            logger.LogInformation("Data seeding completed successfully");
        }
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while initializing the database");
    }
}

app.Run();

// Make the implicit Program class public for testing
public partial class Program { }
