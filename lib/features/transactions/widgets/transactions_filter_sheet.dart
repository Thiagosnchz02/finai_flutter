import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsFilterSheet extends StatefulWidget {
  final String type;
  final double? minAmount;
  final double? maxAmount;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? concept;

  const TransactionsFilterSheet({
    super.key,
    required this.type,
    this.minAmount,
    this.maxAmount,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.concept,
  });

  @override
  State<TransactionsFilterSheet> createState() =>
      _TransactionsFilterSheetState();
}

class _TransactionsFilterSheetState extends State<TransactionsFilterSheet> {
  late String _type;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _categoryController;
  late TextEditingController _conceptController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _minAmountController =
        TextEditingController(text: widget.minAmount?.toString() ?? '');
    _maxAmountController =
        TextEditingController(text: widget.maxAmount?.toString() ?? '');
    _categoryController =
        TextEditingController(text: widget.categoryId ?? '');
    _conceptController =
        TextEditingController(text: widget.concept ?? '');
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _categoryController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _apply() {
    Navigator.of(context).pop({
      'type': _type,
      'minAmount': double.tryParse(_minAmountController.text),
      'maxAmount': double.tryParse(_maxAmountController.text),
      'categoryId':
          _categoryController.text.isEmpty ? null : _categoryController.text,
      'startDate': _startDate,
      'endDate': _endDate,
      'concept':
          _conceptController.text.isEmpty ? null : _conceptController.text,
    });
  }

  void _clear() {
    setState(() {
      _type = 'todos';
      _minAmountController.clear();
      _maxAmountController.clear();
      _categoryController.clear();
      _conceptController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat.yMd();
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            TextField(
              controller: _minAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importe mínimo'),
            ),
            TextField(
              controller: _maxAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Importe máximo'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'ID de categoría'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _pickStartDate,
                    child: Text(_startDate != null
                        ? 'Desde: ${dateFormatter.format(_startDate!)}'
                        : 'Desde'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _pickEndDate,
                    child: Text(_endDate != null
                        ? 'Hasta: ${dateFormatter.format(_endDate!)}'
                        : 'Hasta'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _conceptController,
              decoration: const InputDecoration(labelText: 'Concepto'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clear,
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

