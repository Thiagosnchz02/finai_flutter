import 'package:flutter/material.dart';

class ImageToImageScreen extends StatelessWidget {
  const ImageToImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar con IA (Foto)'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Próximamente: Aquí podrás subir una foto para generar tu avatar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}