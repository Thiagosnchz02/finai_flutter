import 'package:flutter/material.dart';

class GoalProjectionView extends StatelessWidget {
  const GoalProjectionView({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parseGoals() {
    final dynamic raw = data['goals'] ?? data['data'] ?? [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((goal) => goal.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final goals = _parseGoals();
    if (goals.isEmpty) {
      return const Center(child: Text('No hay metas para mostrar.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final goal = goals[index];
        final String name = goal['name']?.toString() ?? 'Meta ${index + 1}';
        final double target = double.tryParse(goal['target'].toString()) ?? 0;
        final double current = double.tryParse(goal['current'].toString()) ?? 0;
        final String? projectedDate = goal['projected_date']?.toString();
        final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                Text('Actual: ${current.toStringAsFixed(2)} / Meta: ${target.toStringAsFixed(2)}'),
                if (projectedDate != null && projectedDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Fecha proyectada: $projectedDate'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
