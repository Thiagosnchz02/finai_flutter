// lib/features/accounts/services/accounts_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';

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
}