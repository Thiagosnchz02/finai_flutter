import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class N8nService {
  /// Llama al workflow de n8n para generar avatares.
  /// Puede recibir un [prompt] de texto o la URL de una [baseImage] subida.
  Future<List<String>> generateAvatar({
    required String type,
    String? prompt,
    String? baseImage,
    String? style,
    String? action,
    String? background,
    String? perspective,
  }) async {
    final url = Uri.parse(dotenv.env['N8N_WEBHOOK_URL']!);
    final apiKey = dotenv.env['N8N_API_KEY'];
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final Map<String, dynamic> body = {
      'type': type,
      'userId': userId,
      'prompt': prompt,
      'baseImage': baseImage,
      'style': style,
    };

    // Creamos el objeto anidado solo si estamos en el flujo de texto a imagen
    if (type == 'TEXT_TO_IMAGE') {
      body['enrichment'] = {
        'action': action,
        'background': background,
        'perspective': perspective,
      };
      // Limpiamos los valores nulos o vacíos dentro del objeto de enriquecimiento
      (body['enrichment'] as Map).removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    }
    
    body.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    final jsonBody = json.encode(body);

    // --- DEPURACIÓN AÑADIDA ---
    print('--- Enviando a n8n ---');
    print('URL: $url');
    print('Body: $jsonBody');
    print('----------------------');
    // -------------------------

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'X-N8N-API-KEY': apiKey,
        },
        body: jsonBody,
      );

      print('--- Respuesta de n8n ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('--------------------------');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('n8n devolvió una respuesta vacía. Revisa el nodo "Respond to Webhook".');
        }
        
        final responseData = json.decode(response.body);
        
        if (responseData['image_urls'] == null) {
          throw Exception('La respuesta de n8n es un JSON válido, pero no contiene la clave "image_urls". Revisa el nodo "Code" en n8n.');
        }

        final List<dynamic> imageUrls = responseData['image_urls'];
        return imageUrls.cast<String>();
      } else {
        throw Exception('Error en la llamada a n8n: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('La respuesta de n8n no es un JSON válido. Revisa que el flujo esté devolviendo datos.');
      }
      rethrow;
    }
  }
}