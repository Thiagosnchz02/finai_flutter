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
  });
}

class BudgetSummary {
  final double spendingBalance; // Saldo total en cuentas de 'nómina'
  final double committedFixed; // Dinero comprometido en gastos fijos (solo para Pro)
  final double availableToBudget; // Lo que realmente queda para presupuestar
  final String userPlan; // 'free' o 'pro'
  final bool enableBudgetRollover;

  BudgetSummary({
    this.spendingBalance = 0.0,
    this.committedFixed = 0.0,
    this.availableToBudget = 0.0,
    required this.userPlan,
    required this.enableBudgetRollover,
  });
}