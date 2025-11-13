// lib/features/fincount/models/plan_expense_model.dart
class PlanExpense {
  final String id;
  final String planId;
  final String paidByParticipantId;
  final double amount;
  final String description;
  final DateTime createdAt; // <-- Usaremos esta, que sí existe

  PlanExpense({
    required this.id,
    required this.planId,
    required this.paidByParticipantId,
    required this.amount,
    required this.description,
    required this.createdAt, // <-- Eliminamos splitType
  });

  factory PlanExpense.fromMap(Map<String, dynamic> map) {
    return PlanExpense(
      id: map['id'],
      planId: map['plan_id'],
      paidByParticipantId: map['paid_by_participant_id'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']), // <-- Usamos created_at
    );
  }
}