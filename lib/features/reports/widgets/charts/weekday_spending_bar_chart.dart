import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeekdaySpendingBarChart extends StatelessWidget {
  const WeekdaySpendingBarChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parseItems() {
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
    final items = _parseItems();
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos de gastos por día.'));
    }

    final maxY = items.fold<double>(
      0,
      (previous, element) {
        final value = double.tryParse(element['value'].toString()) ?? 0;
        return value > previous ? value : previous;
      },
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Gasto por día de la semana',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.1,
                barTouchData: BarTouchData(enabled: true),
                gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
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
                  final value = double.tryParse(items[index]['value'].toString()) ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
