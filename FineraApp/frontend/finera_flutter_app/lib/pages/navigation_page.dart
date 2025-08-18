//pages/navigation_page.dart

import 'package:flutter/material.dart';

class NavigationPage extends StatelessWidget {
  final Widget content; // Page content injected here
  final String selectedPage; // To highlight active page
  final Function(String) onNavSelected; // Callback when nav item clicked

  const NavigationPage({
    super.key,
    required this.content,
    required this.selectedPage,
    required this.onNavSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Bar
          NavigationRail(
            selectedIndex: _getSelectedIndex(),
            onDestinationSelected: (index) {
              final pages = ['Dashboard', 'Transactions', 'Categories', 'Budgets', 'AI Assistant'];
              onNavSelected(pages[index]);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.indigo.shade50,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Finera',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_graph_outlined),
                selectedIcon: Icon(Icons.auto_graph),
                label: Text('AI Assistant'),
              ),
            ],
          ),

          // Main Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex() {
    switch (selectedPage) {
      case 'Dashboard':
        return 0;
      case 'Transactions':
        return 1;
      case 'Categories':
        return 2;
      case 'Budgets':
        return 3;
      case 'AI Assistant':
        return 4;
      default:
        return 0;
    }
  }
}
