import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:finai_flutter/core/utils/icon_utils.dart';

class TransactionsFilterSheet extends StatefulWidget {
  final String type;
  final double? minAmount;
  final double? maxAmount;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? concept;
  final List<Map<String, dynamic>> filteredCategories;
  final Future<List<Map<String, dynamic>>> Function(String type)
      loadCategoriesForType;

  const TransactionsFilterSheet({
    super.key,
    required this.type,
    this.minAmount,
    this.maxAmount,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.concept,
    required this.filteredCategories,
    required this.loadCategoriesForType,
  });

  @override
  State<TransactionsFilterSheet> createState() =>
      _TransactionsFilterSheetState();
}

class _TransactionsFilterSheetState extends State<TransactionsFilterSheet> {
  late String _type;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _conceptController;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<Map<String, dynamic>> _categories;
  String? _selectedCategoryId;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _minAmountController =
        TextEditingController(text: widget.minAmount?.toString() ?? '');
    _maxAmountController =
        TextEditingController(text: widget.maxAmount?.toString() ?? '');
    _conceptController =
        TextEditingController(text: widget.concept ?? '');
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _categories = List<Map<String, dynamic>>.from(widget.filteredCategories);
    final initialCategory = widget.categoryId;
    if (initialCategory != null &&
        _categories.any((category) => category['id'] == initialCategory)) {
      _selectedCategoryId = initialCategory;
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final initialRange =
        _startDate != null && _endDate != null && !_startDate!.isAfter(_endDate!)
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null;

    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange ??
          DateTimeRange(
            start: _startDate ?? _endDate ?? now,
            end: _endDate ?? _startDate ?? now,
          ),
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _handleTypeChanged(String newType) async {
    setState(() {
      _type = newType;
      _isLoadingCategories = true;
    });

    try {
      final categories = await widget.loadCategoriesForType(newType);
      if (!mounted) return;
      setState(() {
        _categories = List<Map<String, dynamic>>.from(categories);
        if (_selectedCategoryId != null &&
            !_categories.any((category) => category['id'] == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _selectedCategoryId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop({
      'type': _type,
      'minAmount':
          double.tryParse(_minAmountController.text.replaceAll(',', '.')),
      'maxAmount':
          double.tryParse(_maxAmountController.text.replaceAll(',', '.')),
      'categoryId': _selectedCategoryId,
      'startDate': _startDate,
      'endDate': _endDate,
      'concept': _conceptController.text.trim().isEmpty
          ? null
          : _conceptController.text.trim(),
    });
  }

  Future<void> _clear() async {
    FocusScope.of(context).unfocus();
    await _handleTypeChanged('todos');
    if (!mounted) return;
    setState(() {
      _minAmountController.clear();
      _maxAmountController.clear();
      _conceptController.clear();
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat.yMd();
    final viewInsets = MediaQuery.of(context).viewInsets;

    String _buildRangeText() {
      if (_startDate != null && _endDate != null) {
        return '${dateFormatter.format(_startDate!)} - ${dateFormatter.format(_endDate!)}';
      }
      if (_startDate != null) {
        return 'Desde: ${dateFormatter.format(_startDate!)}';
      }
      if (_endDate != null) {
        return 'Hasta: ${dateFormatter.format(_endDate!)}';
      }
      return 'Selecciona un rango';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Filtros de transacciones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                      DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                    ],
                    onChanged: (value) {
                      if (value != null && value != _type) {
                        _handleTypeChanged(value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _minAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importe mínimo'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _maxAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importe máximo'),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ..._categories.map((category) {
                          final icon =
                              parseIconFromHex(category['icon'] as String?);
                          return DropdownMenuItem<String?>(
                            value: category['id'] as String?,
                            child: Row(
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category['name'] as String? ?? 'Sin nombre',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      isExpanded: true,
                    ),
                  if (!_isLoadingCategories && _categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No hay categorías disponibles para este tipo.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rango de fechas'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDateRange(),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _buildRangeText(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          if (_startDate != null || _endDate != null)
                            IconButton(
                              tooltip: 'Limpiar fechas',
                              onPressed: _clearDateRange,
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _conceptController,
                    decoration: const InputDecoration(
                      labelText: 'Concepto (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _clear(),
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
        },
      ),
    );
  }
}

