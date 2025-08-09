// lib/features/goals/widgets/add_contribution_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class AddContributionDialog extends StatefulWidget {
  final String goalId;
  final String goalName;
  final double availableToAllocate;

  const AddContributionDialog({
    super.key,
    required this.goalId,
    required this.goalName,
    required this.availableToAllocate,
  });

  @override
  State<AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _service = GoalsService();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitContribution() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        
        await _service.addContribution(
          widget.goalId,
          amount,
          _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aportación realizada con éxito'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // Devolvemos true para indicar éxito
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
      title: Text('Aportar a "${widget.goalName}"'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Disponible para asignar: ${formatter.format(widget.availableToAllocate)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Cantidad a aportar (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduce una cantidad';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null) {
                    return 'Número no válido';
                  }
                  if (amount <= 0) {
                    return 'Debe ser mayor que cero';
                  }
                  if (amount > widget.availableToAllocate) {
                    return 'Fondos insuficientes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas (Opcional)'),
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
          onPressed: _isLoading ? null : _submitContribution,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar Aportación'),
        ),
      ],
    );
  }
}