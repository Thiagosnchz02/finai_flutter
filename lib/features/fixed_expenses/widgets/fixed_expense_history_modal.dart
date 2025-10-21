import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';
import 'package:finai_flutter/features/transactions/screens/add_edit_transaction_screen.dart';

class FixedExpenseHistoryModal extends StatefulWidget {
  final String expenseId;
  final String expenseName;

  const FixedExpenseHistoryModal({
    super.key,
    required this.expenseId,
    required this.expenseName,
  });

  @override
  State<FixedExpenseHistoryModal> createState() => _FixedExpenseHistoryModalState();
}

class _FixedExpenseHistoryModalState extends State<FixedExpenseHistoryModal> {
  final _service = FixedExpensesService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.getHistory(widget.expenseId);
  }

  void _openTransaction(Map<String, dynamic> item) {
    final amount = (item['amount'] as num).toDouble();
    final tx = Transaction(
      id: item['id'] as String,
      description: item['description'] as String? ?? '',
      amount: amount,
      type: amount >= 0 ? 'ingreso' : 'gasto',
      date: DateTime.parse(item['transaction_date'] as String),
      accountId: null,
      notes: null,
      category: null,
      categoryIcon: null,
    );

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(transaction: tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return AlertDialog(
      title: Text('Historial de "${widget.expenseName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar el historial.'));
            }

            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Center(child: Text('No hay transacciones registradas.'));
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final date = DateTime.parse(item['transaction_date'] as String);
                final amount = (item['amount'] as num).toDouble();
                return ListTile(
                  title: Text(DateFormat.yMMMd('es_ES').format(date)),
                  trailing: Text(formatter.format(amount.abs())),
                  onTap: () => _openTransaction(item),
                );
              },
            );
          },
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

