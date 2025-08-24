// lib/features/settings/widgets/settings_widgets.dart

import 'package:flutter/material.dart';

/// Un contenedor de tarjeta estandarizado para las secciones de configuración.
class SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}


/// Una fila para configuraciones que usan un interruptor (Switch).
class SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Una fila para opciones que navegan a otra pantalla.
class SettingsNavigationRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsNavigationRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Una fila para acciones que ejecutan una función, a menudo con un color distintivo.
class SettingsActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const SettingsActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(label, style: TextStyle(color: textColor)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}