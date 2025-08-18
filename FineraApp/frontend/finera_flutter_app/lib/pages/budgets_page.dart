//pages/budgets_page.dart

import 'package:flutter/material.dart';
import 'navigation_page.dart';
import 'dashboard_page.dart';
import 'categories_page.dart';
import 'transactions_page.dart';
import 'ai_assistant_page.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationPage(
      selectedPage: 'Budgets',
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
      content: Center(
        child: Text(
          'Welcome to Finera Budgets Page!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}