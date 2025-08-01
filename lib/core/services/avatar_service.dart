import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  Future<List<String>> generateAvatar({
    required String type,
    String? prompt,
    String? baseImage,
    String? style,
    String? action,
    String? background,
    String? perspective,
  }) async {
    // Cambia esta URL por la de tu servidor Python
    final url = Uri.parse(dotenv.env['PYTHON_WEBHOOK_URL'] ?? 'http://192.168.0.35:8000/webhook/de9a77de-5b32-45f5-97bf-87b789e1fe87');
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final Map<String, dynamic> body = {
      'type': type,
      'userId': userId,
      'prompt': prompt,
      'baseImage': baseImage,
      'style': style,
    };

    if (type == 'TEXT_TO_IMAGE') {
      body['enrichment'] = {
        'action': action,
        'background': background,
        'perspective': perspective,
      };
      (body['enrichment'] as Map).removeWhere((key, value) => value == null || (value is String && value.isEmpty));
      if ((body['enrichment'] as Map).isEmpty) {
        body.remove('enrichment');
      }
    }
    
    body.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    final jsonBody = json.encode(body);

    print('--- Enviando a Python Avatar Service ---');
    print('URL: $url');
    print('Body: $jsonBody');
    print('----------------------------------------');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );

      print('--- Respuesta del servicio ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('-----------------------------');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('El servicio devolvió una respuesta vacía.');
        }
        
        final dynamic responseData = json.decode(response.body);
        
        // El servicio Python devuelve directamente un objeto con "Key"
        if (responseData is Map && responseData.containsKey('Key')) {
          final String key = responseData['Key'];
          
          final projectId = dotenv.env['SUPABASE_PROJECT_ID'];
          if (projectId == null) {
            throw Exception('Falta SUPABASE_PROJECT_ID en el archivo .env');
          }

          final publicUrl = 'https://$projectId.supabase.co/storage/v1/object/public/$key?t=${DateTime.now().millisecondsSinceEpoch}';;
          return [publicUrl];
        } else {
          throw Exception('La respuesta no contiene la Key esperada: $responseData');
        }

      } else {
        throw Exception('Error en la llamada al servicio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('La respuesta del servicio no es un JSON válido.');
      }
      rethrow;
    }
  }
}