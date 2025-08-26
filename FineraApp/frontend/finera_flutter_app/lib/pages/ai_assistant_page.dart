//pages/ai_assistant_page.dart

import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/ai_models.dart';
import 'navigation_page.dart';
import 'transactions_page.dart';
import 'categories_page.dart';
import 'budgets_page.dart';
import 'dashboard_page.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final _amountCtrl = TextEditingController(text: "1000");
  final _locationCtrl = TextEditingController();
  bool _loading = false;
  List<AiSuggestionItem> _items = [];
  final _aiService = AiService();

  // Categories list
  final List<String> _allCategories = [
    "Food",
    "Transport",
    "Accommodation & Hotels",
    "Bills",
    "Entertainment",
    "Savings",
    "Misc"
  ];
  String? _selectedCategory;

  Future<void> _fetch() async {
    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final items = await _aiService.getSuggestions(
        amount: amt,
        location: _locationCtrl.text.trim().isEmpty
            ? "Unknown"
            : _locationCtrl.text.trim(),
        categories: [_selectedCategory!], // send category to backend
      );

      // Sort so selected category comes first
      final sorted = [
        ...items.where((it) => it.category == _selectedCategory),
        ...items.where((it) => it.category != _selectedCategory),
      ];

      setState(() => _items = sorted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPage(
      selectedPage: 'AI Assistant',
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
            // already here
            break;
        }
      },
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Budget Assistant",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Input fields + Dropdown + Button section raw
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount box
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount (LKR)",
                      prefixIcon: const Icon(Icons.currency_exchange),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Location box
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _locationCtrl,
                    decoration: InputDecoration(
                      labelText: "Location (optional)",
                      prefixIcon: const Icon(Icons.place_outlined),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category dropdown
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _allCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                    decoration: InputDecoration(
                      labelText: "Select Category",
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Get Ideas button
                ElevatedButton.icon(
                  onPressed: _loading ? null : _fetch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    _loading ? "Thinking..." : "Get Ideas",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Suggestions
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        "Enter an amount, (optional) location, and select a category to get suggestions.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final it = _items[i];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              it.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                it.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Rs. ${it.estimatedCost.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  it.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

