// lib/features/accounts/screens/add_edit_account_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/account_model.dart';

// Colores consistentes con transactions_screen
const Color _purpleAccent = Color(0xFF4a0873);
const Color _purpleSelected = Color(0xFF3a0560);
const Color _inputFillColor = Color(0x12000000);

class AddEditAccountScreen extends StatefulWidget {
  final Account? account;

  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _initialBalanceController = TextEditingController(text: '0.00');

  String _conceptualType = 'nomina'; // 'nomina' o 'ahorro'
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  final _eventLogger = EventLoggerService();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _bankNameController.text = widget.account!.bankName ?? '';
      _conceptualType = widget.account!.conceptualType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final isEditing = widget.account != null;

      final upsertData = <String, dynamic>{
        'user_id': userId,
        'name': _nameController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'type': 'corriente',
        'conceptual_type': _conceptualType,
      };

      if (isEditing) {
        upsertData['id'] = widget.account!.id;
      }

      final response = await _supabase
          .from('accounts')
          .upsert(upsertData, onConflict: isEditing ? 'id' : null)
          .select();

      if (response.isEmpty) {
        throw Exception(
          'No se pudo guardar la cuenta. La base de datos no devolvió datos.',
        );
      }

      final savedAccount = response.first;
      final savedAccountId = savedAccount['id'] as String;

      try {
        if (isEditing) {
          await _eventLogger.log(
            AppEvent.accountEdited,
            details: {'account_id': savedAccountId},
          );
        } else {
          await _eventLogger.log(
            AppEvent.accountCreated,
            details: {'account_id': savedAccountId},
          );
        }
      } catch (e) {
        debugPrint('Error al registrar evento: $e');
      }

      if (_conceptualType == 'ahorro') {
        try {
          await _supabase.rpc(
            'set_primary_savings_account',
            params: {'p_user_id': userId, 'p_account_id': savedAccountId},
          );

          try {
            await _eventLogger.log(
              AppEvent.savingsAccountDesignated,
              details: {'account_id': savedAccountId},
            );
          } catch (e) {
            debugPrint('Error al registrar evento de ahorro: $e');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Advertencia: No se pudo establecer como cuenta principal de ahorro: $e',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      final initialBalance =
          double.tryParse(
            _initialBalanceController.text.replaceAll(',', '.'),
          ) ??
          0.0;
      if (!isEditing && initialBalance != 0.0) {
        await _supabase.from('transactions').insert({
          'user_id': userId,
          'account_id': savedAccountId,
          'amount': initialBalance,
          'type': initialBalance > 0 ? 'ingreso' : 'gasto',
          'description': 'Saldo Inicial',
          'transaction_date': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta guardada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la cuenta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _inputFillColor,
        labelStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: _purpleAccent.withOpacity(0.9),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.6),
            width: 0.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF000000),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campos del formulario
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('Nombre de la Cuenta'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bankNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration(
                      'Nombre del Banco (Opcional)',
                    ),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _initialBalanceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: buildInputDecoration('Saldo Inicial (€)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value.replaceAll(',', '.')) ==
                                null) {
                          return 'Introduce un número válido';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Sección de propósito
                  const Text(
                    'Propósito de la cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _conceptualType == 'nomina'
                                ? LinearGradient(
                                    colors: [
                                      _purpleSelected.withOpacity(0.6),
                                      _purpleSelected.withOpacity(0.5),
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
                              color: _conceptualType == 'nomina'
                                  ? _purpleSelected.withOpacity(0.8)
                                  : _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (_conceptualType == 'nomina') return;
                              setState(() => _conceptualType = 'nomina');
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              backgroundColor: Colors.transparent,
                              foregroundColor: _conceptualType == 'nomina'
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FontAwesomeIcons.wallet, size: 16),
                                const SizedBox(width: 8),
                                const Text('Para Gastar'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _conceptualType == 'ahorro'
                                ? LinearGradient(
                                    colors: [
                                      _purpleSelected.withOpacity(0.6),
                                      _purpleSelected.withOpacity(0.5),
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
                              color: _conceptualType == 'ahorro'
                                  ? _purpleSelected.withOpacity(0.8)
                                  : _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (_conceptualType == 'ahorro') return;
                              setState(() => _conceptualType = 'ahorro');
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              backgroundColor: Colors.transparent,
                              foregroundColor: _conceptualType == 'ahorro'
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.piggyBank,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Para Ahorrar'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Botón de guardar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a266b).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1a266b).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _saveAccount,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFFFFF),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Guardar Cuenta',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
