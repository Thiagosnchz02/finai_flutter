import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/avatar_service.dart';

class GenerativeAiScreen extends StatefulWidget {
  const GenerativeAiScreen({super.key});

  @override
  State<GenerativeAiScreen> createState() => _GenerativeAiScreenState();
}

class _GenerativeAiScreenState extends State<GenerativeAiScreen> {
  // Controladores para todos los campos de texto
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _backgroundController = TextEditingController();
  final TextEditingController _perspectiveController = TextEditingController();
  
  String? _selectedStyle;
  bool _isLoading = false;
  String? _error;
  List<String> _generatedUrls = [];

  bool _canGenerate = true;
  int _countdownSeconds = 15;

  final AvatarService _avatarService = AvatarService();
  final List<String> _styles = ['Cartoon', 'Pixar', 'Ghibli', 'Realista', 'Anime', 'Cyberpunk'];

  @override
  void dispose() {
    _promptController.dispose();
    _actionController.dispose();
    _backgroundController.dispose();
    _perspectiveController.dispose();
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
      _canGenerate = false;
    });

    try {
      final generatedUrls = await _avatarService.generateAvatar(
        type: 'TEXT_TO_IMAGE',
        prompt: _promptController.text.trim(),
        style: _selectedStyle,
        action: _actionController.text.trim(),
        background: _backgroundController.text.trim(),
        perspective: _perspectiveController.text.trim(),
      );
      setState(() {
        _generatedUrls = generatedUrls;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el avatar: $_error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    const oneSec = Duration(seconds: 1);
    int count = _countdownSeconds;

    Timer.periodic(oneSec, (Timer timer) {
      if (count == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canGenerate = true;
          });
        }
      } else {
        count--;
      }
    });
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
            Text('1. Describe tu avatar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLength: 300,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ej: Un gato astronauta con gafas de sol...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN DE OPCIONES AVANZADAS ---
            ExpansionTile(
              title: Text('Opciones avanzadas (Opcional)', style: Theme.of(context).textTheme.titleMedium),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    children: [
                      _buildAdvancedTextField(_actionController, 'Acción', 'Ej: saltando, sonriendo...'),
                      const SizedBox(height: 12),
                      _buildAdvancedTextField(_backgroundController, 'Fondo', 'Ej: un bosque, una ciudad...'),
                      const SizedBox(height: 12),
                      _buildAdvancedTextField(_perspectiveController, 'Perspectiva', 'Ej: vista frontal, plano cenital...'),
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 24),
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
                    setState(() { _selectedStyle = selected ? style : null; });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedStyle == style ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: (_canGenerate && !_isLoading) ? _generateAvatar : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _canGenerate ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : Text(_canGenerate ? 'Generar Avatar' : 'Espera un momento...', style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 24),
            
            if (_generatedUrls.isNotEmpty)
              Text('3. Elige tu favorito', style: Theme.of(context).textTheme.titleLarge),
            if (_generatedUrls.isNotEmpty)
              const SizedBox(height: 8),
            if (_generatedUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
                ),
                itemCount: _generatedUrls.length,
                itemBuilder: (context, index) {
                  final url = _generatedUrls[index];
                  return GestureDetector(
                    onTap: () { Navigator.of(context).pop({'type': 'ai', 'url': url}); },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          return progress == null ? child : const Center(child: CircularProgressIndicator());
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

  // Widget helper para los campos de texto avanzados
  Widget _buildAdvancedTextField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
