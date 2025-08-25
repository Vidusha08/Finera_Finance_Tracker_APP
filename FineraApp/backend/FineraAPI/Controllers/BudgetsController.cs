//Controllers/BudgetsController.cs

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using FineraAPI.Data;
using FineraAPI.DTOs;
using FineraAPI.Models;

namespace FineraAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class BudgetsController : ControllerBase
    {
        private readonly FineraDbContext _context;

        public BudgetsController(FineraDbContext context)
        {
            _context = context;
        }

        private int GetUserId()
        {
            // Use the same method as CategoriesController for consistency
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        // GET: api/Budgets?month=8&year=2025
        [HttpGet]
        public async Task<ActionResult<IEnumerable<BudgetDto>>> GetBudgets(
            [FromQuery] int? month = null,
            [FromQuery] int? year = null)
        {
            var userId = GetUserId();
            var currentMonth = month ?? DateTime.Now.Month;
            var currentYear = year ?? DateTime.Now.Year;

            var budgets = await _context.Budgets
                .Include(b => b.Category)
                .Where(b => b.UserId == userId && b.Month == currentMonth && b.Year == currentYear)
                .Select(b => new BudgetDto
                {
                    Id = b.Id,
                    CategoryId = b.CategoryId,
                    CategoryName = b.Category.Name,
                    CategoryType = b.Category.Type,
                    Amount = b.Amount,
                    SpentAmount = b.SpentAmount,
                    Month = b.Month,
                    Year = b.Year,
                    RemainingAmount = b.Amount - b.SpentAmount,
                    PercentageUsed = b.Amount > 0 ? (b.SpentAmount / b.Amount) * 100 : 0
                })
                .ToListAsync();

            return Ok(budgets);
        }

        // POST: api/Budgets
        [HttpPost]
        public async Task<ActionResult<BudgetDto>> CreateBudget(CreateBudgetDto createBudgetDto)
        {
            var userId = GetUserId();

            // Additional validation for user ID
            if (userId <= 0)
            {
                return BadRequest("Invalid user authentication");
            }

            // Check if budget already exists for this category, month, and year
            var existingBudget = await _context.Budgets
                .FirstOrDefaultAsync(b => b.UserId == userId && 
                                         b.CategoryId == createBudgetDto.CategoryId && 
                                         b.Month == createBudgetDto.Month && 
                                         b.Year == createBudgetDto.Year);

            if (existingBudget != null)
                return BadRequest("Budget already exists for this category and period");

            // Verify category belongs to user or is default - using the same logic as CategoriesController
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == createBudgetDto.CategoryId && 
                                         (c.IsDefault || c.UserId == userId));

            if (category == null)
            {
                // Better error message for debugging
                var availableCategories = await _context.Categories
                    .Where(c => c.IsDefault || c.UserId == userId)
                    .Select(c => new { c.Id, c.Name, c.IsDefault, c.UserId })
                    .ToListAsync();

                return BadRequest($"Invalid category ID: {createBudgetDto.CategoryId}. " +
                    $"User ID: {userId}. " +
                    $"Available categories: [{string.Join(", ", availableCategories.Select(c => $"ID:{c.Id} Name:{c.Name} Default:{c.IsDefault}"))}]");
            }

            var budget = new Budget
            {
                UserId = userId,
                CategoryId = createBudgetDto.CategoryId,
                Amount = createBudgetDto.Amount,
                Month = createBudgetDto.Month,
                Year = createBudgetDto.Year,
                SpentAmount = 0 // Will be calculated from transactions
            };

            _context.Budgets.Add(budget);
            await _context.SaveChangesAsync();

            // Calculate spent amount from existing transactions
            await UpdateBudgetSpentAmount(budget.Id);

            // Refresh the budget to get the updated spent amount
            var updatedBudget = await _context.Budgets
                .Include(b => b.Category)
                .FirstAsync(b => b.Id == budget.Id);

            var budgetDto = new BudgetDto
            {
                Id = updatedBudget.Id,
                CategoryId = updatedBudget.CategoryId,
                CategoryName = updatedBudget.Category.Name,
                CategoryType = updatedBudget.Category.Type,
                Amount = updatedBudget.Amount,
                SpentAmount = updatedBudget.SpentAmount,
                Month = updatedBudget.Month,
                Year = updatedBudget.Year,
                RemainingAmount = updatedBudget.Amount - updatedBudget.SpentAmount,
                PercentageUsed = updatedBudget.Amount > 0 ? (updatedBudget.SpentAmount / updatedBudget.Amount) * 100 : 0
            };

            return CreatedAtAction(nameof(GetBudgets), budgetDto);
        }

        // PUT: api/Budgets/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateBudget(int id, UpdateBudgetDto updateBudgetDto)
        {
            var userId = GetUserId();
            var budget = await _context.Budgets
                .FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId);

            if (budget == null)
                return NotFound();

            budget.Amount = updateBudgetDto.Amount;
            budget.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/Budgets/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBudget(int id)
        {
            var userId = GetUserId();
            var budget = await _context.Budgets
                .FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId);

            if (budget == null)
                return NotFound();

            _context.Budgets.Remove(budget);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Helper method to update spent amount
        private async Task UpdateBudgetSpentAmount(int budgetId)
        {
            var budget = await _context.Budgets.FindAsync(budgetId);
            if (budget == null) return;

            var startDate = new DateTime(budget.Year, budget.Month, 1);
            var endDate = startDate.AddMonths(1).AddDays(-1);

            var spentAmount = await _context.Transactions
                .Where(t => t.UserId == budget.UserId && 
                           t.CategoryId == budget.CategoryId && 
                           t.Type == "Expense" &&
                           t.TransactionDate >= startDate && 
                           t.TransactionDate <= endDate)
                .SumAsync(t => (decimal?)t.Amount) ?? 0;

            budget.SpentAmount = spentAmount;
            budget.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        // Debug endpoint to help troubleshoot (remove in production)
        [HttpGet("debug/user")]
        public IActionResult GetCurrentUser()
        {
            var userId = GetUserId();
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var allClaims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
            
            return Ok(new 
            { 
                UserId = userId, 
                UserIdClaim = userIdClaim,
                AllClaims = allClaims
            });
        }
    }
}

