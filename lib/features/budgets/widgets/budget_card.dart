// lib/features/budgets/widgets/budget_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final bool enableRollover;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.enableRollover,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final progressColor = budget.remainingAmount < 0
        ? Colors.redAccent
        : (budget.progress > 0.85
            ? Colors.redAccent
            : (budget.progress > 0.6
                ? Colors.orangeAccent
                : Colors.green));

    IconData statusIcon;
    Color statusColor;
    if (budget.remainingAmount < 0) {
      statusIcon = Icons.error;
      statusColor = Colors.redAccent;
    } else if (budget.progress > 0.85) {
      statusIcon = Icons.warning;
      statusColor = Colors.orangeAccent;
    } else {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(budget.categoryName,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Presupuestado: ${formatter.format(budget.amount)}'),
                  Text('Gastado: ${formatter.format(budget.spentAmount)}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restante: ${formatter.format(budget.remainingAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: budget.remainingAmount < 0
                          ? Colors.redAccent
                          : Colors.green,
                    ),
                  ),
                  if (enableRollover)
                    Text(
                      'Rollover aplicado: ${formatter.format(budget.rolloverAmount)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Mes anterior: ${formatter.format(budget.lastMonthSpent)} de ${formatter.format(budget.lastMonthAmount)}',
                style: Theme.of(context).textTheme.bodySmall,
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: budget.remainingAmount < 0
                          ? Colors.red
                          : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}