// lib/features/fixed_expenses/widgets/expense_day_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fixed_expenses/models/fixed_expense_model.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';

class ExpenseDayDetailsDialog extends StatelessWidget {
  final List<FixedExpense> expenses;
  final DateTime selectedDay;

  const ExpenseDayDetailsDialog({
    super.key,
    required this.expenses,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Gastos del ${DateFormat.yMMMd('es_ES').format(selectedDay)}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            return _ExpenseDetailsView(expense: expenses[index]);
          },
          separatorBuilder: (context, index) => const Divider(height: 24),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _ExpenseDetailsView extends StatefulWidget {
  final FixedExpense expense;
  const _ExpenseDetailsView({required this.expense});

  @override
  State<_ExpenseDetailsView> createState() => _ExpenseDetailsViewState();
}

class _ExpenseDetailsViewState extends State<_ExpenseDetailsView> {
  final _service = FixedExpensesService();
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _service.getExpenseDetails(widget.expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.expense.description, style: Theme.of(context).textTheme.titleLarge),
        Text('${formatter.format(widget.expense.amount)} / ${widget.expense.frequency}', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('No se pudieron cargar los detalles.');
            }

            final details = snapshot.data!;
            final totalPaid = (details['total_paid_so_far'] as num).toDouble();
            final annualTotal = (details['estimated_annual_total'] as num).toDouble();
            final recentPayments = List<Map<String, dynamic>>.from(details['recent_payments']);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Total Pagado Histórico:', formatter.format(totalPaid)),
                _buildDetailRow('Estimado Anual:', formatter.format(annualTotal)),
                const SizedBox(height: 8),
                Text('Últimos Pagos:', style: Theme.of(context).textTheme.titleSmall),
                if (recentPayments.isEmpty)
                  const Text('No hay pagos registrados.', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...recentPayments.map((payment) {
                    final date = DateFormat.yMd('es_ES').format(DateTime.parse(payment['transaction_date']));
                    final amount = formatter.format((payment['amount'] as num).abs());
                    return Text('- $amount el $date');
                  }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}