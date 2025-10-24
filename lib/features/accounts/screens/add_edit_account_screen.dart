// lib/features/accounts/screens/add_edit_account_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/account_model.dart';

// Colores consistentes con la pantalla de "Mis Cuentas"
const Color _highlightColor = Color(0xFFFF0088);
const Color _selectedBackgroundColor = Color(0x3DFF0088);
const Color _unselectedBackgroundColor = Color(0x1FFF0088);
const Color _inputFillColor = Color(0x1FFFFFFF);

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
        throw Exception('No se pudo guardar la cuenta. La base de datos no devolvió datos.');
      }

      final savedAccount = response.first;
      final savedAccountId = savedAccount['id'] as String;

      try {
        if (isEditing) {
          await _eventLogger.log(AppEvent.accountEdited, details: {'account_id': savedAccountId});
        } else {
          await _eventLogger.log(AppEvent.accountCreated, details: {'account_id': savedAccountId});
        }
      } catch (e) {
        debugPrint('Error al registrar evento: $e');
      }

      if (_conceptualType == 'ahorro') {
        try {
          await _supabase.rpc('set_primary_savings_account', params: {
            'p_user_id': userId,
            'p_account_id': savedAccountId,
          });

          try {
            await _eventLogger.log(AppEvent.savingsAccountDesignated, details: {'account_id': savedAccountId});
          } catch (e) {
            debugPrint('Error al registrar evento de ahorro: $e');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Advertencia: No se pudo establecer como cuenta principal de ahorro: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      final initialBalance = double.tryParse(_initialBalanceController.text.replaceAll(',', '.')) ?? 0.0;
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
          const SnackBar(content: Text('Cuenta guardada con éxito'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la cuenta: $e'), backgroundColor: Colors.red),
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
        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        floatingLabelStyle: const TextStyle(color: _highlightColor, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x66FF0088)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x66FF0088)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _highlightColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
        backgroundColor: const Color(0xFF4D0029),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4D0029), Color(0xFF121212)],
          ),
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
                    validator: (value) =>
                        value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bankNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('Nombre del Banco (Opcional)'),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _initialBalanceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: buildInputDecoration('Saldo Inicial (€)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value.replaceAll(',', '.')) == null) {
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
                        child: TextButton(
                          onPressed: () {
                            if (_conceptualType == 'nomina') return;
                            setState(() => _conceptualType = 'nomina');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            backgroundColor: _conceptualType == 'nomina'
                                ? _selectedBackgroundColor
                                : _unselectedBackgroundColor,
                            foregroundColor: const Color(0xFFE0E0E0),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _conceptualType == 'nomina'
                                    ? _highlightColor
                                    : const Color(0x66FF0088),
                                width: 2,
                              ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (_conceptualType == 'ahorro') return;
                            setState(() => _conceptualType = 'ahorro');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            backgroundColor: _conceptualType == 'ahorro'
                                ? _selectedBackgroundColor
                                : _unselectedBackgroundColor,
                            foregroundColor: const Color(0xFFE0E0E0),
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _conceptualType == 'ahorro'
                                    ? _highlightColor
                                    : const Color(0x66FF0088),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(FontAwesomeIcons.piggyBank, size: 16),
                              const SizedBox(width: 8),
                              const Text('Para Ahorrar'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Botón de guardar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _highlightColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Guardar Cuenta'),
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
