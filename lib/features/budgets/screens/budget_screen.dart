// lib/features/budgets/screens/budget_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:finai_flutter/features/budgets/services/budget_service.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_card.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_summary_header.dart';
import 'package:finai_flutter/features/budgets/widgets/budget_distribution_chart.dart';
import 'package:finai_flutter/features/budgets/widgets/add_edit_budget_dialog.dart';

enum _CopyAction { overwrite, addOnly, cancel }

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _service = BudgetService();
  late Future<_BudgetScreenData> _dataFuture;
  late DateTime _periodStart;
  StreamSubscription<double>? _pendingSubscription;
  double? _latestPending;
  BudgetSummary? _latestSummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1);
    final future = _fetchAllData();
    _pendingSubscription?.cancel();
    _latestSummary = null;
    _latestPending = null;
    setState(() {
      _dataFuture = future;
    });

    future.then((data) {
      if (!mounted) return;
      _latestSummary = data.summary;
      _latestPending = data.summary.initiallyPending;
      _pendingSubscription?.cancel();
      _pendingSubscription = _service
          .getPendingToAssign(data.summary.periodStart, data.summary.moneyToAssign)
          .listen((value) {
        _latestPending = value;
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  Future<_BudgetScreenData> _fetchAllData() async {
    final summary = await _service.getBudgetSummary(_periodStart);
    final budgets = await _service.getBudgetsForPeriod(_periodStart);

    return _BudgetScreenData(summary: summary, budgets: budgets);
  }

  Future<void> _openBudgetDialog({Budget? budget}) async {
    final summary = _latestSummary;
    if (summary == null) {
      return;
    }

    final currentPending = _latestPending ?? summary.initiallyPending;
    final availableForDialog = currentPending + (budget?.amount ?? 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditBudgetDialog(
        budget: budget,
        periodStart: summary.periodStart,
        pendingToAssign: currentPending,
        availableToAssign: availableForDialog,
      ),
    );
    if (result == true && mounted) {
      _loadData();
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
    _loadData();
  }

  Future<void> _onCopyFromLastMonth() async {
    final summary = _latestSummary;
    if (summary == null) return;
    try {
      bool overwrite = false;
      final hasConflicts =
          await _service.hasConflictingBudgetsFromLastMonth(summary.periodStart);
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

      await _service.copyBudgetsFromLastMonth(
          periodStart: summary.periodStart, overwriteExisting: overwrite);
      _loadData();
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

  @override
  void dispose() {
    _pendingSubscription?.cancel();
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
            onPressed:
                _latestSummary == null ? null : () => _openBudgetDialog(),
          ),
        ],
      ),
      body: FutureBuilder<_BudgetScreenData>(
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

          final summary = snapshot.data!.summary;
          final budgets = snapshot.data!.budgets;
          final pending = _latestPending ?? summary.initiallyPending;

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _dataFuture;
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 16.0),
                  child: BudgetSummaryHeader(
                    summary: summary,
                    pendingToAssign: pending,
                  ),
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

class _BudgetScreenData {
  final BudgetSummary summary;
  final List<Budget> budgets;

  _BudgetScreenData({required this.summary, required this.budgets});
}
