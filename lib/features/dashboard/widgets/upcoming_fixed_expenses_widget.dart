// Archivo a crear: lib/features/dashboard/widgets/upcoming_fixed_expenses_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fixed_expenses/models/fixed_expense_model.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';

class UpcomingFixedExpensesWidget extends StatefulWidget {
  const UpcomingFixedExpensesWidget({super.key});

  @override
  State<UpcomingFixedExpensesWidget> createState() => _UpcomingFixedExpensesWidgetState();
}

class _UpcomingFixedExpensesWidgetState extends State<UpcomingFixedExpensesWidget> {
  final _service = FixedExpensesService();
  late Future<List<FixedExpense>> _upcomingExpensesFuture;

  @override
  void initState() {
    super.initState();
    _upcomingExpensesFuture = _service.getFixedExpenses()
        .then((maps) => maps.map((map) => FixedExpense.fromMap(map)).toList());
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
                Text('Próximos Gastos Fijos', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/fixed-expenses');
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<FixedExpense>>(
              future: _upcomingExpensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar datos.');
                }
                final expenses = snapshot.data?.where((e) => e.isActive).take(3).toList() ?? [];
                if (expenses.isEmpty) {
                  return const Text('No tienes próximos gastos fijos.');
                }

                return Column(
                  children: expenses.map((expense) => ListTile(
                    title: Text(expense.description),
                    trailing: Text('${expense.amount.toStringAsFixed(2)} €'),
                    subtitle: Text('Vence: ${DateFormat.yMMMd('es_ES').format(expense.nextDueDate)}'),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}