// lib/features/goals/screens/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/goals/models/goal_model.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';
import 'package:finai_flutter/features/goals/widgets/goal_card.dart';
import 'package:finai_flutter/features/goals/widgets/goals_summary_header.dart';
import 'add_edit_goal_screen.dart'; 
import '../widgets/add_contribution_dialog.dart';
import '../widgets/add_trip_expense_dialog.dart'; // <-- 1. IMPORTAMOS EL NUEVO DIÁLOGO
import '../widgets/contribution_history_dialog.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _service = GoalsService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchAllData();
    });
  }

  Future<Map<String, dynamic>> _fetchAllData() async {
    final summary = await _service.getGoalsSummary();
    final goals = await _service.getGoals();
    return {'summary': summary, 'goals': goals};
  }

  void _navigateAndRefresh({Goal? goal}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddEditGoalScreen(goal: goal)),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
  
  void _showContributionDialog(Goal goal, double availableToAllocate) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddContributionDialog(
        goalId: goal.id,
        goalName: goal.name,
        availableToAllocate: availableToAllocate,
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  // --- INICIO DEL NUEVO CÓDIGO ---
  /// Muestra el diálogo para añadir un gasto a un viaje.
  void _showTripExpenseDialog(Goal goal) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddTripExpenseDialog(
        goalId: goal.id,
        goalName: goal.name,
        goalBalance: goal.currentAmount,
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
  // --- FIN DEL NUEVO CÓDIGO ---

  Future<void> _archiveGoal(Goal goal) async {
    try {
      await _service.archiveGoal(goal.id, goal.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta archivada con éxito'), backgroundColor: Colors.green),
        );
        _loadData(); // Recargamos para que desaparezca de la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al archivar la meta: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Muestra el diálogo con el historial de aportaciones.
  void _showHistoryDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => ContributionHistoryDialog(
        goalId: goal.id,
        goalName: goal.name,
      ),
    );
  }
  // --- FIN DEL NUEVO CÓDIGO ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Metas (Huchas)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateAndRefresh(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF381D74),
              Color(0xFF121212),
            ],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
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

            final summary = snapshot.data!['summary'] as GoalsSummary;
            final goals = snapshot.data!['goals'] as List<Goal>;
            final activeGoals = goals.where((g) => !g.isArchived).toList();

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GoalsSummaryHeader(summary: summary),
                  ),
                  Expanded(
                    child: activeGoals.isEmpty
                        ? const Center(
                            child: Text('¡Crea tu primera hucha para empezar a ahorrar!'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: activeGoals.length,
                            itemBuilder: (context, index) {
                              final goal = activeGoals[index];
                              return GestureDetector(
                                onTap: () => _navigateAndRefresh(goal: goal),
                                child: GoalCard(
                                  goal: goal,
                                  onContribute: () {
                                    _showContributionDialog(goal, summary.availableToAllocate);
                                  },
                                  onAddExpense: () {
                                    // 4. LLAMAMOS AL NUEVO MÉTODO
                                    _showTripExpenseDialog(goal);
                                  },
                                  onArchive: () => _archiveGoal(goal),
                                  onViewHistory: () => _showHistoryDialog(goal),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}