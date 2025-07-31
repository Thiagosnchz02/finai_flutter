import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String type; // 'gasto' o 'ingreso'
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Helper para parsear el color hexadecimal
    Color parseColor(String? colorStr) {
      if (colorStr == null || colorStr.isEmpty) return Colors.grey;
      final buffer = StringBuffer();
      if (colorStr.length == 6 || colorStr.length == 7) buffer.write('ff');
      buffer.write(colorStr.replaceFirst('#', ''));
      try {
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }

    return Transaction(
      id: json['id'] as String,
      date: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      categoryName: (json['categories'] as Map<String, dynamic>?)?['name'] as String? ?? 'Sin Categoría',
      categoryIcon: (json['categories'] as Map<String, dynamic>?)?['icon'] as String? ?? 'fas fa-question-circle',
      categoryColor: parseColor((json['categories'] as Map<String, dynamic>?)?['color'] as String?),
    );
  }
}