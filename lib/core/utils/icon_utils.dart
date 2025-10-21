import 'package:flutter/material.dart';

IconData parseIconFromHex(String? iconHex, {IconData fallback = Icons.category}) {
  if (iconHex == null || iconHex.isEmpty) {
    return fallback;
  }

  try {
    final cleaned = iconHex.startsWith('0x') ? iconHex.substring(2) : iconHex;
    final codePoint = int.parse(cleaned, radix: 16);
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  } catch (_) {
    return fallback;
  }
}
