// lib/features/accounts/widgets/account_button_styles.dart

import 'package:flutter/material.dart';

class AccountButtonStyles {
  AccountButtonStyles._();

  static final ButtonStyle maroon = _base(
    backgroundColor: const Color(0xFF1a266b).withOpacity(0.2), // Azul casi transparente como "Guardar Transacción"
    borderColor: const Color(0xFF1a266b).withOpacity(0.4),
    foregroundColor: Colors.white,
  );

  static final ButtonStyle pink = _base(
    backgroundColor: const Color(0xFF1a266b).withOpacity(0.2), // Mismo estilo azul
    borderColor: const Color(0xFF1a266b).withOpacity(0.4),
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
        borderRadius: BorderRadius.circular(14), // Consistente con "Guardar Transacción"
      ),
      side: BorderSide(color: borderColor, width: 0.8), // Width consistente
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.bold,
        fontSize: 15,
        letterSpacing: 0.5,
      ),
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
          return BorderSide(color: disabledBorder, width: 0.8);
        }
        return BorderSide(color: borderColor, width: 0.8);
      }),
    );
  }
}
