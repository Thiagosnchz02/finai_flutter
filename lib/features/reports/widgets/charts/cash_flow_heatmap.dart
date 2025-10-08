import 'dart:math';

import 'package:flutter/material.dart';

class CashFlowHeatmap extends StatelessWidget {
  const CashFlowHeatmap({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rowsRaw = data['rows'] ?? data['data'] ?? [];
    if (rowsRaw is! List || rowsRaw.isEmpty) {
      return const Center(child: Text('No hay datos de flujo de caja disponibles.'));
    }

    final List<String> rowLabels = [];
    final List<String> columnLabels = [];
    final List<List<double>> values = [];

    for (int rowIndex = 0; rowIndex < rowsRaw.length; rowIndex++) {
      final row = rowsRaw[rowIndex];
      if (row is Map) {
        rowLabels.add(row['label']?.toString() ?? 'Fila ${rowIndex + 1}');
        final rawValues = row['values'] ?? row['data'] ?? [];
        if (rawValues is List) {
          final rowValues = <double>[];
          for (int colIndex = 0; colIndex < rawValues.length; colIndex++) {
            final cell = rawValues[colIndex];
            if (rowIndex == 0) {
              if (cell is Map && cell.containsKey('label')) {
                columnLabels.add(cell['label'].toString());
              } else {
                columnLabels.add('Col ${colIndex + 1}');
              }
            }

            double? value;
            if (cell is Map && cell.containsKey('value')) {
              value = double.tryParse(cell['value'].toString());
            } else {
              value = double.tryParse(cell.toString());
            }
            rowValues.add(value ?? 0);
          }
          values.add(rowValues);
        }
      }
    }

    if (columnLabels.isEmpty && values.isNotEmpty) {
      columnLabels.addAll(List<String>.generate(values.first.length, (index) => 'Col ${index + 1}'));
    }

    double maxValue = 0;
    double minValue = double.infinity;

    for (final row in values) {
      for (final value in row) {
        maxValue = max(maxValue, value);
        minValue = min(minValue, value);
      }
    }

    if (minValue == double.infinity) {
      minValue = 0;
    }

    Color colorForValue(double value) {
      final normalized = maxValue == minValue
          ? 0.5
          : (value - minValue) / (maxValue - minValue);
      return Color.lerp(
            Colors.green.shade50,
            Colors.green.shade700,
            normalized.clamp(0, 1),
          ) ??
          Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Heatmap de flujo de caja',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Periodo')),
                ...columnLabels.map((label) => DataColumn(label: Text(label))),
              ],
              rows: List.generate(values.length, (rowIndex) {
                final cells = <DataCell>[
                  DataCell(Text(rowLabels[rowIndex])),
                ];
                for (final value in values[rowIndex]) {
                  cells.add(
                    DataCell(
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: colorForValue(value),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  );
                }
                return DataRow(cells: cells);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
