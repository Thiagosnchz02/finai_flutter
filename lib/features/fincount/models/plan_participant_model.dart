// lib/features/fincount/models/plan_participant_model.dart
class PlanParticipant {
  final String id;
  final String planId;
  final String name;
  double balance;

  PlanParticipant({
    required this.id,
    required this.planId,
    required this.name,
    this.balance = 0.0,
  });

  factory PlanParticipant.fromMap(Map<String, dynamic> map) {
    return PlanParticipant(
      id: map['id'],
      planId: map['plan_id'],
      name: map['participant_name'],
      balance: (map['balance'] as num? ?? 0.0).toDouble(),
    );
  }
}