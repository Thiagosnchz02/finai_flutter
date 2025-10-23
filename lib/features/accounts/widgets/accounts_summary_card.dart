// lib/features/accounts/widgets/accounts_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../presentation/widgets/glass_card.dart';

class AccountsSummaryCard extends StatelessWidget {
  final String title;
  final double totalAmount;
  final String? headerTitle;
  final IconData iconData;
  final Gradient gradient;
  final Color borderColor;
  final List<BoxShadow> boxShadows;
  final Color iconBackgroundColor;
  final Color iconBorderColor;
  final Color iconColor;
  final List<Widget> headerActions;
  final Widget? child; // Para la lista de cuentas o CTA

  const AccountsSummaryCard({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.iconData,
    this.headerTitle,
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF952D65),
        Color(0xFF3D0020),
      ],
      stops: [0, 0.7071],
    ),
    this.borderColor = const Color(0x57FF0088),
    this.boxShadows = const [
      BoxShadow(
        color: Color(0x40000000),
        offset: Offset(0, 25),
        blurRadius: 50,
        spreadRadius: 0,
      ),
    ],
    this.iconBackgroundColor = const Color(0xFFFF0088),
    this.iconBorderColor = Colors.transparent,
    this.iconColor = Colors.white,
    this.headerActions = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTotal = NumberFormat.currency(locale: 'es_ES', symbol: '€').format(totalAmount);
    
    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(kCardBorderRadius),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: boxShadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerTitle != null || headerActions.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (headerTitle != null)
                      Expanded(
                        child: Text(
                          headerTitle!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (headerActions.isNotEmpty) ...[
                      if (headerTitle != null) const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: headerActions,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _AccountsSummaryIcon(
                    iconData: iconData,
                    backgroundColor: iconBackgroundColor,
                    borderColor: iconBorderColor,
                    iconColor: iconColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  formattedTotal,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    color: Colors.white,
                  ),
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

class _AccountsSummaryIcon extends StatelessWidget {
  final IconData iconData;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const _AccountsSummaryIcon({
    required this.iconData,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: FaIcon(
          iconData,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }
}