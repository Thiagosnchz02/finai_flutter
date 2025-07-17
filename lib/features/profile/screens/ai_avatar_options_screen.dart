import 'package:flutter/material.dart';

class AiAvatarOptionsScreen extends StatelessWidget {
  const AiAvatarOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Avatar con IA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige un método',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes crear un avatar único a partir de una foto tuya o describiendo tu idea con palabras.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _OptionCard(
              icon: Icons.photo_camera_back_outlined,
              title: 'Generar desde Foto',
              subtitle: 'Sube un selfie y transfórmalo en diferentes estilos artísticos.',
              tooltipText: 'Usaremos tu foto como base para crear un avatar que se parezca a ti, aplicando el estilo que elijas (ej. Pixar, Ghibli, etc.).',
              onTap: () {
                Navigator.of(context).pushNamed('/avatar/image-to-image');
              },
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.text_fields_rounded,
              title: 'Generar desde Texto',
              subtitle: 'Usa tu imaginación y describe el avatar que quieres crear.',
              tooltipText: 'Escribe una descripción detallada (ej. "astronauta con pelo azul, estilo cartoon") y la IA la convertirá en una imagen. ¡El límite es tu creatividad!',
              onTap: () {
                Navigator.of(context).pushNamed('/avatar/generative');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget interno reutilizable para las tarjetas de opción
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tooltipText;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tooltipText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(title),
                      content: Text(tooltipText),
                      actions: [
                        TextButton(
                          child: const Text('Entendido'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Más información',
              ),
            ],
          ),
        ),
      ),
    );
  }
}