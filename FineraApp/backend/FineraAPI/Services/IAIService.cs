//Services/IAIService.cs

using FineraAPI.DTOs;

namespace FineraAPI.Services
{
    public interface IAIService
    {
        Task<List<AISuggestionItemDto>> GetSuggestionsAsync(AISuggestionRequestDto request, string userId);
    }
}


