import 'package:flutter/material.dart';
import '../../../core/services/n8n_service.dart'; 

class GenerativeAiScreen extends StatefulWidget {
  const GenerativeAiScreen({super.key});

  @override
  State<GenerativeAiScreen> createState() => _GenerativeAiScreenState();
}

class _GenerativeAiScreenState extends State<GenerativeAiScreen> {
  final TextEditingController _promptController = TextEditingController();
  List<String> _urls = [];
  bool _loading = false;
  String? _error;

  // 2. Crear una instancia del servicio
  final N8nService _n8nService = N8nService();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // 3. Modificar la función `_generate` para usar el servicio
  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _urls = [];
    });

    try {
      final generatedUrls = await _n8nService.generateAvatar(
        prompt: _promptController.text.trim(),
      );
      setState(() {
        _urls = generatedUrls;
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar con IA (Texto)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Describe tu avatar...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _generate,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Generar (2 Opciones)'),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Text('Generando... esto puede tardar un momento.')),
            if (_error != null && !_loading)
              Center(child: Text('Ocurrió un error: $_error', style: const TextStyle(color: Colors.red))),
            if (_urls.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _urls.length,
                  itemBuilder: (context, index) {
                    final url = _urls[index];
                    return GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                        {'type': 'ai', 'url': url},
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null ? child : const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
