// lib/features/transactions/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/core/utils/icon_utils.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isIncome = transaction.type == 'ingreso';
    final bool isExpense = transaction.type == 'gasto';
    final bool isTransfer = transaction.type == 'transferencia';

    final Color amountColor = isIncome
        ? Colors.greenAccent.shade400
        : isExpense
            ? Colors.redAccent.shade200
            : Colors.white;

    final currencyFormatter =
        NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final String amountPrefix = isIncome
        ? '+'
        : isExpense
            ? '-'
            : '';
    final String amountString = '$amountPrefix${currencyFormatter.format(transaction.amount)}';

    final IconData iconData = isTransfer
        ? Icons.lock
        : parseIconFromHex(
            transaction.categoryIcon,
            fallback: isIncome
                ? Icons.trending_up
                : Icons.trending_down,
          );

    final Color avatarColor = isIncome
        ? Colors.greenAccent.withOpacity(0.15)
        : isExpense
            ? Colors.redAccent.withOpacity(0.15)
            : Colors.white.withOpacity(0.1);

    final Color backgroundColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF1E1E1E);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
    );

    final subtitleText =
        '${transaction.category?.name ?? 'Sin Categoría'} · ${DateFormat.Hm().format(transaction.date)}';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: avatarColor,
              child: Icon(
                iconData,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.relatedScheduledExpenseId != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.autorenew,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  amountString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PopupMenuButton<_TransactionAction>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 20,
                  ),
                  color: theme.colorScheme.surface,
                  onSelected: (value) {
                    switch (value) {
                      case _TransactionAction.edit:
                        if (!isTransfer) {
                          onEdit?.call();
                        }
                        break;
                      case _TransactionAction.delete:
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<_TransactionAction>(
                      value: _TransactionAction.edit,
                      enabled: !isTransfer && onEdit != null,
                      child: const Text('Editar'),
                    ),
                    PopupMenuItem<_TransactionAction>(
                      value: _TransactionAction.delete,
                      enabled: onDelete != null,
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _TransactionAction { edit, delete }
