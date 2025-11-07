// lib/features/accounts/services/accounts_preferences_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accounts_preferences.dart';

class AccountsPreferencesService {
  final _supabase = Supabase.instance.client;

  /// Obtiene las preferencias de cuentas del usuario actual
  Future<AccountsPreferences> getPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('profiles')
          .select(
            'accounts_view_mode, '
            'accounts_advanced_animations, show_account_sparkline',
          )
          .eq('id', userId)
          .single();

      return AccountsPreferences.fromMap(response);
    } catch (e) {
      // En caso de error, devuelve preferencias por defecto
      return const AccountsPreferences();
    }
  }

  /// Actualiza una o varias preferencias del usuario
  Future<void> updatePreferences(AccountsPreferences preferences) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase.from('profiles').update(preferences.toMap()).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza solo el modo de vista (compact/context)
  Future<void> updateViewMode(AccountsViewMode mode) async {
    final current = await getPreferences();
    await updatePreferences(current.copyWith(viewMode: mode));
  }

  /// Activa/desactiva animaciones avanzadas
  Future<void> toggleAdvancedAnimations(bool enabled) async {
    final current = await getPreferences();
    await updatePreferences(current.copyWith(advancedAnimations: enabled));
  }

  /// Activa/desactiva el mini-gráfico sparkline
  Future<void> toggleSparkline(bool enabled) async {
    final current = await getPreferences();
    await updatePreferences(current.copyWith(showSparkline: enabled));
  }
}
