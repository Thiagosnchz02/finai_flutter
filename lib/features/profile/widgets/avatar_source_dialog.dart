import "package:flutter/material.dart";
enum AvatarSource { avataaars, generativeAI, metaImport }

Future<AvatarSource?> showAvatarSourceDialog(BuildContext context) {
  return showDialog<AvatarSource>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Selecciona el origen del avatar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Avataaars (2D SVG)'),
              onTap: () => Navigator.pop(context, AvatarSource.avataaars),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generative AI'),
              onTap: () => Navigator.pop(context, AvatarSource.generativeAI),
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Importar de Facebook/Instagram'),
              onTap: () => Navigator.pop(context, AvatarSource.metaImport),
            ),
          ],
        ),
      );
    },
  );
}
