// lib/features/budgets/widgets/add_edit_budget_dialog.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:finai_flutter/features/budgets/services/budget_service.dart';

/// Dialogo para crear o editar un presupuesto de categoria.
class AddEditBudgetDialog extends StatefulWidget {
  final Budget? budget; // null cuando se crea uno nuevo

  const AddEditBudgetDialog({super.key, this.budget});

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = BudgetService();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  double? _suggestedAmount;

  bool get isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amountController.text = widget.budget!.amount.toString();
      _categoriesFuture = Future.value([
        {'id': widget.budget!.categoryId, 'name': widget.budget!.categoryName}
      ]);
    } else {
      _categoriesFuture = _service.getAvailableCategoriesForBudget();
    }
  }

  Future<void> _onCategoryChanged(String? value) async {
    setState(() {
      _selectedCategoryId = value;
      _suggestedAmount = null;
    });
    if (value != null) {
      final suggestion = await _service.getCategorySpendingSuggestion(value);
      if (mounted) {
        setState(() {
          _suggestedAmount = suggestion;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final now = DateTime.now();

        final data = {
          'user_id': userId,
          'category_id': _selectedCategoryId,
          'amount': double.parse(_amountController.text.replaceAll(',', '.')),
          'start_date': DateTime(now.year, now.month, 1).toIso8601String(),
          'period': 'mensual',
        };

        if (isEditing) {
          data['id'] = widget.budget!.id;
        }

        await _service.saveBudget(data, isEditing);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al guardar: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          final categories = snapshot.data ?? [];

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration:
                        const InputDecoration(labelText: 'Categoría'),
                    onChanged: isEditing ? null : _onCategoryChanged,
                    items: categories
                        .map<DropdownMenuItem<String>>((cat) =>
                            DropdownMenuItem<String>(
                                value: cat['id'] as String,
                                child: Text(cat['name'] as String)))
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                        labelText: 'Límite de Gasto (€)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El límite es obligatorio';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) ==
                          null) {
                        return 'Número no válido';
                      }
                      return null;
                    },
                  ),
                  if (_suggestedAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Sugerencia: €${_suggestedAmount!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBudget,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

