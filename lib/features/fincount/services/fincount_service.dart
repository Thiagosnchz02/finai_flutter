// lib/features/fincount/services/fincount_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/split_plan_model.dart';
import '../models/plan_participant_model.dart';

class FincountService {
  final _supabase = Supabase.instance.client;

  /// Obtiene todos los planes de Fincount para el usuario actual.
  Future<List<Map<String, dynamic>>> getSplitPlans() async {
    // Esta función obtendrá los planes y un resumen de cada uno.
    // Por ahora, simularemos la llamada y devolveremos datos más completos.
    // En una implementación real, esto podría ser una RPC que calcule el balance.
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
        .insert({'name': name, 'user_id': _supabase.auth.currentUser!.id})
        .select()
        .single();
    return SplitPlan.fromMap(response);
  }
  
  // Aquí irían los métodos para llamar a las RPCs `add_split_expense` y `resolve_split_plan`
}