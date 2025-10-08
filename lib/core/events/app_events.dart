// lib/core/events/app_events.dart

enum AppEvent {
  // Eventos de Autenticación
  userSignedIn,
  userSignedUp,
  userSignedOut,
  passwordRecovered,
  
  // Eventos del Módulo de Cuentas
  accountCreated,
  accountEdited,
  accountArchived,
  savingsAccountDesignated,
  internalTransferExecuted,

  // Eventos del Módulo de Transacciones
  transactionCreated,
  transactionEdited,
  transactionDeleted,

  // Eventos del Módulo de Gastos Fijos
  fixedExpenseCreated,
  fixedExpenseUpdated,
  fixedExpenseDeleted,
  fixedExpenseToggled,

  // Eventos del Módulo de Metas (Huchas)
  goalCreated,
  goalUpdated,
  goalArchived,
  goalContributionAdded,
  goalAchieved,
  tripExpenseCreatedFromGoal,

  // Eventos del Módulo de Presupuestos
  budgetCreated,
  budgetUpdated,
  budgetDeleted,
  budgetRolloverToggled,

  // Evento del Módulo de Informes
  reportGenerated,

  // Eventos del Módulo de Configuración
  settingsThemeChanged,
  settings2faToggled,
  settingsNotificationToggled,
  userDataExported,
  userAccountDeleted,

  // --- NUEVOS EVENTOS ---
  // Eventos del Módulo de Inversiones
  investmentCreated,
  investmentUpdated,
  investmentDeleted,
  // --- FIN NUEVOS EVENTOS ---
}