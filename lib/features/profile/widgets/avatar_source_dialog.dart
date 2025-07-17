import "package:flutter/material.dart";

// Se elimina AvatarSource.avataaars
enum AvatarSource { generativeAI, metaImport }

Future<AvatarSource?> showAvatarSourceDialog(BuildContext context) {
  return showDialog<AvatarSource>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Selecciona el origen del avatar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Se elimina la ListTile de Avataaars
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generar con IA'),
              onTap: () => Navigator.pop(context, AvatarSource.generativeAI),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt), // Icono cambiado para más claridad
              title: const Text('Importar de Facebook/Instagram'),
              onTap: () => Navigator.pop(context, AvatarSource.metaImport),
            ),
          ],
        ),
      );
    },
  );
}
