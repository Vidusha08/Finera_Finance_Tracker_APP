//pages/budgets_page.dart

import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../widgets/budget_form.dart';

import 'navigation_page.dart';
import 'dashboard_page.dart';
import 'categories_page.dart';
import 'transactions_page.dart';
import 'ai_assistant_page.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final _budgetService = BudgetService();
  final _categoryService = CategoryService();

  bool _loading = false;
  List<Budget> _budgets = [];
  List<CategoryModel> _categories = [];

  int? _filterMonth;
  int? _filterYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterMonth = now.month;
    _filterYear = now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await _categoryService.fetchCategories();
      final b = await _budgetService.getBudgets(month: _filterMonth, year: _filterYear);
      setState(() {
        _categories = cats;
        _budgets = b;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load budgets: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBudget() async {
    await showDialog(
      context: context,
      builder: (_) => BudgetForm(
        categories: _categories,
        onSubmit: (budget) async {
          Navigator.of(context).pop(); // close dialog
          try {
            await _budgetService.createBudget(budget);
            await _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Budget created')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Create failed: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _editBudget(Budget b) async {
    await showDialog(
      context: context,
      builder: (_) => BudgetForm(
        categories: _categories,
        budget: b,
        onSubmit: (updated) async {
          Navigator.of(context).pop();
          try {
            await _budgetService.updateBudget(b.id, updated);
            await _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Budget updated')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteBudget(Budget b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the budget for ${b.categoryName} ${b.month}/${b.year}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _budgetService.deleteBudget(b.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _filters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: _filterMonth?.toString(),
            decoration: const InputDecoration(labelText: 'Month (1-12)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _filterMonth = int.tryParse(v),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextFormField(
            initialValue: _filterYear?.toString(),
            decoration: const InputDecoration(labelText: 'Year (2020-2030)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _filterYear = int.tryParse(v),
          ),
        ),
        /*ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Apply'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _createBudget,
          icon: const Icon(Icons.add),
          label: const Text('Add Budget'),
        ),*/
        // Gradient Apply Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ),

        // Gradient Add Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreenAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton.icon(
            onPressed: _createBudget,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Budget",
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _table() {
    if (_budgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No budgets found for selected month/year')),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          columnSpacing: 48,//24
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Budget')),
            DataColumn(label: Text('Spent')),
            DataColumn(label: Text('Remaining')),
            DataColumn(label: Text('% Used')),
            DataColumn(label: Text('Month/Year')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _budgets.map((b) {
            return DataRow(
              cells: [
                DataCell(Text(b.categoryName)),
                DataCell(Text(b.categoryType)),
                DataCell(Text(b.amount.toStringAsFixed(2))),
                DataCell(Text(b.spentAmount.toStringAsFixed(2))),
                DataCell(Text(b.remainingAmount.toStringAsFixed(2))),
                DataCell(Text('${b.percentageUsed.toStringAsFixed(0)}%')),
                DataCell(Text('${b.month}/${b.year}')),
                DataCell(Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editBudget(b),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBudget(b),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPage(
      selectedPage: 'Budgets',
      onNavSelected: (page) {
        switch (page) {
          case 'Dashboard':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
            break;
          case 'Transactions':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionsPage()));
            break;
          case 'Categories':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
            break;
          case 'Budgets':
            // stay here
            break;
          case 'AI Assistant':
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AIAssistantPage()));
            break;
        }
      },
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Budgets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _filters(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _table(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
