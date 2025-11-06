// lib/features/settings/models/profile_model.dart

class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final bool dobleFactorEnabled;
  final bool biometricAuthEnabled;
  final String theme;
  final String language;
  final bool notifyFixedExpense;
  final bool notifyBudgetAlert;
  final bool notifyGoalReached;
  final bool enableBudgetRollover;
  final bool swipeMonthNavigation; // Nuevo campo
  final String showTransfersCard; // 'never', 'auto', 'always'
  final String planType;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.dobleFactorEnabled,
    required this.biometricAuthEnabled,
    required this.theme,
    required this.language,
    required this.notifyFixedExpense,
    required this.notifyBudgetAlert,
    required this.notifyGoalReached,
    required this.enableBudgetRollover,
    required this.swipeMonthNavigation, // Nuevo campo
    required this.showTransfersCard,
    required this.planType,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      dobleFactorEnabled: map['doble_factor_enabled'] ?? false,
      biometricAuthEnabled: map['biometric_auth_enabled'] ?? false,
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'es',
      notifyFixedExpense: map['notify_fixed_expense'] ?? true,
      notifyBudgetAlert: map['notify_budget_alert'] ?? true,
      notifyGoalReached: map['notify_goal_reached'] ?? true,
      enableBudgetRollover: map['enable_budget_rollover'] ?? true,
      swipeMonthNavigation: map['swipe_month_navigation'] ?? false, // Nuevo campo
      showTransfersCard: map['show_transfers_card'] ?? 'never',
      planType: map['plan_type'] ?? 'free',
    );
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    bool? dobleFactorEnabled,
    bool? biometricAuthEnabled,
    String? theme,
    String? language,
    bool? notifyFixedExpense,
    bool? notifyBudgetAlert,
    bool? notifyGoalReached,
    bool? enableBudgetRollover,
    bool? swipeMonthNavigation, // Nuevo campo
    String? showTransfersCard,
    String? planType,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dobleFactorEnabled: dobleFactorEnabled ?? this.dobleFactorEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notifyFixedExpense: notifyFixedExpense ?? this.notifyFixedExpense,
      notifyBudgetAlert: notifyBudgetAlert ?? this.notifyBudgetAlert,
      notifyGoalReached: notifyGoalReached ?? this.notifyGoalReached,
      enableBudgetRollover: enableBudgetRollover ?? this.enableBudgetRollover,
      swipeMonthNavigation: swipeMonthNavigation ?? this.swipeMonthNavigation, // Nuevo campo
      showTransfersCard: showTransfersCard ?? this.showTransfersCard,
      planType: planType ?? this.planType,
    );
  }
}
