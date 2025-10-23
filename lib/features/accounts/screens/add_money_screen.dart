// lib/features/accounts/screens/add_money_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';

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
    final theme = Theme.of(context);
    final dateFormatted = DateFormat('d MMM, yyyy', 'es_ES').format(_selectedDate);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4D0029), Color(0xFF121212)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Añadir dinero'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registra un ingreso rápido para tus cuentas de gasto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Cantidad'),
                  const SizedBox(height: 8),
                  _GradientFieldContainer(
                    child: TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Ej. 250',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.euro, color: Colors.white70),
                      ),
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
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Cuenta destino'),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _accountsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final accounts = snapshot.data ?? [];
                      if (accounts.isEmpty) {
                        return const _EmptyHelperMessage(
                          message: 'No tienes cuentas de gasto disponibles.',
                        );
                      }
                      return _GradientFieldContainer(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF341931),
                          iconEnabledColor: Colors.white,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: accounts
                              .map(
                                (acc) => DropdownMenuItem<String>(
                                  value: acc['id'] as String,
                                  child: Text(
                                    acc['name'] as String,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedAccountId = value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Propósito'),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return const _EmptyHelperMessage(
                          message: 'Crea categorías de ingreso para clasificarlos mejor.',
                        );
                      }
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: categories.map((category) {
                          final id = category['id'] as String;
                          final isSelected = id == _selectedCategoryId;
                          return ChoiceChip(
                            label: Text(category['name'] as String),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF72585),
                            backgroundColor: const Color(0x33FFFFFF),
                            onSelected: (_) {
                              setState(() => _selectedCategoryId = id);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Fecha del ingreso'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: _GradientFieldContainer(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Notas (opcional)'),
                  const SizedBox(height: 8),
                  _GradientFieldContainer(
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Añade detalles adicionales',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        backgroundColor: const Color(0xFFF72585),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Registrar ingreso'),
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

class _GradientFieldContainer extends StatelessWidget {
  const _GradientFieldContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0x33F72585), Color(0x3300B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyHelperMessage extends StatelessWidget {
  const _EmptyHelperMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
