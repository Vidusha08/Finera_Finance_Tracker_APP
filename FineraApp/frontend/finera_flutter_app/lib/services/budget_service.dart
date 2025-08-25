//services/budget_service.dart

import 'dart:convert';
import '../models/budget.dart';
import 'api_client.dart';

class BudgetService {
  BudgetService();

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    final query = <String>[];
    if (month != null) query.add('month=$month');
    if (year != null) query.add('year=$year');
    final queryString = query.isNotEmpty ? '?${query.join('&')}' : '';

    final response = await ApiClient.get('/api/Budgets$queryString');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch budgets: ${response.statusCode} ${response.body}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Budget.fromJson(e)).toList();
  }

  Future<Budget> createBudget(Budget budget) async {
    final response = await ApiClient.post('/api/Budgets', budget.toJsonCreate());

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create budget: ${response.statusCode} ${response.body}');
    }

    return Budget.fromJson(json.decode(response.body));
  }

  Future<void> updateBudget(int id, Budget budget) async {
    final response = await ApiClient.put('/api/Budgets/$id', budget.toJsonUpdate());

    if (response.statusCode != 204) {
      throw Exception('Failed to update budget: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deleteBudget(int id) async {
    final response = await ApiClient.delete('/api/Budgets/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete budget: ${response.statusCode} ${response.body}');
    }
  }
}

