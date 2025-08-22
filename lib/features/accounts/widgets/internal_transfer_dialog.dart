// lib/features/accounts/widgets/internal_transfer_dialog.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';
import 'package:finai_flutter/features/accounts/services/accounts_service.dart';

// Enum para definir la dirección del traspaso
enum TransferDirection { toSavings, fromSavings }

class InternalTransferDialog extends StatefulWidget {
  final List<Account> spendingAccounts;
  final Account savingsAccount;

  const InternalTransferDialog({
    super.key,
    required this.spendingAccounts,
    required this.savingsAccount,
  });

  @override
  State<InternalTransferDialog> createState() => _InternalTransferDialogState();
}

class _InternalTransferDialogState extends State<InternalTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _service = AccountsService();
  
  // Estado para la nueva lógica
  TransferDirection _direction = TransferDirection.toSavings;
  String? _selectedAccountId; // El ID de la cuenta de gastos seleccionada
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        
        // Determinamos origen y destino según la dirección
        final fromId = _direction == TransferDirection.toSavings ? _selectedAccountId! : widget.savingsAccount.id;
        final toId = _direction == TransferDirection.toSavings ? widget.savingsAccount.id : _selectedAccountId!;

        await _service.executeInternalTransfer(
          fromAccountId: fromId,
          toAccountId: toId,
          amount: amount,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Traspaso realizado con éxito'), backgroundColor: Colors.green),
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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text('Realizar Traspaso'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de dirección del traspaso
              SegmentedButton<TransferDirection>(
                segments: const [
                  ButtonSegment(value: TransferDirection.toSavings, label: Text('A Ahorro')),
                  ButtonSegment(value: TransferDirection.fromSavings, label: Text('Desde Ahorro')),
                ],
                selected: {_direction},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _direction = newSelection.first;
                    _selectedAccountId = null; // Reseteamos la selección al cambiar de dirección
                  });
                },
              ),
              const SizedBox(height: 24),

              // Menú desplegable dinámico
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(labelText: _direction == TransferDirection.toSavings ? 'Desde Cuenta de Gastos' : 'Hacia Cuenta de Gastos'),
                items: widget.spendingAccounts.map((acc) {
                  final balanceText = _direction == TransferDirection.toSavings ? '(${acc.balance.toStringAsFixed(2)} €)' : '';
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} $balanceText'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedAccountId = value),
                validator: (value) => value == null ? 'Selecciona una cuenta' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Cantidad a traspasar (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introduce una cantidad';
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return 'Cantidad no válida';
                  
                  // Validación de saldo
                  if (_selectedAccountId != null) {
                    Account sourceAccount;
                    if (_direction == TransferDirection.toSavings) {
                      sourceAccount = widget.spendingAccounts.firstWhere((acc) => acc.id == _selectedAccountId);
                    } else {
                      sourceAccount = widget.savingsAccount;
                    }
                    if (amount > sourceAccount.balance) {
                      return 'Saldo insuficiente en la cuenta de origen';
                    }
                  }
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
          onPressed: _isLoading ? null : _submitTransfer,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Confirmar'),
        ),
      ],
    );
  }
}