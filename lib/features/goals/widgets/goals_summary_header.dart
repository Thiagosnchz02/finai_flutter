// lib/features/goals/widgets/goals_summary_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';

class GoalsSummaryHeader extends StatelessWidget {
  final GoalsSummary summary;

  const GoalsSummaryHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn(
              context,
              'Total Ahorrado',
              summary.totalSavingsBalance,
              Colors.blueAccent,
            ),
            _buildSummaryColumn(
              context,
              'Asignado a Huchas',
              summary.totalAllocated,
              Colors.purpleAccent,
            ),
            _buildSummaryColumn(
              context,
              'Disponible',
              summary.availableToAllocate,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(BuildContext context, String title, double amount, Color color) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}