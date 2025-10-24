// lib/features/goals/screens/add_edit_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/features/goals/models/goal_model.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class AddEditGoalScreen extends StatefulWidget {
  final Goal? goal; // Para editar una meta existente
  final ValueChanged<bool>? onLoadingChanged;

  const AddEditGoalScreen({super.key, this.goal, this.onLoadingChanged});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = GoalsService();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _goalType = 'Ahorro';
  DateTime? _targetDate;
  String? _savingsAccountId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service.getPrimarySavingsAccount().then((account) {
      if (!mounted) return;
      if (account != null) {
        setState(() {
          _savingsAccountId = account['id'];
        });
      }
    });

    if (widget.goal != null) {
      // Si estamos editando, poblamos el formulario
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _goalType = widget.goal!.type;
      _targetDate = widget.goal!.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  bool get isLoading => _isLoading;

  Future<void> submit() => _saveGoal();

  InputDecoration _baseDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFD1D5DB)),
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      if (_savingsAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se encontró una cuenta de ahorro principal.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      widget.onLoadingChanged?.call(true);

      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final isEditing = widget.goal != null;

        final data = {
          'user_id': userId,
          'account_id': _savingsAccountId,
          'name': _nameController.text.trim(),
          'type': _goalType,
          'target_amount': double.parse(_targetAmountController.text.replaceAll(',', '.')),
          'target_date': _targetDate?.toIso8601String(),
          'notes': _notesController.text.trim(),
        };

        if (isEditing) {
          data['id'] = widget.goal!.id;
        }

        await _service.saveGoal(data, isEditing);
        if (mounted) Navigator.of(context).pop(true);

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la meta: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onLoadingChanged?.call(false);
        } else {
          widget.onLoadingChanged?.call(false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _baseDecoration('Nombre de la Hucha'),
            validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _targetAmountController,
            style: const TextStyle(color: Colors.white),
            decoration: _baseDecoration('Objetivo (€)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return 'El objetivo es obligatorio';
              if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Introduce un número válido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _goalType,
            dropdownColor: const Color(0xFF1F1235),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: const Color(0xFFD1D5DB),
            decoration: _baseDecoration('Tipo de Hucha'),
            items: ['Ahorro', 'Viaje', 'Fondo de emergencia', 'Otro']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _goalType = value!),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _targetDate == null
                          ? 'Seleccionar fecha objetivo (Opcional)'
                          : 'Fecha Objetivo: ${DateFormat.yMMMd('es_ES').format(_targetDate!)}',
                      style: TextStyle(
                        color: _targetDate == null ? const Color(0xFFD1D5DB) : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Color(0xFFD1D5DB)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            decoration: _baseDecoration('Notas (Opcional)'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class AddEditGoalSheet extends StatefulWidget {
  final Goal? goal;

  const AddEditGoalSheet({super.key, this.goal});

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final GlobalKey<_AddEditGoalScreenState> _formKey = GlobalKey<_AddEditGoalScreenState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF381D74),
              Color(0xFF121212),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16 + viewInsets),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.goal == null ? 'Nueva Hucha' : 'Editar Hucha',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AddEditGoalScreen(
                      key: _formKey,
                      goal: widget.goal,
                      onLoadingChanged: (value) => setState(() => _isLoading = value),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : () => _formKey.currentState?.submit(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF8B5CF6),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Guardar Hucha',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
