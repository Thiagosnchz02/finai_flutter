import 'dart:convert';
import 'package:http/http.dart' as http;

// Clase para encapsular la lógica de la API de Ready Player Me
class RpmApiService {
  // ***** URL CORREGIDA *****
  // La nueva URL base para la API es v1 y no requiere /avatars para los assets.
  final String _baseUrl = 'https://api.readyplayer.me/v1';
  
  final String _apiKey = 'sk_live_yZ65J-tQ1mQa4d15VL_whUJjpg6TBn58AfkE';

  /// Obtiene el catálogo de assets (piezas) disponibles para crear el avatar.
  Future<Map<String, dynamic>> getAvailableAssets() async {
    // El endpoint correcto es /assets, no /avatars/assets.
    final uri = Uri.parse('$_baseUrl/assets?type=outfit,beard,hair,facemask,faceshape,eyebrows,eyes,glasses,headwear,lipshape,mouth,noseshape,facewear,shirt');
    
    try {
      final response = await http.get(
        uri,
        // Añadimos la cabecera de autenticación con la API Key
        headers: {'x-api-key': _apiKey},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load avatar assets: ${response.body}');
      }
    }catch (e) {
      print('Error fetching RPM assets: $e');
      throw Exception('Could not connect to Ready Player Me service.');
    }
  }

  /// Solicita una imagen de previsualización 2D basada en la configuración actual del avatar.
  Future<String> render2DPreview(Map<String, dynamic> avatarConfig) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey, // Añadimos la API Key aquí también
        },
        body: json.encode(avatarConfig),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['renders']?['2d-head-render'] ?? '';
      } else {
        throw Exception('Failed to render preview: ${response.body}');
      }
    } catch (e) {
      print('Error rendering RPM preview: $e');
      throw Exception('Could not render avatar preview.');
    }
  }

  /// Crea el avatar 3D final y devuelve la URL del modelo .glb
  Future<String?> createFinalAvatar(Map<String, dynamic> avatarConfig) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey, // Y aquí también
        },
        body: json.encode(avatarConfig),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final avatarId = body['id'];
        if (avatarId != null) {
          return 'https://models.readyplayer.me/$avatarId.glb';
        }
        return null;
      } else {
        throw Exception('Failed to create final avatar: ${response.body}');
      }
    } catch (e) {
      print('Error creating final RPM avatar: $e');
      throw Exception('Could not create final avatar.');
    }
  }
}