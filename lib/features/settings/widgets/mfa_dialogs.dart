// lib/features/settings/widgets/mfa_dialogs.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final secret = factor.totp!.secret;
  
  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final codeController = TextEditingController();
      bool isValid = false;
      bool isVerifying = false;
      String? errorText;
      final regExp = RegExp(r'^[0-9]{6}$');
      return StatefulBuilder(
        builder: (context, setState) {
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
                  Row(
                    children: [
                      Expanded(child: SelectableText(secret)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: secret));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Clave copiada al portapapeles')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Luego, introduce el código de 6 dígitos que te genere la aplicación.'),
                  TextField(
                    controller: codeController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Código de 6 dígitos',
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isValid = regExp.hasMatch(value);
                        errorText = isValid ? null : 'Ingrese un código válido de 6 dígitos';
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isValid && !isVerifying
                    ? () async {
                        setState(() => isVerifying = true);
                        try {
                          await settingsService.verifyMfa(factor.id, codeController.text);
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              isVerifying = false;
                              errorText = 'Código inválido';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al verificar el código: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    : null,
                child: isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verificar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (success == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡2FA activado con éxito!'), backgroundColor: Colors.green),
    );
    return true;
  }
  return false;
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

  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      bool isVerifying = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('¿Desactivar 2FA?'),
            content: const Text('¿Estás seguro de que quieres desactivar la autenticación de dos factores? Tu cuenta será menos segura.'),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isVerifying
                    ? null
                    : () async {
                        setState(() => isVerifying = true);
                        try {
                          await settingsService.unenrollMfa(totpFactor.id);
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isVerifying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al desactivar 2FA: ${e.toString()}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar Desactivación'),
              ),
            ],
          );
        },
      );
    },
  );

  if (success == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('2FA desactivado con éxito.'), backgroundColor: Colors.orange),
    );
    return true;
  }
  return false;
}