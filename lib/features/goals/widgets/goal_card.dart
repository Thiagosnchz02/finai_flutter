// lib/features/goals/widgets/goal_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onContribute;
  final VoidCallback onAddExpense;
  final VoidCallback onArchive;
  final VoidCallback onViewHistory; // <-- 1. NUEVO CALLBACK

  const GoalCard({
    super.key,
    required this.goal,
    required this.onContribute,
    required this.onAddExpense,
    required this.onArchive,
    required this.onViewHistory, // <-- 2. AÑADIR AL CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    // ... (build sin cambios hasta el PopupMenuButton)
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final isCompleted = goal.progress >= 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(goal.name, style: Theme.of(context).textTheme.titleLarge)),
                // 3. AÑADIMOS LA NUEVA OPCIÓN AL MENÚ
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'archive') {
                      onArchive();
                    } else if (value == 'history') {
                      onViewHistory();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'history',
                      child: Text('Ver Historial'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'archive',
                      child: Text('Archivar Meta'),
                    ),
                  ],
                ),
              ],
            ),
            // ... (el resto del widget no cambia)
             const SizedBox(height: 4),
            Text(goal.type, style: Theme.of(context).textTheme.bodySmall),
            if (isCompleted) ...[
              const SizedBox(height: 8),
              Chip(
                label: const Text('¡Meta Conseguida!'),
                backgroundColor: Colors.green.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.green),
              )
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatter.format(goal.currentAmount)),
                Text(formatter.format(goal.targetAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(goal.progress * 100).toStringAsFixed(0)}% completado'),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (goal.type == 'Viaje')
                  OutlinedButton(
                    onPressed: onAddExpense,
                    child: const Text('Añadir Gasto'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isCompleted ? null : onContribute,
                  child: const Text('Aportar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}