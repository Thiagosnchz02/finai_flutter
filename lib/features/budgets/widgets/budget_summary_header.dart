// lib/features/budgets/widgets/budget_summary_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';

class BudgetSummaryHeader extends StatelessWidget {
  final BudgetSummary summary;
  final double pendingToAssign;

  const BudgetSummaryHeader({
    super.key,
    required this.summary,
    required this.pendingToAssign,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final normalizedPending = pendingToAssign.abs() < 0.01 ? 0 : pendingToAssign;
    final pendingColor = normalizedPending < 0
        ? Colors.redAccent
        : (normalizedPending == 0 ? Colors.green : Colors.orangeAccent);

    final pendingMessage = normalizedPending < 0
        ? 'Has asignado más dinero del disponible. Reduce algún presupuesto.'
        : (normalizedPending == 0
            ? '¡Todo tu dinero tiene un propósito asignado!'
            : 'Asigna el resto para alcanzar un presupuesto de suma cero.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pendingColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: pendingColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dinero pendiente de asignar',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: pendingColor),
              ),
              const SizedBox(height: 8),
              Text(
                formatter.format(normalizedPending),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: pendingColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                pendingMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: pendingColor.withOpacity(0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                    context, formatter, 'Dinero para asignar', summary.moneyToAssign),
                const SizedBox(height: 12),
                _buildSummaryRow(
                    context, formatter, 'Ya presupuestado', summary.totalBudgeted),
                const SizedBox(height: 12),
                _buildSummaryRow(context, formatter, 'Pendiente al inicio',
                    summary.initiallyPending,
                    muted: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, NumberFormat formatter, String label, double value,
      {bool muted = false}) {
    final textStyle = muted
        ? Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor)
        : Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(
          formatter.format(value),
          style: textStyle,
        ),
      ],
    );
  }
}
