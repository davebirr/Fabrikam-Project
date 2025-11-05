using System.Net.Http.Headers;

namespace FabrikamDashboard.Services;

/// <summary>
/// HTTP message handler that adds JWT authentication to API requests
/// </summary>
public class JwtAuthenticationHandler : DelegatingHandler
{
    private readonly IJwtTokenService _jwtTokenService;
    private readonly ILogger<JwtAuthenticationHandler> _logger;
    private string? _cachedToken;
    private DateTime _tokenExpiry = DateTime.MinValue;

    public JwtAuthenticationHandler(IJwtTokenService jwtTokenService, ILogger<JwtAuthenticationHandler> logger)
    {
        _jwtTokenService = jwtTokenService;
        _logger = logger;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        // Get or refresh JWT token
        var token = await GetOrRefreshTokenAsync();
        
        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            _logger.LogDebug("Added JWT Bearer token to request for {RequestUri}", request.RequestUri);
        }
        else
        {
            _logger.LogWarning("No JWT token available for request to {RequestUri}", request.RequestUri);
        }

        return await base.SendAsync(request, cancellationToken);
    }

    private async Task<string?> GetOrRefreshTokenAsync()
    {
        // Check if we have a cached token that's still valid (with 5-minute buffer)
        if (!string.IsNullOrEmpty(_cachedToken) && DateTime.UtcNow < _tokenExpiry.AddMinutes(-5))
        {
            _logger.LogDebug("Using cached JWT token (expires at {Expiry})", _tokenExpiry);
            return _cachedToken;
        }

        // Generate new token
        try
        {
            _cachedToken = await _jwtTokenService.GenerateDashboardServiceTokenAsync();
            
            // Parse token to get expiry (tokens are typically valid for 60 minutes)
            var expirationMinutes = 60; // Default from configuration
            _tokenExpiry = DateTime.UtcNow.AddMinutes(expirationMinutes);
            
            _logger.LogInformation("Generated new JWT token (valid until {Expiry})", _tokenExpiry);
            return _cachedToken;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate JWT token");
            return null;
        }
    }
}
