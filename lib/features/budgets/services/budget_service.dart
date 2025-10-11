// lib/features/budgets/services/budget_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/budget_model.dart';

class BudgetService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  Future<BudgetSummary> getBudgetSummary() async {
    final userId = _supabase.auth.currentUser!.id;

    // Obtenemos plan y preferencia de rollover en una sola consulta
    final profileResponse = await _supabase.from('profiles').select('plan_type, enable_budget_rollover').eq('id', userId).single();
    final userPlan = profileResponse['plan_type'] as String;
    final enableRollover = profileResponse['enable_budget_rollover'] as bool? ?? true;

    final spendingAccounts = await _supabase.from('accounts').select('id').eq('user_id', userId).eq('conceptual_type', 'nomina');
    final spendingAccountIds = spendingAccounts.map((a) => a['id'] as String).toList();

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

    double totalSpendingBalance = 0;
    if (spendingAccountIds.isNotEmpty) {
      final spendingResponse = await _supabase
          .from('transactions')
          .select('amount')
          .filter('account_id', 'in', spendingAccountIds);
      totalSpendingBalance = spendingResponse.map((t) => (t['amount'] as num).toDouble()).fold(0.0, (prev, amount) => prev + amount);
    }

    double totalMonthlyIncome = 0;
    final incomeResponse = await _supabase
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'ingreso')
        .gte('transaction_date', firstDayOfMonth.toIso8601String())
        .lt('transaction_date', firstDayOfNextMonth.toIso8601String());
    for (final income in incomeResponse) {
      totalMonthlyIncome += (income['amount'] as num).toDouble();
    }

    double committedFixed = 0;
    try {
      final fixedExpensesResponse = await _supabase
          .from('scheduled_fixed_expenses')
          .select('amount, next_due_date')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('next_due_date', firstDayOfMonth.toIso8601String())
          .lt('next_due_date', firstDayOfNextMonth.toIso8601String());
      for (var expense in fixedExpensesResponse) {
        committedFixed += (expense['amount'] as num).toDouble();
      }
    } catch (e) {
      committedFixed = 0;
    }

    // Presupuestos del mes actual
    final currentBudgets = await _supabase
        .from('budgets')
        .select('category_id, amount')
        .eq('user_id', userId)
        .gte('start_date', firstDayOfMonth.toIso8601String())
        .lt('start_date', firstDayOfNextMonth.toIso8601String());

    double totalBaseBudget = 0;
    final Map<String, double> currentBudgetAmounts = {};
    for (var b in currentBudgets) {
      final amount = (b['amount'] as num).toDouble();
      totalBaseBudget += amount;
      currentBudgetAmounts[b['category_id'] as String] = amount;
    }

    // Datos del mes anterior para rollover
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final firstDayOfCurrentMonth = firstDayOfMonth;

    final lastBudgetsResponse = await _supabase
        .from('budgets')
        .select('category_id, amount')
        .eq('user_id', userId)
        .gte('start_date', firstDayLastMonth.toIso8601String())
        .lt('start_date', firstDayOfCurrentMonth.toIso8601String());
    final lastBudgetAmounts = <String, double>{};
    for (var b in lastBudgetsResponse) {
      lastBudgetAmounts[b['category_id'] as String] =
          (b['amount'] as num).toDouble();
    }

    final lastSpendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', firstDayLastMonth.toIso8601String())
        .lt('transaction_date', firstDayOfCurrentMonth.toIso8601String());
    final lastSpendingByCategory = <String, double>{};
    for (var spent in lastSpendingResponse) {
      if (spent['category_id'] == null) continue;
      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      lastSpendingByCategory[categoryId] =
          (lastSpendingByCategory[categoryId] ?? 0) + amount;
    }

    double totalRollover = 0;
    currentBudgetAmounts.forEach((cat, amount) {
      final rollover =
          (lastBudgetAmounts[cat] ?? 0) - (lastSpendingByCategory[cat] ?? 0);
      totalRollover += rollover;
    });

    // Ajuste según la preferencia de rollover
    double totalAvailableBudget;
    if (!enableRollover) {
      totalRollover = 0;
      totalAvailableBudget = totalBaseBudget;
    } else {
      totalAvailableBudget = totalBaseBudget + totalRollover;
    }

    return BudgetSummary(
      spendingBalance: totalSpendingBalance,
      committedFixed: committedFixed,
      availableToBudget: totalMonthlyIncome - committedFixed,
      userPlan: userPlan,
      // CORRECCIÓN: Pasamos el parámetro requerido
      enableBudgetRollover: enableRollover,
      totalBaseBudget: totalBaseBudget,
      totalAvailableBudget: totalAvailableBudget,
    );
  }

  Future<List<Budget>> getBudgetsForCurrentMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

    // Preferencia de rollover del perfil
    final profileResponse = await _supabase
        .from('profiles')
        .select('enable_budget_rollover')
        .eq('id', userId)
        .single();
    final enableRollover =
        profileResponse['enable_budget_rollover'] as bool? ?? true;

    final budgetsResponse = await _supabase
        .from('budgets')
        .select('*, categories(name, icon)')
        .eq('user_id', userId)
        .gte('start_date', firstDayOfMonth.toIso8601String())
        .lt('start_date', firstDayOfNextMonth.toIso8601String());
    if (budgetsResponse.isEmpty) return [];

    // Gastos del mes actual
    final spendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', firstDayOfMonth.toIso8601String())
        .lt('transaction_date', firstDayOfNextMonth.toIso8601String());
    final spendingByCategory = <String, double>{};
    for (var spent in spendingResponse) {
      if (spent['category_id'] == null) continue;
      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      spendingByCategory[categoryId] =
          (spendingByCategory[categoryId] ?? 0) + amount;
    }

    // Datos del mes anterior
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final firstDayCurrentMonth = firstDayOfMonth;
    final lastBudgetsResponse = await _supabase
        .from('budgets')
        .select('category_id, amount')
        .eq('user_id', userId)
        .gte('start_date', firstDayLastMonth.toIso8601String())
        .lt('start_date', firstDayCurrentMonth.toIso8601String());
    final lastBudgetAmounts = <String, double>{};
    for (var b in lastBudgetsResponse) {
      lastBudgetAmounts[b['category_id'] as String] =
          (b['amount'] as num).toDouble();
    }
    final lastSpendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', firstDayLastMonth.toIso8601String())
        .lt('transaction_date', firstDayCurrentMonth.toIso8601String());
    final lastSpendingByCategory = <String, double>{};
    for (var spent in lastSpendingResponse) {
      if (spent['category_id'] == null) continue;
      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      lastSpendingByCategory[categoryId] =
          (lastSpendingByCategory[categoryId] ?? 0) + amount;
    }

    final List<Budget> budgets = [];
    for (var budgetData in budgetsResponse) {
      final categoryId = budgetData['category_id'] as String;
      final spentAmount = spendingByCategory[categoryId] ?? 0.0;
      final budgetAmount = (budgetData['amount'] as num).toDouble();
      final lastAmount = lastBudgetAmounts[categoryId] ?? 0.0;
      final lastSpent = lastSpendingByCategory[categoryId] ?? 0.0;
      double rollover = lastAmount - lastSpent;
      double availableAmount = budgetAmount + rollover;
      if (!enableRollover) {
        rollover = 0;
        availableAmount = budgetAmount;
      }
      final progress = availableAmount > 0
          ? (spentAmount / availableAmount).clamp(0.0, 1.0)
          : 0.0;
      final remaining = availableAmount - spentAmount;

      budgets.add(Budget(
        id: budgetData['id'],
        categoryId: categoryId,
        categoryName:
            budgetData['categories']?['name'] ?? 'Categoría eliminada',
        categoryIcon: budgetData['categories']?['icon'],
        amount: budgetAmount,
        startDate: DateTime.parse(budgetData['start_date']),
        spentAmount: spentAmount,
        progress: progress,
        remainingAmount: remaining,
        lastMonthSpent: lastSpent,
        lastMonthAmount: lastAmount,
        rolloverAmount: rollover,
        availableAmount: availableAmount,
      ));
    }
    return budgets;
  }
  
  Future<List<Map<String, dynamic>>> getAvailableCategoriesForBudget() async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    final budgetedCategoriesResponse = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', firstDayOfMonth.toIso8601String())
        .lt('start_date', firstDayOfNextMonth.toIso8601String());
    final budgetedCategoryIds = budgetedCategoriesResponse.map((b) => b['category_id'] as String).toList();
    var query = _supabase.from('categories').select('id, name').eq('type', 'gasto').eq('is_archived', false);
    if (budgetedCategoryIds.isNotEmpty) {
      query = query.not('id', 'in', budgetedCategoryIds);
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<void> saveBudget(Map<String, dynamic> data, bool isEditing) async {
    final response = await _supabase.from('budgets').upsert(data).select().single();
    final budgetId = response['id'];
    if (isEditing) {
      await _eventLogger.log(AppEvent.budgetUpdated, details: {'budget_id': budgetId, 'changes': 'updated'});
    } else {
      await _eventLogger.log(AppEvent.budgetCreated, details: {'budget_id': budgetId, 'category_id': data['category_id'], 'amount': data['amount']});
    }
  }

  Future<void> deleteBudget(String id) async {
    await _supabase.from('budgets').delete().eq('id', id);
    await _eventLogger
        .log(AppEvent.budgetDeleted, details: {'budget_id': id});
  }

  Future<bool> hasConflictingBudgetsFromLastMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', firstDayLastMonth.toIso8601String())
        .lt('start_date', firstDayCurrentMonth.toIso8601String());
    if (lastMonthBudgets.isEmpty) return false;

    final currentBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', firstDayCurrentMonth.toIso8601String())
        .lt('start_date', firstDayNextMonth.toIso8601String());

    final lastMonthCategoryIds =
        lastMonthBudgets.map((b) => b['category_id'] as String).toSet();
    final currentCategoryIds =
        currentBudgets.map((b) => b['category_id'] as String).toSet();

    return lastMonthCategoryIds.intersection(currentCategoryIds).isNotEmpty;
  }

  Future<void> copyBudgetsFromLastMonth({bool overwriteExisting = false}) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id, amount, period')
        .eq('user_id', userId)
        .gte('start_date', firstDayLastMonth.toIso8601String())
        .lt('start_date', firstDayCurrentMonth.toIso8601String());
    if (lastMonthBudgets.isEmpty) {
      throw Exception('No se encontraron presupuestos en el mes anterior para copiar.');
    }

    final currentBudgets = await _supabase
        .from('budgets')
        .select('id, category_id')
        .eq('user_id', userId)
        .gte('start_date', firstDayCurrentMonth.toIso8601String())
        .lt('start_date', firstDayNextMonth.toIso8601String());

    final currentMap = {for (var b in currentBudgets) b['category_id']: b['id']};

    final List<Map<String, dynamic>> newBudgets = [];
    final List<Map<String, dynamic>> existingBudgets = [];

    for (var budget in lastMonthBudgets) {
      final categoryId = budget['category_id'] as String;
      final data = {
        'user_id': userId,
        'category_id': categoryId,
        'amount': budget['amount'],
        'start_date': firstDayCurrentMonth.toIso8601String(),
        'period': budget['period'],
      };
      if (currentMap.containsKey(categoryId)) {
        data['id'] = currentMap[categoryId];
        existingBudgets.add(data);
      } else {
        newBudgets.add(data);
      }
    }

    if (newBudgets.isNotEmpty) {
      await _supabase.from('budgets').insert(newBudgets);
    }
    if (overwriteExisting && existingBudgets.isNotEmpty) {
      await _supabase.from('budgets').upsert(existingBudgets);
    }
  }
  
  // >>> Añadido desde la rama de Codex: sugerencia de gasto por categoría
  Future<double?> getCategorySpendingSuggestion(String categoryId) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.rpc(
      'get_category_spending_suggestion',
      params: {
        'p_user_id': userId,
        'p_category_id': categoryId,
      },
    );

    if (response == null) return null;

    // Si viene como número (int/double)
    if (response is num) return response.toDouble();

    // Si viene como objeto { suggested_amount: ... }
    if (response is Map && response['suggested_amount'] != null) {
      final v = response['suggested_amount'];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
    }

    return null;
  }

  Future<void> updateBudgetRollover(bool isEnabled) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').update({'enable_budget_rollover': isEnabled}).eq('id', userId);
    await _eventLogger.log(AppEvent.budgetRolloverToggled, details: {'enabled': isEnabled});
  }
}
