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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          final scale = 0.9 + (0.1 * value);
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF33CC), width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Realizar Traspaso',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dirección del traspaso',
                            style: textTheme.labelLarge?.copyWith(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: TransferDirection.values.map((direction) {
                            final isSelected = _direction == direction;
                            return ChoiceChip(
                              label: Text(
                                direction == TransferDirection.toSavings ? 'A Ahorro' : 'Desde Ahorro',
                                style: textTheme.labelLarge?.copyWith(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
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
                              backgroundColor: const Color(0xFF1E1E1E),
                              selectedColor: const Color(0xFFFF33CC),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFFF33CC) : Colors.white24,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          dropdownColor: const Color(0xFF1E1E1E),
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
                        const SizedBox(height: 16),
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
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _DialogOutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      label: 'Cancelar',
                    ),
                    const SizedBox(width: 12),
                    _GradientButton(
                      onPressed: _isLoading ? null : _submitTransfer,
                      isLoading: _isLoading,
                      label: 'Confirmar',
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
    floatingLabelStyle: const TextStyle(color: Colors.white),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF33CC), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
  );
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const _GradientButton({
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
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          )
        : Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.white10,
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: onPressed == null
              ? const LinearGradient(colors: [Colors.white24, Colors.white24])
              : const LinearGradient(
                  colors: [Color(0xFFFF33CC), Color(0xFF8A2BE2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Center(child: buttonChild),
        ),
      ),
    );
  }
}

class _DialogOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const _DialogOutlinedButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF33CC),
        side: const BorderSide(color: Color(0xFFFF33CC), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: const Color(0xFFFF33CC), fontWeight: FontWeight.bold),
      ),
    );
  }
}
