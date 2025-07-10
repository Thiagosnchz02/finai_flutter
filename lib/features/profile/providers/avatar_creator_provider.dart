import 'package:flutter/material.dart';
import '../../../core/services/rpm_api_service.dart';

// Este provider gestionará el estado de la creación del avatar.
class AvatarCreatorProvider with ChangeNotifier {
  final RpmApiService _apiService = RpmApiService();

  // Estado principal
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _availableAssets = {};
  Map<String, dynamic> _selectedAssets = {
    // Valores iniciales por defecto para un avatar base
    "gender": "male",
    "bodyType": "fullbody",
    "assets": {}
  };
  String? _previewUrl;

  // Getters públicos para que la UI pueda acceder al estado
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get availableAssets => _availableAssets;
  Map<String, dynamic> get selectedAssets => _selectedAssets;
  String? get previewUrl => _previewUrl;

  AvatarCreatorProvider() {
    loadInitialAssets();
  }

  /// Carga el catálogo inicial de piezas desde la API.
  Future<void> loadInitialAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica a la UI que estamos cargando

    try {
      _availableAssets = await _apiService.getAvailableAssets();
      // Una vez cargados los assets, generamos la primera previsualización
      await updatePreview();
    } catch (e) {
      _error = e.toString();
      print(e);
    }

    _isLoading = false;
    notifyListeners(); // Notifica que la carga ha terminado
  }

  /// Actualiza una pieza seleccionada y pide una nueva previsualización.
  Future<void> selectAsset(String type, int id) async {
    _selectedAssets['assets'][type] = id;
    await updatePreview();
  }
  
  /// Actualiza un color y pide una nueva previsualización.
  Future<void> selectColor(String type, String hexColor) async {
    if (_selectedAssets['assets']['colors'] == null) {
      _selectedAssets['assets']['colors'] = {};
    }
    _selectedAssets['assets']['colors'][type] = hexColor;
    await updatePreview();
  }

  /// Llama a la API para renderizar la imagen de previsualización.
  Future<void> updatePreview() async {
    try {
      // El formato del cuerpo de la petición para renderizar es un poco diferente
      final payload = {
        "partner": "demo", // Usamos el subdominio de demo
        "gender": _selectedAssets['gender'],
        "bodyType": _selectedAssets['bodyType'],
        "assets": _selectedAssets['assets'],
      };
      
      _previewUrl = await _apiService.render2DPreview(payload);
    } catch (e) {
      print(e);
      _previewUrl = null; // Si falla el render, limpiamos la preview
    }
    notifyListeners(); // Notifica a la UI que la URL de la preview ha cambiado
  }

  /// Crea el avatar 3D final.
  Future<String?> createFinalAvatar() async {
     _isLoading = true;
     notifyListeners();
     String? finalUrl;
     try {
        final payload = {
          "partner": "demo",
          "gender": _selectedAssets['gender'],
          "bodyType": _selectedAssets['bodyType'],
          "assets": _selectedAssets['assets'],
        };
        finalUrl = await _apiService.createFinalAvatar(payload);
     } catch (e) {
        print(e);
        // Manejar error, quizás mostrando un SnackBar
     }
     _isLoading = false;
     notifyListeners();
     return finalUrl;
  }
}