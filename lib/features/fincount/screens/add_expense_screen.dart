// lib/features/fincount/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:finai_flutter/features/fincount/models/plan_participant_model.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String planId;
  final List<PlanParticipant> participants;

  const AddExpenseScreen({
    super.key,
    required this.planId,
    required this.participants,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _service = FincountService();
  bool _isLoading = false;

  String? _selectedPayerId;
  // Mapa para rastrear quién está incluido en el split
  late Map<String, bool> _splitParticipants;

  @override
  void initState() {
    super.initState();
    // Por defecto, el primer participante es quien paga
    if (widget.participants.isNotEmpty) {
      _selectedPayerId = widget.participants.first.id;
    }
    // Por defecto, todos los participantes están incluidos en el split
    _splitParticipants = {
      for (var p in widget.participants) p.id: true,
    };
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona quién pagó'), backgroundColor: Colors.red),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El importe debe ser mayor que cero'), backgroundColor: Colors.red),
      );
      return;
    }

    // Obtener la lista de IDs de los participantes seleccionados para el split
    final List<String> splitWithIds = _splitParticipants.entries
        .where((entry) => entry.value == true) // Filtra solo los seleccionados
        .map((entry) => entry.key) // Obtiene sus IDs
        .toList();

    if (splitWithIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos un participante para dividir el gasto'), backgroundColor: Colors.red),
      );
      return;
    }

    // Formatear las "shares" para la RPC (tipo 'equal')
    final shares = splitWithIds
        .map((id) => {'participant_id': id})
        .toList();

    setState(() => _isLoading = true);

    try {
      await _service.addExpense(
        planId: widget.planId,
        paidByParticipantId: _selectedPayerId!,
        amount: amount,
        description: _descriptionController.text.trim(),
        splitType: 'equal', // Solo implementamos 'equal' por ahora
        shares: shares,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto añadido con éxito'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Devuelve 'true' para recargar
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir el gasto: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Gasto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Descripción ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción del Gasto'),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            
            // --- Importe ---
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Importe Total', prefixText: '€ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Campo requerido';
                if (double.tryParse(val) == null) return 'Importe inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // --- Quién pagó ---
            DropdownButtonFormField<String>(
              value: _selectedPayerId,
              decoration: const InputDecoration(labelText: 'Pagado por'),
              items: widget.participants.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPayerId = value);
              },
            ),
            const SizedBox(height: 24),
            
            // --- Dividir entre (Partes Iguales) ---
            Text('Dividir entre (partes iguales)', style: Theme.of(context).textTheme.titleMedium),
            ...widget.participants.map((p) {
              return CheckboxListTile(
                title: Text(p.name),
                value: _splitParticipants[p.id],
                onChanged: (bool? value) {
                  setState(() {
                    _splitParticipants[p.id] = value ?? false;
                  });
                },
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // --- Botón Guardar ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar Gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}