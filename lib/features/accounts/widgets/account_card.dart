// lib/features/accounts/widgets/account_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account_model.dart';
import 'account_button_styles.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final bool? showAddMoneyButton;
  final bool? showManageSavingsButton;
  final VoidCallback? onAddMoney;
  final VoidCallback? onManageSavings;

  const AccountCard({
    super.key,
    required this.account,
    this.showAddMoneyButton,
    this.showManageSavingsButton,
    this.onAddMoney,
    this.onManageSavings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedBalance =
        NumberFormat.currency(locale: 'es_ES', symbol: '€').format(account.balance);
    final isSavingsAccount = account.conceptualType.toLowerCase() == 'ahorro';
    final shouldShowAddMoneyButton = showAddMoneyButton ?? !isSavingsAccount;
    final shouldShowManageSavingsButton =
        showManageSavingsButton ?? isSavingsAccount;
    final infoTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.86),
      fontWeight: FontWeight.w500,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccountInfoRow(
              label: 'Nombre',
              value: account.name,
              valueStyle: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            _AccountInfoRow(
              label: 'Banco',
              value: (account.bankName?.isNotEmpty ?? false)
                  ? account.bankName!
                  : 'Sin banco asociado',
              valueStyle: infoTextStyle,
            ),
            const SizedBox(height: 10),
            _AccountInfoRow(
              label: 'Tipo de cuenta',
              value: _prettyConceptualType(account.conceptualType, account.type),
              valueStyle: infoTextStyle,
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0x33FFFFFF), thickness: 1, height: 1),
            const SizedBox(height: 12),
            _AccountInfoRow(
              label: 'Saldo',
              value: formattedBalance,
              valueStyle: theme.textTheme.headlineSmall?.copyWith(
                color: account.balance < 0 ? const Color(0xFFFFD166) : const Color(0xFFADF6FF),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            if (shouldShowAddMoneyButton || shouldShowManageSavingsButton)
              const SizedBox(height: 18),
            if (shouldShowAddMoneyButton || shouldShowManageSavingsButton)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (shouldShowAddMoneyButton)
                    _AccountActionButton(
                      label: 'Añadir dinero',
                      onPressed: onAddMoney,
                      style: AccountButtonStyles.maroon,
                    ),
                  if (shouldShowManageSavingsButton)
                    _AccountActionButton(
                      label: 'Gestionar mis huchas',
                      onPressed: onManageSavings,
                      style: AccountButtonStyles.pink,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _prettyConceptualType(String conceptualType, String rawType) {
    final normalizedConcept = conceptualType.toLowerCase();
    switch (normalizedConcept) {
      case 'ahorro':
        return 'Ahorro';
      case 'nomina':
        return 'Gasto / Nómina';
      default:
        return rawType.isEmpty ? conceptualType : _capitalize(rawType);
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}