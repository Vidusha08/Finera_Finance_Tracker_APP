//Controllers/DashboardController.cs

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using FineraAPI.Data;

namespace FineraAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly FineraDbContext _context;

        public DashboardController(FineraDbContext context)
        {
            _context = context;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        }

        [HttpGet("overview")]
        public async Task<ActionResult> GetDashboardOverview(
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            var userId = GetUserId();
            var start = startDate ?? DateTime.Now.AddMonths(-1);
            var end = endDate ?? DateTime.Now;
            
            // Current period data
            var transactions = await _context.Transactions
                .Where(t => t.UserId == userId && t.TransactionDate >= start && t.TransactionDate <= end)
                .ToListAsync();

            var totalIncome = transactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
            var totalExpenses = transactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);
            var balance = totalIncome - totalExpenses;

            // Previous period for comparison
            var previousStart = start.AddMonths(-1);
            var previousEnd = start.AddDays(-1);
            
            var previousTransactions = await _context.Transactions
                .Where(t => t.UserId == userId && t.TransactionDate >= previousStart && t.TransactionDate <= previousEnd)
                .ToListAsync();

            var previousIncome = previousTransactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
            var previousExpenses = previousTransactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);

            // Calculate percentage changes
            var incomeChange = previousIncome > 0 ? ((totalIncome - previousIncome) / previousIncome) * 100 : 0;
            var expenseChange = previousExpenses > 0 ? ((totalExpenses - previousExpenses) / previousExpenses) * 100 : 0;

            // Expense breakdown by category
            var expenseByCategory = transactions
                .Where(t => t.Type == "Expense")
                .GroupBy(t => t.CategoryId)
                .Select(g => new
                {
                    CategoryId = g.Key,
                    CategoryName = _context.Categories.FirstOrDefault(c => c.Id == g.Key)?.Name ?? "Unknown",
                    Total = g.Sum(t => t.Amount),
                    Color = _context.Categories.FirstOrDefault(c => c.Id == g.Key)?.Color ?? "#007bff"
                })
                .OrderByDescending(x => x.Total)
                .ToList();

            // Monthly trend (last 6 months)
            var monthlyTrend = new List<object>();
            for (int i = 5; i >= 0; i--)
            {
                var monthStart = DateTime.Now.AddMonths(-i).Date.AddDays(1 - DateTime.Now.AddMonths(-i).Day);
                var monthEnd = monthStart.AddMonths(1).AddDays(-1);
                
                var monthTransactions = await _context.Transactions
                    .Where(t => t.UserId == userId && t.TransactionDate >= monthStart && t.TransactionDate <= monthEnd)
                    .ToListAsync();

                var monthIncome = monthTransactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
                var monthExpenses = monthTransactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);

                monthlyTrend.Add(new
                {
                    Month = monthStart.ToString("MMM"),
                    Income = monthIncome,
                    Expenses = monthExpenses
                });
            }

            // Budget overview
            var currentMonth = DateTime.Now.Month;
            var currentYear = DateTime.Now.Year;
            
            var budgets = await _context.Budgets
                .Include(b => b.Category)
                .Where(b => b.UserId == userId && b.Month == currentMonth && b.Year == currentYear)
                .ToListAsync();

            var totalBudget = budgets.Sum(b => b.Amount);
            var totalSpent = budgets.Sum(b => b.SpentAmount);
            var remainingBudget = totalBudget - totalSpent;

            return Ok(new
            {
                // Summary cards
                totalIncome,
                totalExpenses,
                balance = remainingBudget, // Use remaining budget instead of simple balance
                incomeChange,
                expenseChange,
                
                // Charts data
                expenseByCategory,
                monthlyTrend,
                
                // Budget info
                totalBudget,
                totalSpent,
                remainingBudget,
                budgetUsagePercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
                
                // Additional metrics
                transactionCount = transactions.Count,
                averageExpensePerDay = totalExpenses / (decimal)(end - start).Days,
                topSpendingCategory = expenseByCategory.FirstOrDefault()?.CategoryName ?? "None"
            });
        }
    }
}