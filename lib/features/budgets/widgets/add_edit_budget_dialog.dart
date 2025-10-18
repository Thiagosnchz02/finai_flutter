// lib/features/budgets/widgets/add_edit_budget_dialog.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _currencyFormatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
  final _monthFormatter = DateFormat('MMMM yyyy', 'es_ES');

  String? _selectedCategoryId;
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  double? _suggestedAmount;
  bool _isInsightsLoading = false;
  String? _insightsError;
  List<CategorySpendingHistory> _history = [];
  BudgetSummary? _currentSummary;
  StreamSubscription<BudgetSummary>? _summarySubscription;

  bool get isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _summarySubscription =
        _service.watchBudgetSummary().listen((summary) {
      if (mounted) {
        setState(() {
          _currentSummary = summary;
        });
      }
    });

    if (isEditing) {
      _selectedCategoryId = widget.budget!.categoryId;
      _amountController.text = widget.budget!.amount.toString();
      _categoriesFuture = Future.value([
        {'id': widget.budget!.categoryId, 'name': widget.budget!.categoryName}
      ]);
      Future.microtask(() {
        if (mounted) {
          _loadCategoryInsights(widget.budget!.categoryId);
        }
      });
    } else {
      _categoriesFuture = _service.getAvailableCategoriesForBudget();
    }
  }

  Future<void> _onCategoryChanged(String? value) async {
    setState(() {
      _selectedCategoryId = value;
      _suggestedAmount = null;
      _history = [];
      _insightsError = null;
    });
    if (value != null) {
      await _loadCategoryInsights(value);
    }
  }

  Future<void> _loadCategoryInsights(String categoryId) async {
    setState(() {
      _isInsightsLoading = true;
      _insightsError = null;
      _history = [];
      _suggestedAmount = null;
    });

    try {
      final average =
          await _service.getAverageSpendingForCategory(categoryId);
      final history = await _service.getCategorySpendingHistory(categoryId);

      if (!mounted) return;

      setState(() {
        _suggestedAmount = average > 0 ? average : null;
        if (!isEditing &&
            (_amountController.text.isEmpty ||
                double.tryParse(
                        _amountController.text.replaceAll(',', '.')) ==
                    null) &&
            _suggestedAmount != null) {
          _amountController.text =
              _suggestedAmount!.toStringAsFixed(2);
        }
        _history = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _insightsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInsightsLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _summarySubscription?.cancel();
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

        await _service.saveBudget(
          data,
          isEditing: isEditing,
          previousAmount: isEditing ? widget.budget!.amount : 0,
        );
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
    final pending = _currentSummary?.pendingToAssign;
    final availableForEdit = isEditing
        ? (pending ?? 0) + widget.budget!.amount
        : (pending ?? 0);

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
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  if (pending == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (pending != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pendiente de asignar:'),
                        Text(
                          _currencyFormatter.format(pending),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pending < 0
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  if (pending != null) const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                        labelText: 'Límite de Gasto (€)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_formKey.currentState != null) {
                        _formKey.currentState!.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El límite es obligatorio';
                      }
                      final parsed =
                          double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null) {
                        return 'Número no válido';
                      }
                      if (pending != null) {
                        final available = availableForEdit;
                        final difference =
                            isEditing ? parsed - widget.budget!.amount : parsed;
                        if (difference > 0 && difference - 1e-6 > available) {
                          return 'Supera el dinero pendiente de asignar';
                        }
                      }
                      return null;
                    },
                  ),
                  if (_suggestedAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Sugerencia según historial: ${_currencyFormatter.format(_suggestedAmount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_suggestedAmount != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _amountController.text =
                              _suggestedAmount!.toStringAsFixed(2);
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
                        },
                        child: const Text('Usar sugerencia'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Historial de gasto',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isInsightsLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_isInsightsLoading && _insightsError != null)
                    Text(
                      'Error al cargar el historial: $_insightsError',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  if (!_isInsightsLoading && _insightsError == null)
                    _selectedCategoryId == null
                        ? const Text('Selecciona una categoría para ver el historial.')
                        : _history.isEmpty
                            ? const Text(
                                'No hay datos recientes para esta categoría.',
                              )
                            : ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _history.length,
                                separatorBuilder: (_, __) => const Divider(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _history[index];
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _monthFormatter.format(item.month),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      Text(
                                        _currencyFormatter.format(item.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                },
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
          onPressed:
              _isLoading || _currentSummary == null ? null : _saveBudget,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}