// lib/features/investments/models/investment_model.dart

class Investment {
  final String id;
  final String type;
  final String name;
  final String? symbol;
  final double quantity;
  final double purchasePrice;
  final DateTime? purchaseDate;
  final double currentValue;
  final String? broker;
  final String? notes;

  Investment({
    required this.id,
    required this.type,
    required this.name,
    this.symbol,
    required this.quantity,
    required this.purchasePrice,
    this.purchaseDate,
    required this.currentValue,
    this.broker,
    this.notes,
  });

  // Propiedad calculada para el valor total de compra
  double get purchaseTotalValue => quantity * purchasePrice;

  // Propiedad calculada para la ganancia o pérdida
  double get profitLoss => currentValue - purchaseTotalValue;

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      type: map['type'] ?? 'Otro',
      name: map['name'],
      symbol: map['symbol'],
      quantity: (map['quantity'] as num? ?? 0).toDouble(),
      purchasePrice: (map['purchase_price'] as num? ?? 0).toDouble(),
      purchaseDate: map['purchase_date'] != null ? DateTime.parse(map['purchase_date']) : null,
      currentValue: (map['current_value'] as num? ?? 0).toDouble(),
      broker: map['broker'],
      notes: map['notes'],
    );
  }
}