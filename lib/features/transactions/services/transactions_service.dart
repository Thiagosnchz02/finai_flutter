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
          ''') // <-- CAMBIO AQUÍ: Añadido 'account_id' y 'related_scheduled_expense_id'
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
}