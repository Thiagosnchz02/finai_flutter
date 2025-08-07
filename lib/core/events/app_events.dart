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

  // Eventos del Módulo de Transacciones
  transaction_created,
  transaction_edited,
  transaction_deleted,

    // --- NUEVOS EVENTOS ---
  // Eventos del Módulo de Gastos Fijos
  fixed_expense_created,
  fixed_expense_updated,
  fixed_expense_deleted,
  fixed_expense_toggled,
  // --- FIN NUEVOS EVENTOS ---

  // Eventos de Metas (futuro)
  goal_created,
  goal_updated,
  goal_achieved,
}