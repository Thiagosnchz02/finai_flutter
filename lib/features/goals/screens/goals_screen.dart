// lib/features/goals/screens/goals_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/goals/models/goal_model.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';
import 'package:finai_flutter/features/goals/widgets/goal_card.dart';
import 'package:finai_flutter/features/goals/widgets/goals_summary_header.dart';
import 'add_edit_goal_screen.dart'; 
import '../widgets/contribution_history_dialog.dart';
import '../widgets/bottom_sheets/contribution_bottom_sheet.dart';
import '../widgets/bottom_sheets/trip_expense_bottom_sheet.dart';

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
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditGoalSheet(goal: goal),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
  
  void _showContributionDialog(Goal goal, double availableToAllocate) async {
    final result = await showContributionSheet(
      context,
      goalId: goal.id,
      goalName: goal.name,
      availableToAllocate: availableToAllocate,
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  // --- INICIO DEL NUEVO CÓDIGO ---
  /// Muestra el diálogo para añadir un gasto a un viaje.
  void _showTripExpenseDialog(Goal goal) async {
    final result = await showTripExpenseSheet(
      context,
      goalId: goal.id,
      goalName: goal.name,
      goalBalance: goal.currentAmount,
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
  // --- FIN DEL NUEVO CÓDIGO ---

  Future<void> _archiveGoal(Goal goal) async {
    final isCompleted = goal.progress >= 1.0;

    bool proceed = isCompleted;
    if (!isCompleted) {
      proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Archivar meta incompleta?'),
              content: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          "Las aportaciones realizadas a '${goal.name}' serán devueltas a tu cuenta de ahorro asociada. ",
                    ),
                    const TextSpan(
                      text:
                          'Los gastos registrados (si es un viaje) se conservarán en tu historial general. ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(
                      text:
                          '¿Estás seguro de que quieres archivarla?',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí, Archivar'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!proceed) return;

    try {
      if (isCompleted) {
        await _service.archiveGoal(goal.id, goal.name);
      } else {
        await _service.forceArchiveGoal(goal.id, goal.name);
      }
      if (mounted) {
        final successMessage = isCompleted
            ? 'Meta archivada con éxito'
            : 'Meta archivada. Las aportaciones han sido devueltas a tu cuenta de ahorro.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
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
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0013, -1),
            radius: 1.0,
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
              onRefresh: () async {
                _loadData();
                await _dataFuture;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 200,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x338B5CF6),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                    blurStyle: BlurStyle.inner,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Mis metas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 92),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GoalsSummaryHeader(summary: summary),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _navigateAndRefresh(),
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF8B5CF6),
                              ),
                              label: const Text(
                                'Añadir meta',
                                style: TextStyle(
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0x1F8B5CF6),
                                side: const BorderSide(color: Color(0x338B5CF6)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (activeGoals.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Center(
                              child: Text('¡Crea tu primera hucha para empezar a ahorrar!'),
                            ),
                          )
                        else
                          ...activeGoals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: GestureDetector(
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
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
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