// lib/features/dashboard/widgets/goals_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/goals/models/goal_model.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class GoalsDashboardWidget extends StatefulWidget {
  const GoalsDashboardWidget({super.key});

  @override
  State<GoalsDashboardWidget> createState() => _GoalsDashboardWidgetState();
}

class _GoalsDashboardWidgetState extends State<GoalsDashboardWidget> {
  final _service = GoalsService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final summary = await _service.getGoalsSummary();
    final goals = await _service.getGoals();
    return {'summary': summary, 'goals': goals};
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resumen de Metas', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    // Navega a la pantalla de metas
                    Navigator.of(context).pushNamed('/goals');
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar resumen.');
                }
                if (!snapshot.hasData) {
                  return const Text('No hay datos disponibles.');
                }

                final summary = snapshot.data!['summary'] as GoalsSummary;
                final goals = snapshot.data!['goals'] as List<Goal>;
                final activeGoals = goals.where((g) => !g.isArchived).toList();
                final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Asignado a ${activeGoals.length} Huchas:'),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(summary.totalAllocated),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activeGoals.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...activeGoals.take(2).map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: goal.progress),
                          ],
                        ),
                      )),
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}