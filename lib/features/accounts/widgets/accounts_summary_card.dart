// lib/features/accounts/widgets/accounts_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../presentation/widgets/glass_card.dart';

class AccountsSummaryCard extends StatelessWidget {
  final String title;
  final double totalAmount;
  final IconData iconData;
  final Color neonColor;
  final Widget? child; // Para la lista de cuentas o CTA

  const AccountsSummaryCard({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.iconData,
    required this.neonColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat.currency(locale: 'es_ES', symbol: '€').format(totalAmount);
    
    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kCardBorderRadius),
          border: Border.all(color: neonColor.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: neonColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(iconData, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(title, style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8))),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  formattedTotal,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (child != null) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}