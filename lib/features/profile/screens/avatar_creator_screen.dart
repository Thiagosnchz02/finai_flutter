// lib/features/avatar/screens/avatar_creator_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_creator_provider.dart';

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  String _selectedCategory = 'faceshape';
  final Map<String, String> _categoryDisplayNames = {
    'faceshape': 'Rostro',
    'eyes': 'Ojos',
    'eyebrows': 'Cejas',
    'hair': 'Pelo',
    'beard': 'Barba',
    'glasses': 'Gafas',
    'outfit': 'Ropa',
    'headwear': 'Gorros',
    'facewear': 'Acc. Cara',
    'lipshape': 'Labios',
    'mouth': 'Boca',
    'noseshape': 'Nariz',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AvatarCreatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Crea tu Avatar'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final finalUrl =
                              await provider.createFinalAvatar();
                          if (mounted && finalUrl != null) {
                            Navigator.of(context).pop(finalUrl);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('No se pudo crear el avatar.')),
                            );
                          }
                        },
                  child: provider.isLoading && provider.previewUrl != null
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

  Widget _buildBody(
      BuildContext context, AvatarCreatorProvider provider) {
    if (provider.isLoading && provider.previewUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }
    return Column(
      children: [
        _buildPreviewSection(context, provider),
        _buildCategorySelector(provider),
        Expanded(child: _buildAssetGrid(provider)),
      ],
    );
  }

  Widget _buildPreviewSection(
      BuildContext context, AvatarCreatorProvider provider) {
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
                  return const Center(
                      child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline, size: 60);
                },
              ),
      ),
    );
  }

  Widget _buildCategorySelector(
      AvatarCreatorProvider provider) {
    final categories = _categoryDisplayNames.keys.toList();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final key = categories[index];
          final displayName =
              _categoryDisplayNames[key] ?? key;
          final isSelected = _selectedCategory == key;
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () =>
                  setState(() => _selectedCategory = key),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Theme.of(context).cardColor,
                foregroundColor: isSelected
                    ? Colors.white
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
                side: BorderSide(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : Colors.grey.shade700),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20)),
              ),
              child: Text(displayName),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetGrid(
      AvatarCreatorProvider provider) {
    final assets =
        provider.availableAssets[_selectedCategory] ?? [];
    if (assets.isEmpty) {
      return const Center(
          child: Text('No hay opciones para esta página.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        // ID siempre como String
        final String assetId = asset['id'].toString();
        final String? iconUrl =
            asset['iconUrl'] as String?;
        final bool isSelected =
            provider.selectedAssets[_selectedCategory] ==
                assetId;
        return GestureDetector(
          onTap: () =>
              provider.selectAsset(_selectedCategory, assetId),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.grey.shade800,
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            child: iconUrl != null
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: Image.network(iconUrl,
                        fit: BoxFit.contain),
                  )
                : const Icon(Icons.help_outline),
          ),
        );
      },
    );
  }
}