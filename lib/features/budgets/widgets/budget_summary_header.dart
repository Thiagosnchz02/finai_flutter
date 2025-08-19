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
    final isPro = summary.userPlan == 'pro';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo en Cuentas para Gastar:'),
                Text(formatter.format(summary.spendingBalance), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isPro) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comprometido en Gastos Fijos:'),
                  Text('- ${formatter.format(summary.committedFixed)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Disponible para Presupuestar:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  formatter.format(summary.availableToBudget),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}