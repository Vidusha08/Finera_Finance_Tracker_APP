//Models/Category.cs

using System.ComponentModel.DataAnnotations;

namespace FineraAPI.Models
{
    public class Category
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        public string Type { get; set; } = string.Empty; // Income or Expense
        
        public string Color { get; set; } = "#007bff";
        public string? Icon { get; set; }
        public int? UserId { get; set; }
        public bool IsDefault { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual User? User { get; set; }
        public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
        public virtual ICollection<Budget> Budgets { get; set; } = new List<Budget>();
    }
}