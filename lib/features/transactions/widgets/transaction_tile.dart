// lib/features/transactions/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'ingreso';
    final amountColor = isIncome ? Colors.green.shade400 : Theme.of(context).colorScheme.onSurface;
    final amountString = '${isIncome ? '+' : '-'}${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(transaction.amount)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor.withOpacity(0.5),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: transaction.category?.type == 'ingreso' 
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green.shade400 : Colors.red.shade300,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(transaction.category?.name ?? 'Sin Categoría'),
        trailing: Text(
          amountString,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}