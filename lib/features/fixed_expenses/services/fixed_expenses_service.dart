// lib/features/fixed_expenses/services/fixed_expenses_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';

class FixedExpensesService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  Future<List<Map<String, dynamic>>> getFixedExpenses() async {
    final response = await _supabase
        .from('scheduled_fixed_expenses')
        .select('*, categories(name, icon), accounts(name)')
        .order('next_due_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getRelatedData() async {
    final accountsResponse = await _supabase.from('accounts').select('id, name').eq('is_archived', false);
    final categoriesResponse = await _supabase.from('categories').select('id, name').eq('type', 'gasto').eq('is_archived', false);
    return {
      'accounts': List<Map<String, dynamic>>.from(accountsResponse),
      'categories': List<Map<String, dynamic>>.from(categoriesResponse),
    };
  }

  Future<void> saveFixedExpense(Map<String, dynamic> data, bool isEditing) async {
    final response = await _supabase.from('scheduled_fixed_expenses').upsert(data).select().single();
    final expenseId = response['id'];

    if (isEditing) {
      await _eventLogger.log(
        AppEvent.fixed_expense_updated,
        details: {'expense_id': expenseId, 'changes': 'updated'}, // Payload simplificado
      );
    } else {
      await _eventLogger.log(
        AppEvent.fixed_expense_created,
        details: {
          'expense_id': expenseId,
          'amount': data['amount'],
          'frequency': data['frequency'],
          'category_id': data['category_id'],
        },
      );
    }
  }

  Future<void> deleteFixedExpense(String id, String description) async {
    await _supabase.from('scheduled_fixed_expenses').delete().eq('id', id);
    await _eventLogger.log(
      AppEvent.fixed_expense_deleted,
      details: {'expense_id': id, 'description': description},
    );
  }

  Future<void> updateToggle(String id, String field, bool value) async {
    await _supabase.from('scheduled_fixed_expenses').update({field: value}).eq('id', id);
    await _eventLogger.log(
      AppEvent.fixed_expense_toggled,
      details: {'expense_id': id, 'field': field, 'new_value': value},
    );
  }

  Future<List<Map<String, dynamic>>> getHistory(String expenseId) async {
    final response = await _supabase
        .from('transactions')
        .select('transaction_date, description, amount')
        .eq('related_scheduled_expense_id', expenseId)
        .order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}