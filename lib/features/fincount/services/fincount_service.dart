// lib/features/fincount/services/fincount_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/split_plan_model.dart';
import '../models/plan_participant_model.dart';
import '../models/plan_expense_model.dart';

class FincountService {
  final _supabase = Supabase.instance.client;

  // ... (getSplitPlans, createPlan, getPlanDetails, addParticipant sin cambios) ...

  /// Obtiene todos los planes de Fincount para el usuario actual.
  Future<List<Map<String, dynamic>>> getSplitPlans() async {
    final response = await _supabase.from('split_plans').select();
    
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
        'participant_name': name,
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
    required String splitType, // 'equal'
    required List<Map<String, dynamic>> shares, // [{'participant_id': 'id1'}, ...]
  }) async {
    try {
      // --- INICIO DE LA CORRECCIÓN ---

      // 1. Traducir el 'splitType' de la app ('equal') al que espera el SQL ('igual')
      String sqlSplitType;
      if (splitType == 'equal') {
        sqlSplitType = 'igual';
      } else if (splitType == 'percentage') {
        sqlSplitType = 'porcentaje';
      } else if (splitType == 'exact') {
        sqlSplitType = 'exacto';
      } else {
        // Lanzar un error si el tipo no es válido
        throw Exception('Tipo de split desconocido: $splitType');
      }

      // 2. Extraer los datos de 'shares' al formato que espera el SQL
      dynamic sqlSplitValue;
      if (sqlSplitType == 'igual') {
        // El SQL espera una LISTA de IDs: ['id1', 'id2']
        sqlSplitValue = shares
            .map((share) => share['participant_id'] as String)
            .toList();
      } else {
        // TODO: Implementar la lógica para 'porcentaje' y 'exacto'
        // (Esperarían un MAPA: {'id1': 50, 'id2': 50})
        throw Exception('Tipo de split aún no implementado: $sqlSplitType');
      }

      // 3. Construir el objeto 'p_reparto' con las claves correctas ('tipo' y 'valor')
      final repartObject = {
        'tipo': sqlSplitType,
        'valor': sqlSplitValue,
      };

      await _supabase.rpc(
        'add_split_expense',
        params: {
          'p_plan_id': planId,
          'p_paid_by_participant_id': paidByParticipantId,
          'p_amount': amount,
          'p_description': description,
          'p_reparto': repartObject, // Enviamos el objeto corregido
        },
      );
      // --- FIN DE LA CORRECCIÓN ---
    } catch (e) {
      print('Error en addExpense: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de todos los gastos de un plan.
  Future<List<PlanExpense>> getPlanExpenses(String planId) async {
    try {
      final response = await _supabase
          .from('plan_expenses')
          .select()
          .eq('plan_id', planId)
          .order('created_at', ascending: false);

      final expenses = (response as List)
          .map((item) => PlanExpense.fromMap(item as Map<String, dynamic>))
          .toList();
          
      return expenses;
    } catch (e) {
      print('Error en getPlanExpenses: $e');
      rethrow;
    }
  }
}