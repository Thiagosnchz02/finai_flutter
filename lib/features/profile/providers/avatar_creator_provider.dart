import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/rpm_api_service.dart';

class AvatarCreatorProvider with ChangeNotifier {
  final RpmApiService _apiService = RpmApiService();
  final _supabase = Supabase.instance.client;
  final String _currentSupabaseUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  // Estado
  bool _isLoading = true;
  String? _error;
  String? _rpmUserId;
  String? _avatarId;
  String? _rpmToken;

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

  /// Flujo de inicialización simplificado y validado sin operadores '!'
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1️⃣ Crear usuario RPM y obtener token
      final userData = await _apiService.createRpmUser();
      _rpmUserId = userData['id'];
      _rpmToken = userData['token'];
      if (_rpmUserId == null || _rpmToken == null) {
        throw Exception('Error: userId o token nulos tras createRpmUser');
      }
      // Guardar rpm_user_id en Supabase (no bloqueante)
      try {
        await _supabase
            .from('profiles')
            .update({'rpm_user_id': _rpmUserId})
            .eq('id', _currentSupabaseUserId);
      } catch (_) {
        // No interrumpe flujo si falla la escritura
      }

      // 2️⃣ Listar plantillas y crear borrador
      final token = _rpmToken!;
      final templates = await _apiService.getAvatarTemplates(token);
      if (templates.isEmpty) {
        throw Exception('No se encontraron plantillas de avatar');
      }
      final tpl = templates.firstWhere(
        (t) => t['gender'] == 'male',
        orElse: () => templates.first,
      );
      final dynamic tplIdRaw = tpl['id'];
      if (tplIdRaw == null) {
        throw Exception("ID de plantilla nulo");
      }
      final tplId = tplIdRaw.toString();
      final draft = await _apiService.createDraftAvatar(tplId, token);
      final data = draft['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception("Respuesta del draft sin campo 'data'");
      }
      _avatarId = data['id'] as String?;
      if (_avatarId == null) {
        throw Exception('Falta avatarId tras draft');
      }
      // La API v2 no devuelve renders en el draft inicial, generamos preview manualmente:
      _previewUrl = 'https://models.readyplayer.me/$_avatarId.png?preview=true';

      // 3️⃣ Cargar assets disponibles para el selector UI (v1)
      final apiAssets = await _apiService.getAvailableAssets();
      final raw = apiAssets['data'] as List<dynamic>?;
      if (raw == null) {
        throw Exception("Respuesta de assets sin campo 'data'");
      }
      _availableAssets = {};
      for (final asset in raw) {
        final type = asset['type'] as String?;
        if (type == null) continue;
        _availableAssets.putIfAbsent(type, () => []).add(asset);
      }
      if (_availableAssets.isEmpty) {
        throw Exception('No hay assets para mostrar');
      }
    } catch (e) {
      _error = e.toString();
      print('Error en _initialize: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una pieza y refresca la preview
  Future<void> selectAsset(String type, int id) async {
    _selectedAssets[type] = id;
    await updatePreview();
    notifyListeners();
  }

  /// Llama a la API para actualizar el avatar y luego obtener la nueva imagen.
  Future<void> updatePreview() async {
    if (_avatarId == null || _rpmToken == null) return;
    try {
      final updated = await _apiService.updateAvatar(
        _avatarId!,
        _selectedAssets,
        _rpmToken!,
      );
      final data = updated['data'] as Map<String, dynamic>?;
      final renders = data?['renders'] as Map<String, dynamic>?;
      final newUrl = renders?['2d-head-render'] as String?;
      if (newUrl != null) {
        _previewUrl = '$newUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('Error en updatePreview: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Devuelve la URL final del avatar 3D.
  Future<String?> createFinalAvatar() async {
    return _avatarId != null ? 'https://models.readyplayer.me/$_avatarId.glb' : null;
  }
}

