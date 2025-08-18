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

/*using AutoMapper;
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

            // Optional: Verify that the transaction type matches the category type
            // Commented out to allow flexibility - uncomment if you want strict type matching
            
            //if (category.Type != normalizedType)
            //{
             //   return BadRequest($"Transaction type '{normalizedType}' does not match category type '{category.Type}'");
           // }

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

            // Optional: Verify that the transaction type matches the category type  
            // Commented out to allow flexibility - uncomment if you want strict type matching
            /*
            //if (category.Type != normalizedType)
            //{
            //   return BadRequest($"Transaction type '{normalizedType}' does not match category type '{category.Type}'");
            //}
            

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
}*/

/*//Controllers/TransactionsController.cs

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
            // Use the same method as other controllers for consistency
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
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

            // Normalize type parameter
            if (!string.IsNullOrEmpty(type))
            {
                type = type.ToLower() == "income" ? "Income" : 
                       type.ToLower() == "expense" ? "Expense" : type;
                query = query.Where(t => t.Type == type);
            }

            var transactions = await query
                .OrderByDescending(t => t.TransactionDate)
                .ThenByDescending(t => t.Id)
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
        public async Task<ActionResult<TransactionDto>> CreateTransaction(CreateTransactionDto createTransactionDto)
        {
            var userId = GetUserId();
            
            // Validate user ID
            if (userId <= 0)
            {
                return BadRequest("Invalid user authentication");
            }
            
            // Normalize transaction type
            createTransactionDto.Type = createTransactionDto.Type.ToLower() == "income" ? "Income" : 
                                       createTransactionDto.Type.ToLower() == "expense" ? "Expense" : 
                                       createTransactionDto.Type;
            
            if (createTransactionDto.Type != "Income" && createTransactionDto.Type != "Expense")
            {
                return BadRequest("Type must be 'Income' or 'Expense'");
            }
            
            // Check for both user categories AND default categories
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == createTransactionDto.CategoryId && 
                                        (c.UserId == userId || c.IsDefault));
                
            if (category == null)
            {
                var availableCategories = await _context.Categories
                    .Where(c => c.IsDefault || c.UserId == userId)
                    .Select(c => new { c.Id, c.Name, c.Type })
                    .ToListAsync();

                return BadRequest($"Invalid category ID: {createTransactionDto.CategoryId}. " +
                    $"Available categories: [{string.Join(", ", availableCategories.Select(c => $"ID:{c.Id} Name:{c.Name} Type:{c.Type}"))}]");
            }

            // Validate category type matches transaction type
            if (category.Type != createTransactionDto.Type)
            {
                return BadRequest($"Category '{category.Name}' is of type '{category.Type}' but transaction is of type '{createTransactionDto.Type}'");
            }

            var transaction = new Transaction
            {
                UserId = userId,
                CategoryId = createTransactionDto.CategoryId,
                Amount = createTransactionDto.Amount,
                Description = createTransactionDto.Description,
                TransactionDate = createTransactionDto.TransactionDate,
                Type = createTransactionDto.Type,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            var transactionDto = new TransactionDto
            {
                Id = transaction.Id,
                CategoryId = transaction.CategoryId,
                Amount = transaction.Amount,
                Description = transaction.Description,
                TransactionDate = transaction.TransactionDate,
                Type = transaction.Type,
                CategoryName = category.Name,
                CategoryColor = category.Color
            };

            return CreatedAtAction(nameof(GetTransaction), new { id = transaction.Id }, transactionDto);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTransaction(int id, UpdateTransactionDto updateTransactionDto)
        {
            var userId = GetUserId();
            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);

            if (transaction == null)
                return NotFound();
            
            // Normalize transaction type
            updateTransactionDto.Type = updateTransactionDto.Type.ToLower() == "income" ? "Income" : 
                                       updateTransactionDto.Type.ToLower() == "expense" ? "Expense" : 
                                       updateTransactionDto.Type;
            
            if (updateTransactionDto.Type != "Income" && updateTransactionDto.Type != "Expense")
            {
                return BadRequest("Type must be 'Income' or 'Expense'");
            }

            // Verify category exists and belongs to user or is default
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == updateTransactionDto.CategoryId && 
                                        (c.UserId == userId || c.IsDefault));

            if (category == null)
                return BadRequest("Invalid category");

            // Validate category type matches transaction type
            if (category.Type != updateTransactionDto.Type)
            {
                return BadRequest($"Category '{category.Name}' is of type '{category.Type}' but transaction is of type '{updateTransactionDto.Type}'");
            }

            transaction.CategoryId = updateTransactionDto.CategoryId;
            transaction.Amount = updateTransactionDto.Amount;
            transaction.Description = updateTransactionDto.Description;
            transaction.TransactionDate = updateTransactionDto.TransactionDate;
            transaction.Type = updateTransactionDto.Type;
            transaction.UpdatedAt = DateTime.UtcNow;

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
            var end = endDate ?? DateTime.Now.Date.AddDays(1).AddSeconds(-1); // Include the entire end date

            var transactions = await _context.Transactions
                .Include(t => t.Category)
                .Where(t => t.UserId == userId && 
                           t.TransactionDate >= start && 
                           t.TransactionDate <= end)
                .ToListAsync();

            var totalIncome = transactions.Where(t => t.Type == "Income").Sum(t => t.Amount);
            var totalExpenses = transactions.Where(t => t.Type == "Expense").Sum(t => t.Amount);
            var balance = totalIncome - totalExpenses;

            var categoryExpenses = transactions
                .Where(t => t.Type == "Expense")
                .GroupBy(t => new { t.CategoryId, t.Category.Name, t.Category.Color })
                .Select(g => new
                {
                    CategoryId = g.Key.CategoryId,
                    CategoryName = g.Key.Name,
                    CategoryColor = g.Key.Color,
                    Total = g.Sum(t => t.Amount),
                    TransactionCount = g.Count()
                })
                .OrderByDescending(x => x.Total)
                .ToList();

            var categoryIncome = transactions
                .Where(t => t.Type == "Income")
                .GroupBy(t => new { t.CategoryId, t.Category.Name, t.Category.Color })
                .Select(g => new
                {
                    CategoryId = g.Key.CategoryId,
                    CategoryName = g.Key.Name,
                    CategoryColor = g.Key.Color,
                    Total = g.Sum(t => t.Amount),
                    TransactionCount = g.Count()
                })
                .OrderByDescending(x => x.Total)
                .ToList();

            return Ok(new
            {
                Period = new { StartDate = start, EndDate = end },
                TotalIncome = totalIncome,
                TotalExpenses = totalExpenses,
                Balance = balance,
                CategoryExpenses = categoryExpenses,
                CategoryIncome = categoryIncome,
                TransactionCount = transactions.Count,
                IncomeTransactionCount = transactions.Count(t => t.Type == "Income"),
                ExpenseTransactionCount = transactions.Count(t => t.Type == "Expense")
            });
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
}*/