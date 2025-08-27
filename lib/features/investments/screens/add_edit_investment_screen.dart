// lib/features/investments/screens/add_edit_investment_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/investments/models/investment_model.dart';
import 'package:finai_flutter/features/investments/services/investments_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditInvestmentScreen extends StatefulWidget {
  final Investment? investment;

  const AddEditInvestmentScreen({super.key, this.investment});

  @override
  State<AddEditInvestmentScreen> createState() => _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState extends State<AddEditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvestmentsService();
  bool get isEditing => widget.investment != null;
  bool _isLoading = false;

  // Controladores del formulario
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _brokerController = TextEditingController();
  final _notesController = TextEditingController();
  String _investmentType = 'Acciones';
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final inv = widget.investment!;
      _nameController.text = inv.name;
      _symbolController.text = inv.symbol ?? '';
      _quantityController.text = inv.quantity.toString();
      _purchasePriceController.text = inv.purchasePrice.toString();
      _currentValueController.text = inv.currentValue.toString();
      _brokerController.text = inv.broker ?? '';
      _notesController.text = inv.notes ?? '';
      _investmentType = inv.type;
      _purchaseDate = inv.purchaseDate;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _brokerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveInvestment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'user_id': Supabase.instance.client.auth.currentUser!.id,
          'type': _investmentType,
          'name': _nameController.text.trim(),
          'symbol': _symbolController.text.trim(),
          'quantity': double.parse(_quantityController.text),
          'purchase_price': double.parse(_purchasePriceController.text),
          'purchase_date': _purchaseDate?.toIso8601String(),
          'current_value': double.parse(_currentValueController.text),
          'broker': _brokerController.text.trim(),
          'notes': _notesController.text.trim(),
        };

        if (isEditing) {
          data['id'] = widget.investment!.id;
        }

        await _service.saveInvestment(data, isEditing);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Inversión' : 'Añadir Inversión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveInvestment,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ... (Aquí irían los TextFormField y Dropdown para cada campo)
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del Activo')),
            TextFormField(controller: _currentValueController, decoration: const InputDecoration(labelText: 'Valor Actual Total (€)'), keyboardType: TextInputType.number),
            // ... (etc.)
          ],
        ),
      ),
    );
  }
}