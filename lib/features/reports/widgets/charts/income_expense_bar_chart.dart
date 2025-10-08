import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  const IncomeExpenseBarChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parseData() {
    final dynamic raw = data['data'] ?? data['items'] ?? [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _parseData();
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    final maxY = items.fold<double>(
      0,
      (previous, element) {
        final income = double.tryParse(element['income'].toString()) ?? 0;
        final expense = double.tryParse(element['expense'].toString()) ?? 0;
        return [previous, income, expense].reduce((a, b) => a > b ? a : b);
      },
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Ingresos vs Egresos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, horizontalInterval: maxY / 4),
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= items.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            items[index]['label']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(items.length, (index) {
                  final item = items[index];
                  final income = double.tryParse(item['income'].toString()) ?? 0;
                  final expense = double.tryParse(item['expense'].toString()) ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 8,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: Theme.of(context).colorScheme.primary,
                        width: 14,
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: Theme.of(context).colorScheme.error,
                        width: 14,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            children: [
              _LegendItem(
                color: Theme.of(context).colorScheme.primary,
                label: 'Ingresos',
              ),
              _LegendItem(
                color: Theme.of(context).colorScheme.error,
                label: 'Egresos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
