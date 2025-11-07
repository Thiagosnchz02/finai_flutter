// lib/features/accounts/models/accounts_preferences.dart

/// Modos de visualización de tarjetas de cuentas
enum AccountsViewMode {
  compact,  // Solo icono + título + saldo
  context;  // Incluye tags, categoría y más detalles

  static AccountsViewMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'compact':
        return AccountsViewMode.compact;
      case 'context':
        return AccountsViewMode.context;
      default:
        return AccountsViewMode.compact;
    }
  }

  String toDbValue() => name;
}

/// Modelo de preferencias para la pantalla de cuentas
class AccountsPreferences {
  final AccountsViewMode viewMode;
  final bool advancedAnimations;
  final bool showSparkline;

  const AccountsPreferences({
    this.viewMode = AccountsViewMode.compact,
    this.advancedAnimations = true,
    this.showSparkline = false,
  });

  /// Crea preferencias desde mapa de Supabase
  factory AccountsPreferences.fromMap(Map<String, dynamic> map) {
    return AccountsPreferences(
      viewMode: AccountsViewMode.fromString(
        map['accounts_view_mode'] as String? ?? 'compact',
      ),
      advancedAnimations: map['accounts_advanced_animations'] as bool? ?? true,
      showSparkline: map['show_account_sparkline'] as bool? ?? false,
    );
  }

  /// Convierte a mapa para Supabase
  Map<String, dynamic> toMap() {
    return {
      'accounts_view_mode': viewMode.toDbValue(),
      'accounts_advanced_animations': advancedAnimations,
      'show_account_sparkline': showSparkline,
    };
  }

  /// Copia con modificaciones
  AccountsPreferences copyWith({
    AccountsViewMode? viewMode,
    bool? advancedAnimations,
    bool? showSparkline,
  }) {
    return AccountsPreferences(
      viewMode: viewMode ?? this.viewMode,
      advancedAnimations: advancedAnimations ?? this.advancedAnimations,
      showSparkline: showSparkline ?? this.showSparkline,
    );
  }

  @override
  String toString() {
    return 'AccountsPreferences(viewMode: $viewMode, '
        'advancedAnimations: $advancedAnimations, showSparkline: $showSparkline)';
  }
}
