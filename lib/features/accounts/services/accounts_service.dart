// lib/features/accounts/services/accounts_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';

class DeleteAccountResult {
  const DeleteAccountResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class AccountsService {
  final _supabase = Supabase.instance.client;

  Future<AccountSummary> getAccountSummary() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final accountsResponse = await _supabase.from('accounts').select().eq('user_id', userId).eq('is_archived', false);
      if (accountsResponse.isEmpty) {
        return AccountSummary(spendingAccounts: [], savingsAccount: null, totalSpendingBalance: 0.0, totalSavingsBalance: 0.0);
      }
      final List<Map<String, dynamic>> accountMaps = List<Map<String, dynamic>>.from(accountsResponse);
      
      // Asumimos que tienes una RPC 'get_account_balances' que funciona correctamente
      final balancesResponse = await _supabase.rpc('get_account_balances', params: {'user_id_param': userId});
      
      final Map<String, double> balancesMap = {
        for (var item in List<Map<String, dynamic>>.from(balancesResponse))
          item['account_id']: (item['balance'] as num).toDouble()
      };
      
      final allAccounts = accountMaps.map((accountData) {
        final balance = balancesMap[accountData['id']] ?? 0.0;
        return Account.fromMap(accountData).copyWith(balance: balance);
      }).toList();

      List<Account> spendingAccounts = [];
      Account? savingsAccount;
      double totalSpending = 0.0;
      double totalSavings = 0.0;

      for (var acc in allAccounts) {
        if (acc.conceptualType == 'ahorro') {
          savingsAccount = acc;
          totalSavings = acc.balance;
        } else {
          spendingAccounts.add(acc);
          totalSpending += acc.balance;
        }
      }
      spendingAccounts.sort((a, b) => a.name.compareTo(b.name));
      return AccountSummary(
        spendingAccounts: spendingAccounts,
        savingsAccount: savingsAccount,
        totalSpendingBalance: totalSpending,
        totalSavingsBalance: totalSavings,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<double?> getParaGastarBalance() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final accountsResponse = await _supabase
          .from('accounts')
          .select('id, name, type, conceptual_type, is_archived')
          .eq('user_id', userId)
          .eq('is_archived', false);

      final accounts = List<Map<String, dynamic>>.from(accountsResponse);
      if (accounts.isEmpty) {
        return null;
      }

      Map<String, dynamic>? spendingAccount;
      Map<String, dynamic>? nominaAccount;

      for (final account in accounts) {
        final name = (account['name'] as String?)?.toLowerCase();
        final conceptualType = (account['conceptual_type'] as String?)?.toLowerCase();
        final accountType = (account['type'] as String?)?.toLowerCase();

        final normalizedName = name?.replaceAll('ó', 'o');
        final isNominaName = normalizedName != null && normalizedName.contains('nomina');
        final isNominaType = conceptualType == 'nomina';
        final isCorrienteType = accountType == 'corriente';
        final isSavingsConcept = conceptualType == 'ahorro';

        if (isNominaType && nominaAccount == null) {
          nominaAccount = account;
        }

        if (isNominaName && isNominaType) {
          nominaAccount = account;
          break;
        }

        if (isCorrienteType && !isSavingsConcept && spendingAccount == null) {
          spendingAccount = account;
        }
      }

      final targetAccount = nominaAccount ?? spendingAccount;

      if (targetAccount == null) {
        return null;
      }

      final balancesResponse = await _supabase
          .rpc('get_account_balances', params: {'user_id_param': userId});

      if (balancesResponse is! List) {
        return null;
      }

      final balancesList = List<Map<String, dynamic>>.from(balancesResponse);
      final balancesMap = <String, double>{};
      for (final balance in balancesList) {
        final accountId = balance['account_id'];
        if (accountId == null) {
          continue;
        }
        balancesMap[accountId.toString()] = (balance['balance'] as num).toDouble();
      }

      final targetAccountId = targetAccount['id'].toString();
      return balancesMap[targetAccountId] ?? 0.0;
    } catch (e) {
      rethrow;
    }
  }

  // --- MÉTODO ACTUALIZADO ---
  /// Ejecuta una transferencia interna llamando a la función RPC.
  Future<void> executeInternalTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    final userId = _supabase.auth.currentUser!.id; // Obtenemos el ID del usuario actual

    await _supabase.rpc('execute_internal_transfer', params: {
      'p_user_id': userId, // <-- Le pasamos el ID del usuario a la función
      'p_from_account_id': fromAccountId,
      'p_to_account_id': toAccountId,
      'p_amount': amount,
    });
  }

  Future<DeleteAccountResult> deleteAccount(String accountId) async {
    try {
      final result = await _supabase.rpc('delete_account_if_empty', params: {
        'p_account_id': accountId,
      });

      final code = result as String?;
      switch (code) {
        case 'ACCOUNT_ARCHIVED_SUCCESSFULLY':
          return const DeleteAccountResult(
            success: true,
            message: 'Cuenta archivada correctamente.',
          );
        case 'ERROR_ACCOUNT_HAS_TRANSACTIONS':
          return const DeleteAccountResult(
            success: false,
            message:
                'No puedes eliminar la cuenta porque tiene transacciones asociadas.',
          );
        case 'ACCOUNT_NOT_FOUND':
          return const DeleteAccountResult(
            success: false,
            message: 'No encontramos la cuenta o no te pertenece.',
          );
        case 'ERROR_UNKNOWN':
        default:
          return const DeleteAccountResult(
            success: false,
            message:
                'Ocurrió un error al eliminar la cuenta. Inténtalo de nuevo en unos segundos.',
          );
      }
    } on PostgrestException catch (e) {
      final message = e.message?.isNotEmpty == true
          ? 'No se pudo eliminar la cuenta: ${e.message}'
          : 'No se pudo eliminar la cuenta por un error en Supabase.';
      return DeleteAccountResult(success: false, message: message);
    } catch (e) {
      return DeleteAccountResult(
        success: false,
        message: 'Error inesperado al eliminar la cuenta: $e',
      );
    }
  }
}
