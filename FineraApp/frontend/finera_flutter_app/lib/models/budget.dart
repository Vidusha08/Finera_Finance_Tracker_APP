//models/budget.dart

class Budget {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final double amount;
  final double spentAmount;
  final double remainingAmount;
  final double percentageUsed;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.month,
    required this.year,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryType: json['categoryType'],
      amount: (json['amount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      percentageUsed: (json['percentageUsed'] as num).toDouble(),
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  Map<String, dynamic> toJsonUpdate() {
    return {
      'amount': amount,
    };
  }
}
