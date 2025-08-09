// lib/features/goals/screens/add_edit_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/features/goals/models/goal_model.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class AddEditGoalScreen extends StatefulWidget {
  final Goal? goal; // Para editar una meta existente

  const AddEditGoalScreen({super.key, this.goal});

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

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      if (_savingsAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se encontró una cuenta de ahorro principal.'), backgroundColor: Colors.red),
        );
        return;
      }
      
      setState(() => _isLoading = true);

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
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Nueva Hucha' : 'Editar Hucha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveGoal,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre de la Hucha'),
                    validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetAmountController,
                    decoration: const InputDecoration(labelText: 'Objetivo (€)'),
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
                    decoration: const InputDecoration(labelText: 'Tipo de Hucha'),
                    items: ['Ahorro', 'Viaje', 'Fondo de emergencia', 'Otro']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _goalType = value!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(_targetDate == null
                        ? 'Seleccionar fecha objetivo (Opcional)'
                        : 'Fecha Objetivo: ${DateFormat.yMMMd('es_ES').format(_targetDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notas (Opcional)'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
    );
  }
}