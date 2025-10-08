import 'package:flutter/material.dart';

class DateFilterDialog extends StatefulWidget {
  const DateFilterDialog({
    super.key,
    this.initialMonth,
    this.initialYear,
  });

  final int? initialMonth;
  final int? initialYear;

  static Future<Map<String, int>?> show(
    BuildContext context, {
    int? initialMonth,
    int? initialYear,
  }) {
    return showDialog<Map<String, int>?>(
      context: context,
      builder: (_) => DateFilterDialog(
        initialMonth: initialMonth,
        initialYear: initialYear,
      ),
    );
  }

  @override
  State<DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<DateFilterDialog> {
  late int _selectedMonth;
  late int _selectedYear;

  static const List<String> _months = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedMonth = widget.initialMonth ?? now.month;
    _selectedYear = widget.initialYear ?? now.year;
    _years = List<int>.generate(5, (index) => now.year - index);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona el periodo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedMonth,
            decoration: const InputDecoration(labelText: 'Mes'),
            items: List.generate(
              _months.length,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text(_months[index]),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedMonth = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedYear,
            decoration: const InputDecoration(labelText: 'Año'),
            items: _years
                .map(
                  (year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedYear = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'month': _selectedMonth,
              'year': _selectedYear,
            });
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}
