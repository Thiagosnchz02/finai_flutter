// lib/features/accounts/widgets/accounts_action_button.dart

import 'package:flutter/material.dart';

class AccountsActionButton extends StatelessWidget {
  const AccountsActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isEnabled ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white.withOpacity(isEnabled ? 0.95 : 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
