// lib/features/accounts/widgets/swipe_action_button.dart

import 'package:flutter/material.dart';

/// Botón de acción para el swipe horizontal en AccountCard
class SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const SwipeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A), // Negro brillante
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container que agrupa los botones de acción del swipe
class SwipeActionsOverlay extends StatelessWidget {
  final VoidCallback? onAddMoney;
  final VoidCallback? onTransfer;
  final VoidCallback? onManageSavings;
  final bool isSavingsAccount;

  const SwipeActionsOverlay({
    super.key,
    this.onAddMoney,
    this.onTransfer,
    this.onManageSavings,
    this.isSavingsAccount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSavingsAccount)
            SwipeActionButton(
              icon: Icons.add_circle_outline,
              label: 'Añadir',
              color: const Color(0xFF25C9A4), // Verde
              onPressed: onAddMoney,
            ),
          if (!isSavingsAccount) const SizedBox(width: 8),
          SwipeActionButton(
            icon: Icons.sync_alt_rounded,
            label: 'Transferir',
            color: const Color(0xFF4a0873), // Morado
            onPressed: onTransfer,
          ),
          if (isSavingsAccount) const SizedBox(width: 8),
          if (isSavingsAccount)
            SwipeActionButton(
              icon: Icons.flag_outlined,
              label: 'Goals',
              color: const Color(0xFFFF6B9D), // Rosa
              onPressed: onManageSavings,
            ),
        ],
      ),
    );
  }
}
