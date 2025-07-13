import 'dart:convert';
import 'package:http/http.dart' as http;

class RpmApiService {
  final String _baseUrl = 'https://api.readyplayer.me/v1';
  
  // TUS CREDENCIALES
  final String _apiKey = 'sk_live_yZ65J-tQ1mQa4d15VL_whUJjpg6TBn58AfkE';
  final String _applicationId = '682d8039459f37cd4403973f';

  Future<String?> createRpmUser() async {
    final uri = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: json.encode({
          'data': {'partner': 'finai.readyplayer.me', 'applicationId': _applicationId}
        }),
      );
      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        return body['data']?['id'];
      } else {
        throw Exception('Failed to create RPM user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not create user on Ready Player Me.');
    }
  }

  /// **FUNCIÓN CORREGIDA:** Crea un avatar inicial con parámetros base.
  Future<Map<String, dynamic>> createInitialAvatar(
    String rpmUserId,
    String outfitGender,
    String bodyType,
  ) async {
    final uri = Uri.parse('$_baseUrl/avatars');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: json.encode({
          "data": {
            "userId": rpmUserId,
            "partner": "finai.readyplayer.me",
            "applicationId": _applicationId,
            "outfitGender": outfitGender,
            "bodyType": bodyType,
            "assets": {}
          }
        }),
      );
      if (response.statusCode == 201) { // 201 Created
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create initial avatar: ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not create initial avatar.');
    }
  }

  /// **FUNCIÓN CORREGIDA:** Actualiza un avatar existente con el método PATCH.
  Future<Map<String, dynamic>> updateAvatar(String avatarId, Map<String, dynamic> assets) async {
    final uri = Uri.parse('$_baseUrl/avatars/$avatarId');
    try {
      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: json.encode({'data': {'assets': assets}}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update avatar: ${response.body}');
      }
    } catch (e) {
      throw Exception('Could not update avatar.');
    }
  }
  
  Future<Map<String, dynamic>> getAvailableAssets() async {
    final assetTypes = 'outfit,beard,hair,facemask,faceshape,eyebrows,eyes,glasses,headwear,lipshape,mouth,noseshape,facewear,shirt';
    final uri = Uri.parse('$_baseUrl/assets?type=$assetTypes');
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
}