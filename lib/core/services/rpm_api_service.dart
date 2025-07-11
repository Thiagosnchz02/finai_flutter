import 'dart:convert';
import 'package:http/http.dart' as http;

class RpmApiService {
  final String _baseUrl = 'https://api.readyplayer.me/v1';
  final String _apiKey = 'sk_live_yZ65J-tQ1mQa4d15VL_whUJjpg6TBn58AfkE'; // RECUERDA PONER TU CLAVE AQUÍ

  /// **NUEVA FUNCIÓN:** Crea un nuevo usuario anónimo en RPM.
  /// Devuelve el ID de usuario generado por RPM.
  Future<String?> createRpmUser() async {
    final uri = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: json.encode({
          'data': {'partner': 'finai.readyplayer.me'} // Usamos tu subdominio
        }),
      );
      if (response.statusCode == 201) { // 201 Created
        final body = json.decode(response.body);
        return body['data']?['id'];
      } else {
        throw Exception('Failed to create RPM user: ${response.body}');
      }
    } catch (e) {
      print('Error creating RPM user: $e');
      throw Exception('Could not create user on Ready Player Me.');
    }
  }

  // Las demás funciones se mantienen igual, pero las incluimos para que tengas el archivo completo.
  
  Future<Map<String, dynamic>> getAvailableAssets() async {
    final uri = Uri.parse('$_baseUrl/assets?type=outfit,beard,hair,facemask,faceshape,eyebrows,eyes,glasses,headwear,lipshape,mouth,noseshape,facewear,shirt');
    try {
      final response = await http.get(uri, headers: {'x-api-key': _apiKey});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load avatar assets: ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not connect to Ready Player Me service.');
    }
  }

  Future<String> render2DPreview(Map<String, dynamic> avatarConfig) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: json.encode(avatarConfig),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['renders']?['2d-head-render'] ?? '';
      } else {
        throw Exception('Failed to render preview: ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not render avatar preview.');
    }
  }

  Future<String?> createFinalAvatar(Map<String, dynamic> avatarConfig) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
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
      throw Exception('Could not create final avatar.');
    }
  }
}