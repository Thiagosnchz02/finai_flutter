// lib/features/transactions/screens/add_edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/transaction_model.dart';
import '../services/transactions_service.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _transactionType = 'gasto';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedFixedExpenseId;

  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  late Future<List<Map<String, dynamic>>> _accountsFuture;
  late Future<List<Map<String, dynamic>>> _fixedExpensesFuture;
  bool _isLoading = false;

  final _eventLogger = EventLoggerService();
  final _transactionsService = TransactionsService();

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _descriptionController.text = tx.description;
      // CORRECCIÓN: Mostramos siempre el valor absoluto en el campo de texto
      _amountController.text = tx.amount.abs().toString();
      _transactionType = tx.type;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.category?.id;
      _selectedAccountId = tx.accountId;
      _selectedFixedExpenseId = tx.relatedScheduledExpenseId;
    }

    _categoriesFuture = _fetchCategories(_transactionType);
    _accountsFuture = _fetchAccounts();
    _fixedExpensesFuture = _fetchFixedExpenses();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchCategories(String transactionType) async {
    try {
      final data = await Supabase.instance.client
        .from('categories')
        .select('id, name')
        .eq('type', transactionType);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('ERROR en _fetchCategories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAccounts() async {
    try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final data = await Supabase.instance.client
            .from('accounts')
            .select('id, name')
            .eq('user_id', userId);
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        print('ERROR en _fetchAccounts: $e');
        return [];
      }
  }

  Future<List<Map<String, dynamic>>> _fetchFixedExpenses() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('scheduled_fixed_expenses')
          .select('id, description')
          .eq('user_id', userId)
          .eq('is_active', true);

      final expenses = List<Map<String, dynamic>>.from(data);

      // Guardamos el id en una variable local para permitir la promoción
      // de nulabilidad y evitar errores de tipo.
      final fixedExpenseId = _selectedFixedExpenseId;
      if (fixedExpenseId != null &&
          !expenses.any((e) => e['id'] == fixedExpenseId)) {
        final inactive = await Supabase.instance.client
            .from('scheduled_fixed_expenses')
            .select('id, description')
            .eq('id', fixedExpenseId)
            .maybeSingle();
        if (inactive != null) {
          expenses.add(Map<String, dynamic>.from(inactive));
        }
      }

      return expenses;
    } catch (e) {
      print('ERROR en _fetchFixedExpenses: $e');
      return [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final bool isEditing = widget.transaction != null;

        final rawAmount =
            double.parse(_amountController.text.replaceAll(',', '.'));

        // Si se seleccionó un gasto fijo y se está creando una nueva transacción,
        // utilizamos la RPC para registrar el pago y evitar duplicados.
        if (_selectedFixedExpenseId != null && !isEditing) {
          final result = await _transactionsService.registerFixedExpensePayment(
            expenseId: _selectedFixedExpenseId!,
            amount: rawAmount.abs(),
            transactionDate: _selectedDate,
            accountId: _selectedAccountId!,
          );

          if (result == 'SUCCESS') {
            _eventLogger.log(
              AppEvent.transaction_created,
              details: {
                'type': _transactionType,
                'amount': -rawAmount.abs(),
              },
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Pago de gasto fijo registrado con éxito'),
                    backgroundColor: Colors.green),
              );
              Navigator.of(context).pop(true);
            }
          } else if (result == 'DUPLICATE') {
            final action = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pago duplicado'),
                content: const Text(
                    'Ya existe un pago para este gasto fijo en este mes.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'replace'),
                      child: const Text('Reemplazar')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, 'additional'),
                      child: const Text('Cargo adicional')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, 'cancel'),
                      child: const Text('Cancelar')),
                ],
              ),
            );

            if (action == 'additional') {
              final retry =
                  await _transactionsService.registerFixedExpensePayment(
                expenseId: _selectedFixedExpenseId!,
                amount: rawAmount.abs(),
                transactionDate: _selectedDate,
                accountId: _selectedAccountId!,
                ignoreDuplicate: true,
              );
              if (retry == 'SUCCESS') {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pago registrado'),
                        backgroundColor: Colors.green),
                  );
                  Navigator.of(context).pop(true);
                }
              }
            }
          }
        } else {
          // --- LÓGICA CORREGIDA AQUÍ ---
          // Si es un gasto, nos aseguramos de que sea negativo. Si es un ingreso, positivo.
          final finalAmount =
              _transactionType == 'gasto' ? -rawAmount.abs() : rawAmount.abs();

          final dataToUpsert = {
            'user_id': userId,
            'description': _descriptionController.text.trim(),
            'amount': finalAmount, // Usamos el importe corregido con el signo correcto
            'transaction_date': _selectedDate.toIso8601String(),
            'type': _transactionType,
            'category_id': _selectedCategoryId,
            'account_id': _selectedAccountId,
            'related_scheduled_expense_id': _selectedFixedExpenseId,
          };

          if (isEditing) {
            dataToUpsert['id'] = widget.transaction!.id;
          }

          final savedTransaction = await Supabase.instance.client
              .from('transactions')
              .upsert(dataToUpsert)
              .select()
              .single();
          final savedTransactionId = savedTransaction['id'];

          if (isEditing) {
            _eventLogger.log(
              AppEvent.transaction_edited,
              details: {'transaction_id': savedTransactionId},
            );
          } else {
            _eventLogger.log(
              AppEvent.transaction_created,
              details: {
                'transaction_id': savedTransactionId,
                'type': _transactionType,
                'amount': finalAmount, // Registramos el importe con su signo
              },
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Transacción guardada con éxito'),
                  backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(true);
          }
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Nueva Transacción' : 'Editar Transacción'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(FontAwesomeIcons.arrowDown)),
                  ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(FontAwesomeIcons.arrowUp)),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    _categoriesFuture = _fetchCategories(_transactionType);
                    _selectedCategoryId = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Introduce una descripción' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Cantidad (€)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introduce una cantidad';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Introduce un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _accountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const ListTile(title: Text('Cuenta'), subtitle: Text('No se encontraron cuentas'));
                  }
                  final accounts = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(labelText: 'Cuenta', border: OutlineInputBorder()),
                    items: accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account['id'] as String,
                        child: Text(account['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedAccountId = value),
                    validator: (value) => value == null ? 'Selecciona una cuenta' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fixedExpensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final expenses = snapshot.data!;
                  if (_selectedFixedExpenseId != null &&
                      !expenses.any((e) => e['id'] == _selectedFixedExpenseId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedFixedExpenseId = null);
                      }
                    });
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedFixedExpenseId,
                    decoration: const InputDecoration(
                        labelText: 'Gasto fijo (opcional)',
                        border: OutlineInputBorder()),
                    items: expenses.map((exp) {
                      return DropdownMenuItem<String>(
                        value: exp['id'] as String,
                        child: Text(exp['description'] as String),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedFixedExpenseId = value),
                  );
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error al cargar categorías');
                  }
                  final categories = snapshot.data;
                  if (categories == null || categories.isEmpty) {
                    return const ListTile(title: Text('Categoría'), subtitle: Text('No hay categorías para este tipo'));
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'] as String,
                        child: Text(category['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                    validator: (value) => value == null ? 'Selecciona una categoría' : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                title: Text('Fecha: ${DateFormat.yMMMd('es_ES').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar Transacción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
