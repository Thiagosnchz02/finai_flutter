// lib/features/accounts/widgets/internal_transfer_dialog.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';
import 'package:finai_flutter/features/accounts/services/accounts_service.dart';

// Enum para definir la dirección del traspaso
enum TransferDirection { toSavings, fromSavings }

// Constantes de color para mantener consistencia
const Color _purpleAccent = Color(0xFF4a0873);
const Color _inputFillColor = Color(0x12000000);

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
        // Ya no necesitamos _selectedAccountId, usamos la primera cuenta disponible
        String fromId, toId;
        
        if (_direction == TransferDirection.toSavings) {
          // De gasto a ahorro: usar la primera cuenta de gasto con suficiente saldo
          final sourceAccount = widget.spendingAccounts.firstWhere(
            (acc) => acc.balance >= amount,
            orElse: () => widget.spendingAccounts.first,
          );
          fromId = sourceAccount.id;
          toId = widget.savingsAccount.id;
        } else {
          // De ahorro a gasto: usar la primera cuenta de gasto disponible
          fromId = widget.savingsAccount.id;
          toId = widget.spendingAccounts.first.id;
        }

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
          colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
          stops: [0.0, 0.98],
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
                    fontFamily: 'Inter',
                    color: const Color(0xFFE0E0E0),
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
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
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _direction == TransferDirection.toSavings
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF7d0ab8).withOpacity(0.6),
                                          const Color(0xFF7d0ab8).withOpacity(0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          _purpleAccent.withOpacity(0.15),
                                          _purpleAccent.withOpacity(0.12),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _direction == TransferDirection.toSavings
                                      ? const Color(0xFF7d0ab8).withOpacity(0.8)
                                      : _purpleAccent.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  if (_direction == TransferDirection.toSavings) return;
                                  setState(() {
                                    _direction = TransferDirection.toSavings;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: _direction == TransferDirection.toSavings
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF6B6B6B),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('A Ahorro'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _direction == TransferDirection.fromSavings
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF7d0ab8).withOpacity(0.6),
                                          const Color(0xFF7d0ab8).withOpacity(0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          _purpleAccent.withOpacity(0.15),
                                          _purpleAccent.withOpacity(0.12),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _direction == TransferDirection.fromSavings
                                      ? const Color(0xFF7d0ab8).withOpacity(0.8)
                                      : _purpleAccent.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  if (_direction == TransferDirection.fromSavings) return;
                                  setState(() {
                                    _direction = TransferDirection.fromSavings;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: _direction == TransferDirection.fromSavings
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF6B6B6B),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Desde Ahorro'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _amountController,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(labelText: 'Cantidad a traspasar (€)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Introduce una cantidad';
                          final amount = double.tryParse(value.replaceAll(',', '.'));
                          if (amount == null || amount <= 0) return 'Cantidad no válida';

                          // Validación de saldo
                          Account sourceAccount;
                          if (_direction == TransferDirection.toSavings) {
                            // De gasto a ahorro: verificar que haya alguna cuenta de gasto con saldo
                            final accountsWithBalance = widget.spendingAccounts.where((acc) => acc.balance >= amount).toList();
                            if (accountsWithBalance.isEmpty) {
                              return 'Saldo insuficiente en las cuentas de gasto';
                            }
                          } else {
                            // De ahorro a gasto: verificar cuenta de ahorro
                            sourceAccount = widget.savingsAccount;
                            if (amount > sourceAccount.balance) {
                              return 'Saldo insuficiente en la cuenta de ahorro';
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
    filled: true,
    fillColor: _inputFillColor,
    labelStyle: const TextStyle(
      fontFamily: 'Inter',
      color: Color(0xFFA0AEC0),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    floatingLabelStyle: TextStyle(
      color: _purpleAccent.withOpacity(0.9),
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0x1FFFFFFF),
        width: 0.6,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0x1FFFFFFF),
        width: 0.6,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _purpleAccent.withOpacity(0.6),
        width: 0.8,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 0.6),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 0.8),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    errorStyle: const TextStyle(
      color: Colors.redAccent,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
    ),
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
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          );

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(1, 51, 102, 0.12),
            Color.fromRGBO(74, 144, 226, 0.15),
            Color.fromRGBO(1, 51, 102, 0.12),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.25),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(child: buttonChild),
        ),
      ),
    );
  }
}

class _SheetOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const _SheetOutlinedButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF000000).withOpacity(0.88),
            const Color(0xFF0D0D0D).withOpacity(0.92),
            const Color(0xFF000000).withOpacity(0.88),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFFFFFFF).withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: -4,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: const Color(0xFF700aa3).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 0),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF9E9E9E),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
