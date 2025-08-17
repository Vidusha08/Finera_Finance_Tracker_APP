//Controllers/TransactionsController.cs

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
    public class TransactionsController : ControllerBase
    {
        private readonly FineraDbContext _context;

        public TransactionsController(FineraDbContext context)
        {
            _context = context;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TransactionDto>>> GetTransactions(
            [FromQuery] int page = 1,
            [FromQuery] int limit = 50,
            [FromQuery] string? type = null)
        {
            var userId = GetUserId();
            var query = _context.Transactions
                .Include(t => t.Category)
                .Where(t => t.UserId == userId);

            if (!string.IsNullOrEmpty(type))
            {
                query = query.Where(t => t.Type == type);
            }

            var transactions = await query
                .OrderByDescending(t => t.TransactionDate)
                .Skip((page - 1) * limit)
                .Take(limit)
                .Select(t => new TransactionDto
                {
                    Id = t.Id,
                    CategoryId = t.CategoryId,
                    Amount = t.Amount,
                    Description = t.Description,
                    TransactionDate = t.TransactionDate,
                    Type = t.Type,
                    CategoryName = t.Category.Name,
                    CategoryColor = t.Category.Color
                })
                .ToListAsync();

            return Ok(transactions);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TransactionDto>> GetTransaction(int id)
        {
            var userId = GetUserId();
            var transaction = await _context.Transactions
                .Include(t => t.Category)
                .Where(t => t.Id == id && t.UserId == userId)
                .Select(t => new TransactionDto
                {
                    Id = t.Id,
                    CategoryId = t.CategoryId,
                    Amount = t.Amount,
                    Description = t.Description,
                    TransactionDate = t.TransactionDate,
                    Type = t.Type,
                    CategoryName = t.Category.Name,
                    CategoryColor = t.Category.Color
                })
                .FirstOrDefaultAsync();

            if (transaction == null)
                return NotFound();

            return Ok(transaction);
        }

        [HttpPost]
        public async Task<ActionResult<TransactionDto>> CreateTransaction(TransactionDto transactionDto)
        {
            var userId = GetUserId();
            
            // Fix: Check for both user categories AND default categories
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == transactionDto.CategoryId && 
                                        (c.UserId == userId || c.IsDefault));
            //var category = await _context.Categories
                //.FirstOrDefaultAsync(c => c.Id == transactionDto.CategoryId && c.UserId == userId);
                
            if (category == null)
                return BadRequest("Invalid category");

            var transaction = new Transaction
            {
                UserId = userId,
                CategoryId = transactionDto.CategoryId,
                Amount = transactionDto.Amount,
                Description = transactionDto.Description,
                TransactionDate = transactionDto.TransactionDate,
                Type = transactionDto.Type
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            transactionDto.Id = transaction.Id;
            transactionDto.CategoryName = category.Name;
            transactionDto.CategoryColor = category.Color;

            return CreatedAtAction(nameof(GetTransaction), new { id = transaction.Id }, transactionDto);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTransaction(int id, TransactionDto transactionDto)
        {
            var userId = GetUserId();
            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

            if (transaction == null)
                return NotFound();

            transaction.CategoryId = transactionDto.CategoryId;
            transaction.Amount = transactionDto.Amount;
            transaction.Description = transactionDto.Description;
            transaction.TransactionDate = transactionDto.TransactionDate;
            transaction.Type = transactionDto.Type;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTransaction(int id)
        {
            var userId = GetUserId();
            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

            if (transaction == null)
                return NotFound();

            _context.Transactions.Remove(transaction);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpGet("summary")]
        public async Task<ActionResult> GetSummary(
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            var userId = GetUserId();
            
            var start = startDate ?? DateTime.Now.AddMonths(-1);
            var end = endDate ?? DateTime.Now;

            var transactions = await _context.Transactions
                .Where(t => t.UserId == userId && t.TransactionDate >= start && t.TransactionDate <= end)
                .ToListAsync();

            var totalIncome = transactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
            var totalExpenses = transactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);
            var balance = totalIncome - totalExpenses;

            var categoryExpenses = transactions
                .Where(t => t.Type == "Expense")
                .GroupBy(t => t.CategoryId)
                .Select(g => new
                {
                    CategoryId = g.Key,
                    Total = g.Sum(t => t.Amount)
                })
                .ToList();

            return Ok(new
            {
                totalIncome,
                totalExpenses,
                balance,
                categoryExpenses,
                transactionCount = transactions.Count
            });
        }
    }
}