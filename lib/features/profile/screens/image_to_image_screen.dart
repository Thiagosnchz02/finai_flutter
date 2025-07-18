import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/n8n_service.dart';

class ImageToImageScreen extends StatefulWidget {
  const ImageToImageScreen({super.key});

  @override
  State<ImageToImageScreen> createState() => _ImageToImageScreenState();
}

class _ImageToImageScreenState extends State<ImageToImageScreen> {
  // Estado del widget
  XFile? _selectedImage;
  String? _selectedStyle;
  bool _isLoading = false;
  String? _error;
  List<String> _generatedUrls = [];

  final ImagePicker _picker = ImagePicker();
  final N8nService _n8nService = N8nService();

  final List<String> _styles = ['Cartoon', 'Pixar', 'Ghibli', 'Realista', 'Anime', 'Cyberpunk'];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _generateAvatar() async {
    if (_selectedImage == null || _selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen y un estilo.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _generatedUrls = [];
    });

    try {
      // 1. Leer la imagen y convertirla a Base64
      final imageBytes = await File(_selectedImage!.path).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. Llamar al servicio de n8n
      final generatedUrls = await _n8nService.generateAvatar(
        type: 'IMAGE_TO_IMAGE',
        baseImage: base64Image,
        style: _selectedStyle,
      );

      setState(() {
        _generatedUrls = generatedUrls;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al generar el avatar: $_error')),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar con IA (Foto)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Sección de Carga de Imagen ---
            Text('1. Sube una foto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(16),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(File(_selectedImage!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            const Text('Toca para seleccionar una foto'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 24),

            // --- Sección de Selección de Estilo ---
            Text('2. Elige un estilo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _styles.map((style) {
                return ChoiceChip(
                  label: Text(style),
                  selected: _selectedStyle == style,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStyle = selected ? style : null;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedStyle == style ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            // --- Botón de Generar ---
            ElevatedButton(
              onPressed: (_selectedImage != null && _selectedStyle != null && !_isLoading) ? _generateAvatar : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : const Text('Generar Avatar', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 24),

            // --- Sección de Resultados ---
            if (_generatedUrls.isNotEmpty)
              Text('3. Elige tu favorito', style: Theme.of(context).textTheme.titleLarge),
            if (_generatedUrls.isNotEmpty)
              const SizedBox(height: 8),
            if (_generatedUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _generatedUrls.length,
                itemBuilder: (context, index) {
                  final url = _generatedUrls[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop({'type': 'ai', 'url': url});
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}