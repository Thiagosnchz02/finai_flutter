import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SavingsGaugeChart extends StatelessWidget {
  const SavingsGaugeChart({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final double target = double.tryParse(data['target'].toString()) ?? 100;
    final double current = double.tryParse(data['current'].toString()) ?? 0;
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Indicador de ahorro',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                        color: Theme.of(context).colorScheme.primary,
                        value: progress * 100,
                        radius: 100,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        value: (1 - progress) * 100,
                        radius: 100,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ahorro actual',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Actual: ${current.toStringAsFixed(2)}'),
          Text('Meta: ${target.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
