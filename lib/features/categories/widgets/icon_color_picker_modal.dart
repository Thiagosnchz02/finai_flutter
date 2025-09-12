// lib/features/categories/widgets/icon_color_picker_modal.dart

import 'package:flutter/material.dart';

// Mapa para asociar nombres de string con objetos IconData
const Map<String, IconData> kCategoryIcons = {
  'category': Icons.category_rounded,
  'home': Icons.home_rounded,
  'food': Icons.restaurant_rounded,
  'transport': Icons.directions_car_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'health': Icons.local_hospital_rounded,
  'entertainment': Icons.movie_rounded,
  'education': Icons.school_rounded,
  'bills': Icons.receipt_long_rounded,
  'savings': Icons.savings_rounded,
  'gift': Icons.card_giftcard_rounded,
  'pets': Icons.pets_rounded,
};

// Paleta de colores predefinida
const List<Color> kCategoryColors = [
  Color(0xFF5A67D8), Color(0xFF9F7AEA), Color(0xFFED64A6), Color(0xFFF56565),
  Color(0xFFED8936), Color(0xFFECC94B), Color(0xFF48BB78), Color(0xFF38B2AC),
  Color(0xFF4299E1), Color(0xFF667EEA), Color(0xFFB794F4), Color(0xFFF687B3),
];


class IconColorPickerModal extends StatefulWidget {
  final String initialIcon;
  final String initialColor;

  const IconColorPickerModal({
    super.key,
    required this.initialIcon,
    required this.initialColor,
  });

  @override
  State<IconColorPickerModal> createState() => _IconColorPickerModalState();
}

class _IconColorPickerModalState extends State<IconColorPickerModal> {
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Iconos
          Text('Selecciona un Icono', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 150, // Altura fija para la cuadrícula de iconos
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: kCategoryIcons.length,
              itemBuilder: (context, index) {
                final iconName = kCategoryIcons.keys.elementAt(index);
                final iconData = kCategoryIcons.values.elementAt(index);
                final isSelected = _selectedIcon == iconName;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconData, color: isSelected ? Colors.white : null),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Colores
          Text('Selecciona un Color', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kCategoryColors.map((color) {
              final colorHex = color.value.toRadixString(16).substring(2).toUpperCase();
              final isSelected = _selectedColor == colorHex;

              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Theme.of(context).indicatorColor, width: 3) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Botón de confirmación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Devuelve los valores seleccionados a la pantalla anterior
                Navigator.pop(context, {
                  'icon': _selectedIcon,
                  'color': _selectedColor,
                });
              },
              child: const Text('Seleccionar'),
            ),
          ),
        ],
      ),
    );
  }
}