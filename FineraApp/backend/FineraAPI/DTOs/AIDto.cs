// DTOs/AIDto.cs

namespace FineraAPI.DTOs;

public class AISuggestionRequestDto
{
    public decimal Amount { get; set; }            // e.g., 1000
    public string? Location { get; set; }          // e.g., "Colombo"
    public string? Currency { get; set; } = "LKR"; // default Sri Lankan Rupees
    public List<string>? Categories { get; set; }  // optional user-selected cats
}

public class AISuggestionItemDto
{
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public string Category { get; set; } = "";     // Food/Transport/Bills/...
    public decimal EstimatedCost { get; set; }     // in LKR
}

public class AISuggestionResponseDto
{
    public List<AISuggestionItemDto> Suggestions { get; set; } = new();
}

