// lib/features/transactions/screens/add_edit_transaction_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/transaction_model.dart';
import '../services/transactions_service.dart';

// Colores actualizados para consistencia con transactions_screen
const Color _purpleAccent = Color(0xFF4a0873); // Morado de la pantalla principal
const Color _purpleSelected = Color(0xFF3a0560); // Morado más oscuro para seleccionado
const Color _inputFillColor = Color(0x12000000); // Negro brillante muy sutil (transparente)

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
      // Tema personalizado estilo iOS moderno
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _purpleAccent, // Color de selección
              onPrimary: Colors.white, // Texto sobre color primario
              surface: const Color(0xFF0A0A0A), // Fondo del calendario (negro brillante)
              onSurface: Colors.white, // Texto sobre superficie
              secondary: _purpleAccent.withOpacity(0.3), // Color secundario
            ),
            dialogBackgroundColor: const Color(0xFF0A0A0A), // Fondo del diálogo (negro brillante)
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 255, 255, 255), // blanco para botones Cancel y OK
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            // Estilo del encabezado del calendario
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFF0A0A0A), // Fondo negro brillante
              elevation: 8,
            ),
            // Color del icono de editar en azul oscuro
            iconTheme: const IconThemeData(
              color: Color(0xFF1E3A8A), // Azul oscuro para el icono de editar
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Muestra un SnackBar elegante con animación para mensajes de éxito
  void _showSuccessSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF25C9A4).withOpacity(0.3),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25C9A4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF25C9A4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remover después de 3 segundos con animación de salida
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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
            _showSuccessSnackBar('Transacción guardada con éxito');
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
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFFA0AEC0), // Gris Neutro
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF4a0873), // Morado
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.6),
            width: 0.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Negro puro brillante
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Nueva Transacción' : 'Editar Transacción',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF000000),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF000000), // Negro puro
              const Color(0xFF0A0A0A).withOpacity(0.98), // Negro ligeramente más claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _transactionType == 'gasto'
                                ? LinearGradient(
                                    colors: [
                                      _purpleSelected.withOpacity(0.6),
                                      _purpleSelected.withOpacity(0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      _purpleAccent.withOpacity(0.15),
                                      _purpleAccent.withOpacity(0.12),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _transactionType == 'gasto'
                                  ? _purpleSelected.withOpacity(0.8)
                                  : _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
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
                              backgroundColor: Colors.transparent,
                              foregroundColor: _transactionType == 'gasto'
                                  ? const Color(0xFF9E9E9E)
                                  : const Color(0xFF6B6B6B),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.arrowDown,
                                  size: 14,
                                  color: _transactionType == 'gasto'
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF6B6B6B),
                                ),
                                const SizedBox(width: 8),
                                const Text('Gasto'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _transactionType == 'ingreso'
                                ? LinearGradient(
                                    colors: [
                                      _purpleSelected.withOpacity(0.6),
                                      _purpleSelected.withOpacity(0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      _purpleAccent.withOpacity(0.15),
                                      _purpleAccent.withOpacity(0.12),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _transactionType == 'ingreso'
                                  ? _purpleSelected.withOpacity(0.8)
                                  : _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
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
                              backgroundColor: Colors.transparent,
                              foregroundColor: _transactionType == 'ingreso'
                                  ? const Color(0xFF9E9E9E)
                                  : const Color(0xFF6B6B6B),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.arrowUp,
                                  size: 14,
                                  color: _transactionType == 'ingreso'
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF6B6B6B),
                                ),
                                const SizedBox(width: 8),
                                const Text('Ingreso'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Header: Descripción
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('Ej: Compra supermercado').copyWith(
                      prefixIcon: Icon(
                        Icons.text_fields,
                        size: 20,
                        color: Color(0xFFA0AEC0),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Introduce una descripción' : null,
                  ),
                  const SizedBox(height: 24),
                  // Header: Cantidad
                  Row(
                    children: [
                      Icon(
                        Icons.euro_symbol,
                        size: 18,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInputDecoration('0.00').copyWith(
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: Color(0xFFA0AEC0),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Introduce una cantidad';
                      if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Introduce un número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Cuenta
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cuenta',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _accountsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _purpleAccent),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _purpleAccent.withOpacity(0.15),
                                _purpleAccent.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
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
                        decoration: buildInputDecoration('Seleccionar cuenta').copyWith(
                          prefixIcon: Icon(
                            Icons.credit_card,
                            size: 20,
                            color: Color(0xFFA0AEC0),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        dropdownColor: const Color(0xFF0A0A0A),
                        iconEnabledColor: _purpleAccent,
                        // Radio personalizado para dropdown
                        menuMaxHeight: 300,
                        borderRadius: BorderRadius.circular(14),
                        items: accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account['id'] as String,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _purpleAccent.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  account['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedAccountId = value),
                        validator: (value) => value == null ? 'Selecciona una cuenta' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Gasto fijo (condicional)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fixedExpensesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _purpleAccent),
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: _purpleAccent.withOpacity(0.8),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Gasto fijo (opcional)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedFixedExpenseId,
                            decoration: buildInputDecoration('Ninguno').copyWith(
                              prefixIcon: Icon(
                                Icons.repeat,
                                size: 20,
                                color: Color(0xFFA0AEC0),
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            dropdownColor: const Color(0xFF0A0A0A),
                            iconEnabledColor: _purpleAccent,
                            menuMaxHeight: 300,
                            borderRadius: BorderRadius.circular(14),
                            items: expenses.map((exp) {
                              return DropdownMenuItem<String>(
                                value: exp['id'] as String,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _purpleAccent.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      exp['description'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedFixedExpenseId = value),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  // Header: Categoría
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 18,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _purpleAccent),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _purpleAccent.withOpacity(0.15),
                                _purpleAccent.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Error al cargar categorías',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      final categories = snapshot.data;
                      if (categories == null || categories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _purpleAccent.withOpacity(0.15),
                                _purpleAccent.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _purpleAccent.withOpacity(0.25),
                              width: 0.8,
                            ),
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
                        decoration: buildInputDecoration('Seleccionar categoría').copyWith(
                          prefixIcon: Icon(
                            Icons.label_outline,
                            size: 20,
                            color: Color(0xFFA0AEC0),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        dropdownColor: const Color(0xFF0A0A0A),
                        iconEnabledColor: _purpleAccent,
                        menuMaxHeight: 300,
                        borderRadius: BorderRadius.circular(14),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'] as String,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _purpleAccent.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                        validator: (value) => value == null ? 'Selecciona una categoría' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Fecha',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _purpleAccent.withOpacity(0.15),
                            _purpleAccent.withOpacity(0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _purpleAccent.withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: Color(0xFFA0AEC0),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat.yMMMd('es_ES').format(_selectedDate),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _purpleAccent,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a266b).withOpacity(0.2), // Azul casi transparente
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1a266b).withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _isLoading ? null : _saveTransaction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFFFFF),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Guardar Transacción',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFFFFF),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
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
