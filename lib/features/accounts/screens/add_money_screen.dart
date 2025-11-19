// lib/features/accounts/screens/add_money_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';

// Colores consistentes con transactions_screen
const Color _purpleAccent = Color(0xFF4a0873);
const Color _inputFillColor = Color(0x12000000);

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key, this.initialAccount});

  final Account? initialAccount;

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _accountsFuture;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  final _eventLogger = EventLoggerService();

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccount?.id;
    _accountsFuture = _fetchSpendingAccounts();
    _categoriesFuture = _fetchIncomeCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchSpendingAccounts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('accounts')
          .select('id, name, conceptual_type')
          .eq('user_id', userId)
          .eq('is_archived', false)
          .neq('conceptual_type', 'ahorro')
          .order('name');
      final accounts = List<Map<String, dynamic>>.from(response);
      if (_selectedAccountId == null && accounts.isNotEmpty) {
        _selectedAccountId = accounts.first['id'] as String?;
      }
      return accounts;
    } catch (error) {
      debugPrint('Error fetching accounts: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchIncomeCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .eq('type', 'ingreso')
          .order('name');
      final categories = List<Map<String, dynamic>>.from(response);
      if (_selectedCategoryId == null && categories.isNotEmpty) {
        _selectedCategoryId = categories.first['id'] as String?;
      }
      return categories;
    } catch (error) {
      debugPrint('Error fetching categories: $error');
      return [];
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _purpleAccent,
              onPrimary: Colors.white,
              surface: const Color(0xFF0A0A0A),
              onSurface: Colors.white,
              secondary: _purpleAccent.withOpacity(0.3),
            ),
            dialogBackgroundColor: const Color(0xFF0A0A0A),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cuenta para continuar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '.'),
      );

      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'description': 'Ingreso manual desde cuentas',
        'amount': amount.abs(),
        'type': 'ingreso',
        'transaction_date': _selectedDate.toIso8601String(),
        'account_id': _selectedAccountId,
        'category_id': _selectedCategoryId,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      await _eventLogger.log(
        AppEvent.transactionCreated,
        details: {
          'type': 'ingreso',
          'amount': amount.abs(),
          'source': 'accounts_add_money',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Ingreso registrado correctamente'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('Error inserting income: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text('Ocurrió un error al guardar el ingreso'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM, yyyy', 'es_ES').format(_selectedDate);

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _inputFillColor,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFFA0AEC0),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: _purpleAccent.withOpacity(0.9),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0x1FFFFFFF),
            width: 0.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0x1FFFFFFF),
            width: 0.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _purpleAccent.withOpacity(0.6),
            width: 0.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Añadir dinero',
          style: TextStyle(
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
              const Color(0xFF000000),
              const Color(0xFF0A0A0A).withOpacity(0.98),
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
                  const SizedBox(height: 8),
                  // Header: Cantidad
                  Row(
                    children: [
                      Icon(
                        Icons.euro_symbol,
                        size: 22,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: buildInputDecoration('0.00'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce una cantidad válida';
                      }
                      final normalized = value.replaceAll('.', '').replaceAll(',', '.');
                      final amount = double.tryParse(normalized);
                      if (amount == null || amount <= 0) {
                        return 'La cantidad debe ser mayor que cero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Cuenta destino
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 22,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cuenta destino',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
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
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF4a0873)),
                        );
                      }
                      final accounts = snapshot.data ?? [];
                      if (accounts.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
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
                            'No tienes cuentas de gasto disponibles.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        decoration: buildInputDecoration(''),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        dropdownColor: const Color(0xFF0A0A0A),
                        iconEnabledColor: _purpleAccent,
                        menuMaxHeight: 300,
                        borderRadius: BorderRadius.circular(14),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<String>(
                            value: acc['id'] as String,
                            child: Text(
                              acc['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedAccountId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Categoría
                  Row(
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 22,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
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
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF4a0873)),
                        );
                      }
                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
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
                            'Crea categorías de ingreso para clasificarlos mejor.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: buildInputDecoration(''),
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
                            child: Text(
                              category['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Header: Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 22,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Fecha del ingreso',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: _inputFillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x1FFFFFFF),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          
                          const SizedBox(width: 12),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: _purpleAccent.withOpacity(0.6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Header: Notas
                  Row(
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 22,
                        color: _purpleAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notas (opcional)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: buildInputDecoration('Añade detalles adicionales'),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(1, 51, 102, 0.12),
                            Color.fromRGBO(74, 144, 226, 0.15),
                            Color.fromRGBO(1, 51, 102, 0.12),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting ? null : _submit,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Registrar ingreso',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
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
