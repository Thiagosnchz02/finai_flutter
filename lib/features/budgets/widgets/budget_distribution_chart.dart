// lib/features/budgets/widgets/budget_distribution_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget_model.dart';

class BudgetDistributionChart extends StatefulWidget {
  final List<Budget> budgets;
  const BudgetDistributionChart({super.key, required this.budgets});

  @override
  State<StatefulWidget> createState() => BudgetDistributionChartState();
}

class BudgetDistributionChartState extends State<BudgetDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.budgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    double totalBudgeted = widget.budgets.fold(0.0, (sum, item) => sum + item.amount);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          final touchedSection = pieTouchResponse?.touchedSection;
                          if (touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }

                          if (event is FlTapUpEvent) {
                            touchedIndex =
                                touchedSection.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2, // Espacio entre secciones
                    centerSpaceRadius: 60, // Radio del agujero central
                    sections: showingSections(),
                  ),
                ),
                // Texto que aparece en el centro al tocar
                if (touchedIndex != -1)
                  _buildCenterText(totalBudgeted)
                else
                  const Text('Toca una sección', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          // Leyenda personalizada debajo del gráfico
          _buildLegend(),
        ],
      ),
    );
  }
  
  // Construye el texto del centro del gráfico
  Widget _buildCenterText(double totalBudgeted) {
    final budget = widget.budgets[touchedIndex];
    final percentage = (budget.amount / totalBudgeted * 100).toStringAsFixed(1);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          budget.categoryName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text('$percentage %'),
      ],
    );
  }

  // Construye la leyenda personalizada
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(widget.budgets.length, (i) {
        final budget = widget.budgets[i];
        final color = Colors.primaries[i % Colors.primaries.length];
        return _Indicator(
          color: color,
          text: budget.categoryName,
          isSquare: false,
          size: touchedIndex == i ? 18 : 16,
          textColor: touchedIndex == i ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
        );
      }),
    );
  }

  // Genera las "rebanadas" del gráfico de dona
  List<PieChartSectionData> showingSections() {
    return List.generate(widget.budgets.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 70.0 : 60.0;
      final color = Colors.primaries[i % Colors.primaries.length];

      return PieChartSectionData(
        color: color,
        value: widget.budgets[i].amount,
        title: '', // No mostramos título en las secciones
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        // Replicamos el borde blanco del ejemplo
        borderSide: isTouched ? const BorderSide(color: Colors.white, width: 4) : const BorderSide(color: Colors.white54, width: 1),
      );
    });
  }
}

// Widget auxiliar para la leyenda
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: textColor))
      ],
    );
  }
}