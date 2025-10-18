// lib/features/budgets/screens/budget_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:finai_flutter/features/budgets/services/budget_service.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_card.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_summary_header.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_distribution_chart.dart';
import 'package:finai_flutter/features/budgets/widgets/add_edit_budget_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _CopyAction { overwrite, addOnly, cancel }

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _service = BudgetService();
  late Future<Map<String, dynamic>> _dataFuture;
  StreamSubscription<List<Map<String, dynamic>>>? _transactionsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _budgetsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscriptions();
  }

  Future<void> _loadData() async {
    final future = _fetchAllData();
    if (!mounted) return;
    setState(() {
      _dataFuture = future;
    });
    await future;
  }

  Future<Map<String, dynamic>> _fetchAllData() async {
    final budgets = await _service.getBudgetsForCurrentMonth();
    final summary = await _service.getBudgetSummaryFromBudgets(budgets);
    final enableRollover = await _service.isBudgetRolloverEnabled();

    return {'summary': summary, 'budgets': budgets, 'enableRollover': enableRollover};
  }

  void _setupRealtimeSubscriptions() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final firstDayNext = DateTime(now.year, now.month + 1, 1);

    _transactionsSubscription = client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .gte('transaction_date', firstDay.toIso8601String())
        .lt('transaction_date', firstDayNext.toIso8601String())
        .listen((_) {
      _loadData();
    });

    _budgetsSubscription = client
        .from('budgets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .gte('start_date', firstDay.toIso8601String())
        .lt('start_date', firstDayNext.toIso8601String())
        .listen((_) {
      _loadData();
    });

    _profileSubscription = client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .listen((_) {
      _loadData();
    });
  }

  Future<void> _openBudgetDialog({Budget? budget}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditBudgetDialog(budget: budget),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteBudget(String id) async {
    await _service.deleteBudget(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Presupuesto eliminado'),
            backgroundColor: Colors.redAccent),
      );
    }
    await _loadData();
  }

  Future<void> _onCopyFromLastMonth() async {
    try {
      bool overwrite = false;
      final hasConflicts = await _service.hasConflictingBudgetsFromLastMonth();
      if (hasConflicts && mounted) {
        final action = await showDialog<_CopyAction>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conflicto de presupuestos'),
            content: const Text(
                'Algunas categorías ya tienen presupuesto este mes. ¿Deseas sobrescribirlos o agregar solo los que faltan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, _CopyAction.cancel),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _CopyAction.addOnly),
                child: const Text('Solo nuevos'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _CopyAction.overwrite),
                child: const Text('Sobrescribir'),
              ),
            ],
          ),
        );
        if (action == null || action == _CopyAction.cancel) return;
        overwrite = action == _CopyAction.overwrite;
      }

      await _service.copyBudgetsFromLastMonth(overwriteExisting: overwrite);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presupuestos copiados con éxito'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onRolloverChanged(bool value) async {
    try {
      await _service.updateBudgetRollover(value);
      await _loadData();
    } catch (e) {
      // Manejar error si es necesario
    }
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') {
                _onCopyFromLastMonth();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'copy',
                child: Text('Copiar del mes anterior'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openBudgetDialog(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No hay datos disponibles.'));
          }

          final summary = snapshot.data!['summary'] as BudgetSummary;
          final budgets = snapshot.data!['budgets'] as List<Budget>;
          final enableRollover = snapshot.data!['enableRollover'] as bool;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0),
                  child: BudgetSummaryHeader(summary: summary),
                ),
                SwitchListTile(
                  title: const Text('Activar Rollover'),
                  subtitle: const Text('Arrastrar sobrante/faltante del mes anterior'),
                  value: enableRollover,
                  onChanged: _onRolloverChanged,
                  dense: true,
                ),
                if (budgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: BudgetDistributionChart(budgets: budgets),
                  ),
                Expanded(
                  child: budgets.isEmpty
                      ? const Center(child: Text('Crea tu primer presupuesto para este mes.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: budgets.length,
                          itemBuilder: (context, index) {
                            final budget = budgets[index];
                            return BudgetCard(
                              budget: budget,
                              enableRollover: enableRollover,
                              onTap: () => _openBudgetDialog(budget: budget),
                              onDelete: () => _deleteBudget(budget.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}