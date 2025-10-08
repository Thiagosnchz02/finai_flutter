import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryTrendLineChart extends StatelessWidget {
  const CategoryTrendLineChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  List<Map<String, dynamic>> _parseSeries() {
    final dynamic raw = data['series'] ?? data['data'] ?? [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((series) => series.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }
    return [];
  }

  List<String> _parseLabels(List<Map<String, dynamic>> series) {
    final dynamic labelsRaw = data['labels'];
    if (labelsRaw is List) {
      return labelsRaw.map((label) => label.toString()).toList();
    }

    if (series.isNotEmpty) {
      final points = series.first['points'] ?? series.first['data'];
      if (points is List) {
        return points
            .map((point) =>
                point is Map ? point['label']?.toString() ?? '' : point.toString())
            .toList();
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final series = _parseSeries();
    if (series.isEmpty) {
      return const Center(child: Text('No hay datos de tendencias disponibles.'));
    }

    final labels = _parseLabels(series);
    double maxY = 0;
    double minY = double.infinity;

    final colors = Colors.primaries;

    final List<LineChartBarData> lines = [];

    for (int seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final serie = series[seriesIndex];
      final pointsRaw = serie['points'] ?? serie['data'] ?? [];
      if (pointsRaw is! List) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < pointsRaw.length; i++) {
        final point = pointsRaw[i];
        double? value;
        if (point is Map) {
          value = double.tryParse(point['value'].toString());
        } else {
          value = double.tryParse(point.toString());
        }
        value ??= 0;
        if (value > maxY) maxY = value;
        if (value < minY) minY = value;
        spots.add(FlSpot(i.toDouble(), value));
      }

      lines.add(
        LineChartBarData(
          isCurved: true,
          color: colors[seriesIndex % colors.length],
          barWidth: 3,
          dotData: const FlDotData(show: false),
          spots: spots,
        ),
      );
    }

    if (minY == double.infinity) {
      minY = 0;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Tendencia por categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minY: minY == maxY ? minY * 0.9 : minY * 0.9,
                maxY: maxY == 0 ? 1 : maxY * 1.1,
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
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: lines,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(series.length, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[index % colors.length],
                  ),
                  const SizedBox(width: 8),
                  Text(series[index]['name']?.toString() ?? 'Serie ${index + 1}'),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
