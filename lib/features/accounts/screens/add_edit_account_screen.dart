// lib/features/accounts/screens/add_edit_account_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/account_model.dart'; // Asegúrate que la ruta sea correcta

class AddEditAccountScreen extends StatefulWidget {
  final Account? account; // Recibe una cuenta para editar (opcional)

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
      final isEditing = widget.account != null; // Saber si estamos editando
      
      final upsertData = {
        'user_id': userId,
        'name': _nameController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'type': 'corriente',
        'conceptual_type': _conceptualType,
      };

      if (isEditing) {
        upsertData['id'] = widget.account!.id;
      }

      final savedAccount = await _supabase.from('accounts').upsert(upsertData).select().single();
      final savedAccountId = savedAccount['id'];

      // --- INICIO DE LA LÓGICA DE REGISTRO DE EVENTOS ---
      
      if (isEditing) {
        // Si estamos editando, registramos el evento de edición.
        _eventLogger.log(AppEvent.accountEdited, details: {'account_id': savedAccountId});
      } else {
        // Si es una cuenta nueva, registramos el evento de creación.
        _eventLogger.log(AppEvent.accountCreated, details: {'account_id': savedAccountId});
      }

      // Si se designó como AHORRO, registramos este evento tan importante.
      if (_conceptualType == 'ahorro') {
        await _supabase.rpc('set_primary_savings_account', params: {
          'p_user_id': userId,
          'p_account_id': savedAccountId,
        });
        
        // Registrar que esta cuenta ha sido designada como la principal de ahorro.
        _eventLogger.log(AppEvent.savingsAccountDesignated, details: {'account_id': savedAccountId});
      }
      
      // --- FIN DE LA LÓGICA DE REGISTRO DE EVENTOS ---

      // La lógica de la transacción de saldo inicial se mantiene igual
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Nueva Cuenta' : 'Editar Cuenta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Cuenta'),
              validator: (value) => value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Banco (Opcional)'),
            ),
            if (widget.account == null) ...[ // Solo para cuentas nuevas
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                decoration: const InputDecoration(labelText: 'Saldo Inicial'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Introduce un número válido';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            const Text('¿Cuál es el propósito de esta cuenta?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'nomina', label: Text('Para Gastar'), icon: Icon(Icons.payment)),
                ButtonSegment(value: 'ahorro', label: Text('Para Ahorrar'), icon: Icon(Icons.savings)),
              ],
              selected: {_conceptualType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _conceptualType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAccount,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar Cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}