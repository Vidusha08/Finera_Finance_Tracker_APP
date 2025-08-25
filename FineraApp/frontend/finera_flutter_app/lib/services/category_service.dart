// lib/services/category_service.dart

import 'dart:convert';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  Future<List<CategoryModel>> fetchCategories() async {
    final res = await ApiClient.get('/api/Categories');
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Unauthorized: token may be missing or expired');
    } else {
      throw Exception('Failed to load categories: ${res.statusCode}');
    }
  }

  Future<CategoryModel> createCategory(CategoryModel model) async {
    final res = await ApiClient.post('/api/Categories', model.toJson());
    if (res.statusCode == 200 || res.statusCode == 201) {
      return CategoryModel.fromJson(json.decode(res.body));
    }
    throw Exception('Failed to create category: ${res.statusCode}');
  }

  Future<void> updateCategory(CategoryModel model) async {
    if (model.id == null) throw Exception('Category ID is null');
    final res = await ApiClient.put('/api/Categories/${model.id}', model.toJson());
    if (res.statusCode != 204) throw Exception('Failed to update category: ${res.statusCode}');
  }

  Future<void> deleteCategory(int id) async {
    final res = await ApiClient.delete('/api/Categories/$id');
    if (res.statusCode != 204) throw Exception('Failed to delete category: ${res.statusCode}');
  }
}

