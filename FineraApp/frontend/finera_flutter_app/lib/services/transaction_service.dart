//services/transaction_service.dart

// lib/services/transaction_service.dart

import 'dart:convert';
import 'api_client.dart';
import '../models/transaction.dart';

class TransactionService {
  Future<List<TransactionModel>> getTransactions({
    int? month,
    int? year,
    String? type,
    int? categoryId,
  }) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (categoryId != null) params['categoryId'] = categoryId.toString();

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await ApiClient.get('/api/Transactions${query.isNotEmpty ? '?$query' : ''}');

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load transactions: ${res.statusCode}');
  }

  /// Summary endpoint integration
  /// Backend returns PascalCase:
  /// { "totalIncome": decimal, "totalExpense": decimal, "balance": decimal, "month": int, "year": int }
  /// We normalize to camelCase + expose `netBalance`.
  Future<Map<String, dynamic>> getSummary({int? month, int? year}) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await ApiClient.get('/api/Transactions/summary${query.isNotEmpty ? '?$query' : ''}');

    if (res.statusCode == 200) {
      final Map<String, dynamic> raw = json.decode(res.body) as Map<String, dynamic>;
      // Normalize keys to what the UI expects
      final totalIncome = (raw['totalIncome'] ?? raw['TotalIncome'] ?? 0) as num;
      final totalExpense = (raw['totalExpense'] ?? raw['TotalExpense'] ?? 0) as num;
      final balance = (raw['netBalance'] ?? raw['balance'] ?? raw['Balance'] ?? (totalIncome - totalExpense)) as num;

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netBalance': balance, // UI uses netBalance
        'month': raw['month'] ?? raw['Month'],
        'year': raw['year'] ?? raw['Year'],
      };
    }
    throw Exception('Failed to load summary: ${res.statusCode}');
  }

  Future<TransactionModel> createTransaction(TransactionModel model) async {
    final res = await ApiClient.post('/api/Transactions', model.toJsonCreate());
    if (res.statusCode == 200 || res.statusCode == 201) {
      return TransactionModel.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to create transaction: ${res.statusCode}');
  }

  Future<void> updateTransaction(int id, TransactionModel model) async {
    final res = await ApiClient.put('/api/Transactions/$id', model.toJsonUpdate());
    if (res.statusCode != 204) {
      throw Exception('Failed to update transaction: ${res.statusCode}');
    }
  }

  Future<void> deleteTransaction(int id) async {
    final res = await ApiClient.delete('/api/Transactions/$id');
    if (res.statusCode != 204) {
      throw Exception('Failed to delete transaction: ${res.statusCode}');
    }
  }
}
