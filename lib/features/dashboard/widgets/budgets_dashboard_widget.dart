// lib/features/dashboard/widgets/budgets_dashboard_widget.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:finai_flutter/features/budgets/services/budget_service.dart';
import 'package:intl/intl.dart';

class BudgetsDashboardWidget extends StatefulWidget {
  const BudgetsDashboardWidget({super.key});

  @override
  State<BudgetsDashboardWidget> createState() => _BudgetsDashboardWidgetState();
}

class _BudgetsDashboardWidgetState extends State<BudgetsDashboardWidget> {
  final _service = BudgetService();
  late Future<List<Budget>> _budgetsFuture;

  IconData _parseIcon(String? iconStr) {
    if (iconStr == null) return Icons.category;
    try {
      final cleaned = iconStr.startsWith('0x') ? iconStr.substring(2) : iconStr;
      final codePoint = int.parse(cleaned, radix: 16);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (_) {
      return Icons.category;
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    _budgetsFuture = _service.getBudgetsForPeriod(periodStart);
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
                // CORRECCIÓN: Envolvemos el título en un Expanded
                Expanded(
                  child: Text('Resumen de Presupuestos', style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/budgets'),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Budget>>(
              future: _budgetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar datos.');
                }
                final budgets = snapshot.data ?? [];
                if (budgets.isEmpty) {
                  return const Text('No hay presupuestos este mes.');
                }
                
                // Mostramos los 3 presupuestos con mayor progreso
                budgets.sort((a, b) => b.progress.compareTo(a.progress));
                final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

                return Column(
                  children: budgets.take(3).map((budget) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_parseIcon(budget.categoryIcon)),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                budget.categoryName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${(budget.progress * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: budget.progress),
                            const SizedBox(height: 4),
                            Text(
                              '${formatter.format(budget.spentAmount)} / ${formatter.format(budget.amount)}',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
