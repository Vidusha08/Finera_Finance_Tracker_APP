//Controllers/TransactionsController.cs

using AutoMapper;
using FineraAPI.Data;
using FineraAPI.DTOs;
using FineraAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace FineraAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class TransactionsController : ControllerBase
    {
        private readonly FineraDbContext _context;
        private readonly IMapper _mapper;

        public TransactionsController(FineraDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        // GET: api/Transactions
        [HttpGet]
        public async Task<ActionResult<IEnumerable<TransactionDto>>> GetTransactions(
            [FromQuery] int? month = null,
            [FromQuery] int? year = null,
            [FromQuery] string? type = null,
            [FromQuery] int? categoryId = null)
        {
            var userId = GetUserId();
            var query = _context.Transactions
                .Include(t => t.Category)
                .Where(t => t.UserId == userId);

            if (month.HasValue && year.HasValue)
            {
                query = query.Where(t => t.TransactionDate.Month == month.Value && t.TransactionDate.Year == year.Value);
            }

            if (!string.IsNullOrEmpty(type))
            {
                var normalizedType = type.ToLower() == "income" ? "Income" :
                                   type.ToLower() == "expense" ? "Expense" : "";
                if (!string.IsNullOrEmpty(normalizedType))
                {
                    query = query.Where(t => t.Type == normalizedType);
                }
            }

            if (categoryId.HasValue)
            {
                query = query.Where(t => t.CategoryId == categoryId.Value);
            }

            var transactions = await query
                .OrderByDescending(t => t.TransactionDate)
                .ThenByDescending(t => t.CreatedAt)
                .Select(t => new TransactionDto
                {
                    Id = t.Id,
                    CategoryId = t.CategoryId,
                    CategoryName = t.Category.Name,
                    CategoryType = t.Category.Type,
                    Amount = t.Amount,
                    Description = t.Description,
                    TransactionDate = t.TransactionDate,
                    Type = t.Type
                })
                .ToListAsync();

            return Ok(transactions);
        }

        // GET: api/Transactions/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<TransactionDto>> GetTransaction(int id)
        {
            var userId = GetUserId();

            var transaction = await _context.Transactions
                .Include(t => t.Category)
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

            if (transaction == null)
                return NotFound();

            var transactionDto = new TransactionDto
            {
                Id = transaction.Id,
                CategoryId = transaction.CategoryId,
                CategoryName = transaction.Category.Name,
                CategoryType = transaction.Category.Type,
                Amount = transaction.Amount,
                Description = transaction.Description,
                TransactionDate = transaction.TransactionDate,
                Type = transaction.Type
            };

            return Ok(transactionDto);
        }

        // POST: api/Transactions
        [HttpPost]
        public async Task<ActionResult<TransactionDto>> CreateTransaction(CreateTransactionDto createTransactionDto)
        {
            var userId = GetUserId();

            // Additional validation for user ID
            if (userId <= 0)
            {
                return BadRequest("Invalid user authentication");
            }

            // Normalize the type to proper case
            var normalizedType = createTransactionDto.Type.ToLower() == "income" ? "Income" :
                               createTransactionDto.Type.ToLower() == "expense" ? "Expense" : "";

            if (normalizedType != "Income" && normalizedType != "Expense")
                return BadRequest("Type must be 'Income' or 'Expense'");

            // Verify category belongs to user or is default - using the same logic as other controllers
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == createTransactionDto.CategoryId &&
                                         (c.IsDefault || c.UserId == userId));

            if (category == null)
            {
                return BadRequest($"Invalid category ID: {createTransactionDto.CategoryId}");
            }

            // Verify that the transaction type matches the category type
            if (category.Type != normalizedType)
            {
                return BadRequest($"Transaction type '{normalizedType}' does not match category type '{category.Type}'");
            }

            var transaction = new Transaction
            {
                UserId = userId,
                CategoryId = createTransactionDto.CategoryId,
                Amount = createTransactionDto.Amount,
                Description = createTransactionDto.Description,
                TransactionDate = createTransactionDto.TransactionDate,
                Type = normalizedType
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            // Return the created transaction with category information
            var createdTransaction = await _context.Transactions
                .Include(t => t.Category)
                .FirstAsync(t => t.Id == transaction.Id);

            var transactionDto = new TransactionDto
            {
                Id = createdTransaction.Id,
                CategoryId = createdTransaction.CategoryId,
                CategoryName = createdTransaction.Category.Name,
                CategoryType = createdTransaction.Category.Type,
                Amount = createdTransaction.Amount,
                Description = createdTransaction.Description,
                TransactionDate = createdTransaction.TransactionDate,
                Type = createdTransaction.Type
            };

            return CreatedAtAction(nameof(GetTransaction), new { id = transaction.Id }, transactionDto);
        }

        // PUT: api/Transactions/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTransaction(int id, UpdateTransactionDto updateTransactionDto)
        {
            var userId = GetUserId();
            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

            if (transaction == null)
                return NotFound();

            // Normalize the type to proper case
            var normalizedType = updateTransactionDto.Type.ToLower() == "income" ? "Income" :
                               updateTransactionDto.Type.ToLower() == "expense" ? "Expense" : "";

            if (normalizedType != "Income" && normalizedType != "Expense")
                return BadRequest("Type must be 'Income' or 'Expense'");

            // Verify category belongs to user or is default
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == updateTransactionDto.CategoryId &&
                                         (c.IsDefault || c.UserId == userId));

            if (category == null)
            {
                return BadRequest($"Invalid category ID: {updateTransactionDto.CategoryId}");
            }

            // Verify that the transaction type matches the category type
            if (category.Type != normalizedType)
            {
                return BadRequest($"Transaction type '{normalizedType}' does not match category type '{category.Type}'");
            }

            transaction.CategoryId = updateTransactionDto.CategoryId;
            transaction.Amount = updateTransactionDto.Amount;
            transaction.Description = updateTransactionDto.Description;
            transaction.TransactionDate = updateTransactionDto.TransactionDate;
            transaction.Type = normalizedType;
            transaction.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/Transactions/{id}
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

        // GET: api/Transactions/summary
        [HttpGet("summary")]
        public async Task<ActionResult<TransactionSummaryDto>> GetTransactionSummary(
            [FromQuery] int? month = null,
            [FromQuery] int? year = null)
        {
            var userId = GetUserId();
            var currentMonth = month ?? DateTime.Now.Month;
            var currentYear = year ?? DateTime.Now.Year;

            var transactions = await _context.Transactions
                .Where(t => t.UserId == userId &&
                           t.TransactionDate.Month == currentMonth &&
                           t.TransactionDate.Year == currentYear)
                .ToListAsync();

            var totalIncome = transactions
                .Where(t => t.Type == "Income")
                .Sum(t => t.Amount);

            var totalExpense = transactions
                .Where(t => t.Type == "Expense")
                .Sum(t => t.Amount);

            var summary = new TransactionSummaryDto
            {
                TotalIncome = totalIncome,
                TotalExpense = totalExpense,
                Balance = totalIncome - totalExpense,
                Month = currentMonth,
                Year = currentYear
            };

            return Ok(summary);
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
