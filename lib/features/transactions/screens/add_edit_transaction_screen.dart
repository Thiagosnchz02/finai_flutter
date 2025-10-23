// lib/features/transactions/screens/add_edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/transaction_model.dart';
import '../services/transactions_service.dart';

const Color _highlightColor = Color(0xFFEA00FF);
const Color _selectedBackgroundColor = Color(0x3DEA00FF);
const Color _unselectedBackgroundColor = Color(0x1FEA00FF);
const Color _inputFillColor = Color(0x1FFFFFFF);

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final String initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialType = 'gasto',
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late String _transactionType;
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
    } else {
      final normalizedInitialType = widget.initialType.toLowerCase();
      _transactionType =
          normalizedInitialType == 'ingreso' ? 'ingreso' : 'gasto';
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
              AppEvent.transactionCreated,
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
              AppEvent.transactionEdited,
              details: {'transaction_id': savedTransactionId},
            );
          } else {
            _eventLogger.log(
              AppEvent.transactionCreated,
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
    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _inputFillColor,
        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        floatingLabelStyle: const TextStyle(color: Color(0xFFEA00FF), fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x66EA00FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x66EA00FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEA00FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 12, 56),
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Nueva Transacción' : 'Editar Transacción'),
        backgroundColor: const Color.fromARGB(255, 46, 12, 56),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: const Color.fromARGB(255, 46, 12, 56),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (_transactionType == 'gasto') return;
                            setState(() {
                              _transactionType = 'gasto';
                              _categoriesFuture = _fetchCategories(_transactionType);
                              _selectedCategoryId = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            backgroundColor: _transactionType == 'gasto'
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
                                color: _transactionType == 'gasto'
                                    ? _highlightColor
                                    : const Color(0x66EA00FF),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(FontAwesomeIcons.arrowDown, size: 16),
                              const SizedBox(width: 8),
                              const Text('Gasto'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (_transactionType == 'ingreso') return;
                            setState(() {
                              _transactionType = 'ingreso';
                              _categoriesFuture = _fetchCategories(_transactionType);
                              _selectedCategoryId = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            backgroundColor: _transactionType == 'ingreso'
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
                                color: _transactionType == 'ingreso'
                                    ? _highlightColor
                                    : const Color(0x66EA00FF),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(FontAwesomeIcons.arrowUp, size: 16),
                              const SizedBox(width: 8),
                              const Text('Ingreso'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('Descripción'),
                    validator: (value) => value == null || value.isEmpty ? 'Introduce una descripción' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('Cantidad (€)'),
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
                        return const Center(
                          child: CircularProgressIndicator(color: _highlightColor),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: _unselectedBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66EA00FF), width: 2),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cuenta', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('No se encontraron cuentas', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        );
                      }
                      final accounts = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        decoration: buildInputDecoration('Cuenta'),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2A1237),
                        iconEnabledColor: _highlightColor,
                        items: accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account['id'] as String,
                            child: Text(
                              account['name'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
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
                        return const Center(
                          child: CircularProgressIndicator(color: _highlightColor),
                        );
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
                        decoration: buildInputDecoration('Gasto fijo (opcional)'),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2A1237),
                        iconEnabledColor: _highlightColor,
                        items: expenses.map((exp) {
                          return DropdownMenuItem<String>(
                            value: exp['id'] as String,
                            child: Text(
                              exp['description'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
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
                        return const Center(
                          child: CircularProgressIndicator(color: _highlightColor),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: _unselectedBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66EA00FF), width: 2),
                          ),
                          child: const Text(
                            'Error al cargar categorías',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      final categories = snapshot.data;
                      if (categories == null || categories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: _unselectedBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66EA00FF), width: 2),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Categoría', style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('No hay categorías para este tipo', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: buildInputDecoration('Categoría'),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2A1237),
                        iconEnabledColor: _highlightColor,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'] as String,
                            child: Text(
                              category['name'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                        validator: (value) => value == null ? 'Selecciona una categoría' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: _unselectedBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66EA00FF), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha: ${DateFormat.yMMMd('es_ES').format(_selectedDate)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const Icon(Icons.calendar_today, color: Color(0xFFEA00FF)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
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
                        : const Text('Guardar Transacción'),
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
