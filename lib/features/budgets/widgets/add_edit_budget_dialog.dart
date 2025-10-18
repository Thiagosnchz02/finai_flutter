// lib/features/budgets/widgets/add_edit_budget_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:finai_flutter/features/budgets/services/budget_service.dart';

/// Dialogo para crear o editar un presupuesto de categoria.
class AddEditBudgetDialog extends StatefulWidget {
  final Budget? budget; // null cuando se crea uno nuevo
  final DateTime periodStart;
  final double pendingToAssign;
  final double availableToAssign; // pendiente + presupuesto actual (si edita)

  const AddEditBudgetDialog({
    super.key,
    this.budget,
    required this.periodStart,
    required this.pendingToAssign,
    required this.availableToAssign,
  });

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
  static const int _monthsHistory = 3;

  bool get isEditing => widget.budget != null;

  late final NumberFormat _currencyFormatter;

  @override
  void initState() {
    super.initState();
    _currencyFormatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    if (isEditing) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amountController.text = widget.budget!.amount.toStringAsFixed(2);
      _categoriesFuture = Future.value([
        {'id': widget.budget!.categoryId, 'name': widget.budget!.categoryName}
      ]);
      _loadCategoryAverage(widget.budget!.categoryId, prefillField: false);
    } else {
      _categoriesFuture =
          _service.getAvailableCategoriesForBudget(widget.periodStart);
    }
  }

  Future<void> _onCategoryChanged(String? value) async {
    setState(() {
      _selectedCategoryId = value;
      _suggestedAmount = null;
    });
    if (value != null) {
      await _loadCategoryAverage(value);
    }
  }

  Future<void> _loadCategoryAverage(String categoryId,
      {bool prefillField = true}) async {
    try {
      final suggestion =
          await _service.getAverageSpendingForCategory(categoryId, _monthsHistory);
      if (!mounted) return;
      setState(() {
        _suggestedAmount = suggestion > 0 ? suggestion : null;
        if (!isEditing && prefillField && suggestion > 0) {
          _amountController.text = suggestion.toStringAsFixed(2);
        } else if (!isEditing && prefillField && suggestion == 0) {
          _amountController.clear();
        }
      });
    } catch (_) {
      // Ignoramos el error de sugerencia, el usuario puede introducir manualmente
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
        final parsedAmount =
            double.parse(_amountController.text.replaceAll(',', '.'));

        const tolerance = 0.0001;
        final existingAmount = widget.budget?.amount ?? 0.0;
        final currentPending = widget.pendingToAssign;
        final available = widget.availableToAssign;

        if (currentPending >= -tolerance &&
            parsedAmount > available + tolerance) {
          throw BudgetValidationException(available);
        }

        final newPending = currentPending + (existingAmount - parsedAmount);
        if (newPending < -tolerance) {
          if (currentPending >= -tolerance ||
              newPending < currentPending - tolerance) {
            throw BudgetValidationException(newPending, wouldBeNegative: true);
          }
        }

        await _service.upsertBudget(
          id: widget.budget?.id,
          categoryId: _selectedCategoryId!,
          amount: parsedAmount,
          periodStart: widget.periodStart,
        );
        if (mounted) Navigator.of(context).pop(true);
      } on BudgetValidationException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.orangeAccent),
          );
        }
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        labelText: 'Cantidad a asignar (€)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La cantidad es obligatoria';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) ==
                          null) {
                        return 'Número no válido';
                      }
                      if (_selectedCategoryId == null) {
                        return 'Selecciona una categoría primero';
                      }
                      final parsed =
                          double.parse(value.replaceAll(',', '.'));
                      const tolerance = 0.0001;
                      final existingAmount = widget.budget?.amount ?? 0.0;
                      final currentPending = widget.pendingToAssign;
                      final available = widget.availableToAssign;

                      if (currentPending >= -tolerance &&
                          parsed > available + tolerance) {
                        return 'Solo quedan ${_currencyFormatter.format(available)} por asignar';
                      }

                      final newPending =
                          currentPending + (existingAmount - parsed);

                      if (newPending < -tolerance) {
                        if (currentPending >= -tolerance) {
                          return 'Esta cantidad dejaría el pendiente en ${_currencyFormatter.format(newPending)}';
                        }
                        if (newPending < currentPending - tolerance) {
                          return 'Esta cantidad empeora tu pendiente (${_currencyFormatter.format(newPending)}).';
                        }
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dinero pendiente de asignar: ${_currencyFormatter.format(widget.pendingToAssign)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  _buildProjectedPending(context),
                  if (_suggestedAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Gasto promedio últimos $_monthsHistory meses: ${_currencyFormatter.format(_suggestedAmount!)}',
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

  Widget _buildProjectedPending(BuildContext context) {
    const tolerance = 0.0001;
    final existingAmount = widget.budget?.amount ?? 0.0;
    final currentPending = widget.pendingToAssign;
    final parsed = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final newPending = currentPending + (existingAmount - parsed);
    final projected = newPending;
    final theme = Theme.of(context);

    Color color;
    String message;
    if (projected < -tolerance) {
      if (currentPending < -tolerance && projected > currentPending) {
        color = Colors.orangeAccent;
        message =
            'Seguirás negativo (${_currencyFormatter.format(projected)}), pero estarás mejor que antes.';
      } else {
        color = Colors.redAccent;
        message =
            'Te quedarías con ${_currencyFormatter.format(projected)} por asignar. Reduce el monto.';
      }
    } else if (projected.abs() <= tolerance) {
      color = Colors.green;
      message = '¡Perfecto! Habrás asignado cada euro.';
    } else {
      color = Colors.orangeAccent;
      message =
          'Te quedarían ${_currencyFormatter.format(projected)} por asignar.';
    }

    return Row(
      children: [
        Icon(
          projected < 0
              ? Icons.warning_amber_rounded
              : (projected == 0 ? Icons.check_circle : Icons.info_outline),
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
