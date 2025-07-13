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
  String? _rpmUserId;
  String? _avatarId;

  Map<String, List<dynamic>> _availableAssets = {};
  final Map<String, dynamic> _selectedAssets = {};
  String? _previewUrl;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<dynamic>> get availableAssets => _availableAssets;
  Map<String, dynamic> get selectedAssets => _selectedAssets;
  String? get previewUrl => _previewUrl;

  AvatarCreatorProvider() {
    _initialize();
  }

  /// Flujo de inicialización completo y corregido
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rpmUserId = await _getOrCreateRpmUserId();
      if (_rpmUserId == null) throw Exception("No se pudo obtener el ID de usuario de RPM.");

      // 1. Crear un avatar inicial para obtener su ID y la primera imagen
      final initialAvatarData = await _apiService.createInitialAvatar(
        _rpmUserId!,
        'male',
        'halfbody',
      );
      _avatarId = initialAvatarData['data']?['id'];
      if (_avatarId == null) throw Exception("No se pudo crear el avatar inicial.");
      
      // La respuesta de la creación ya contiene la primera URL de renderizado
      _previewUrl = initialAvatarData['data']?['renders']?['2d-head-render'];

      // 2. Cargar los assets disponibles
      final apiResponse = await _apiService.getAvailableAssets();
      _availableAssets = Map<String, List<dynamic>>.from(
        apiResponse['data'] ?? {},
      );

      if (_availableAssets.isEmpty) {
        throw Exception("No se encontraron assets en la respuesta de la API.");
      }
    } catch (e) {
      _error = e.toString();
      print("Error en _initialize: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> _getOrCreateRpmUserId() async {
    final profileResponse = await _supabase.from('profiles').select('rpm_user_id').eq('id', _currentSupabaseUserId).single();
    if (profileResponse['rpm_user_id'] != null) return profileResponse['rpm_user_id'];
    
    final newRpmId = await _apiService.createRpmUser();
    if (newRpmId != null) {
      await _supabase.from('profiles').update({'rpm_user_id': newRpmId}).eq('id', _currentSupabaseUserId);
      return newRpmId;
    }
    return null;
  }

  /// Actualiza una pieza y refresca la preview
  Future<void> selectAsset(String type, int id) async {
    _selectedAssets[type] = id;
    await updatePreview();
    notifyListeners();
  }

  /// Llama a la API para actualizar el avatar y luego obtener la nueva imagen.
  Future<void> updatePreview() async {
    if (_avatarId == null) return;
    try {
      final updatedAvatarData = await _apiService.updateAvatar(_avatarId!, _selectedAssets);
      final newRenderUrl = updatedAvatarData['renders']?['2d-head-render'];

      if (newRenderUrl != null) {
        _previewUrl = '$newRenderUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print("Error en updatePreview: $e");
    }
    notifyListeners();
  }

  /// Devuelve la URL final del avatar 3D.
  Future<String?> createFinalAvatar() async {
    if (_avatarId == null) return null;
    return 'https://models.readyplayer.me/$_avatarId.glb';
  }
}