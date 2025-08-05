// lib/features/transactions/models/transaction_model.dart

// Modelo para la categoría, que ahora viene anidada en la transacción
class Category {
  final String id;
  final String name;
  final String type;

  Category({required this.id, required this.name, required this.type});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }
}

// Modelo principal de la transacción
class Transaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'gasto' o 'ingreso'
  final DateTime date;
  final String? accountId;
  final String? notes;
  final Category? category; // La categoría puede ser nula

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
     this.accountId,
    this.notes,
    this.category,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: DateTime.parse(map['transaction_date'] as String),
      accountId: map['account_id'] as String?,
      notes: map['notes'] as String?,
      category: map['categories'] != null
          ? Category.fromMap(map['categories'] as Map<String, dynamic>)
          : null,
    );
  }
}