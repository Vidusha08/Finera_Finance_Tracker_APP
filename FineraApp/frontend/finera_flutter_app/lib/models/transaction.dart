//models/transaction.dart

class TransactionModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryType; // "Income" or "Expense" (from category)
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String type; // "Income" or "Expense" (explicit type)

  TransactionModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    this.description,
    required this.transactionDate,
    required this.type,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: (json['categoryName'] ?? '') as String,
      categoryType: (json['categoryType'] ?? '') as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      type: (json['type'] ?? 'Expense') as String,
    );
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      'type': type,
    };
  }

  Map<String, dynamic> toJsonUpdate() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      'type': type,
    };
  }
}

