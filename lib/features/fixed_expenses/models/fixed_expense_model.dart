// lib/features/fixed_expenses/models/fixed_expense_model.dart

enum PaymentStatus { pagado, pendiente, vencido }

class FixedExpense {
  final String id;
  final String description;
  final double amount;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final bool notificationEnabled;
  final String? categoryName;
  final String? categoryIcon;
  final String? accountName;
  final DateTime? lastPaymentProcessedOn;

  FixedExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
    required this.notificationEnabled,
    this.categoryName,
    this.categoryIcon,
    this.accountName,
    this.lastPaymentProcessedOn,
  });

  factory FixedExpense.fromMap(Map<String, dynamic> map) {
    return FixedExpense(
      id: map['id'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      frequency: map['frequency'],
      nextDueDate: DateTime.parse(map['next_due_date']),
      isActive: map['is_active'],
      notificationEnabled: map['notification_enabled'],
      categoryName: map['categories']?['name'],
      categoryIcon: map['categories']?['icon'],
      accountName: map['accounts']?['name'],
      lastPaymentProcessedOn: map['last_payment_processed_on'] != null
          ? DateTime.parse(map['last_payment_processed_on'])
          : null,
    );
  }

  PaymentStatus getStatus(DateTime now) {
    if (lastPaymentProcessedOn != null &&
        lastPaymentProcessedOn!.year == now.year &&
        lastPaymentProcessedOn!.month == now.month) {
      return PaymentStatus.pagado;
    } else if (nextDueDate.isBefore(now)) {
      return PaymentStatus.vencido;
    } else {
      return PaymentStatus.pendiente;
    }
  }
}