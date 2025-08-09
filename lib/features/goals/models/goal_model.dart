// lib/features/goals/models/goal_model.dart

class Goal {
  final String id;
  final String name;
  final String type; // 'Ahorro', 'Viaje', 'Fondo de emergencia', 'Otro'
  final String? icon;
  final double targetAmount;
  final DateTime? targetDate;
  final bool isArchived;
  
  // Estos campos son calculados y se añadirán en el servicio
  final double currentAmount;
  final double progress; // 0.0 a 1.0

  Goal({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    required this.targetAmount,
    this.targetDate,
    required this.isArchived,
    this.currentAmount = 0.0,
    this.progress = 0.0,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      isArchived: map['is_archived'],
      // Los campos calculados se añadirán después
    );
  }

  // Método para crear una copia con los valores calculados
  Goal copyWith({double? currentAmount, double? progress}) {
    return Goal(
      id: id,
      name: name,
      type: type,
      icon: icon,
      targetAmount: targetAmount,
      targetDate: targetDate,
      isArchived: isArchived,
      currentAmount: currentAmount ?? this.currentAmount,
      progress: progress ?? this.progress,
    );
  }
}

class GoalsSummary {
  final double totalSavingsBalance;
  final double totalAllocated;
  final double availableToAllocate;

  GoalsSummary({
    this.totalSavingsBalance = 0.0,
    this.totalAllocated = 0.0,
    this.availableToAllocate = 0.0,
  });
}