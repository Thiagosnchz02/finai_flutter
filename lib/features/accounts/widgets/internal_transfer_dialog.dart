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
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4D0029), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: mediaQuery.viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Título
                Text(
                  'Realizar Traspaso',
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dirección del traspaso',
                        style: textTheme.labelLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (int i = 0; i < TransferDirection.values.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: Builder(
                                  builder: (context) {
                                    final direction = TransferDirection.values[i];
                                    final isSelected = _direction == direction;
                                    return ChoiceChip(
                                      label: Center(
                                        child: Text(
                                          direction == TransferDirection.toSavings
                                              ? 'A Ahorro'
                                              : 'Desde Ahorro',
                                          style: textTheme.labelLarge?.copyWith(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _direction = direction;
                                            _selectedAccountId = null;
                                          });
                                        }
                                      },
                                      showCheckmark: false,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      selectedColor: const Color(0xFFFF0088),
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFFFF0088)
                                              : Colors.white.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        dropdownColor: const Color(0xFF4D0029),
                        style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: _direction == TransferDirection.toSavings
                              ? 'Desde Cuenta de Gastos'
                              : 'Hacia Cuenta de Gastos',
                        ),
                        items: widget.spendingAccounts.map((acc) {
                          final balanceText =
                              _direction == TransferDirection.toSavings ? '(${acc.balance.toStringAsFixed(2)} €)' : '';
                          return DropdownMenuItem(
                            value: acc.id,
                            child: Text(
                              '${acc.name} $balanceText',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedAccountId = value),
                        validator: (value) => value == null ? 'Selecciona una cuenta' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _amountController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(labelText: 'Cantidad a traspasar (€)'),
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
                const SizedBox(height: 32),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: _SheetOutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        label: 'Cancelar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SheetElevatedButton(
                        onPressed: _isLoading ? null : _submitTransfer,
                        isLoading: _isLoading,
                        label: 'Confirmar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(color: Colors.white70),
    floatingLabelStyle: const TextStyle(color: Color(0xFFFF0088)),
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF0088), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
  );
}

class _SheetElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const _SheetElevatedButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.white.withOpacity(0.1) : const Color(0xFFFF0088),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: buttonChild,
    );
  }
}

class _SheetOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const _SheetOutlinedButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(
          color: onPressed == null ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        backgroundColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onPressed == null ? Colors.white.withOpacity(0.3) : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
      ),
    );
  }
}
