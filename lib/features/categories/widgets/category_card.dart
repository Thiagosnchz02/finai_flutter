// lib/features/categories/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/category_service.dart'; // Para obtener el modelo Category

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onArchive,
    required this.onTap,
  });

  // Ayudante para obtener un IconData a partir de un String
  IconData _getIconFromString(String? iconName) {
    // Esto es un placeholder. En una app real, tendrías un mapa o un sistema más robusto.
    // Por ahora, usamos algunos iconos por defecto.
    switch (iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }


  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getIconFromString(category.iconData), color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!category.isStandard)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'archive') {
                          onArchive();
                        }
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'archive',
                          child: Text('Archivar'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}