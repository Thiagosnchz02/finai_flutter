// lib/features/accounts/widgets/account_button_styles.dart

import 'package:flutter/material.dart';

class AccountButtonStyles {
  AccountButtonStyles._();

  static final ButtonStyle maroon = _base(
    backgroundColor: const Color(0xFF2E0019),
    borderColor: const Color(0xFFFF0088),
    foregroundColor: Colors.white,
  );

  static final ButtonStyle pink = _base(
    backgroundColor: const Color(0xFFFF0088),
    borderColor: const Color(0xFFFF0088),
    foregroundColor: Colors.white,
  );

  static ButtonStyle _base({
    required Color backgroundColor,
    required Color borderColor,
    required Color foregroundColor,
  }) {
    final disabledBackground = backgroundColor.withOpacity(0.55);
    final disabledBorder = borderColor.withOpacity(0.55);
    final disabledForeground = foregroundColor.withOpacity(0.7);

    return TextButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(color: borderColor, width: 1.4),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return disabledBackground;
        }
        if (states.contains(MaterialState.pressed)) {
          return backgroundColor.withOpacity(0.9);
        }
        return backgroundColor;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return disabledForeground;
        }
        return foregroundColor;
      }),
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return foregroundColor.withOpacity(0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return foregroundColor.withOpacity(0.06);
        }
        return null;
      }),
      side: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return BorderSide(color: disabledBorder, width: 1.4);
        }
        return BorderSide(color: borderColor, width: 1.4);
      }),
    );
  }
}
