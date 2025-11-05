using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace FabrikamDashboard.Services;

/// <summary>
/// Service for generating JWT tokens for dashboard-to-API authentication
/// </summary>
public interface IJwtTokenService
{
    /// <summary>
    /// Generate a service JWT token for the dashboard
    /// </summary>
    Task<string> GenerateDashboardServiceTokenAsync();
}

/// <summary>
/// Implementation of JWT token generation for dashboard
/// </summary>
public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<JwtTokenService> _logger;
    private readonly string _dashboardGuid;

    public JwtTokenService(IConfiguration configuration, ILogger<JwtTokenService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        
        // Use configured dashboard GUID or generate a consistent one
        _dashboardGuid = _configuration["Dashboard:ServiceGuid"] 
            ?? "dashboard-00000000-0000-0000-0000-000000000001";
    }

    /// <summary>
    /// Generate a service JWT token for the dashboard
    /// </summary>
    public Task<string> GenerateDashboardServiceTokenAsync()
    {
        var jwtSecretKey = _configuration["Authentication:Jwt:SecretKey"];
        var jwtIssuer = _configuration["Authentication:Jwt:Issuer"] ?? "fabrikam-api";
        var jwtAudience = _configuration["Authentication:Jwt:Audience"] ?? "fabrikam-api";
        var expirationMinutes = int.Parse(_configuration["Authentication:Jwt:ExpirationMinutes"] ?? "60");

        if (string.IsNullOrEmpty(jwtSecretKey))
        {
            _logger.LogError("JWT SecretKey is not configured");
            throw new InvalidOperationException("JWT SecretKey is not configured in app settings");
        }

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, _dashboardGuid),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
            new Claim("name", "Fabrikam Dashboard"),
            new Claim("email", "dashboard@fabrikam.com"),
            new Claim("fabrikam_service_jwt", "true"),
            new Claim("fabrikam_service_name", "dashboard")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: jwtIssuer,
            audience: jwtAudience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: creds
        );

        var tokenString = new JwtSecurityTokenHandler().WriteToken(token);
        
        _logger.LogDebug("Generated service JWT token for dashboard with GUID {DashboardGuid}", _dashboardGuid);
        
        return Task.FromResult(tokenString);
    }
}
