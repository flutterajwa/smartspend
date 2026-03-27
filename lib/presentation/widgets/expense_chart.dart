import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';


import '../../data/models/transaction_model.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpenseChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate category-wise totals
    final Map<String, double> categoryTotals = {};
    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    if (categoryTotals.isEmpty) return const Center(child: Text("No expenses for chart analysis."));

    return PieChart(
      PieChartData(
        sections: categoryTotals.entries.map((entry) {
          final cat = TransactionCategory.getByName(entry.key);
          return PieChartSectionData(
            value: entry.value,
            title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
            color: cat.color,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 4,
      ),
    );
  }
}
