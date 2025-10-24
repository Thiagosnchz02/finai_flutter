// lib/features/budgets/services/budget_service.dart

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';

import '../models/budget_model.dart';

class BudgetService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  Future<BudgetSummary> getBudgetSummary() async {
    final budgets = await getBudgetsForCurrentMonth();
    return _buildBudgetSummary(budgets);
  }

  Future<BudgetSummary> getBudgetSummaryFromBudgets(List<Budget> budgets) async {
    return _buildBudgetSummary(budgets);
  }

  Future<List<Budget>> getBudgetsForCurrentMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final range = _currentMonthRange();

    final rolloverEnabled = await isBudgetRolloverEnabled();

    final budgetsResponse = await _supabase
        .from('budgets')
        .select('*, categories(name, icon)')
        .eq('user_id', userId)
        .gte('start_date', range.start.toIso8601String())
        .lt('start_date', range.end.toIso8601String());

    if (budgetsResponse.isEmpty) {
      return [];
    }

    final spendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount, goals!left(is_archived)')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', range.start.toIso8601String())
        .lt('transaction_date', range.end.toIso8601String());

    final spendingByCategory = <String, double>{};
    for (final rawSpent in spendingResponse) {
      final spent = Map<String, dynamic>.from(rawSpent as Map);
      if (spent['category_id'] == null) continue;

      final goalData = spent['goals'];
      if (goalData is Map && goalData['is_archived'] == true) {
        continue;
      }

      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      spendingByCategory[categoryId] =
          (spendingByCategory[categoryId] ?? 0) + amount;
    }

    final previousRange = _previousMonthRange();
    final lastBudgetsResponse = await _supabase
        .from('budgets')
        .select('category_id, amount')
        .eq('user_id', userId)
        .gte('start_date', previousRange.start.toIso8601String())
        .lt('start_date', previousRange.end.toIso8601String());

    final lastBudgetAmounts = <String, double>{};
    for (final budget in lastBudgetsResponse) {
      lastBudgetAmounts[budget['category_id'] as String] =
          (budget['amount'] as num).toDouble();
    }

    final lastSpendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount, goals!left(is_archived)')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', previousRange.start.toIso8601String())
        .lt('transaction_date', previousRange.end.toIso8601String());

    final lastSpendingByCategory = <String, double>{};
    for (final rawSpent in lastSpendingResponse) {
      final spent = Map<String, dynamic>.from(rawSpent as Map);
      if (spent['category_id'] == null) continue;

      final goalData = spent['goals'];
      if (goalData is Map && goalData['is_archived'] == true) {
        continue;
      }

      final categoryId = spent['category_id'] as String;
      final amount = (spent['amount'] as num).abs().toDouble();
      lastSpendingByCategory[categoryId] =
          (lastSpendingByCategory[categoryId] ?? 0) + amount;
    }

    final budgets = <Budget>[];
    for (final budgetData in budgetsResponse) {
      final categoryId = budgetData['category_id'] as String;
      final budgetAmount = (budgetData['amount'] as num).toDouble();
      final spentAmount = spendingByCategory[categoryId] ?? 0.0;

      final lastAmount = lastBudgetAmounts[categoryId] ?? 0.0;
      final lastSpent = lastSpendingByCategory[categoryId] ?? 0.0;
      final rollover = rolloverEnabled ? (lastAmount - lastSpent) : 0.0;

      final progress = budgetAmount > 0
          ? (spentAmount / budgetAmount).clamp(0.0, 1.0)
          : 0.0;
      final remaining = budgetAmount - spentAmount;

      budgets.add(
        Budget(
          id: budgetData['id'],
          categoryId: categoryId,
          categoryName: budgetData['categories']?['name'] ?? 'Categoría eliminada',
          categoryIcon: budgetData['categories']?['icon'],
          amount: budgetAmount,
          startDate: DateTime.parse(budgetData['start_date']),
          spentAmount: spentAmount,
          progress: progress,
          remainingAmount: remaining,
          lastMonthSpent: lastSpent,
          lastMonthAmount: lastAmount,
          rolloverAmount: rollover,
          availableAmount: budgetAmount,
        ),
      );
    }

    return budgets;
  }

  Future<List<Map<String, dynamic>>> getAvailableCategoriesForBudget() async {
    final userId = _supabase.auth.currentUser!.id;
    final range = _currentMonthRange();

    final budgetedCategoriesResponse = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', range.start.toIso8601String())
        .lt('start_date', range.end.toIso8601String());

    final budgetedCategoryIds =
        budgetedCategoriesResponse.map((b) => b['category_id'] as String).toList();

    var query = _supabase
        .from('categories')
        .select('id, name')
        .eq('type', 'gasto')
        .eq('is_archived', false);

    if (budgetedCategoryIds.isNotEmpty) {
      query = query.not('id', 'in', budgetedCategoryIds);
    }

    return List<Map<String, dynamic>>.from(await query);
  }

  Future<void> saveBudget(Map<String, dynamic> data,
      {bool isEditing = false, double previousAmount = 0}) async {
    final newAmount = (data['amount'] as num).toDouble();
    final budgets = await getBudgetsForCurrentMonth();
    final summary = await getBudgetSummaryFromBudgets(budgets);

    final available = summary.pendingToAssign + previousAmount;
    final difference = newAmount - previousAmount;
    if (difference > 0 && difference - 1e-6 > available) {
      throw Exception(
        'No hay suficiente dinero pendiente de asignar para guardar este presupuesto.',
      );
    }

    final response =
        await _supabase.from('budgets').upsert(data).select().single();
    final budgetId = response['id'];

    if (isEditing) {
      await _eventLogger.log(AppEvent.budgetUpdated,
          details: {'budget_id': budgetId, 'changes': 'updated'});
    } else {
      await _eventLogger.log(AppEvent.budgetCreated, details: {
        'budget_id': budgetId,
        'category_id': data['category_id'],
        'amount': data['amount'],
      });
    }
  }

  Future<void> deleteBudget(String id) async {
    await _supabase.from('budgets').delete().eq('id', id);
    await _eventLogger
        .log(AppEvent.budgetDeleted, details: {'budget_id': id});
  }

  Future<bool> hasConflictingBudgetsFromLastMonth() async {
    final userId = _supabase.auth.currentUser!.id;
    final range = _currentMonthRange();
    final previousRange = _previousMonthRange();

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', previousRange.start.toIso8601String())
        .lt('start_date', previousRange.end.toIso8601String());

    if (lastMonthBudgets.isEmpty) {
      return false;
    }

    final currentBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', range.start.toIso8601String())
        .lt('start_date', range.end.toIso8601String());

    final lastMonthCategories =
        lastMonthBudgets.map((b) => b['category_id'] as String).toSet();
    final currentCategories =
        currentBudgets.map((b) => b['category_id'] as String).toSet();

    return lastMonthCategories.intersection(currentCategories).isNotEmpty;
  }

  Future<void> copyBudgetsFromLastMonth({bool overwriteExisting = false}) async {
    final userId = _supabase.auth.currentUser!.id;
    final range = _currentMonthRange();
    final previousRange = _previousMonthRange();

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id, amount, period')
        .eq('user_id', userId)
        .gte('start_date', previousRange.start.toIso8601String())
        .lt('start_date', previousRange.end.toIso8601String());

    if (lastMonthBudgets.isEmpty) {
      throw Exception(
        'No se encontraron presupuestos en el mes anterior para copiar.',
      );
    }

    final currentBudgets = await _supabase
        .from('budgets')
        .select('id, category_id')
        .eq('user_id', userId)
        .gte('start_date', range.start.toIso8601String())
        .lt('start_date', range.end.toIso8601String());

    final currentMap = {
      for (final budget in currentBudgets) budget['category_id']: budget['id']
    };

    final newBudgets = <Map<String, dynamic>>[];
    final existingBudgets = <Map<String, dynamic>>[];

    for (final budget in lastMonthBudgets) {
      final categoryId = budget['category_id'] as String;
      final data = {
        'user_id': userId,
        'category_id': categoryId,
        'amount': budget['amount'],
        'start_date': range.start.toIso8601String(),
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

  Future<double> getAverageSpendingForCategory(String categoryId,
      {int months = 6}) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final response = await _supabase
        .from('transactions')
        .select('amount, transaction_date, goals!left(is_archived)')
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .eq('type', 'gasto')
        .gte('transaction_date', start.toIso8601String())
        .lt('transaction_date', end.toIso8601String());

    if (response.isEmpty) {
      return 0;
    }

    final grouped = <DateTime, double>{};
    for (final rawItem in response) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final goalData = item['goals'];
      if (goalData is Map && goalData['is_archived'] == true) {
        continue;
      }

      final date = DateTime.parse(item['transaction_date'] as String);
      final monthKey = DateTime(date.year, date.month, 1);
      final amount = (item['amount'] as num).abs().toDouble();
      grouped[monthKey] = (grouped[monthKey] ?? 0) + amount;
    }

    final total = grouped.values.fold<double>(0, (sum, item) => sum + item);
    return grouped.isEmpty ? 0 : total / grouped.length;
  }

  Future<List<CategorySpendingHistory>> getCategorySpendingHistory(
      String categoryId,
      {int months = 6}) async {
    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final response = await _supabase
        .from('transactions')
        .select('amount, transaction_date, goals!left(is_archived)')
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .eq('type', 'gasto')
        .gte('transaction_date', start.toIso8601String())
        .lt('transaction_date', end.toIso8601String());

    final spendingByMonth = <DateTime, double>{};
    for (final rawItem in response) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      final goalData = item['goals'];
      if (goalData is Map && goalData['is_archived'] == true) {
        continue;
      }

      final date = DateTime.parse(item['transaction_date'] as String);
      final monthKey = DateTime(date.year, date.month, 1);
      final amount = (item['amount'] as num).abs().toDouble();
      spendingByMonth[monthKey] = (spendingByMonth[monthKey] ?? 0) + amount;
    }

    final history = <CategorySpendingHistory>[];
    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      history.add(
        CategorySpendingHistory(
          month: monthDate,
          amount: spendingByMonth[monthDate] ?? 0.0,
        ),
      );
    }

    return history;
  }

  Stream<BudgetSummary> watchBudgetSummary() {
    final userId = _supabase.auth.currentUser!.id;
    return Stream.multi((multi) {
      StreamSubscription<List<Map<String, dynamic>>>? transactionSub;
      StreamSubscription<List<Map<String, dynamic>>>? budgetSub;

      Future<void> emitSummary() async {
        try {
          final budgets = await getBudgetsForCurrentMonth();
          final summary = await getBudgetSummaryFromBudgets(budgets);
          multi.add(summary);
        } catch (error, stack) {
          multi.addError(error, stack);
        }
      }

      Future(() async {
        transactionSub = _supabase
            .from('transactions')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .listen((_) => emitSummary());

        budgetSub = _supabase
            .from('budgets')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .listen((_) => emitSummary());

        await emitSummary();
      });

      multi.onCancel = () async {
        await transactionSub?.cancel();
        await budgetSub?.cancel();
      };
    });
  }

  Future<void> updateBudgetRollover(bool isEnabled) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('profiles')
        .update({'enable_budget_rollover': isEnabled}).eq('id', userId);
    await _eventLogger.log(AppEvent.budgetRolloverToggled,
        details: {'enabled': isEnabled});
  }

  Future<bool> isBudgetRolloverEnabled() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('profiles')
        .select('enable_budget_rollover')
        .eq('id', userId)
        .single();

    return response['enable_budget_rollover'] as bool? ?? true;
  }

  _MonthRange _currentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _MonthRange(start: start, end: end);
  }

  _MonthRange _previousMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 1);
    return _MonthRange(start: start, end: end);
  }

  Future<double> _calculateMoneyToAssign() async {
    final userId = _supabase.auth.currentUser!.id;
    final range = _currentMonthRange();
    final accountIds = await _getSpendingAccountIds(userId);

    if (accountIds.isEmpty) {
      return 0;
    }

    final balancesResponse = await _supabase
        .rpc('get_account_balances', params: {'user_id_param': userId});

    double currentBalance = 0;
    if (balancesResponse is List) {
      for (final rawItem in balancesResponse) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        if (accountIds.contains(item['account_id'])) {
          currentBalance += (item['balance'] as num).toDouble();
        }
      }
    }

    final transactionsResponse = await _supabase
        .from('transactions')
        .select('amount, type, goals!left(is_archived)')
        .eq('user_id', userId)
        .inFilter('account_id', accountIds)
        .gte('transaction_date', range.start.toIso8601String())
        .lt('transaction_date', range.end.toIso8601String());

    double netChange = 0;
    double incomes = 0;
    for (final rawTransaction in transactionsResponse) {
      final transaction = Map<String, dynamic>.from(rawTransaction as Map);
      final goalData = transaction['goals'];
      if (goalData is Map && goalData['is_archived'] == true) {
        continue;
      }

      final amount = (transaction['amount'] as num).toDouble();
      netChange += amount;

      if (transaction['type'] == 'ingreso') {
        incomes += amount.abs();
      }
    }

    final initialBalance = currentBalance - netChange;
    return initialBalance + incomes;
  }

  Future<List<String>> _getSpendingAccountIds(String userId) async {
    final accountsResponse = await _supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .eq('conceptual_type', 'nomina')
        .eq('is_archived', false);

    return accountsResponse
        .map<String>((account) => account['id'] as String)
        .toList();
  }

  Future<BudgetSummary> _buildBudgetSummary(List<Budget> budgets) async {
    final moneyToAssign = await _calculateMoneyToAssign();

    final totalBudgeted =
        budgets.fold<double>(0, (sum, item) => sum + item.amount);
    final totalSpent =
        budgets.fold<double>(0, (sum, item) => sum + item.spentAmount);
    final pendingToAssign = moneyToAssign - totalBudgeted;
    final totalRemaining = totalBudgeted - totalSpent;

    return BudgetSummary(
      moneyToAssign: moneyToAssign,
      pendingToAssign: pendingToAssign,
      totalBudgeted: totalBudgeted,
      totalSpent: totalSpent,
      totalRemaining: totalRemaining,
    );
  }
}

class _MonthRange {
  final DateTime start;
  final DateTime end;

  const _MonthRange({required this.start, required this.end});
}
