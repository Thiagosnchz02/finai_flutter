// lib/features/settings/models/profile_model.dart

class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final bool dobleFactorEnabled;
  final String theme;
  final String language;
  final bool notifyFixedExpense;
  final bool notifyBudgetAlert;
  final bool notifyGoalReached;
  final bool enableBudgetRollover;
  final String planType;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.dobleFactorEnabled,
    required this.theme,
    required this.language,
    required this.notifyFixedExpense,
    required this.notifyBudgetAlert,
    required this.notifyGoalReached,
    required this.enableBudgetRollover,
    required this.planType,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      dobleFactorEnabled: map['doble_factor_enabled'] ?? false,
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'es',
      notifyFixedExpense: map['notify_fixed_expense'] ?? true,
      notifyBudgetAlert: map['notify_budget_alert'] ?? true,
      notifyGoalReached: map['notify_goal_reached'] ?? true,
      enableBudgetRollover: map['enable_budget_rollover'] ?? true,
      planType: map['plan_type'] ?? 'free',
    );
  }
}