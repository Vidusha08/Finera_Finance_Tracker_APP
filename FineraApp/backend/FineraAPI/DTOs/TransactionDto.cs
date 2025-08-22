//DTOs/TransactionDto.cs

using System.ComponentModel.DataAnnotations;

namespace FineraAPI.DTOs
{
    public class TransactionDto
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string CategoryType { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string? Description { get; set; }
        public DateTime TransactionDate { get; set; }
        public string Type { get; set; } = string.Empty; // Income or Expense
    }

    public class CreateTransactionDto
    {
        [Required]
        public int CategoryId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
        public decimal Amount { get; set; }

        [StringLength(255)]
        public string? Description { get; set; }

        [Required]
        public DateTime TransactionDate { get; set; }

        [Required]
        public string Type { get; set; } = string.Empty; // "Income" or "Expense"
    }

    public class UpdateTransactionDto
    {
        [Required]
        public int CategoryId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than 0")]
        public decimal Amount { get; set; }

        [StringLength(255)]
        public string? Description { get; set; }

        [Required]
        public DateTime TransactionDate { get; set; }

        [Required]
        public string Type { get; set; } = string.Empty; // "Income" or "Expense"
    }

    public class TransactionSummaryDto
    {
        public decimal TotalIncome { get; set; }
        public decimal TotalExpense { get; set; }
        public decimal Balance { get; set; }
        public int Month { get; set; }
        public int Year { get; set; }
    }
}
