import 'package:flutter/material.dart';
import '../../../core/services/n8n_service.dart';

class GenerativeAiScreen extends StatefulWidget {
  const GenerativeAiScreen({super.key});

  @override
  State<GenerativeAiScreen> createState() => _GenerativeAiScreenState();
}

class _GenerativeAiScreenState extends State<GenerativeAiScreen> {
  // Estado del widget
  final TextEditingController _promptController = TextEditingController();
  String? _selectedStyle;
  bool _isLoading = false;
  String? _error;
  List<String> _generatedUrls = [];

  final N8nService _n8nService = N8nService();

  final List<String> _styles = ['Cartoon', 'Pixar', 'Ghibli', 'Realista', 'Anime', 'Cyberpunk'];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateAvatar() async {
    if (_promptController.text.trim().isEmpty || _selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe una descripción y elige un estilo.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _generatedUrls = [];
    });

    try {
      // Llamamos a nuestro servicio n8n con el tipo correcto
      final generatedUrls = await _n8nService.generateAvatar(
        type: 'TEXT_TO_IMAGE',
        prompt: _promptController.text.trim(),
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
        title: const Text('Avatar con IA (Texto)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Sección de Prompt ---
            Text('1. Describe tu avatar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLength: 300,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ej: Un gato astronauta con gafas de sol, fondo de galaxias...',
                border: OutlineInputBorder(),
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
              onPressed: (_promptController.text.isNotEmpty && _selectedStyle != null && !_isLoading) ? _generateAvatar : null,
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