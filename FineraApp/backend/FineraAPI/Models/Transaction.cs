//Models/Transaction.cs

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FineraAPI.Models
{
    public class Transaction
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int CategoryId { get; set; }
        
        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Amount { get; set; }
        
        [StringLength(255)]
        public string? Description { get; set; }
        
        [Required]
        public DateTime TransactionDate { get; set; }
        
        [Required]
        public string Type { get; set; } = string.Empty; // Income or Expense
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual User User { get; set; } = null!;
        public virtual Category Category { get; set; } = null!;
    }
}