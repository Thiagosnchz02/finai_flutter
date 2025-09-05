// lib/features/transactions/services/transactions_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';

class TransactionsService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('transactions')
          .select('''
            id,
            description,
            amount,
            type,
            transaction_date,
            notes,
            account_id,
            related_scheduled_expense_id,
            categories (id, name, type)
          ''') // <-- CAMBIO AQUÍ: Añadido 'account_id'
          .eq('user_id', userId)
          .order('transaction_date', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print('Error en fetchTransactions: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentTransactions({int limit = 5}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('transactions')
          .select('''
            id,
            description,
            amount,
            type,
            transaction_date,
            notes,
            account_id,
            related_scheduled_expense_id,
            categories (id, name, type)
          ''')
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .limit(limit); // <-- Usamos el límite aquí
          
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print('Error en fetchRecentTransactions: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _supabase.from('transactions').delete().eq('id', transactionId);
      
      _eventLogger.log(
        AppEvent.transaction_deleted,
        details: {'transaction_id': transactionId},
      );

    } catch (e) {
      print('Error en deleteTransaction: $e');
      rethrow;
    }
  }

  /// Registers a payment for a fixed expense using the Supabase RPC
  /// `register_fixed_expense_payment`.
  ///
  /// Returns the string result from the RPC, typically 'SUCCESS' or
  /// 'DUPLICATE'.
  Future<String> registerFixedExpensePayment({
    required String expenseId,
    required double amount,
    required DateTime transactionDate,
    required String accountId,
    String? notes,
    bool ignoreDuplicate = false,
  }) async {
    final params = {
      'p_expense_id': expenseId,
      'p_amount': amount,
      'p_transaction_date': transactionDate.toIso8601String(),
      'p_account_id': accountId,
      'p_notes': notes,
    };

    if (ignoreDuplicate) {
      // El parámetro puede ser ignorado por la función RPC si no está
      // implementado aún en el backend.
      params['ignore_duplicate'] = true;
    }

    final response =
        await _supabase.rpc('register_fixed_expense_payment', params: params);
    return response as String;
  }
}