// lib/features/settings/services/preferences_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../accounts/models/accounts_preferences.dart';

/// Servicio unificado para gestionar todas las preferencias de personalización
class PreferencesService {
  final _supabase = Supabase.instance.client;

  /// Obtiene todas las preferencias del usuario actual
  Future<UserPreferences> getAllPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('profiles')
          .select(
            'swipe_month_navigation, '
            'show_transfers_card, '
            'accounts_view_mode, '
            'accounts_advanced_animations, '
            'show_account_sparkline',
          )
          .eq('id', userId)
          .single();

      return UserPreferences.fromMap(response);
    } catch (e) {
      // En caso de error, devolver valores por defecto
      return UserPreferences.defaults();
    }
  }

  /// Actualiza una preferencia específica
  Future<void> updatePreference(String key, dynamic value) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase.from('profiles').update({key: value}).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza múltiples preferencias a la vez
  Future<void> updateMultiplePreferences(Map<String, dynamic> preferences) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase.from('profiles').update(preferences).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}

/// Modelo unificado de preferencias del usuario
class UserPreferences {
  // === PREFERENCIAS DE TRANSACCIONES ===
  final bool swipeMonthNavigation;
  final String showTransfersCard; // 'never', 'auto', 'always'

  // === PREFERENCIAS DE CUENTAS ===
  final AccountsViewMode accountsViewMode;
  final bool accountsAdvancedAnimations;
  final bool showAccountSparkline;

  const UserPreferences({
    // Transacciones
    required this.swipeMonthNavigation,
    required this.showTransfersCard,
    // Cuentas
    required this.accountsViewMode,
    required this.accountsAdvancedAnimations,
    required this.showAccountSparkline,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      // Transacciones
      swipeMonthNavigation: map['swipe_month_navigation'] as bool? ?? true,
      showTransfersCard: map['show_transfers_card'] as String? ?? 'auto',
      // Cuentas
      accountsViewMode: AccountsViewMode.fromString(
        map['accounts_view_mode'] as String? ?? 'compact',
      ),
      accountsAdvancedAnimations: map['accounts_advanced_animations'] as bool? ?? true,
      showAccountSparkline: map['show_account_sparkline'] as bool? ?? false,
    );
  }

  factory UserPreferences.defaults() {
    return UserPreferences(
      swipeMonthNavigation: true,
      showTransfersCard: 'auto',
      accountsViewMode: AccountsViewMode.compact,
      accountsAdvancedAnimations: true,
      showAccountSparkline: false,
    );
  }

  UserPreferences copyWith({
    bool? swipeMonthNavigation,
    String? showTransfersCard,
    AccountsViewMode? accountsViewMode,
    bool? accountsAdvancedAnimations,
    bool? showAccountSparkline,
  }) {
    return UserPreferences(
      swipeMonthNavigation: swipeMonthNavigation ?? this.swipeMonthNavigation,
      showTransfersCard: showTransfersCard ?? this.showTransfersCard,
      accountsViewMode: accountsViewMode ?? this.accountsViewMode,
      accountsAdvancedAnimations: accountsAdvancedAnimations ?? this.accountsAdvancedAnimations,
      showAccountSparkline: showAccountSparkline ?? this.showAccountSparkline,
    );
  }
}
