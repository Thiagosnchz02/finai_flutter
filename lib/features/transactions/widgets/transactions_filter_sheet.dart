import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:finai_flutter/core/utils/icon_utils.dart';

// Colores actualizados para consistencia
const Color _purpleAccent = Color(0xFF4a0873);
const Color _blueButton = Color(0xFF1a266b);
const Color _inputFillColor = Color(0x12000000); // Negro brillante muy sutil (transparente)

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
        floatingLabelStyle: TextStyle(
          fontFamily: 'Inter',
          color: _purpleAccent,
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

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF000000),
                  const Color(0xFF0A0A0A).withOpacity(0.98),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    margin: const EdgeInsets.only(left: 160, right: 160, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Filtros de transacciones',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: [
                      DropdownMenuItem(
                        value: 'todos',
                        child: Text(
                          'Todos',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'gasto',
                        child: Text(
                          'Gasto',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ingreso',
                        child: Text(
                          'Ingreso',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != _type) {
                        _handleTypeChanged(value);
                      }
                    },
                    decoration: buildInputDecoration('Tipo'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    dropdownColor: const Color(0xFF1A1A1A),
                    iconEnabledColor: _purpleAccent,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAmountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: buildInputDecoration('Mínimo').copyWith(
                            prefixText: '€ ',
                            prefixStyle: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFA0AEC0),
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          cursorColor: _purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxAmountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: buildInputDecoration('Máximo').copyWith(
                            prefixText: '€ ',
                            prefixStyle: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFA0AEC0),
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          cursorColor: _purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoadingCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: _purpleAccent),
                      ),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: buildInputDecoration('Categoría'),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Todas las categorías',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        ..._categories.map((category) {
                          final icon =
                              parseIconFromHex(category['icon'] as String?);
                          return DropdownMenuItem<String?>(
                            value: category['id'] as String?,
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category['name'] as String? ?? 'Sin nombre',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      dropdownColor: const Color(0xFF1A1A1A),
                      iconEnabledColor: _purpleAccent,
                      isExpanded: true,
                    ),
                  if (!_isLoadingCategories && _categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No hay categorías disponibles para este tipo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rango de fechas',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFA0AEC0), // Gris Neutro
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _inputFillColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                side: BorderSide(
                                  color: _purpleAccent.withOpacity(0.25),
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => _pickDateRange(),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _buildRangeText(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          if (_startDate != null || _endDate != null)
                            IconButton(
                              tooltip: 'Limpiar fechas',
                              onPressed: _clearDateRange,
                              icon: const Icon(Icons.clear),
                              color: Colors.white70,
                              splashRadius: 24,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _conceptController,
                    decoration: buildInputDecoration('Concepto (opcional)'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    cursorColor: _purpleAccent,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Botón Limpiar con estilo similar a "Guardar transacción"
                      Container(
                        decoration: BoxDecoration(
                          color: _blueButton.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _blueButton.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _clear(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: const Text(
                                'Limpiar',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón Aplicar con estilo similar a "Guardar transacción"
                      Container(
                        decoration: BoxDecoration(
                          color: _blueButton.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _blueButton.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _apply,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: const Text(
                                'Aplicar',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        );
        },
      ),
    );
  }
}

