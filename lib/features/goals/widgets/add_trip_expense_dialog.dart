// lib/features/goals/widgets/add_trip_expense_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class AddTripExpenseDialog extends StatefulWidget {
  final String goalId;
  final String goalName;
  final double goalBalance;

  const AddTripExpenseDialog({
    super.key,
    required this.goalId,
    required this.goalName,
    required this.goalBalance,
  });

  @override
  State<AddTripExpenseDialog> createState() => _AddTripExpenseDialogState();
}

class _AddTripExpenseDialogState extends State<AddTripExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _service = GoalsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        
        await _service.addExpenseToTripGoal(
          goalId: widget.goalId,
          amount: amount,
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gasto de viaje registrado'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
          Navigator.of(context).pop(false);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    return AlertDialog(
      title: Text('Añadir Gasto a "${widget.goalName}"'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo disponible en la hucha: ${formatter.format(widget.goalBalance)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción del Gasto'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Importe del Gasto (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introduce una cantidad';
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null) return 'Número no válido';
                  if (amount <= 0) return 'Debe ser mayor que cero';
                  if (amount > widget.goalBalance) return 'El gasto supera el saldo de la hucha';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitExpense,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrar Gasto'),
        ),
      ],
    );
  }
}