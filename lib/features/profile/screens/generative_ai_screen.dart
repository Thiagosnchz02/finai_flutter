import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';

class GenerativeAiScreen extends StatefulWidget {
  const GenerativeAiScreen({super.key});

  @override
  State<GenerativeAiScreen> createState() => _GenerativeAiScreenState();
}

class _GenerativeAiScreenState extends State<GenerativeAiScreen> {
  final TextEditingController promptController = TextEditingController();
  List<String> _urls = [];
  bool _loading = false;

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
    });
    try {
      final imageResponse = await OpenAI.instance.image.create(
        prompt: promptController.text,
        n: 4,
        size: OpenAIImageSize.size256,
      );
      final urls = <String>[];
      for (final data in imageResponse.data) {
        final url = data.url;
        if (url != null) urls.add(url);
      }
      setState(() {
        _urls = urls;
      });
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
      appBar: AppBar(title: const Text('Generative AI Avatar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: promptController),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _generate,
              child: const Text('Generar'),
            ),
            if (_loading) const CircularProgressIndicator(),
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
                      child: Image.network(url, fit: BoxFit.cover),
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
