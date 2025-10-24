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

      // Reemplazar .single() con manejo seguro para evitar crashes
      final response = await _supabase
          .from('accounts')
          .upsert(upsertData, onConflict: isEditing ? 'id' : null)
          .select();

      // Verificar que la respuesta no esté vacía
      if (response.isEmpty) {
        throw Exception('No se pudo guardar la cuenta. La base de datos no devolvió datos.');
      }

      // Obtener el primer resultado de forma segura
      final savedAccount = response.first;
      final savedAccountId = savedAccount['id'] as String;

      // --- INICIO DE LA LÓGICA DE REGISTRO DE EVENTOS ---

      // Registrar eventos con manejo de errores (no bloquean el flujo principal)
      try {
        if (isEditing) {
          // Si estamos editando, registramos el evento de edición.
          await _eventLogger.log(AppEvent.accountEdited, details: {'account_id': savedAccountId});
        } else {
          // Si es una cuenta nueva, registramos el evento de creación.
          await _eventLogger.log(AppEvent.accountCreated, details: {'account_id': savedAccountId});
        }
      } catch (e) {
        // Log del error pero no interrumpe el flujo
        debugPrint('Error al registrar evento: $e');
      }

      // Si se designó como AHORRO, ejecutar el RPC con manejo de errores mejorado
      if (_conceptualType == 'ahorro') {
        try {
          await _supabase.rpc('set_primary_savings_account', params: {
            'p_user_id': userId,
            'p_account_id': savedAccountId,
          });

          // Registrar que esta cuenta ha sido designada como la principal de ahorro.
          try {
            await _eventLogger.log(AppEvent.savingsAccountDesignated, details: {'account_id': savedAccountId});
          } catch (e) {
            debugPrint('Error al registrar evento de ahorro: $e');
          }
        } catch (e) {
          // Mostrar advertencia pero no interrumpir el flujo
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
    final isEditing = widget.account != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF120C2E),
            Color(0xFF2B0B3F),
            Color(0xFF3E0B4D),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF121126).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFF4F9A).withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.arrow_back, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _AccountInputField(
                      label: 'Nombre de la Cuenta',
                      controller: _nameController,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),
                    _AccountInputField(
                      label: 'Nombre del Banco (Opcional)',
                      controller: _bankNameController,
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: 20),
                      _AccountInputField(
                        label: 'Saldo Inicial',
                        controller: _initialBalanceController,
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
                    const Text(
                      '¿Cuál es el propósito de esta cuenta?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ConceptualTypeSelector(
                      selectedValue: _conceptualType,
                      onChanged: (newValue) {
                        setState(() => _conceptualType = newValue);
                      },
                    ),
                    const SizedBox(height: 36),
                    _PrimaryGradientButton(
                      label: 'Guardar Cuenta',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountInputField extends StatelessWidget {
  const _AccountInputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFFF4F9A), width: 1),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFFF6B81), width: 1.5),
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Colors.white,
            ),
            cursorColor: const Color(0xFFFF6BCB),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1B33),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              enabledBorder: baseBorder,
              focusedBorder: baseBorder.copyWith(
                borderSide: const BorderSide(color: Color(0xFFFF6BCB), width: 1.5),
              ),
              errorBorder: errorBorder,
              focusedErrorBorder: errorBorder,
              errorStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFFFB4B4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptualTypeSelector extends StatelessWidget {
  const _ConceptualTypeSelector({
    required this.selectedValue,
    required this.onChanged,
  });

  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      _ConceptualTypeOption(
        value: 'nomina',
        label: 'Para Gastar',
        icon: Icons.payment,
      ),
      _ConceptualTypeOption(
        value: 'ahorro',
        label: 'Para Ahorrar',
        icon: Icons.savings,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in options)
          _FilterChipButton(
            option: option,
            isSelected: option.value == selectedValue,
            onSelected: () => onChanged(option.value),
          ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final _ConceptualTypeOption option;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFFF4F9A);
    final Color inactiveColor = Colors.white.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF4F9A), Color(0xFFFF6BCB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : inactiveColor,
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 18,
                color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConceptualTypeOption {
  const _ConceptualTypeOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1 : 0.7,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4F9A), Color(0xFF9C1AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FF4F9A),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isEnabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: isLoading
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
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}