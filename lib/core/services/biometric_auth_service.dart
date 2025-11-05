// lib/core/services/biometric_auth_service.dart

import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static const _biometricEnabledKey = 'biometric_enabled_for_user';
  
  final _localAuth = LocalAuthentication();
  final _supabase = Supabase.instance.client;

  /// Verifica si el dispositivo soporta autenticación biométrica
  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Marca que el usuario ha habilitado la biometría localmente
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await prefs.setBool('${_biometricEnabledKey}_$userId', enabled);
    }
  }

  /// Verifica si el usuario actual tiene habilitada la biometría localmente
  Future<bool> isBiometricEnabledLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    return prefs.getBool('${_biometricEnabledKey}_$userId') ?? false;
  }

  /// Autentica con biometría - Solo verifica la huella
  Future<bool> authenticateWithBiometrics() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a FinAi',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario tiene habilitada la autenticación biométrica en la BD
  Future<bool> isBiometricEnabledInDB() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('biometric_auth_enabled')
          .eq('id', userId)
          .maybeSingle();

      return response?['biometric_auth_enabled'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
