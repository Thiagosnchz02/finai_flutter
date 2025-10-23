// lib/features/transactions/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/core/utils/icon_utils.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
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

    final bool isDark = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFF1E1E1E);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.18)
        : Colors.black.withOpacity(0.05);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
    );

    final subtitleText =
        '${transaction.category?.name ?? 'Sin Categoría'} · ${DateFormat.Hm().format(transaction.date)}';

    final Color deleteActionBackground = const Color(0xFF1C0E29);
    final Color deleteActionBorder = const Color(0xFFEA00FF);
    final Color deleteAccentColor = const Color(0xFFFF6B6B);
    final bool canDelete = onDelete != null;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canDelete ? onDelete : null,
                    borderRadius: BorderRadius.circular(14),
                    splashColor: deleteAccentColor.withOpacity(0.2),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: canDelete
                            ? deleteActionBackground
                            : deleteActionBackground.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: canDelete
                              ? deleteActionBorder.withOpacity(0.8)
                              : deleteActionBorder.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: canDelete
                            ? deleteAccentColor
                            : deleteAccentColor.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
