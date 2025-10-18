// lib/features/budgets/services/budget_service.dart

import 'dart:async';

import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import 'package:finai_flutter/features/budgets/models/budget_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetValidationException implements Exception {
  final double pendingAmount;
  final bool wouldBeNegative;

  BudgetValidationException(this.pendingAmount, {this.wouldBeNegative = false});

  @override
  String toString() {
    if (wouldBeNegative) {
      return 'Esta asignación dejaría el dinero pendiente de asignar en ${pendingAmount.toStringAsFixed(2)}€. Ajusta el monto.';
    }
    return 'No hay suficiente dinero pendiente de asignar. Quedan ${pendingAmount.toStringAsFixed(2)}€ disponibles.';
  }
}

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EventLoggerService _eventLogger = EventLoggerService();

  Future<BudgetSummary> getBudgetSummary(DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final moneyToAssign = await calculateMoneyToAssign(normalizedStart);
    final totalBudgeted = await _sumBudgetedAmount(normalizedStart);

    return BudgetSummary(
      periodStart: normalizedStart,
      moneyToAssign: moneyToAssign,
      totalBudgeted: totalBudgeted,
    );
  }

  Future<List<Budget>> getBudgetsForPeriod(DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final budgetsResponse = await _supabase
        .from('budgets')
        .select('id, category_id, amount, start_date, categories(name, icon)')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    if (budgetsResponse.isEmpty) {
      return [];
    }

    final spendingResponse = await _supabase
        .from('transactions')
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .gte('transaction_date', normalizedStart.toIso8601String())
        .lt('transaction_date', nextPeriodStart.toIso8601String());

    final Map<String, double> spendingByCategory = {};
    for (final row in spendingResponse) {
      final categoryId = row['category_id'] as String?;
      if (categoryId == null) continue;
      final amount = (row['amount'] as num).toDouble().abs();
      spendingByCategory.update(categoryId, (value) => value + amount,
          ifAbsent: () => amount);
    }

    final List<Budget> budgets = [];
    for (final row in budgetsResponse) {
      final categoryId = row['category_id'] as String;
      final categoryName =
          row['categories']?['name'] as String? ?? 'Categoría eliminada';
      final categoryIcon = row['categories']?['icon'] as String?;
      final amount = (row['amount'] as num).toDouble();
      final spent = spendingByCategory[categoryId] ?? 0.0;
      final remaining = amount - spent;
      final progress = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;

      budgets.add(Budget(
        id: row['id'] as String,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        amount: amount,
        startDate: DateTime.parse(row['start_date'] as String),
        spentAmount: spent,
        progress: progress,
        remainingAmount: remaining,
        lastMonthSpent: 0,
        lastMonthAmount: 0,
        rolloverAmount: 0,
        availableAmount: amount,
      ));
    }

    return budgets;
  }

  Future<List<Map<String, dynamic>>> getAvailableCategoriesForBudget(
      DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final budgetedCategoriesResponse = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    final budgetedCategoryIds = budgetedCategoriesResponse
        .map((row) => row['category_id'] as String)
        .toList();

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

  Future<void> upsertBudget({
    String? id,
    required String categoryId,
    required double amount,
    required DateTime periodStart,
  }) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final budgetsResponse = await _supabase
        .from('budgets')
        .select('id, amount')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    double totalBudgeted = 0;
    double existingAmount = 0;
    for (final budget in budgetsResponse) {
      final budgetId = budget['id'] as String;
      final budgetAmount = (budget['amount'] as num).toDouble();
      totalBudgeted += budgetAmount;
      if (id != null && budgetId == id) {
        existingAmount = budgetAmount;
      }
    }

    final moneyToAssign = await calculateMoneyToAssign(normalizedStart);
    final available = moneyToAssign - (totalBudgeted - existingAmount);
    const tolerance = 0.0001;

    if (available >= 0 && amount > available + tolerance) {
      throw BudgetValidationException(available);
    }

    final newTotalBudgeted = totalBudgeted - existingAmount + amount;
    final newPending = moneyToAssign - newTotalBudgeted;
    final currentPending = moneyToAssign - totalBudgeted;

    if (newPending < -tolerance) {
      if (currentPending >= -tolerance) {
        throw BudgetValidationException(newPending, wouldBeNegative: true);
      }
      if (newPending < currentPending - tolerance) {
        throw BudgetValidationException(newPending, wouldBeNegative: true);
      }
    }

    final data = <String, dynamic>{
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'start_date': normalizedStart.toIso8601String(),
      'period': 'mensual',
    };

    if (id != null) {
      data['id'] = id;
    }

    final response = await _supabase.from('budgets').upsert(data).select().single();
    final budgetId = response['id'];

    if (id != null) {
      await _eventLogger
          .log(AppEvent.budgetUpdated, details: {'budget_id': budgetId});
    } else {
      await _eventLogger.log(AppEvent.budgetCreated, details: {
        'budget_id': budgetId,
        'category_id': categoryId,
        'amount': amount,
      });
    }
  }

  Future<void> deleteBudget(String id) async {
    await _supabase.from('budgets').delete().eq('id', id);
    await _eventLogger
        .log(AppEvent.budgetDeleted, details: {'budget_id': id});
  }

  Future<bool> hasConflictingBudgetsFromLastMonth(DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final previousPeriodStart = _previousPeriodStart(normalizedStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', previousPeriodStart.toIso8601String())
        .lt('start_date', normalizedStart.toIso8601String());

    if (lastMonthBudgets.isEmpty) {
      return false;
    }

    final currentBudgets = await _supabase
        .from('budgets')
        .select('category_id')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    final lastMonthCategories =
        lastMonthBudgets.map((row) => row['category_id'] as String).toSet();
    final currentCategories =
        currentBudgets.map((row) => row['category_id'] as String).toSet();

    return lastMonthCategories.intersection(currentCategories).isNotEmpty;
  }

  Future<void> copyBudgetsFromLastMonth({
    required DateTime periodStart,
    bool overwriteExisting = false,
  }) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final previousPeriodStart = _previousPeriodStart(normalizedStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final lastMonthBudgets = await _supabase
        .from('budgets')
        .select('category_id, amount, period')
        .eq('user_id', userId)
        .gte('start_date', previousPeriodStart.toIso8601String())
        .lt('start_date', normalizedStart.toIso8601String());

    if (lastMonthBudgets.isEmpty) {
      throw Exception(
          'No se encontraron presupuestos en el periodo anterior para copiar.');
    }

    final currentBudgets = await _supabase
        .from('budgets')
        .select('id, category_id')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    final Map<String, dynamic> currentMap = {
      for (final budget in currentBudgets)
        budget['category_id'] as String: budget['id']
    };

    final List<Map<String, dynamic>> newBudgets = [];
    final List<Map<String, dynamic>> existingBudgets = [];

    for (final budget in lastMonthBudgets) {
      final categoryId = budget['category_id'] as String;
      final data = {
        'user_id': userId,
        'category_id': categoryId,
        'amount': budget['amount'],
        'start_date': normalizedStart.toIso8601String(),
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

  Future<double> calculateMoneyToAssign(DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final userId = _supabase.auth.currentUser!.id;

    final accountsResponse = await _supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .eq('conceptual_type', 'nomina')
        .eq('is_archived', false);

    if (accountsResponse.isEmpty) {
      return 0.0;
    }

    final List<String> accountIds =
        accountsResponse.map((row) => row['id'] as String).toList();

    final balancesResponse = await _fetchAccountBalances(userId);
    final Map<String, double> balancesMap = {
      for (final item in balancesResponse)
        item['account_id'] as String: (item['balance'] as num).toDouble()
    };

    final transactionsResponse = await _supabase
        .from('transactions')
        .select('account_id, amount')
        .eq('user_id', userId)
        .in_('account_id', accountIds)
        .gte('transaction_date', normalizedStart.toIso8601String());

    final Map<String, double> netChanges = {
      for (final id in accountIds) id: 0.0,
    };

    for (final row in transactionsResponse) {
      final accountId = row['account_id'] as String?;
      if (accountId == null) continue;
      final amount = (row['amount'] as num).toDouble();
      netChanges.update(accountId, (value) => value + amount,
          ifAbsent: () => amount);
    }

    double totalInitialBalance = 0;
    for (final accountId in accountIds) {
      final currentBalance = balancesMap[accountId] ?? 0.0;
      final change = netChanges[accountId] ?? 0.0;
      totalInitialBalance += currentBalance - change;
    }

    return totalInitialBalance;
  }

  Stream<double> getPendingToAssign(
      DateTime periodStart, double initialMoneyToAssign) {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('budgets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String())
        .map((rows) {
      final totalBudgeted = rows.fold<double>(
        0,
        (previousValue, element) =>
            previousValue + (element['amount'] as num).toDouble(),
      );
      return initialMoneyToAssign - totalBudgeted;
    });
  }

  Future<double> getAverageSpendingForCategory(
      String categoryId, int monthsHistory) async {
    if (monthsHistory <= 0) {
      return 0;
    }

    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final currentPeriodStart = DateTime(now.year, now.month, 1);
    final historyStart = DateTime(
        currentPeriodStart.year, currentPeriodStart.month - monthsHistory, 1);

    final spendingResponse = await _supabase
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'gasto')
        .eq('category_id', categoryId)
        .gte('transaction_date', historyStart.toIso8601String())
        .lt('transaction_date', currentPeriodStart.toIso8601String());

    double totalSpent = 0;
    for (final row in spendingResponse) {
      totalSpent += (row['amount'] as num).toDouble().abs();
    }

    return totalSpent / monthsHistory;
  }

  Future<List<Map<String, dynamic>>> _fetchAccountBalances(String userId) async {
    final response = await _supabase
        .rpc('get_account_balances', params: {'user_id_param': userId});

    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    return const [];
  }

  Future<double> _sumBudgetedAmount(DateTime periodStart) async {
    final normalizedStart = _normalizePeriodStart(periodStart);
    final nextPeriodStart = _nextPeriodStart(normalizedStart);
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('budgets')
        .select('amount')
        .eq('user_id', userId)
        .gte('start_date', normalizedStart.toIso8601String())
        .lt('start_date', nextPeriodStart.toIso8601String());

    return response.fold<double>(
      0,
      (previousValue, element) =>
          previousValue + (element['amount'] as num).toDouble(),
    );
  }

  DateTime _normalizePeriodStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _nextPeriodStart(DateTime date) => DateTime(date.year, date.month + 1, 1);

  DateTime _previousPeriodStart(DateTime date) =>
      DateTime(date.year, date.month - 1, 1);
}
