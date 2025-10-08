import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryDistributionChart extends StatelessWidget {
  const CategoryDistributionChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parseCategories() {
    final dynamic raw = data['categories'] ?? data['data'] ?? [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((category) => category.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _parseCategories();

    if (categories.isEmpty) {
      return const Center(child: Text('No hay datos de categorías disponibles.'));
    }

    final total = categories.fold<double>(
      0,
      (previousValue, element) =>
          previousValue + (double.tryParse(element['value'].toString()) ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Distribución por categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.2,
            child: PieChart(
              PieChartData(
                sections: List.generate(categories.length, (index) {
                  final category = categories[index];
                  final value =
                      double.tryParse(category['value'].toString()) ?? 0.0;
                  final percentage = total == 0 ? 0 : (value / total) * 100;
                  final color = Colors.primaries[index % Colors.primaries.length];
                  return PieChartSectionData(
                    color: color,
                    value: value,
                    radius: 80,
                    title: '${percentage.toStringAsFixed(1)}%',
                    titleStyle: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(categories.length, (index) {
              final category = categories[index];
              final color = Colors.primaries[index % Colors.primaries.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(category['name']?.toString() ?? 'Sin nombre'),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
