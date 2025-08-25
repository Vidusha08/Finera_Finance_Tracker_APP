//Controllers/CategoriesController.cs

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
    public class CategoriesController : ControllerBase
    {
        private readonly FineraDbContext _context;
        private readonly IMapper _mapper;

        public CategoriesController(FineraDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        private int GetUserId()
        {
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        [HttpGet]
        public async Task<IActionResult> GetCategories()
        {
            var userId = GetUserId();

            var categories = await _context.Categories
                .Where(c => c.IsDefault || c.UserId == userId)
                .OrderBy(c => c.Type)
                .ThenBy(c => c.Name)
                .ToListAsync();

            return Ok(_mapper.Map<IEnumerable<CategoryDto>>(categories));
        }

        [HttpGet("{type}")]
        public async Task<IActionResult> GetCategoriesByType(string type)
        {
            // Normalize the type to proper case
            type = type.ToLower() == "income" ? "Income" : 
            type.ToLower() == "expense" ? "Expense" : "";
            
            if (type != "Income" && type != "Expense")
                return BadRequest("Type must be 'Income' or 'Expense'");

            var userId = GetUserId();

            var categories = await _context.Categories
                .Where(c => c.Type == type && (c.IsDefault || c.UserId == userId))
                .OrderBy(c => c.Name)
                .ToListAsync();

            return Ok(_mapper.Map<IEnumerable<CategoryDto>>(categories));
        }

        // POST: api/Categories
        [HttpPost]
        public async Task<ActionResult<CategoryDto>> CreateCategory(CreateCategoryDto createCategoryDto)
        {
            var userId = GetUserId();

            // Check if category name already exists for this user
            var existingCategory = await _context.Categories
                .FirstOrDefaultAsync(c => c.Name == createCategoryDto.Name && 
                                         c.UserId == userId);

            if (existingCategory != null)
                return BadRequest("Category with this name already exists");

            var category = _mapper.Map<Category>(createCategoryDto);
            category.UserId = userId;

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            var categoryDto = _mapper.Map<CategoryDto>(category);
            return CreatedAtAction(nameof(GetCategories), categoryDto);
        }

        // PUT: api/Categories/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateCategory(int id, UpdateCategoryDto updateCategoryDto)
        {
            var userId = GetUserId();
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

            if (category == null)
                return NotFound();

            // Don't allow updating default categories
            if (category.IsDefault)
                return BadRequest("Cannot update default categories");

            // Check if new name conflicts with existing categories
            var existingCategory = await _context.Categories
                .FirstOrDefaultAsync(c => c.Name == updateCategoryDto.Name && 
                                         c.UserId == userId && 
                                         c.Id != id);

            if (existingCategory != null)
                return BadRequest("Category with this name already exists");

            _mapper.Map(updateCategoryDto, category);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/Categories/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var userId = GetUserId();
            var category = await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

            if (category == null)
                return NotFound();

            // Don't allow deleting default categories
            if (category.IsDefault)
                return BadRequest("Cannot delete default categories");

            // Check if category is being used in transactions or budgets
            var hasTransactions = await _context.Transactions
                .AnyAsync(t => t.CategoryId == id);

            var hasBudgets = await _context.Budgets
                .AnyAsync(b => b.CategoryId == id);

            if (hasTransactions || hasBudgets)
                return BadRequest("Cannot delete category that has associated transactions or budgets");

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}

