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
    
    double totalSpendingBalance = 0;
    if (spendingAccountIds.isNotEmpty) {
      // CORRECCIÓN DEFINITIVA: Usamos el método .filter()
      final spendingResponse = await _supabase
          .from('transactions')
          .select('amount')
          .filter('account_id', 'in', spendingAccountIds);
      totalSpendingBalance = spendingResponse.map((t) => (t['amount'] as num).toDouble()).fold(0.0, (prev, amount) => prev + amount);
    }
    
    double committedFixed = 0;
    if (userPlan == 'pro') {
      try {
        final fixedExpensesResponse = await _supabase.from('scheduled_fixed_expenses').select('amount, frequency, next_due_date').eq('user_id', userId).eq('is_active', true);
        final now = DateTime.now();
        for (var expense in fixedExpensesResponse) {
          final nextDueDate = DateTime.parse(expense['next_due_date']);
          if (expense['frequency'] == 'mensual' || (nextDueDate.year == now.year && nextDueDate.month == now.month)) {
            committedFixed += (expense['amount'] as num).toDouble();
          }
        }
      } catch (e) {
        print('Could not fetch fixed expenses, likely due to RLS. User might not be PRO. Error: $e');
        committedFixed = 0;
      }
    }

    return BudgetSummary(
      spendingBalance: totalSpendingBalance,
      committedFixed: committedFixed,
      availableToBudget: totalSpendingBalance - committedFixed,
      userPlan: userPlan,
      // CORRECCIÓN: Pasamos el parámetro requerido
      enableBudgetRollover: enableRollover,
    );
  }

  // ... (El resto del archivo permanece igual)
  Future<List<Budget>> getBudgetsForCurrentMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final budgetsResponse = await _supabase.from('budgets').select('*, categories(name, icon)').eq('user_id', userId).gte('start_date', firstDayOfMonth.toIso8601String());
    if (budgetsResponse.isEmpty) return [];
    final spendingResponse = await _supabase.from('transactions').select('category_id, amount').eq('user_id', userId).eq('type', 'gasto').gte('transaction_date', firstDayOfMonth.toIso8601String());
    final spendingByCategory = <String, double>{};
    for (var spent in spendingResponse) {
      if (spent['category_id'] == null) continue;
      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      spendingByCategory[categoryId] = (spendingByCategory[categoryId] ?? 0) + amount;
    }
    final List<Budget> budgets = [];
    for (var budgetData in budgetsResponse) {
      final categoryId = budgetData['category_id'] as String;
      final spentAmount = spendingByCategory[categoryId] ?? 0.0;
      final budgetAmount = (budgetData['amount'] as num).toDouble();
      budgets.add(Budget(
        id: budgetData['id'],
        categoryId: categoryId,
        categoryName: budgetData['categories']?['name'] ?? 'Categoría eliminada',
        categoryIcon: budgetData['categories']?['icon'],
        amount: budgetAmount,
        startDate: DateTime.parse(budgetData['start_date']),
        spentAmount: spentAmount,
        progress: budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0.0,
        remainingAmount: budgetAmount - spentAmount,
      ));
    }
    return budgets;
  }
  
  Future<List<Map<String, dynamic>>> getAvailableCategoriesForBudget() async {
    final userId = _supabase.auth.currentUser!.id;
    final firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final budgetedCategoriesResponse = await _supabase.from('budgets').select('category_id').eq('user_id', userId).gte('start_date', firstDayOfMonth.toIso8601String());
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
      await _eventLogger.log(AppEvent.budget_updated, details: {'budget_id': budgetId, 'changes': 'updated'});
    } else {
      await _eventLogger.log(AppEvent.budget_created, details: {'budget_id': budgetId, 'category_id': data['category_id'], 'amount': data['amount']});
    }
  }

  Future<void> copyBudgetsFromLastMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = firstDayCurrentMonth.subtract(const Duration(days: 1));
    final lastMonthBudgets = await _supabase.from('budgets').select('category_id, amount, period').eq('user_id', userId).gte('start_date', firstDayLastMonth.toIso8601String()).lte('start_date', lastDayLastMonth.toIso8601String());
    if (lastMonthBudgets.isEmpty) {
      throw Exception('No se encontraron presupuestos en el mes anterior para copiar.');
    }
    final newBudgets = lastMonthBudgets.map((budget) {
      return {
        'user_id': userId,
        'category_id': budget['category_id'],
        'amount': budget['amount'],
        'start_date': firstDayCurrentMonth.toIso8601String(),
        'period': budget['period'],
      };
    }).toList();
    await _supabase.from('budgets').insert(newBudgets);
  }

  Future<void> updateBudgetRollover(bool isEnabled) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').update({'enable_budget_rollover': isEnabled}).eq('id', userId);
    await _eventLogger.log(AppEvent.budget_rollover_toggled, details: {'enabled': isEnabled});
  }
}