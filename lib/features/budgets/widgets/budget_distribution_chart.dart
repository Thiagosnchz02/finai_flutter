// lib/features/budgets/widgets/budget_distribution_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget_model.dart';

class BudgetDistributionChart extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetDistributionChart({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    // Generamos un color para cada sección del gráfico
    final colors = List.generate(budgets.length, (index) => Colors.primaries[index % Colors.primaries.length]);
    double totalBudgeted = budgets.fold(0.0, (sum, item) => sum + item.amount);

    if (budgets.isEmpty) {
      return const SizedBox.shrink(); // No muestra nada si no hay presupuestos
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: List.generate(budgets.length, (i) {
            final budget = budgets[i];
            final percentage = (budget.amount / totalBudgeted) * 100;
            return PieChartSectionData(
              color: colors[i],
              value: budget.amount,
              title: '${percentage.toStringAsFixed(0)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }
}