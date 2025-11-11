using Microsoft.AspNetCore.Mvc;
using FabrikamApi.Services;
using Microsoft.AspNetCore.Authorization;

namespace FabrikamApi.Controllers;

[ApiController]
[Route("api/[controller]")]
// TODO: Re-enable when Admin policy is configured: [Authorize(Policy = "Admin")]
// TEMPORARY: Allowing anonymous access in development for debugging
public class SeedController : ControllerBase
{
    private readonly JsonDataSeedService _jsonSeedService;
    private readonly DataSeedService _hardcodedSeedService;
    private readonly ILogger<SeedController> _logger;

    public SeedController(
        JsonDataSeedService jsonSeedService,
        DataSeedService hardcodedSeedService,
        ILogger<SeedController> logger)
    {
        _jsonSeedService = jsonSeedService;
        _hardcodedSeedService = hardcodedSeedService;
        _logger = logger;
    }

    /// <summary>
    /// Re-seed the database using JSON seed data
    /// </summary>
    [HttpPost("json")]
    public async Task<ActionResult> SeedFromJson()
    {
        try
        {
            _logger.LogInformation("Manual JSON seed requested");
            await _jsonSeedService.SeedDataAsync();
            return Ok(new
            {
                Message = "Database seeded successfully from JSON files",
                Method = "Json",
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during JSON seed operation");
            return StatusCode(500, new
            {
                Error = "Failed to seed database from JSON files",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// Force re-seed the database using JSON seed data, clearing existing data first
    /// </summary>
    [HttpPost("json/force")]
    public async Task<ActionResult> ForceReseedFromJson()
    {
        try
        {
            _logger.LogInformation("Manual force JSON re-seed requested");
            await _jsonSeedService.ForceReseedAsync();
            return Ok(new
            {
                Message = "Database force re-seeded successfully from JSON files",
                Method = "Json Force",
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during JSON force re-seed operation");
            return StatusCode(500, new
            {
                Error = "Failed to force re-seed database from JSON files",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// Re-seed the database using hardcoded seed data
    /// </summary>
    [HttpPost("hardcoded")]
    public async Task<ActionResult> SeedFromHardcoded()
    {
        try
        {
            _logger.LogInformation("Manual hardcoded seed requested");
            await _hardcodedSeedService.SeedDataAsync();
            return Ok(new
            {
                Message = "Database seeded successfully from hardcoded data",
                Method = "Hardcoded",
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during hardcoded seed operation");
            return StatusCode(500, new
            {
                Error = "Failed to seed database from hardcoded data",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// Get information about available seeding methods
    /// </summary>
    [HttpGet("methods")]
    public ActionResult GetSeedMethods()
    {
        return Ok(new
        {
            AvailableMethods = new[]
            {
                new {
                    Name = "Json",
                    Description = "Seed from JSON files (human-readable, testable)",
                    Endpoint = "/api/seed/json"
                },
                new {
                    Name = "Hardcoded",
                    Description = "Seed from hardcoded data (legacy, demo)",
                    Endpoint = "/api/seed/hardcoded"
                }
            },
            CurrentDefault = "Json (configured in appsettings.json)",
            Timestamp = DateTime.UtcNow
        });
    }
}
