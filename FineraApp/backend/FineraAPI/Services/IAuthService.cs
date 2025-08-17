//Services/IAuthService.cs
using FineraAPI.DTOs;

namespace FineraAPI.Services
{
    public interface IAuthService
    {
        Task<AuthResponseDto?> RegisterAsync(RegisterDto registerDto);
        Task<AuthResponseDto?> LoginAsync(LoginDto loginDto);
        string GenerateJwtToken(int userId, string username, string email);
    }
}