// lib/features/budgets/widgets/budget_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final progressColor = budget.progress > 0.85 ? Colors.redAccent : (budget.progress > 0.6 ? Colors.orangeAccent : Colors.green);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(budget.categoryName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gastado: ${formatter.format(budget.spentAmount)}'),
                Text('Límite: ${formatter.format(budget.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Quedan ${formatter.format(budget.remainingAmount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: budget.remainingAmount < 0 ? Colors.red : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}