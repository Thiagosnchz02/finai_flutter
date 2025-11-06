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
      borderRadius: BorderRadius.circular(18), // Reducido de 24 a 18
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18), // Reducido de 24 a 18
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Reducido de 25 a 20
          child: Container(
            padding: const EdgeInsets.all(14), // Reducido de 20 a 14 (30% menos)
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D0D0D).withOpacity(0.92), // Ligeramente más transparente
                  const Color(0xFF000000).withOpacity(0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18), // Reducido de 24 a 18
              border: Border.all(
                color: const Color(0x1FFFFFFF), // Borde más sutil (reducido de 0x26 a 0x1F)
                width: 0.6, // Reducido de 0.8 a 0.6
              ),
              boxShadow: [
                // Sombra exterior más sutil
                BoxShadow(
                  color: Colors.black.withOpacity(0.4), // Reducido de 0.5 a 0.4
                  blurRadius: 15, // Reducido de 20 a 15
                  spreadRadius: 0,
                  offset: const Offset(0, 6), // Reducido de 8 a 6
                ),
                // Highlight superior (brillo) más sutil
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withOpacity(0.15), // Reducido de 0.2 a 0.15
                  blurRadius: 8, // Reducido de 10 a 8
                  spreadRadius: -4, // Ajustado de -5 a -4
                  offset: const Offset(0, -3), // Reducido de -4 a -3
                ),
                // Brillo interno púrpura más sutil
                BoxShadow(
                  color: const Color(0xFF700aa3).withOpacity(0.08), // Reducido de 0.12 a 0.08
                  blurRadius: 20, // Reducido de 30 a 20
                  spreadRadius: -6, // Ajustado de -8 a -6
                  offset: const Offset(0, 0),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Container(
              width: 48, // Reducido de 52 a 48
              height: 48, // Reducido de 52 a 48
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle, // Forma circular
              ),
              child: Icon(
                iconData,
                color: amountColor,
                size: 24, // Reducido de tamaño default (24) para que se vea proporcionado
              ),
            ),
            const SizedBox(width: 12), // Reducido de 16 a 12
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
                          padding: EdgeInsets.only(left: 6.0), // Reducido de 8 a 6
                          child: Icon(
                            Icons.autorenew,
                            size: 14, // Reducido de 16 a 14
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
