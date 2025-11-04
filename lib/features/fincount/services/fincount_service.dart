// lib/features/fincount/services/fincount_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/split_plan_model.dart';
import '../models/plan_participant_model.dart';

class FincountService {
  final _supabase = Supabase.instance.client;

  /// Obtiene todos los planes de Fincount para el usuario actual.
  Future<List<Map<String, dynamic>>> getSplitPlans() async {
    final response = await _supabase.from('split_plans').select();
    
    // Simulación de datos adicionales que vendrían de un cálculo más complejo
    final plans = response.map((plan) {
      return {
        ...plan,
        'participants_count': 4, // Dato de ejemplo
        'user_balance': -125.75, // Dato de ejemplo
      };
    }).toList();

    return List<Map<String, dynamic>>.from(plans);
  }

  /// Crea un nuevo plan.
  Future<SplitPlan> createPlan(String name) async {
    final response = await _supabase
        .from('split_plans')
        .insert({'name': name, 'creator_user_id': _supabase.auth.currentUser!.id}) // Corregido
        .select()
        .single();
    return SplitPlan.fromMap(response);
  }
  
  /// Obtiene los detalles y saldos de un plan específico.
  Future<List<PlanParticipant>> getPlanDetails(String planId) async {
    try {
      final response = await _supabase.rpc(
        'resolve_split_plan',
        params: {'p_plan_id': planId},
      );

      if (response is! List) {
        print('Respuesta inesperada de RPC (probablemente RLS o sin datos): $response');
        return <PlanParticipant>[]; // Devuelve una lista vacía
      }

      final participants = response
          .map((item) => PlanParticipant.fromMap(item as Map<String, dynamic>))
          .toList();
          
      return participants;
    } catch (e) {
      print('Error en getPlanDetails: $e');
      rethrow;
    }
  }

  /// Añade un nuevo participante a un plan.
  Future<void> addParticipant(String planId, String name) async {
    try {
      await _supabase.from('plan_participants').insert({
        'plan_id': planId,
        'participant_name': name, // <-- CORRECCIÓN AQUÍ
      });
    } catch (e) {
      print('Error en addParticipant: $e');
      rethrow;
    }
  }

  /// Llama a la RPC para añadir un nuevo gasto y sus divisiones.
  Future<void> addExpense({
    required String planId,
    required String paidByParticipantId,
    required double amount,
    required String description,
    required String splitType, // 'equal', 'percentage', 'exact'
    required List<Map<String, dynamic>> shares,
  }) async {
    try {
      await _supabase.rpc(
        'add_split_expense',
        params: {
          'p_plan_id': planId,
          'p_paid_by_participant_id': paidByParticipantId,
          'p_amount': amount,
          'p_description': description,
          'p_split_type': splitType,
          'p_shares': shares,
        },
      );
    } catch (e) {
      print('Error en addExpense: $e');
      rethrow;
    }
  }
}