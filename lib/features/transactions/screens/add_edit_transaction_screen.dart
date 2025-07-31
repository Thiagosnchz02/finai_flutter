import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

// Modelo simple para las categorías que cargaremos en el dropdown
class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});
}

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
  
  // Lista para almacenar las categorías cargadas
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargamos las categorías iniciales (por defecto, las de 'gasto')
    _fetchCategories();

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _descriptionController.text = tx.description;
      _amountController.text = tx.amount.toString();
      _transactionType = tx.type;
      _selectedDate = tx.date;
      // TODO: Implementar la selección de la categoría al editar
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS MEJORADA ---

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      // Reseteamos los datos de categorías para evitar inconsistencias
      _categories = [];
      _selectedCategoryId = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .eq('user_id', userId)
          .eq('type', _transactionType); // <-- Filtramos por el tipo seleccionado
      
      final loadedCategories = response
          .map<Category>((item) => Category(id: item['id'], name: item['name']))
          .toList();
      
      setState(() {
        _categories = loadedCategories;
        _isLoadingCategories = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: ${e.toString()}'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoadingCategories = false;
        });
      }
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
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                  });
                  // --- CAMBIO CLAVE: Volvemos a cargar las categorías ---
                  _fetchCategories();
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
              _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  // Si no hay categorías, mostramos un item deshabilitado
                  items: _categories.isEmpty
                    ? [const DropdownMenuItem(value: null, child: Text('No hay categorías de este tipo'))]
                    : _categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: _categories.isEmpty ? null : (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
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
