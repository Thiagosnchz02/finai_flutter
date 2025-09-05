import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fixed_expenses/models/fixed_expense_model.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';

class FixedExpenseRow extends StatefulWidget {
  final FixedExpense expense;
  const FixedExpenseRow({super.key, required this.expense});

  @override
  State<FixedExpenseRow> createState() => _FixedExpenseRowState();
}

class _FixedExpenseRowState extends State<FixedExpenseRow> {
  final _service = FixedExpensesService();
  late bool _isActive;
  late bool _notificationEnabled;

  @override
  void initState() {
    super.initState();
    _isActive = widget.expense.isActive;
    _notificationEnabled = widget.expense.notificationEnabled;
  }

  Future<void> _toggle(String field, bool value) async {
    setState(() {
      if (field == 'is_active') {
        _isActive = value;
      } else {
        _notificationEnabled = value;
      }
    });
    await _service.updateToggle(widget.expense.id, field, value);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String status;
    Color statusColor;
    if (widget.expense.lastPaymentProcessedOn != null &&
        widget.expense.lastPaymentProcessedOn!.year == now.year &&
        widget.expense.lastPaymentProcessedOn!.month == now.month) {
      status = 'Pagado';
      statusColor = Colors.green;
    } else if (widget.expense.nextDueDate.isBefore(now)) {
      status = 'Vencido';
      statusColor = Colors.red;
    } else {
      status = 'Pendiente';
      statusColor = Colors.orange;
    }

    return ListTile(
      title: Text(widget.expense.description),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vence: ${DateFormat.yMMMd('es_ES').format(widget.expense.nextDueDate)}'),
          Text(status, style: TextStyle(color: statusColor)),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.expense.amount.toStringAsFixed(2)} €'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: _isActive,
                onChanged: (value) => _toggle('is_active', value),
              ),
              Switch(
                value: _notificationEnabled,
                onChanged: (value) => _toggle('notification_enabled', value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

