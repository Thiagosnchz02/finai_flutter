// lib/features/settings/widgets/delete_account_dialog.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/settings/services/settings_service.dart';

/// Muestra un diálogo de confirmación para eliminar la cuenta del usuario.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final settingsService = SettingsService();
  final success = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final passwordController = TextEditingController();
      bool isDeleting = false;
      String? errorText;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Eliminar Cuenta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ingresa tu contraseña para confirmar la eliminación de tu cuenta.'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() {
                          isDeleting = true;
                          errorText = null;
                        });
                        try {
                          await settingsService.deleteAccount(passwordController.text);
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              isDeleting = false;
                              errorText = 'Error: ${e.toString()}';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al eliminar cuenta: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Eliminar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (success == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta eliminada con éxito.'), backgroundColor: Colors.green),
    );
    return true;
  }
  return false;
}

