// lib/features/budgets/models/budget_model.dart

class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final double amount; // El límite del presupuesto
  final DateTime startDate;

  // Campos calculados
  final double spentAmount; // Cuánto se ha gastado
  final double progress; // 0.0 a 1.0
  final double remainingAmount; // Cuánto queda
  final double lastMonthSpent; // Gastado en el mes anterior
  final double lastMonthAmount; // Presupuesto del mes anterior
  final double rolloverAmount; // Diferencia del mes anterior
  final double availableAmount; // Presupuesto base + rollover

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.amount,
    required this.startDate,
    this.spentAmount = 0.0,
    this.progress = 0.0,
    this.remainingAmount = 0.0,
    this.lastMonthSpent = 0.0,
    this.lastMonthAmount = 0.0,
    this.rolloverAmount = 0.0,
    this.availableAmount = 0.0,
  });
}

class BudgetSummary {
  final DateTime periodStart;
  final double moneyToAssign; // Dinero inicial disponible para asignar
  final double totalBudgeted; // Suma de presupuestos creados en el periodo

  const BudgetSummary({
    required this.periodStart,
    required this.moneyToAssign,
    required this.totalBudgeted,
  });

  double get initiallyPending => moneyToAssign - totalBudgeted;
}
