import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/rpm_api_service.dart';

class AvatarCreatorProvider with ChangeNotifier {
  final RpmApiService _apiService = RpmApiService();
  final _supabase = Supabase.instance.client;
  final String _currentSupabaseUserId = Supabase.instance.client.auth.currentUser!.id;

  // Estado
  bool _isLoading = true;
  String? _error;
  String? _rpmUserId; // ID de usuario de Ready Player Me

  Map<String, List<dynamic>> _availableAssets = {};
  Map<String, dynamic> _selectedAssets = {
    "gender": "male",
    "bodyType": "halfbody",
    "assets": {}
  };
  String? _previewUrl;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<dynamic>> get availableAssets => _availableAssets;
  String? get previewUrl => _previewUrl;

  AvatarCreatorProvider() {
    _initialize();
  }

  /// Flujo de inicialización completo
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Obtener o crear el ID de usuario de RPM
      _rpmUserId = await _getOrCreateRpmUserId();
      if (_rpmUserId == null) {
        throw Exception("No se pudo obtener el ID de usuario para el avatar.");
      }

      // 2. Cargar los assets disponibles
      final apiResponse = await _apiService.getAvailableAssets();
      _availableAssets = Map<String, List<dynamic>>.from(apiResponse);


      // 3. Generar la primera previsualización
      if (_availableAssets.isNotEmpty) {
        await updatePreview();
      } else {
        throw Exception("No se encontraron assets en la respuesta de la API.");
      }

    } catch (e) {
      _error = e.toString();
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Busca el rpm_user_id en nuestro perfil, si no existe, lo crea en RPM y lo guarda.
  Future<String?> _getOrCreateRpmUserId() async {
    // Busca primero en nuestra base de datos
    final profileResponse = await _supabase
        .from('profiles')
        .select('rpm_user_id')
        .eq('id', _currentSupabaseUserId)
        .single();

    if (profileResponse['rpm_user_id'] != null) {
      print('RPM User ID encontrado en Supabase: ${profileResponse['rpm_user_id']}');
      return profileResponse['rpm_user_id'];
    }

    // Si no existe, lo creamos en RPM
    print('No se encontró RPM User ID, creando uno nuevo...');
    final newRpmId = await _apiService.createRpmUser();
    if (newRpmId != null) {
      // Y lo guardamos en nuestro perfil para futuras sesiones
      await _supabase
          .from('profiles')
          .update({'rpm_user_id': newRpmId})
          .eq('id', _currentSupabaseUserId);
      print('Nuevo RPM User ID guardado en Supabase: $newRpmId');
      return newRpmId;
    }
    return null;
  }

  Future<void> selectAsset(String type, int id) async {
    _selectedAssets['assets'][type] = id;
    await updatePreview();
    notifyListeners();
  }

  /// Llama a la API para renderizar la imagen de previsualización.
  Future<void> updatePreview() async {
    if (_rpmUserId == null) return;
    try {
      final payload = {
        "data": {
          "userId": _rpmUserId, // Usamos el ID de RPM
          "partner": "finai.readyplayer.me",
          "bodyType": _selectedAssets['bodyType'],
          "gender": _selectedAssets['gender'],
          "assets": _selectedAssets['assets'],
        }
      };
      _previewUrl = await _apiService.render2DPreview(payload);
    } catch (e) {
      print("Error en updatePreview: $e");
      _previewUrl = null;
    }
    notifyListeners();
  }

  /// Crea el avatar 3D final.
  Future<String?> createFinalAvatar() async {
    if (_rpmUserId == null) return null;
     _isLoading = true;
     notifyListeners();
     String? finalUrl;
     try {
        final payload = {
          "data": {
            "userId": _rpmUserId, // Usamos el ID de RPM
            "partner": "finai.readyplayer.me",
            "gender": _selectedAssets['gender'],
            "bodyType": _selectedAssets['bodyType'],
            "assets": _selectedAssets['assets'],
          }
        };
        finalUrl = await _apiService.createFinalAvatar(payload);
     } catch (e) {
        print(e);
     }
     _isLoading = false;
     notifyListeners();
     return finalUrl;
  }
}