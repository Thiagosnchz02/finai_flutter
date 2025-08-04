// lib/features/accounts/models/account_model.dart

// --- CONTENIDO COMPLETO DEL ARCHIVO ---

/// Representa una cuenta bancaria individual con su saldo ya calculado.
/// Este modelo se usa después de combinar la información de la tabla `accounts`
/// y los resultados de la RPC `get_account_balances`.
class Account {
  final String id;
  final String name;
  final String? bankName;
  final String conceptualType; // 'nomina' o 'ahorro'
  final String type; // 'corriente', 'ahorro', etc. (del banco)
  final double balance;
  final String currency;
  final bool isArchived;

  Account({
    required this.id,
    required this.name,
    this.bankName,
    required this.conceptualType,
    required this.type,
    required this.balance,
    required this.currency,
    required this.isArchived,
  });
}


/// Contiene los datos ya procesados y listos para ser mostrados en la UI.
/// Este es el modelo principal que la pantalla `AccountsScreen` utilizará
/// para construir la interfaz.
class AccountSummary {
  /// Lista de todas las cuentas designadas como 'para gastar' (nomina).
  final List<Account> spendingAccounts;

  /// La única cuenta designada como 'para ahorrar' (ahorro). Puede ser nula si no hay ninguna.
  final Account? savingsAccount;

  /// La suma total de los saldos de todas las `spendingAccounts`.
  final double totalSpendingBalance;

  /// El saldo de la `savingsAccount`. Es 0.0 si no hay cuenta de ahorro.
  final double totalSavingsBalance;

  AccountSummary({
    this.spendingAccounts = const [],
    this.savingsAccount,
    this.totalSpendingBalance = 0.0,
    this.totalSavingsBalance = 0.0,
  });
}