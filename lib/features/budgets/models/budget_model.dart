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
  /// Dinero disponible para presupuestar durante el mes actual.
  /// Incluye el saldo inicial en cuentas de gasto más los ingresos recibidos
  /// en el período.
  final double moneyToAssign;

  /// Dinero pendiente de asignar a presupuestos. Es el indicador principal
  /// que debe llevarse a cero.
  final double pendingToAssign;

  /// Suma de todos los presupuestos creados en el período actual.
  final double totalBudgeted;

  /// Suma del gasto registrado en las categorías presupuestadas durante el
  /// período actual.
  final double totalSpent;

  /// Dinero restante dentro de los presupuestos creados
  /// (`totalBudgeted - totalSpent`). Puede ser negativo si hay sobregasto.
  final double totalRemaining;

  const BudgetSummary({
    this.moneyToAssign = 0.0,
    this.pendingToAssign = 0.0,
    this.totalBudgeted = 0.0,
    this.totalSpent = 0.0,
    this.totalRemaining = 0.0,
  });

  bool get hasDeficit => pendingToAssign < 0;
}

class CategorySpendingHistory {
  final DateTime month;
  final double amount;

  const CategorySpendingHistory({required this.month, required this.amount});
}