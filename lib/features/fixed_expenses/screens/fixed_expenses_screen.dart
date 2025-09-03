// Archivo a reemplazar: lib/features/fixed_expenses/screens/fixed_expenses_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:finai_flutter/features/fixed_expenses/models/fixed_expense_model.dart';
import 'package:finai_flutter/features/fixed_expenses/services/fixed_expenses_service.dart';
import 'add_edit_fixed_expense_screen.dart';

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final _service = FixedExpensesService();
  late Future<List<FixedExpense>> _fixedExpensesFuture;
  bool _isListView = true;

  // Estado para el calendario
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<FixedExpense>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _selectedDay = _focusedDay;
  }

  void _loadData() {
    _fixedExpensesFuture = _service.getFixedExpenses().then((maps) {
      final expenses = maps.map((map) => FixedExpense.fromMap(map)).toList();
      _events = _groupExpensesByDate(expenses);
      return expenses;
    });
    setState(() {});
  }

  Map<DateTime, List<FixedExpense>> _groupExpensesByDate(List<FixedExpense> expenses) {
    Map<DateTime, List<FixedExpense>> data = {};
    for (var expense in expenses) {
      final date = DateTime.utc(expense.nextDueDate.year, expense.nextDueDate.month, expense.nextDueDate.day);
      data[date] = data[date] ?? [];
      data[date]!.add(expense);
    }
    return data;
  }

  double _calculateMonthlyTotal(List<FixedExpense> expenses) {
    // ... (lógica sin cambios)
    final now = DateTime.now();
    double total = 0;
    for (var expense in expenses) {
      if (expense.isActive) {
        if (expense.frequency == 'mensual') {
          total += expense.amount;
        } else if (expense.nextDueDate.year == now.year && expense.nextDueDate.month == now.month) {
          total += expense.amount;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Fijos'),
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.calendar_month_outlined : Icons.list_alt_outlined),
            onPressed: () => setState(() => _isListView = !_isListView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const AddEditFixedExpenseScreen()),
              );
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<FixedExpense>>(
        future: _fixedExpensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          final monthlyTotal = _calculateMonthlyTotal(expenses);

          return Column(
            children: [
              // ... (Tarjeta de total mensual sin cambios)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Total Fijo Estimado (Este Mes)', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '${monthlyTotal.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isListView
                    ? ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return ListTile(
                            title: Text(expense.description),
                            subtitle: Text('Vence: ${DateFormat.yMMMd('es_ES').format(expense.nextDueDate)}'),
                            trailing: Text('${expense.amount.toStringAsFixed(2)} €'),
                          );
                        },
                      )
                    : TableCalendar<FixedExpense>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        eventLoader: (day) => _events[day] ?? [],
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}