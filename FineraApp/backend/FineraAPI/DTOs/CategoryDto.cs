//DTOs/CategoryDto.cs

using System.ComponentModel.DataAnnotations;

namespace FineraAPI.DTOs
{
    public class CategoryDto
    {
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Type { get; set; } = string.Empty; // "Income" or "Expense"

        public string Color { get; set; } = "#007bff";
        public string? Icon { get; set; }
    }

    public class CreateCategoryDto
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Type { get; set; } = string.Empty; // "Income" or "Expense"

        public string Color { get; set; } = "#007bff";
        public string? Icon { get; set; }
    }

    public class UpdateCategoryDto
    {
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Type { get; set; } = string.Empty; // "Income" or "Expense"

        public string Color { get; set; } = "#007bff";
        public string? Icon { get; set; }
    }
}