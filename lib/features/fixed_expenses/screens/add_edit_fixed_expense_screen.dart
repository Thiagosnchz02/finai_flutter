// Archivo a reemplazar: lib/features/fixed_expenses/screens/add_edit_fixed_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddEditFixedExpenseScreen extends StatefulWidget {
  const AddEditFixedExpenseScreen({super.key});

  @override
  State<AddEditFixedExpenseScreen> createState() => _AddEditFixedExpenseScreenState();
}

class _AddEditFixedExpenseScreenState extends State<AddEditFixedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FixedExpensesService();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedAccountId;
  String _frequency = 'mensual';
  DateTime _nextDueDate = DateTime.now();
  bool _isActive = true;
  bool _notificationEnabled = true;

  bool _isLoading = false;
  late Future<Map<String, dynamic>> _relatedDataFuture;

  @override
  void initState() {
    super.initState();
    _relatedDataFuture = _service.getRelatedData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _nextDueDate) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final data = {
          'user_id': userId,
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text.replaceAll(',', '.')),
          'category_id': _selectedCategoryId,
          'account_id': _selectedAccountId,
          'frequency': _frequency,
          'next_due_date': _nextDueDate.toIso8601String(),
          'is_active': _isActive,
          'notification_enabled': _notificationEnabled,
        };
        await _service.saveFixedExpense(data, false); // Asumimos que es nuevo por simplicidad
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
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
        title: const Text('Nuevo Gasto Fijo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _relatedDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          
          final accounts = snapshot.data?['accounts'] as List<Map<String, dynamic>>? ?? [];
          final categories = snapshot.data?['categories'] as List<Map<String, dynamic>>? ?? [];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Importe (€)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Cuenta de Cargo'),
                  items: accounts.map<DropdownMenuItem<String>>((acc) => DropdownMenuItem(value: acc['id'], child: Text(acc['name']))).toList(),
                  onChanged: (value) => setState(() => _selectedAccountId = value),
                  validator: (value) => value == null ? 'Selecciona una cuenta' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: categories.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['name']))).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: const [
                    DropdownMenuItem(value: 'diario', child: Text('Diario')),
                    DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  onChanged: (value) => setState(() => _frequency = value!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Próximo Vencimiento: ${DateFormat.yMMMd('es_ES').format(_nextDueDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                SwitchListTile(
                  title: const Text('Gasto Activo'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                SwitchListTile(
                  title: const Text('Activar Notificaciones'),
                  value: _notificationEnabled,
                  onChanged: (value) => setState(() => _notificationEnabled = value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}