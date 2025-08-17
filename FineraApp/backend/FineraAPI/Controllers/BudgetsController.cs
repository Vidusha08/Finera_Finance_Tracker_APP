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
            return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        }

        // GET: api/Budgets?month=8&year=2024
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

            // Check if budget already exists for this category, month, and year
            var existingBudget = await _context.Budgets
                .FirstOrDefaultAsync(b => b.UserId == userId && 
                                         b.CategoryId == createBudgetDto.CategoryId && 
                                         b.Month == createBudgetDto.Month && 
                                         b.Year == createBudgetDto.Year);

            if (existingBudget != null)
                return BadRequest("Budget already exists for this category and period");

            // Verify category belongs to user or is default
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == createBudgetDto.CategoryId && 
                                         (c.UserId == userId || c.IsDefault));

            if (category == null)
                return BadRequest("Invalid category");

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

            var budgetDto = new BudgetDto
            {
                Id = budget.Id,
                CategoryId = budget.CategoryId,
                CategoryName = category.Name,
                CategoryType = category.Type,
                Amount = budget.Amount,
                SpentAmount = budget.SpentAmount,
                Month = budget.Month,
                Year = budget.Year,
                RemainingAmount = budget.Amount - budget.SpentAmount,
                PercentageUsed = budget.Amount > 0 ? (budget.SpentAmount / budget.Amount) * 100 : 0
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
            await _context.SaveChangesAsync();
        }
    }
}