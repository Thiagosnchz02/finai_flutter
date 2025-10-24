// lib/features/goals/services/goals_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/goal_model.dart';

class GoalsService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();
  
  // --- INICIO DEL NUEVO CÓDIGO ---
  /// Obtiene el ID y nombre de la cuenta de ahorro principal del usuario.
  Future<Map<String, String>?> getPrimarySavingsAccount() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final response = await _supabase
          .from('accounts')
          .select('id, name')
          .eq('user_id', userId)
          .eq('conceptual_type', 'ahorro')
          .single(); // Usamos single() para esperar un único resultado
      return {'id': response['id'] as String, 'name': response['name'] as String};
    } catch (e) {
      // Si no se encuentra ninguna cuenta de ahorro (o hay más de una), devuelve nulo.
      print('Error o no se encontró cuenta de ahorro principal: $e');
      return null;
    }
  }
  // --- FIN DEL NUEVO CÓDIGO ---

  /// Obtiene el resumen general de la cuenta de ahorro.
  Future<GoalsSummary> getGoalsSummary() async {
    final userId = _supabase.auth.currentUser!.id;

    final savingsAccountData = await getPrimarySavingsAccount();
    // Si no hay cuenta de ahorro, devolvemos un resumen a cero.
    if (savingsAccountData == null) {
      return GoalsSummary();
    }
    
    final savingsAccountId = savingsAccountData['id'];

    // Ahora sabemos que savingsAccountId no es nulo y podemos usarlo de forma segura.
    final totalSavingsBalance = (await _supabase
        .from('transactions')
        .select('amount')
        .eq('account_id', savingsAccountId!)) // Ahora es seguro
        .map((e) => (e['amount'] as num).toDouble())
        .fold(0.0, (sum, amount) => sum + amount);
    
    final totalAllocatedResponse = await _supabase
        .from('goal_allocations')
        .select('amount')
        .eq('user_id', userId);
        
    final totalAllocated = totalAllocatedResponse
        .map((e) => (e['amount'] as num).toDouble())
        .fold(0.0, (sum, amount) => sum + amount);
        
    return GoalsSummary(
      totalSavingsBalance: totalSavingsBalance,
      totalAllocated: totalAllocated,
      availableToAllocate: totalSavingsBalance - totalAllocated,
    );
  }

  // El resto de los métodos (getGoals, saveGoal, addContribution) permanecen sin cambios...
  Future<List<Goal>> getGoals() async {
    final response = await _supabase.from('goals').select().order('created_at');
    final goals = response.map((map) => Goal.fromMap(map)).toList();

    final List<Goal> goalsWithBalance = [];
    for (final goal in goals) {
      final balance = (await _supabase.rpc('get_goal_balance', params: {'p_goal_id': goal.id})) as num;
      final progress = goal.targetAmount > 0 ? (balance / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
      
      goalsWithBalance.add(goal.copyWith(
        currentAmount: balance.toDouble(),
        progress: progress,
      ));
    }
    
    return goalsWithBalance;
  }

  Future<void> saveGoal(Map<String, dynamic> data, bool isEditing) async {
    final response = await _supabase.from('goals').upsert(data).select().single();
    final goalId = response['id'];

    if (isEditing) {
      await _eventLogger.log(
        AppEvent.goalUpdated,
        details: {'goal_id': goalId, 'changes': 'updated'},
      );
    } else {
      await _eventLogger.log(
        AppEvent.goalCreated,
        details: {
          'goal_id': goalId,
          'goal_name': data['name'],
          'target_amount': data['target_amount'],
        },
      );
    }
  }

  Future<void> addContribution(String goalId, double amount, String? notes) async {
    await _supabase.rpc('add_contribution_to_goal', params: {'p_goal_id': goalId, 'p_amount': amount, 'p_notes': notes});
    await _eventLogger.log(AppEvent.goalContributionAdded, details: {'goal_id': goalId, 'amount_added': amount});
  }

  // --- INICIO DEL NUEVO CÓDIGO ---
  /// Registra un gasto contra una meta de viaje.
  /// Este gasto se vincula a la cuenta de ahorro principal.
  Future<void> addExpenseToTripGoal({
    required String goalId,
    required double amount,
    required String description,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final savingsAccount = await getPrimarySavingsAccount();

    if (savingsAccount == null) {
      throw Exception('No se puede registrar el gasto: no hay una cuenta de ahorro principal configurada.');
    }
    
    // Validamos que la hucha tenga saldo suficiente.
    final currentBalance = (await _supabase.rpc('get_goal_balance', params: {'p_goal_id': goalId})) as num;
    if (amount > currentBalance) {
      throw Exception('El gasto supera el saldo disponible en esta hucha.');
    }

    final transactionData = {
      'user_id': userId,
      'account_id': savingsAccount['id'],
      'description': description,
      'amount': -amount, // Los gastos se guardan como negativos
      'type': 'gasto',
      'transaction_date': DateTime.now().toIso8601String(),
      'related_goal_id': goalId, // Vinculamos la transacción a la hucha
    };

    final savedTransaction = await _supabase.from('transactions').insert(transactionData).select().single();

    await _eventLogger.log(
      AppEvent.tripExpenseCreatedFromGoal,
      details: {
        'goal_id': goalId,
        'transaction_id': savedTransaction['id'],
        'amount': amount,
      },
    );
  }

  Future<void> archiveGoal(String goalId, String goalName) async {
    await _supabase.rpc('archive_goal', params: {'p_goal_id': goalId});

    // Registramos el evento
    await _eventLogger.log(
      AppEvent.goalArchived,
      details: {'goal_id': goalId, 'goal_name': goalName},
    );
  }

  /// Fuerza el archivado de una meta que aún no está completada.
  ///
  /// Este flujo utiliza el RPC `force_archive_goal`, que revierte las
  /// aportaciones de la meta hacia la cuenta asociada, conserva las
  /// transacciones registradas y finalmente marca la meta como archivada.
  Future<void> forceArchiveGoal(String goalId, String goalName) async {
    final response = await _supabase
        .rpc('force_archive_goal', params: {'p_goal_id': goalId});

    final result = response as String?;
    var shouldLogEvent = true;

    switch (result) {
      case null:
      case 'GOAL_FORCE_ARCHIVED_SUCCESSFULLY':
        break;
      case 'GOAL_ALREADY_ARCHIVED':
        shouldLogEvent = false;
        break;
      case 'ERROR_GOAL_NOT_FOUND':
        throw Exception('No se encontró la meta seleccionada.');
      case 'ERROR_GOAL_ACCOUNT_NOT_FOUND':
        throw Exception(
            'No se encontró la cuenta asociada a esta meta. Revisa la configuración.');
      case 'ERROR_ARCHIVE_FAILED':
        throw Exception('No fue posible archivar la meta. Inténtalo de nuevo.');
      default:
        throw Exception('Error desconocido al archivar la meta ($result).');
    }

    if (shouldLogEvent) {
      await _eventLogger.log(
        AppEvent.goalArchived,
        details: {
          'goal_id': goalId,
          'goal_name': goalName,
          'forced': true,
        },
      );
    }
  }
  // --- FIN DEL NUEVO CÓDIGO ---

  Future<List<Map<String, dynamic>>> getContributionHistory(String goalId) async {
    final response = await _supabase
        .from('goal_allocations')
        .select('created_at, amount, notes')
        .eq('goal_id', goalId)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }
}