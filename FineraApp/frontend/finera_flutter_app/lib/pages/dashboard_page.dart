//pages/dashboard_page.dart

import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/summary_card.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/income_expense_bar_chart.dart';
import 'navigation_page.dart';
import 'transactions_page.dart';
import 'categories_page.dart';
import 'budgets_page.dart';
import 'ai_assistant_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _txService = TransactionService();
  final _catService = CategoryService();
  bool _loading = false;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  double _income = 0, _expense = 0, _balance = 0;
  double _lastIncome = 0, _lastExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await _catService.fetchCategories();
      final txs = await _txService.getTransactions();

      final now = DateTime.now();
      double income = 0, expense = 0, lastIncome = 0, lastExpense = 0;
      for (var tx in txs) {
        if (tx.transactionDate.month == now.month && tx.transactionDate.year == now.year) {
          if (tx.type == "Income") income += tx.amount;
          if (tx.type == "Expense") expense += tx.amount;
        }
        if (tx.transactionDate.month == now.month - 1 && tx.transactionDate.year == now.year) {
          if (tx.type == "Income") lastIncome += tx.amount;
          if (tx.type == "Expense") lastExpense += tx.amount;
        }
      }

      setState(() {
        _categories = cats;
        _transactions = txs;
        _income = income;
        _expense = expense;
        _balance = income - expense;
        _lastIncome = lastIncome;
        _lastExpense = lastExpense;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    String incomeChange = _lastIncome > 0
        ? "${((_income - _lastIncome) / _lastIncome * 100).toStringAsFixed(1)}% vs last month"
        : "This month income";
    String expenseChange = _lastExpense > 0
        ? "${((_expense - _lastExpense) / _lastExpense * 100).toStringAsFixed(1)}% vs last month"
        : "This month expense";

    return NavigationPage(
      selectedPage: "Dashboard",
      onNavSelected: (page) {
        switch (page) {
          case "Dashboard":
            break;
          case "Transactions":
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TransactionsPage()));
            break;
          case "Categories":
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const CategoriesPage()));
            break;
          case "Budgets":
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const BudgetsPage()));
            break;
          case "AI Assistant":
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AIAssistantPage()));
            break;
        }
      },
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                          child: SummaryCard(
                              title: "Total Income",
                              value: _income.toStringAsFixed(2),
                              subtitle: incomeChange,
                              color: Colors.green,
                              icon: Icons.arrow_downward)),
                      Expanded(
                          child: SummaryCard(
                              title: "Total Expense",
                              value: _expense.toStringAsFixed(2),
                              subtitle: expenseChange,
                              color: Colors.red,
                              icon: Icons.arrow_upward)),
                      Expanded(
                          child: SummaryCard(
                              title: "Remaining Balance",
                              value: _balance.toStringAsFixed(2),
                              subtitle: "This month balance",
                              color: Colors.blue,
                              icon: Icons.account_balance_wallet)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Charts
                  Expanded(
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(
                                  child: ExpensePieChart(
                                      transactions: _transactions,
                                      categories: _categories)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: IncomeExpenseBarChart(
                                      transactions: _transactions)),
                            ],
                          )
                        : ListView(
                            children: [
                              ExpensePieChart(
                                  transactions: _transactions,
                                  categories: _categories),
                              const SizedBox(height: 16),
                              IncomeExpenseBarChart(
                                  transactions: _transactions),
                            ],
                          ),
                  )
                ],
              ),
            ),
    );
  }
}

