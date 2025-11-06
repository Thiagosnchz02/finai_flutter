// lib/features/transactions/widgets/transaction_tile.dart

import 'dart:ui';
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
    final bool isTransfer = transaction.type == 'traspaso';
    
    // Para transferencias, determinar si es entrada o salida según el signo del amount
    final bool isTransferOut = isTransfer && transaction.amount < 0;
    final bool isTransferIn = isTransfer && transaction.amount >= 0;

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
            : isTransferIn
                ? '+'
                : isTransferOut
                    ? '-'
                    : '';
    final double amountForDisplay = amountPrefix.isEmpty
        ? transaction.amount
        : transaction.amount.abs();
    final String amountString =
        '$amountPrefix${currencyFormatter.format(amountForDisplay)}';

    final IconData iconData = isTransferOut
        ? Icons.trending_down  // Transferencia salida: mismo icono que gastos
        : isTransferIn
            ? Icons.trending_up  // Transferencia entrada: mismo icono que ingresos
            : isTransfer
                ? Icons.swap_horiz  // Fallback para transferencias sin signo claro
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

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
    );

    // Para traspasos, mostrar "Entre Cuentas Propias" (retrocompatibilidad para traspasos antiguos sin categoría)
    final String categoryName = isTransfer 
        ? (transaction.category?.name ?? 'Entre Cuentas Propias')
        : (transaction.category?.name ?? 'Sin Categoría');
    
    final subtitleText = '$categoryName · ${DateFormat.Hm().format(transaction.date)}';

    final Color deleteAccentColor = const Color(0xFFFF6B6B);
    final bool canDelete = onDelete != null;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D0D0D).withOpacity(0.95), // Negro brillante arriba
                  const Color(0xFF000000).withOpacity(0.9), // Negro puro abajo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x26FFFFFF), // Borde blanco más sutil
                width: 0.8,
              ),
              boxShadow: [
                // Sombra exterior
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // Highlight superior (brillo)
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -5,
                  offset: const Offset(0, -4),
                ),
                // Brillo interno púrpura
                BoxShadow(
                  color: const Color(0xFF700aa3).withOpacity(0.12),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 0),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle, // Forma circular
              ),
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
                    borderRadius: BorderRadius.circular(24),
                    splashColor: deleteAccentColor.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.delete_outline,
                        color: canDelete
                            ? deleteAccentColor
                            : deleteAccentColor.withOpacity(0.45),
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
        ),
      ),
    );
  }
}
