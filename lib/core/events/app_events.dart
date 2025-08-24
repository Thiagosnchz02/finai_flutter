// lib/core/events/app_events.dart

enum AppEvent {
  // Eventos de Autenticación
  user_signed_in,
  user_signed_up,
  user_signed_out,
  password_recovered,
  
  // Eventos del Módulo de Cuentas
  account_created,
  account_edited,
  account_archived,
  savings_account_designated,
  internal_transfer_executed,

  // Eventos del Módulo de Transacciones
  transaction_created,
  transaction_edited,
  transaction_deleted,

  // Eventos del Módulo de Gastos Fijos
  fixed_expense_created,
  fixed_expense_updated,
  fixed_expense_deleted,
  fixed_expense_toggled,

  // Eventos del Módulo de Metas (Huchas)
  goal_created,
  goal_updated,
  goal_archived,
  goal_contribution_added,
  goal_achieved,
  trip_expense_created_from_goal,

  // Eventos del Módulo de Presupuestos
  budget_created,
  budget_updated,
  budget_deleted,
  budget_rollover_toggled,

  // Evento del Módulo de Informes
  report_generated,

  // --- NUEVOS EVENTOS ---
  // Eventos del Módulo de Configuración
  settings_theme_changed,
  settings_2fa_toggled,
  settings_notification_toggled,
  user_data_exported,
  user_account_deleted,
  // --- FIN NUEVOS EVENTOS ---
}