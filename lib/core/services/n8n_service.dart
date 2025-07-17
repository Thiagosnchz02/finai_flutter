import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class N8nService {
  /// Llama al workflow de n8n para generar avatares.
  /// Puede recibir un [prompt] de texto o la URL de una [baseImage] subida.
  Future<List<String>> generateAvatar({
    String? prompt,
    String? baseImage, // URL de la imagen que el usuario suba
    String? style,      // "Cartoon", "Pixar", etc.
  }) async {
    final url = Uri.parse(dotenv.env['N8N_WEBHOOK_URL']!);
    final apiKey = dotenv.env['N8N_API_KEY'];
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final body = {
      'userId': userId,
      'prompt': prompt,
      'baseImage': baseImage,
      'style': style,
    };

    // Eliminamos del cuerpo los valores que sean nulos para no enviarlos
    body.removeWhere((key, value) => value == null);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'X-N8N-API-KEY': apiKey,
        },
        body: json.encode(body), // Importante: codificar el mapa a un string JSON
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Asumimos que n8n devuelve un JSON con una lista de URLs, ej: {"image_urls": ["url1", "url2"]}
        final List<dynamic> imageUrls = responseData['image_urls'];
        return imageUrls.cast<String>();
      } else {
        // Lanza una excepción que la UI puede capturar y mostrar
        throw Exception('Error en la llamada a n8n: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Relanza el error para que la UI lo gestione
      throw Exception('Error de conexión con el servicio de avatares: $e');
    }
  }
}