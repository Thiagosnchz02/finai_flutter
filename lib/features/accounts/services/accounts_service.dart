// lib/features/accounts/services/accounts_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_model.dart';

class AccountsService {
  final _supabase = Supabase.instance.client;

  Future<AccountSummary> getAccountSummary() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Obtener todas las cuentas (activas) del usuario
      final accountsResponse = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false);

      if (accountsResponse.isEmpty) {
        return AccountSummary(); // Devuelve un resumen vacío si no hay cuentas
      }
      
      final List<Map<String, dynamic>> accountMaps = List<Map<String, dynamic>>.from(accountsResponse);

      // 2. Obtener los saldos de todas esas cuentas con la RPC
      // LA LÍNEA INNECESARIA HA SIDO ELIMINADA DE AQUÍ
      final balancesResponse = await _supabase.rpc(
        'get_account_balances',
        params: {'user_id_param': userId},
      );

      final Map<String, double> balancesMap = {
        for (var item in List<Map<String, dynamic>>.from(balancesResponse))
          item['account_id']: (item['balance'] as num).toDouble()
      };
      
      // 3. Crear objetos Account combinando datos y saldos
      final allAccounts = accountMaps.map((accountData) {
        final balance = balancesMap[accountData['id']] ?? 0.0;
        return Account(
          id: accountData['id'],
          name: accountData['name'],
          bankName: accountData['bank_name'],
          conceptualType: accountData['conceptual_type'] ?? 'nomina',
          type: accountData['type'],
          balance: balance,
          currency: accountData['currency'],
          isArchived: accountData['is_archived'],
        );
      }).toList();

      // 4. Agrupar, procesar y calcular totales
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

      // Ordenar cuentas para gastar por nombre
      spendingAccounts.sort((a, b) => a.name.compareTo(b.name));

      return AccountSummary(
        spendingAccounts: spendingAccounts,
        savingsAccount: savingsAccount,
        totalSpendingBalance: totalSpending,
        totalSavingsBalance: totalSavings,
      );
    } catch (e) {
      print('Error en AccountsService: $e');
      rethrow; // Relanza el error para que la UI lo pueda manejar
    }
  }
}