// lib/features/fincount/services/fincount_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/split_plan_model.dart';
import '../models/plan_participant_model.dart'; // <-- IMPORTACIÓN AÑADIDA

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
        .insert({'name': name, 'creator_user_id': _supabase.auth.currentUser!.id})
        .select()
        .single();
    return SplitPlan.fromMap(response);
  }

  /// Obtiene los detalles y saldos de un plan específico.
  Future<List<PlanParticipant>> getPlanDetails(String planId) async {
    try {
      // Llama a la RPC que calcula los saldos
      final response = await _supabase.rpc(
        'resolve_split_plan',
        params: {'p_plan_id': planId},
      );

      // Convierte la respuesta (que es una lista de mapas) en una lista de modelos
      final participants = (response as List)
          .map((item) => PlanParticipant.fromMap(item as Map<String, dynamic>))
          .toList();
          
      return participants;
    } catch (e) {
      // Manejar el error, por ejemplo, si la RPC falla
      print('Error en getPlanDetails: $e');
      rethrow;
    }
  }
}