import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';


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

  // Controllers y estado para notas y cuentas
  final _notesController = TextEditingController();
  String? _selectedAccountId;
  late Future<List<Map<String, dynamic>>> _accountsFuture;

  String _transactionType = 'gasto';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;

  // Future que manejará la carga de categorías
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargamos las categorías iniciales (por defecto, las de 'gasto')
    _categoriesFuture = _fetchCategories(_transactionType);
    _accountsFuture = _fetchAccounts();

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _descriptionController.text = tx.description;
      _amountController.text = tx.amount.toString();
      _transactionType = tx.type;
      _selectedDate = tx.date;
      // TODO: Implementar la selección de la categoría al editar
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedAccountId = widget.transaction!.accountId;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS MEJORADA ---

  Future<List<Map<String, dynamic>>> _fetchCategories(String transactionType) async {
    print('DEBUG: _fetchCategories llamado para el tipo: $transactionType');
    try {
      final data = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .eq('type', transactionType);
      print('DEBUG: Respuesta de Supabase: $data');
      // Asegúrate de que la conversión es segura.
      final categories = List<Map<String, dynamic>>.from(data);
      print("DEBUG: Categorías procesadas: ${categories.map((c) => c['name']).toList()}");
      return categories;
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

  // --- LÓGICA DE UI Y GUARDADO (sin cambios) ---

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
        final amount = double.parse(_amountController.text.replaceAll(',', '.'));
        final description = _descriptionController.text;

        final dataToUpsert = {
          'user_id': userId,
          'description': description,
          'amount': amount,
          'transaction_date': _selectedDate.toIso8601String(),
          'type': _transactionType,
          'category_id': _selectedCategoryId,
          'account_id': _selectedAccountId,
          'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        };

        if (widget.transaction != null) {
          dataToUpsert['id'] = widget.transaction!.id;
        }

        await Supabase.instance.client.from('transactions').upsert(dataToUpsert);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción guardada con éxito'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
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
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () { /* TODO: Lógica para eliminar */ },
            )
        ],
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
                    // Reinicia el future para que se vuelva a ejecutar con el nuevo tipo
                    _categoriesFuture = _fetchCategories(_transactionType);
                    // Resetea la categoría seleccionada para evitar inconsistencias
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

              // --- WIDGET DE CATEGORÍAS MEJORADO ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  // Caso 1: El future se está ejecutando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Caso 2: El future terminó con un error
                  if (snapshot.hasError) {
                    return const Text('Error al cargar las categorías');
                  }

                  // Caso 3: El future terminó, pero no hay datos o la lista está vacía
                  final categories = snapshot.data;
                  if (categories == null || categories.isEmpty) {
                    return const ListTile(
                      title: Text('Categoría'),
                      subtitle: Text('No hay categorías para este tipo'),
                      trailing: Icon(Icons.arrow_drop_down),
                    );
                  }

                  // Caso 4: El future terminó con éxito y hay datos
                  if (_selectedCategoryId != null && !categories.any((c) => c['id'] == _selectedCategoryId)) {
                      _selectedCategoryId = null;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'] as String,
                        child: Text(category['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                validator: (value) => value == null ? 'Por favor, selecciona una categoría' : null,
                );
              },
              ),

              const SizedBox(height: 20), // Espaciador

              // WIDGET PARA SELECCIONAR LA CUENTA
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _accountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const ListTile(
                      title: Text('Cuenta'),
                      subtitle: Text('No se encontraron cuentas'),
                      trailing: Icon(Icons.error),
                    );
                  }

                  final accounts = snapshot.data!;
                  // Asegurarse de que el ID seleccionado es válido
                  if (_selectedAccountId != null && !accounts.any((acc) => acc['id'] == _selectedAccountId)) {
                      _selectedAccountId = null;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account['id'] as String,
                        child: Text(account['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedAccountId = value),
                    validator: (value) => value == null ? 'Por favor, selecciona una cuenta' : null,
                  );
                },
              ),

              const SizedBox(height: 20), // Espaciador

              // WIDGET PARA LAS NOTAS
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400)
                ),
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
