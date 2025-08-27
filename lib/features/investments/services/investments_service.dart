// lib/features/investments/services/investments_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import 'package:finai_flutter/features/investments/models/investment_model.dart';

class InvestmentsService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  /// Obtiene todas las inversiones del usuario actual.
  Future<List<Investment>> getInvestments() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('investments')
        .select()
        .eq('user_id', userId)
        .order('name', ascending: true);
        
    return response.map((item) => Investment.fromMap(item)).toList();
  }

  /// Guarda una nueva inversión o actualiza una existente.
  Future<void> saveInvestment(Map<String, dynamic> data, bool isEditing) async {
    final response = await _supabase.from('investments').upsert(data).select().single();
    final investmentId = response['id'];

    if (isEditing) {
      await _eventLogger.log(
        AppEvent.investment_updated,
        details: {
          'investment_id': investmentId,
          // El payload de 'changes' es complejo, por ahora enviamos un placeholder.
          'changes': 'updated',
        },
      );
    } else {
      await _eventLogger.log(
        AppEvent.investment_created,
        details: {
          'investment_id': investmentId,
          'type': data['type'],
          'initial_value': (data['quantity'] as double) * (data['purchase_price'] as double),
        },
      );
    }
  }

  /// Elimina una inversión por su ID.
  Future<void> deleteInvestment(String id, String type) async {
    await _supabase.from('investments').delete().eq('id', id);

    await _eventLogger.log(
      AppEvent.investment_deleted,
      details: {
        'investment_id': id,
        'type': type,
      },
    );
  }
}