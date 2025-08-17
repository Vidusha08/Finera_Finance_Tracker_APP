/*using System.ComponentModel.DataAnnotations;

namespace FineraAPI.DTOs
{
    public class TransactionDto
    {
        [Required]
        public int CategoryId { get; set; }
        
        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
        public decimal Amount { get; set; }
        
        public string? Description { get; set; }
        
        [Required]
        public DateTime TransactionDate { get; set; }
        
        [Required]
        public string Type { get; set; } = string.Empty; // Income or Expense
    }

    public class TransactionResponseDto
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryColor { get; set; } = string.Empty;
        public string? CategoryIcon { get; set; }
        public decimal Amount { get; set; }
        public string? Description { get; set; }
        public DateTime TransactionDate { get; set; }
        public string Type { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}*/

//DTOs/TransactionDto.cs
using System.ComponentModel.DataAnnotations;

namespace FineraAPI.DTOs
{
    public class TransactionDto
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        
        [Required]
        public decimal Amount { get; set; }
        
        public string? Description { get; set; }
        
        [Required]
        public DateTime TransactionDate { get; set; }
        
        [Required]
        public string Type { get; set; } = string.Empty;
        
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryColor { get; set; } = string.Empty;
    }
}