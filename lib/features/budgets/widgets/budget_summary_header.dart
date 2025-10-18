// lib/features/budgets/widgets/budget_summary_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetSummaryHeader extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetSummaryHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final pendingColor = summary.pendingToAssign < 0
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dinero para asignar',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              formatter.format(summary.moneyToAssign),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total presupuestado:'),
                Text(formatter.format(summary.totalBudgeted),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gasto en presupuestos:'),
                Text(
                  formatter.format(summary.totalSpent),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Restante en presupuestos:'),
                Text(
                  formatter.format(summary.totalRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: summary.totalRemaining < 0
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: pendingColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinero pendiente de asignar',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(summary.pendingToAssign),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                            fontWeight: FontWeight.bold, color: pendingColor),
                  ),
                  if (summary.pendingToAssign < 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Has asignado más dinero del disponible. Ajusta tus presupuestos.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}