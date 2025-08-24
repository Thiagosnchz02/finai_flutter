// lib/features/settings/widgets/mfa_dialogs.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finai_flutter/features/settings/services/settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diálogo para mostrar el QR code y pedir el primer código de verificación.
Future<bool> showMfaEnrollDialog(BuildContext context) async {
  final settingsService = SettingsService();
  final factor = await Supabase.instance.client.auth.mfa.enroll(factorType: FactorType.totp);

  if (factor.totp == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al generar el código QR para 2FA.'), backgroundColor: Colors.red),
    );
    return false;
  }
  final qrCodeSvg = factor.totp!.qrCode;
  
  final code = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final codeController = TextEditingController();
      return AlertDialog(
        title: const Text('Activar 2FA - Paso 1 de 2'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escanea este código QR con tu aplicación de autenticación (Google Authenticator, Authy, etc.).'),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 200,
                child: SvgPicture.string(qrCodeSvg),
              ),
              const SizedBox(height: 16),
              const Text('Luego, introduce el código de 6 dígitos que te genere la aplicación.'),
              TextField(
                controller: codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(codeController.text),
            child: const Text('Verificar'),
          ),
        ],
      );
    },
  );

  if (code == null || code.isEmpty) return false;

  try {
    await settingsService.verifyMfa(factor.id, code);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡2FA activado con éxito!'), backgroundColor: Colors.green),
    );
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al verificar el código: ${e.toString()}'), backgroundColor: Colors.red),
    );
    return false;
  }
}

/// Diálogo para confirmar la desactivación de 2FA.
Future<bool> showMfaUnenrollDialog(BuildContext context) async {
  final settingsService = SettingsService();
  final response = await Supabase.instance.client.auth.mfa.listFactors();
  
  // --- CORRECCIÓN DEFINITIVA AQUÍ ---
  // Accedemos a la lista de factores a través de la propiedad '.all'
  final totpFactor = response.all.firstWhere(
    (f) => f.factorType == FactorType.totp,
    orElse: () => throw Exception('No se encontró un factor TOTP activo')
  );

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Desactivar 2FA?'),
      content: const Text('¿Estás seguro de que quieres desactivar la autenticación de dos factores? Tu cuenta será menos segura.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmar Desactivación'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  try {
    await settingsService.unenrollMfa(totpFactor.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2FA desactivado con éxito.'), backgroundColor: Colors.orange),
    );
    return true;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al desactivar 2FA: ${e.toString()}'), backgroundColor: Colors.red),
    );
    return false;
  }
}