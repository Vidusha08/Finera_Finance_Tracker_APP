//widgets/income_expense_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class IncomeExpenseBarChart extends StatefulWidget {
  final List<TransactionModel> transactions;

  const IncomeExpenseBarChart({super.key, required this.transactions});

  @override
  State<IncomeExpenseBarChart> createState() => _IncomeExpenseBarChartState();
}

class _IncomeExpenseBarChartState extends State<IncomeExpenseBarChart> {
  bool show12Months = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(show12Months ? 12 : 6, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      final income = widget.transactions
          .where((t) => t.type == "Income" && t.transactionDate.month == date.month && t.transactionDate.year == date.year)
          .fold(0.0, (a, b) => a + b.amount);
      final expense = widget.transactions
          .where((t) => t.type == "Expense" && t.transactionDate.month == date.month && t.transactionDate.year == date.year)
          .fold(0.0, (a, b) => a + b.amount);
      return {"month": date, "income": income, "expense": expense};
    }).reversed.toList();

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
                const Text("Income vs Expense Trend",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<bool>(
                  value: show12Months,
                  items: const [
                    DropdownMenuItem(value: false, child: Text("Last 6 Months")),
                    DropdownMenuItem(value: true, child: Text("Last 12 Months")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      show12Months = val!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: months.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    final income = (m["income"] as double?) ?? 0.0;
                    final expense = (m["expense"] as double?) ?? 0.0;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: income, color: Colors.green, width: 10),
                      BarChartRodData(toY: expense, color: Colors.red, width: 10),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= months.length) return const SizedBox();
                          final month = months[idx]["month"] as DateTime;
                          return Text(DateFormat.MMM().format(month),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    //leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.square, color: Colors.green, size: 12),
                SizedBox(width: 6),
                Text("Income"),
                SizedBox(width: 16),
                Icon(Icons.square, color: Colors.red, size: 12),
                SizedBox(width: 6),
                Text("Expense"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

