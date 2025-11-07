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
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF4a0873).withOpacity(0.2),
                          const Color(0xFF4a0873).withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isEnabled ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4a0873).withOpacity(isEnabled ? 0.3 : 0.1),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isEnabled ? const Color(0xFF4a0873) : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
