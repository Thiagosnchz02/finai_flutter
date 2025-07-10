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

  @override
  Widget build(BuildContext context) {
    // Usamos un Consumer para escuchar los cambios en nuestro provider
    return Consumer<AvatarCreatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Crea tu Avatar'),
            actions: [
              // Botón para guardar el avatar final
              TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final finalUrl = await provider.createFinalAvatar();
                        if (mounted && finalUrl != null) {
                          Navigator.of(context).pop(finalUrl);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo crear el avatar.')),
                          );
                        }
                      },
                child: provider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Guardar'),
              )
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AvatarCreatorProvider provider) {
    if (provider.isLoading && provider.previewUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    return Column(
      children: [
        // --- SECCIÓN DE PREVISUALIZACIÓN ---
        _buildPreviewSection(context, provider),
        
        // --- SECCIÓN DE CATEGORÍAS ---
        _buildCategorySelector(provider),
        
        // --- SECCIÓN DE ASSETS ---
        Expanded(
          child: _buildAssetGrid(provider),
        ),
      ],
    );
  }

  // Widget para la previsualización del avatar
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

  // Widget para los botones de selección de categoría (Pelo, Ojos, etc.)
  Widget _buildCategorySelector(AvatarCreatorProvider provider) {
    // Categorías que queremos mostrar. Puedes añadir más.
    final categories = ['faceShape', 'eyes', 'eyebrows', 'hair', 'mouth', 'beard', 'glasses', 'outfit'];
    
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedCategory = category),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
                foregroundColor: isSelected ? Colors.white : null,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              child: Text(category), // Puedes poner nombres más amigables
            ),
          );
        },
      ),
    );
  }

  // Widget para la cuadrícula de assets de la categoría seleccionada
  Widget _buildAssetGrid(AvatarCreatorProvider provider) {
    // Obtenemos la lista de assets para la categoría seleccionada
    final List<dynamic> assets = provider.availableAssets[_selectedCategory] ?? [];

    if (assets.isEmpty) {
      return const Center(child: Text('No hay opciones para esta categoría.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 assets por fila
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final int assetId = asset['id'];
        final String? iconUrl = asset['icon'];

        // Verificamos si este asset es el que está seleccionado actualmente
        final bool isSelected = provider.selectedAssets['assets']?[_selectedCategory] == assetId;

        return GestureDetector(
          onTap: () => provider.selectAsset(_selectedCategory, assetId),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: iconUrl != null
                ? Image.network(iconUrl, fit: BoxFit.contain)
                : const Icon(Icons.help_outline),
          ),
        );
      },
    );
  }
}