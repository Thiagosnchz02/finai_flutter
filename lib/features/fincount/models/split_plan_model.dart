// lib/features/fincount/models/split_plan_model.dart
class SplitPlan {
  final String id;
  final String name;
  final DateTime createdAt;

  SplitPlan({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory SplitPlan.fromMap(Map<String, dynamic> map) {
    return SplitPlan(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}