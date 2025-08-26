// Controllers/AIController.cs

using FineraAPI.DTOs;
using FineraAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FineraAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // require JWT like the rest of your APIs
public class AIController : ControllerBase
{
    private readonly IAIService _ai;

    public AIController(IAIService ai) => _ai = ai;

    [HttpPost("suggestions")]
    public async Task<ActionResult<AISuggestionResponseDto>> GetSuggestions([FromBody] AISuggestionRequestDto dto)
    {
        if (dto.Amount <= 0) return BadRequest("Amount must be > 0.");
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown";
        var items = await _ai.GetSuggestionsAsync(dto, userId);
        return Ok(new AISuggestionResponseDto { Suggestions = items });
    }
}
