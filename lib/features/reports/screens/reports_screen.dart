// lib/features/reports/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/reports/services/reports_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = ReportsService();
  bool _isLoading = false;

  // Estado de los filtros
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _transactionType = 'all';
  String _selectedAccountId = 'all';
  String _selectedCategoryId = 'all';
  String _selectedGoalId = 'all';

  late Future<Map<String, List<Map<String, dynamic>>>> _filtersDataFuture;

  @override
  void initState() {
    super.initState();
    _filtersDataFuture = _loadFiltersData();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadFiltersData() async {
    final accounts = await _service.getAccounts();
    final categories = await _service.getCategories();
    final goals = await _service.getGoals();
    return {'accounts': accounts, 'categories': categories, 'goals': goals};
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      final filters = {
        'dateFrom': _dateFrom?.toIso8601String(),
        'dateTo': _dateTo?.toIso8601String(),
        'type': _transactionType,
        'accountId': _selectedAccountId,
        'categoryId': _selectedCategoryId,
        'goalId': _selectedGoalId,
      };
      
      // Eliminamos filtros nulos o 'all'
      filters.removeWhere((key, value) => value == null || value == 'all');
      
      await _service.generateReport(filters);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe descargado y abierto.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // Helper para mostrar DatePicker
  Future<DateTime?> _selectDate(BuildContext context, DateTime initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Informe'),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _filtersDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar filtros: ${snapshot.error}'));
          }

          final accounts = snapshot.data?['accounts'] ?? [];
          final categories = snapshot.data?['categories'] ?? [];
          final goals = snapshot.data?['goals'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Filtrar Transacciones', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),

              // Filtros de Fecha
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Desde: ${_dateFrom == null ? 'Inicio' : DateFormat.yMd('es_ES').format(_dateFrom!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await _selectDate(context, _dateFrom ?? DateTime.now());
                        if (date != null) setState(() => _dateFrom = date);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Hasta: ${_dateTo == null ? 'Ahora' : DateFormat.yMd('es_ES').format(_dateTo!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await _selectDate(context, _dateTo ?? DateTime.now());
                        if (date != null) setState(() => _dateTo = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Dropdowns de filtros
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(labelText: 'Tipo de Transacción'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todos')),
                  DropdownMenuItem(value: 'gasto', child: Text('Gastos')),
                  DropdownMenuItem(value: 'ingreso', child: Text('Ingresos')),
                ],
                onChanged: (value) => setState(() => _transactionType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(labelText: 'Cuenta'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todas')),
                  ...accounts.map((acc) => DropdownMenuItem(value: acc['id'], child: Text(acc['name']))),
                ],
                onChanged: (value) => setState(() => _selectedAccountId = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todas')),
                  ...categories.map((cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['name']))),
                ],
                onChanged: (value) => setState(() => _selectedCategoryId = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGoalId,
                decoration: const InputDecoration(labelText: 'Hucha (Meta)'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Ninguna')),
                  ...goals.map((goal) => DropdownMenuItem(value: goal['id'], child: Text(goal['name']))),
                ],
                onChanged: (value) => setState(() => _selectedGoalId = value!),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.download),
                label: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generar y Descargar CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}