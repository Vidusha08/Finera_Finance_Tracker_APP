// Services/AIService.cs

using System.Text;
using System.Text.Json;
using FineraAPI.DTOs;

namespace FineraAPI.Services
{
    public class AIService : IAIService
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public AIService(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<List<AISuggestionItemDto>> GetSuggestionsAsync(AISuggestionRequestDto request, string userId)
        {
            var model  = _config["Gemini:Model"] ?? "gemini-2.5-flash";
            var apiKey = _config["Gemini:ApiKey"] ?? Environment.GetEnvironmentVariable("GEMINI_API_KEY");
            if (string.IsNullOrWhiteSpace(apiKey))
                throw new InvalidOperationException("Gemini API key is missing.");

            var endpoint = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";

            // Ask for strict JSON back (schema-lite)
            var system = """
    You are Finera's AI Budget Assistant. 
    Rules:
    - Output ONLY valid JSON (no markdown, no extra text).
    - JSON is an array of items: [{ "title": string, "description": string, "category": string, "estimatedCost": number }]
    - "estimatedCost" is in LKR. Maximum each suggestion must be <= user's amount.
    - Mix short-term ideas (e.g., dinner/transport) and long-term (e.g., savings/bills).
    - Avoid naming specific real businesses unless very generic; prefer categories (e.g., "rice & curry at a cafe").
    """;

            // can enrich with user data from DB Keeping simple for now.
            var prompt = $@"
    User:
    - Budget Amount: {request.Amount} {request.Currency}
    - Location (optional): {request.Location ?? "Unknown"}
    - Preferred categories (optional): {(request.Categories is { Count: >0 } ? string.Join(", ", request.Categories!) : "None")}
    Task:
    - Return 6 budget-friendly suggestions for Sri Lanka context, suitable for {request.Currency}.
    - Include at least 2 food ideas under the amount (e.g., dinner under Rs. {request.Amount}).
    - Keep titles concise; descriptions 1–2 sentences.
    - Use categories like Food, Transport, Bills, Entertainment, Savings, Misc.
    ";

            var payload = new
            {
                contents = new[]
                {
                    new {
                        parts = new[] {
                            new { text = system },
                            new { text = prompt }
                        }
                    }
                },
                generationConfig = new {
                    temperature = 0.6,
                    candidateCount = 1,
                    response_mime_type = "application/json"
                }
            };

            var json = JsonSerializer.Serialize(payload);
            using var req = new HttpRequestMessage(HttpMethod.Post, endpoint);
            req.Content = new StringContent(json, Encoding.UTF8, "application/json");

            var res = await _http.SendAsync(req);
            res.EnsureSuccessStatusCode();

            using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
            var text = doc.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var items = JsonSerializer.Deserialize<List<AISuggestionItemDto>>(text ?? "[]", options) ?? new();

            // filter by user's amount
            return items.Where(i => i.EstimatedCost <= request.Amount && i.EstimatedCost >= 0).ToList();
            
            
        }
    }
}

