import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RpmApiService {
  // Base URL v1 para usuario y token
  final String _baseUrl = 'https://api.readyplayer.me/v1';
  // Base URL v2 para plantillas y borrador
  final String _baseUrlV2 = 'https://api.readyplayer.me/v2';

  final String _apiKey = dotenv.env['RPM_API_KEY'] ?? '';
  final String _applicationId = dotenv.env['RPM_APPLICATION_ID'] ?? '';
  final String _partner = (dotenv.env['RPM_PARTNER']?.trim().isNotEmpty == true)
      ? dotenv.env['RPM_PARTNER']!.trim()
      : 'finai'; // fallback si no está definido

  /// Crea un usuario anónimo en v1 y devuelve su id + token
  Future<Map<String, String?>> createRpmUser() async {
    final uri = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: json.encode({
          'data': {
            'applicationId': _applicationId,
            'requestToken': true,
          },
        }),
      );
      // Aceptar tanto 200 como 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return {
          'id': body['data']?['id'] as String?,
          'token': body['data']?['token'] as String?,
        };
      } else {
        throw Exception('Failed to create RPM user: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not create user on Ready Player Me: $e');
    }
  }

  /// Obtiene token JWT para un usuario existente
  Future<String> getUserToken(String userId) async {
    final uri = Uri.parse(
      '$_baseUrl/auth/token'
      '?userId=$userId'
      '&partner=$_partner'
    );
    final resp = await http.get(
      uri,
      headers: {'x-api-key': _apiKey},
    );
    print('🔹 getUserToken ($uri) → ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return data['data']['token'] as String;
    }
    throw Exception('Could not fetch RPM token: ${resp.statusCode} ${resp.body}');
  }

  /// Lista plantillas de avatar (v2)
  Future<List<dynamic>> getAvatarTemplates(String token) async {
    final uri = Uri.parse('$_baseUrlV2/avatars/templates');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      return body['data'] as List<dynamic>;
    }
    throw Exception('Failed to fetch templates: ${resp.statusCode} ${resp.body}');
  }

  /// Crea un borrador de avatar a partir de una plantilla (v2)
  Future<Map<String, dynamic>> createDraftAvatar(
    String templateId,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrlV2/avatars/templates/$templateId');
    print('🔹 createDraftAvatar partner=$_partner');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'data': {
          'partner': _partner,
          'bodyType': 'halfbody',
        },
      }),
    );
    print('🔹 createDraftAvatar ($uri) → ${resp.statusCode} ${resp.body}');
    if (resp.statusCode == 201) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Draft avatar error: ${resp.statusCode} ${resp.body}');
  }

  /// Equipar assets y refrescar render 2D (v2)
  Future<Map<String, dynamic>> updateAvatar(
    String avatarId,
    Map<String, dynamic> assets,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrlV2/avatars/$avatarId');
    final resp = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'data': {'assets': assets}}),
    );
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update avatar: ${resp.statusCode} ${resp.body}');
  }

  /// Obtiene assets disponibles (v1), usando parámetros repetidos type=
  Future<Map<String, dynamic>> getAvailableAssets() async {
    // Generamos repeated type params para soportar filtrado múltiple
    final List<String> assetTypes = [
      'outfit', 'beard', 'hair', 'facemask', 'faceshape', 'eyebrows',
      'eyes', 'glasses', 'headwear', 'lipshape', 'mouth', 'noseshape',
      'facewear', 'shirt'
    ];
    final query = assetTypes.map((t) => 'type=$t').join('&');
    final uri = Uri.parse('$_baseUrl/assets?$query');
    try {
      final response = await http.get(
        uri,
        headers: {'x-api-key': _apiKey},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load avatar assets: ${response.statusCode} ${response.body}'
        );
      }
    } catch (e) {
      throw Exception('Could not connect to Ready Player Me service: $e');
    }
  }
}