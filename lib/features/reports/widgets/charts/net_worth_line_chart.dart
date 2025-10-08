import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parsePoints() {
    final dynamic raw = data['data'] ?? data['points'] ?? [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((point) => point.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final points = _parsePoints();

    if (points.isEmpty) {
      return const Center(child: Text('No hay datos de patrimonio disponibles.'));
    }

    final spots = List.generate(points.length, (index) {
      final value = double.tryParse(points[index]['value'].toString()) ?? 0;
      return FlSpot(index.toDouble(), value);
    });

    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Patrimonio neto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minY: minY * 0.9,
                maxY: maxY * 1.1,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            points[index]['label']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    spots: spots,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
