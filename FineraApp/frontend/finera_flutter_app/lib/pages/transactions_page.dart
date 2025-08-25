//pages/transactions_page.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../widgets/transaction_form.dart';

import 'navigation_page.dart';
import 'dashboard_page.dart';
import 'categories_page.dart';
import 'budgets_page.dart';
import 'ai_assistant_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _txService = TransactionService();
  final _catService = CategoryService();

  bool _loading = false;
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];

  int? _filterMonth;
  int? _filterYear;
  Map<String, dynamic>? _summary; // { totalIncome, totalExpense, netBalance }

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
      final cats = await _catService.fetchCategories();
      final txs = await _txService.getTransactions(month: _filterMonth, year: _filterYear);
      final sum = await _txService.getSummary(month: _filterMonth, year: _filterYear);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _transactions = txs;
        _summary = sum;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTransaction() async {
    await showDialog(
      context: context,
      builder: (_) => TransactionForm(
        categories: _categories,
        onSubmit: (tx) async {
          Navigator.pop(context);
          try {
            await _txService.createTransaction(tx);
            await _loadData(); // refresh list + summary (and rely on backend to recompute budgets)
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction created")));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Create failed: $e")));
          }
        },
      ),
    );
  }

  Future<void> _editTransaction(TransactionModel tx) async {
    await showDialog(
      context: context,
      builder: (_) => TransactionForm(
        categories: _categories,
        transaction: tx,
        onSubmit: (updated) async {
          Navigator.pop(context);
          try {
            await _txService.updateTransaction(tx.id, updated);
            await _loadData(); // refresh list + summary
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction updated")));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
          }
        },
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: Text("Are you sure to delete ${tx.categoryName} (${tx.amount.toStringAsFixed(2)})?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _txService.deleteTransaction(tx.id);
      await _loadData(); // refresh list + summary
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction deleted")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
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
        // Gradient Apply Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
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
            gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreenAccent]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton.icon(
            onPressed: _createTransaction,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Transaction", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    final income = (_summary!['totalIncome'] ?? 0).toString();
    final expense = (_summary!['totalExpense'] ?? 0).toString();
    final balance = (_summary!['netBalance'] ?? 0).toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: const [Text("Income", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 5, 103, 29)))]),
            Text(income),
            const SizedBox(width: 16),
            Column(children: const [Text("Expense", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 248, 13, 13)))]),
            Text(expense),
            const SizedBox(width: 16),
            Column(children: const [Text("Balance", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 19, 59, 235)))]),
            Text(balance),
          ],
        ),
      ),
    );
  }

  Widget _table() {
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("No transactions found")),
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
          columnSpacing: 48,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text("Category")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Actions")),
          ],
          rows: _transactions.map((tx) {
            return DataRow(cells: [
              DataCell(Text(tx.categoryName)),
              DataCell(Text(tx.type)),
              DataCell(Text(tx.amount.toStringAsFixed(2))),
              DataCell(Text(tx.description ?? "")),
              DataCell(Text(tx.transactionDate.toLocal().toString().split(' ')[0])),
              DataCell(Row(children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editTransaction(tx),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTransaction(tx),
                ),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPage(
      selectedPage: "Transactions",
      onNavSelected: (page) {
        switch (page) {
          case "Dashboard":
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
            break;
          case "Transactions":
            // stay
            break;
          case "Categories":
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
            break;
          case "Budgets":
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BudgetsPage()));
            break;
          case "AI Assistant":
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
                  const Text("Transactions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _filters(),        // monthly separation controls
                  _summaryCard(),    // uses /api/Transactions/summary (normalized)
                  Expanded(child: SingleChildScrollView(child: _table())),
                ],
              ),
      ),
    );
  }
}
