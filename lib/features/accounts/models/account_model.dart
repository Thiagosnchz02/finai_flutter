// lib/features/accounts/models/account_model.dart
class Account {
  final String id;
  final String name;
  final String? bankName;
  final String conceptualType;
  final String type;
  final double balance;
  final String? currency;
  final bool isArchived;

  Account({
    required this.id,
    required this.name,
    this.bankName,
    required this.conceptualType,
    required this.type,
    this.balance = 0.0, // El saldo se calculará por separado
    this.currency,
    required this.isArchived,
  });

  // --- NUEVO MÉTODO fromMap ---
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      bankName: map['bank_name'],
      conceptualType: map['conceptual_type'] ?? 'nomina',
      type: map['type'],
      currency: map['currency'],
      isArchived: map['is_archived'],
    );
  }
  
  // --- NUEVO MÉTODO copyWith ---
  Account copyWith({double? balance}) {
    return Account(
      id: id,
      name: name,
      bankName: bankName,
      conceptualType: conceptualType,
      type: type,
      balance: balance ?? this.balance,
      currency: currency,
      isArchived: isArchived,
    );
  }
}

class AccountSummary {
  final List<Account> spendingAccounts;
  final Account? savingsAccount;
  final double totalSpendingBalance;
  final double totalSavingsBalance;

  AccountSummary({
    required this.spendingAccounts,
    this.savingsAccount,
    required this.totalSpendingBalance,
    required this.totalSavingsBalance,
  });
}