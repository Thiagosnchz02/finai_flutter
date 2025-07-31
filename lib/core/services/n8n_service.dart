import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class N8nService {
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

    print('--- Enviando a n8n ---');
    print('URL: $url');
    print('Body: $jsonBody');
    print('----------------------');

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
          throw Exception('n8n devolvió una respuesta vacía. Revisa el flujo.');
        }
        
        final dynamic responseData = json.decode(response.body);
        
        // --- LÓGICA DE PROCESAMIENTO CORREGIDA ---
        // Esta es la clave: ahora manejamos tanto una lista como un objeto único.

        final List<dynamic> items = responseData is List ? responseData : [responseData];
        
        if (items.isEmpty) {
            throw Exception('La respuesta de n8n estaba vacía o en un formato no reconocido.');
        }

        final projectId = dotenv.env['SUPABASE_PROJECT_ID'];
        if (projectId == null) {
          throw Exception('Falta SUPABASE_PROJECT_ID en el archivo .env');
        }

        final List<String> finalUrls = [];
        for (var item in items) {
          if (item is Map && item.containsKey('Key')) {
            final String key = item['Key'];
            final publicUrl = 'https://$projectId.supabase.co/storage/v1/object/public/$key';
            finalUrls.add(publicUrl);
          }
        }
        
        if (finalUrls.isEmpty) {
          throw Exception('La respuesta de n8n no contenía ninguna "Key" válida.');
        }

        return finalUrls;

      } else {
        throw Exception('Error en la llamada a n8n: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('La respuesta de n8n no es un JSON válido.');
      }
      rethrow;
    }
  }
}