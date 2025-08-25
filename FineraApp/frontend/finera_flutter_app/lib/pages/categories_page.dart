// lib/pages/categories_page.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../widgets/category_card.dart';
import '../widgets/category_form.dart';
import 'navigation_page.dart';
import 'dashboard_page.dart';
import 'budgets_page.dart';
import 'transactions_page.dart';
import 'ai_assistant_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _service = CategoryService();
  List<CategoryModel> _categories = [];
  String _selectedType = 'Expense';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final items = await _service.fetchCategories();
      if (!mounted) return; // Fix: avoid using context if widget is disposed
      setState(() => _categories = items);
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
    
  }

  Future<void> _addOrEditCategory([CategoryModel? initial]) async {
    final result = await showDialog<CategoryModel>(
      context: context,
      builder: (_) => CategoryForm(initial: initial),
    );
    if (result != null) {
      if (initial == null) {
        await _service.createCategory(result);
      } else {
        await _service.updateCategory(result);
      }
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    await _service.deleteCategory(cat.id!);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPage(
      selectedPage: 'Categories',
      onNavSelected: (page) {
        switch (page) {
          case 'Dashboard':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
            break;
          case 'Transactions':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsPage()),
            );
            break;
          case 'Categories':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesPage()),
            );
            break;
          case 'Budgets':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BudgetsPage()),
            );
            break;
          case 'AI Assistant':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantPage()),
            );
            break;
        }
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                  DropdownMenuItem(value: 'Income', child: Text('Income')),
                ],
                onChanged: (v) =>
                    setState(() => _selectedType = v ?? 'Expense'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
                onPressed: () => _addOrEditCategory(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories grid
          Expanded(
            child: GridView.builder(
              itemCount: _categories
                  .where((c) => c.type == _selectedType)
                  .length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) {
                final filtered =
                    _categories.where((c) => c.type == _selectedType).toList();
                final cat = filtered[i];
                return CategoryCard(
                  category: cat,
                  onEdit: () => _addOrEditCategory(cat),
                  onDelete: () => _deleteCategory(cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
