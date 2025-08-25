//widgets/expense_pie_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'color_utils.dart';

class ExpensePieChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const ExpensePieChart({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int selectedMonthIndex = DateTime.now().month - 1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth =
        DateFormat.MMMM().format(DateTime(now.year, selectedMonthIndex + 1));

    // filter current month expenses
    final expenseTxs = widget.transactions.where((t) =>
        t.type == "Expense" &&
        t.transactionDate.month == selectedMonthIndex + 1 &&
        t.transactionDate.year == now.year).toList();

    final Map<String, double> byCategory = {};
    for (var tx in expenseTxs) {
      byCategory[tx.categoryName] =
          (byCategory[tx.categoryName] ?? 0) + tx.amount;
    }

    final total = byCategory.values.fold(0.0, (a, b) => a + b);

    final sections = byCategory.entries.map((e) {
      final cat = widget.categories.firstWhere(
          (c) => c.name == e.key,
          orElse: () =>
              CategoryModel(id: 0, name: e.key, type: "Expense", color: "#FF0000"));
      final color = colorFromHex(cat.color);
      final percentage = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : "0";
      return PieChartSectionData(
        value: e.value,
        title: "$percentage%",
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      selectedMonthIndex =
                          (selectedMonthIndex - 1 + 12) % 12;
                    });
                  },
                ),
                Text("$currentMonth Expense Breakdown",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      selectedMonthIndex =
                          (selectedMonthIndex + 1) % 12;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: byCategory.keys.map((catName) {
                final cat = widget.categories.firstWhere(
                    (c) => c.name == catName,
                    orElse: () => CategoryModel(
                        id: 0, name: catName, type: "Expense", color: "#FF0000"));
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        color: colorFromHex(cat.color)),
                    const SizedBox(width: 6),
                    Text(catName),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'color_utils.dart';

class ExpensePieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const ExpensePieChart({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final expenseTxs = transactions.where((t) => t.type == "Expense").toList();

    final Map<String, double> byCategory = {};
    for (var tx in expenseTxs) {
      byCategory[tx.categoryName] =
          (byCategory[tx.categoryName] ?? 0) + tx.amount;
    }

    final sections = byCategory.entries.map((e) {
      final cat = categories.firstWhere(
          (c) => c.name == e.key,
          orElse: () => CategoryModel(
              id: 0, name: e.key, type: "Expense", color: "#FF0000"));
      final color = colorFromHex(cat.color);
      return PieChartSectionData(
        value: e.value,
        title: "${e.key}\n${e.value.toStringAsFixed(0)}",
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Expense Breakdown",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 250, child: PieChart(PieChartData(sections: sections))),
          ],
        ),
      ),
    );
  }
}
*/