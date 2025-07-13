import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_creator_provider.dart';

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  // Categoría de assets seleccionada actualmente (pelo, ojos, etc.)
  String _selectedCategory = 'faceShape';

  // Mapeo de nombres técnicos a nombres amigables para la UI
  final Map<String, String> _categoryDisplayNames = {
    'faceShape': 'Rostro',
    'eyes': 'Ojos',
    'eyebrows': 'Cejas',
    'hair': 'Pelo',
    'beard': 'Barba',
    'glasses': 'Gafas',
    'outfit': 'Ropa',
    'headwear': 'Gorros',
    'facewear': 'Acc. Cara',
    'lipShape': 'Labios',
    'mouth': 'Boca',
    'noseShape': 'Nariz',
  };

  @override
  Widget build(BuildContext context) {
    // Usamos un Consumer para escuchar los cambios en nuestro provider y reconstruir la UI.
    return Consumer<AvatarCreatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Crea tu Avatar'),
            actions: [
              // Botón para guardar el avatar final
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final finalUrl = await provider.createFinalAvatar();
                          if (mounted && finalUrl != null) {
                            // Si se crea con éxito, devolvemos la URL a la pantalla anterior.
                            Navigator.of(context).pop(finalUrl);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No se pudo crear el avatar.')),
                            );
                          }
                        },
                  child: provider.isLoading && provider.previewUrl != null // Muestra carga solo al guardar
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              )
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  /// Construye el cuerpo principal de la pantalla.
  Widget _buildBody(BuildContext context, AvatarCreatorProvider provider) {
    // Muestra un indicador de carga grande solo la primera vez.
    if (provider.isLoading && provider.previewUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Muestra un mensaje de error si algo falló al cargar los assets.
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    return Column(
      children: [
        // --- SECCIÓN DE PREVISUALIZACIÓN ---
        _buildPreviewSection(context, provider),
        
        // --- SECCIÓN DE CATEGORÍAS ---
        _buildCategorySelector(provider),
        
        // --- SECCIÓN DE ASSETS (opciones) ---
        Expanded(
          child: _buildAssetGrid(provider),
        ),
      ],
    );
  }

  /// Widget para la previsualización del avatar.
  Widget _buildPreviewSection(BuildContext context, AvatarCreatorProvider provider) {
    return Container(
      height: 250,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: provider.previewUrl == null
            ? const CircularProgressIndicator()
            : Image.network(
                provider.previewUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline, size: 60);
                },
              ),
      ),
    );
  }

  /// Widget para los botones de selección de categoría (Pelo, Ojos, etc.).
  Widget _buildCategorySelector(AvatarCreatorProvider provider) {
    // Usamos las claves de nuestro mapa de nombres para asegurar consistencia
    final categories = _categoryDisplayNames.keys.toList();
    
    return SizedBox(
      height: 60, // Aumentamos un poco la altura para que se vea mejor
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryKey = categories[index];
          final displayName = _categoryDisplayNames[categoryKey] ?? categoryKey;
          final isSelected = _selectedCategory == categoryKey;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedCategory = categoryKey),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                foregroundColor: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(displayName),
            ),
          );
        },
      ),
    );
  }

  /// Widget para la cuadrícula de assets de la categoría seleccionada.
  Widget _buildAssetGrid(AvatarCreatorProvider provider) {
    final List<dynamic> assets = provider.availableAssets[_selectedCategory] ?? [];

    if (assets.isEmpty) {
      return const Center(child: Text('No hay opciones para esta categoría.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final int assetId = asset['id'];
        final String? iconUrl = asset['icon'];
        final bool isSelected = provider.selectedAssets[_selectedCategory] == assetId;

        return GestureDetector(
          onTap: () => provider.selectAsset(_selectedCategory, assetId),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade800,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(iconUrl, fit: BoxFit.contain)
                  )
                : const Icon(Icons.help_outline),
          ),
        );
      },
    );
  }
}