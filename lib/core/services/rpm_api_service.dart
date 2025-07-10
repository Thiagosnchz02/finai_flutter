import 'dart:convert';
import 'package:http/http.dart' as http;

// Clase para encapsular la lógica de la API de Ready Player Me
class RpmApiService {
  final String _baseUrl = 'https://api.readyplayer.me/v2';
  
  // NOTA: Para una app en producción, deberías registrarte como partner en RPM
  // y usar tu propio subdominio. Para desarrollo, 'demo' funciona.
  final String _partnerDomain = 'demo'; 

  /// Obtiene el catálogo de assets (piezas) disponibles para crear el avatar.
  Future<Map<String, dynamic>> getAvailableAssets() async {
    // Este endpoint nos da todas las piezas (pelo, ojos, ropa, etc.)
    final uri = Uri.parse('$_baseUrl/avatars/assets');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load avatar assets: ${response.body}');
      }
    } catch (e) {
      print('Error fetching RPM assets: $e');
      throw Exception('Could not connect to Ready Player Me service.');
    }
  }

  /// Solicita una imagen de previsualización 2D basada en la configuración actual del avatar.
  Future<String> render2DPreview(Map<String, dynamic> avatarConfig) async {
    // La API de renderizado es diferente y espera el partner en el cuerpo de la petición.
    final uri = Uri.parse('https://api.readyplayer.me/v1/avatars');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(avatarConfig),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // La URL de la imagen 2D se encuentra en 'renders' -> '2d-head-render'
        // o a veces en 'avatar' -> '2d-head-render'. Verificamos ambas.
        return body['renders']?['2d-head-render'] ?? body['avatar']?['2d-head-render'] ?? '';
      } else {
        throw Exception('Failed to render preview: ${response.body}');
      }
    } catch (e) {
      print('Error rendering RPM preview: $e');
      throw Exception('Could not render avatar preview.');
    }
  }

  /// Crea el avatar 3D final y devuelve la URL del modelo .glb
  Future<String> createFinalAvatar(Map<String, dynamic> avatarConfig) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(avatarConfig),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // La URL final del modelo .glb se encuentra en el campo 'url'
        return body['url'];
      } else {
        throw Exception('Failed to create final avatar: ${response.body}');
      }
    } catch (e) {
      print('Error creating final RPM avatar: $e');
      throw Exception('Could not create final avatar.');
    }
  }
}