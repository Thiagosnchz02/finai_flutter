// lib/features/settings/services/settings_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finai_flutter/core/events/app_events.dart';
import 'package:finai_flutter/core/services/event_logger_service.dart';
import '../models/profile_model.dart';

class SettingsService {
  final _supabase = Supabase.instance.client;
  final _eventLogger = EventLoggerService();

  Future<Profile> getProfileSettings() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(response);
  }

  Future<void> updateProfileSetting(String key, dynamic value) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').update({key: value}).eq('id', userId);

    if (key == 'theme') {
      await _eventLogger.log(AppEvent.settingsThemeChanged, details: {'new_theme': value});
    } else if (key.startsWith('notify_')) {
      await _eventLogger.log(AppEvent.settingsNotificationToggled, details: {
        'notification_type': key,
        'enabled': value,
      });
    }
  }

  Future<String> enrollMfa() async {
    final result = await _supabase.auth.mfa.enroll(factorType: FactorType.totp);
    if (result.totp == null) {
      throw Exception('No se pudieron obtener los detalles del QR para 2FA.');
    }
    return result.totp!.qrCode;
  }

  Future<void> verifyMfa(String factorId, String code) async {
    final challenge = await _supabase.auth.mfa.challenge(factorId: factorId);
    await _supabase.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
    
    await updateProfileSetting('doble_factor_enabled', true);
    await _eventLogger.log(AppEvent.settings2faToggled, details: {'enabled': true});
  }
  
  /// Desactiva un factor de 2FA.
  Future<void> unenrollMfa(String factorId) async {
    // --- CORRECCIÓN DEFINITIVA AQUÍ ---
    // El valor se pasa como un argumento posicional, sin el nombre 'factorId:'.
    await _supabase.auth.mfa.unenroll(factorId);
    
    await updateProfileSetting('doble_factor_enabled', false);
    await _eventLogger.log(AppEvent.settings2faToggled, details: {'enabled': false});
  }

  Future<void> exportData() async {
    await _supabase.functions.invoke('export_data');
    await _eventLogger.log(AppEvent.userDataExported);
  }

  Future<void> deleteAccount(String password) async {
    await _eventLogger.log(AppEvent.userAccountDeleted);
    await _supabase.functions.invoke('delete_user_account', body: {'password': password});
  }
}