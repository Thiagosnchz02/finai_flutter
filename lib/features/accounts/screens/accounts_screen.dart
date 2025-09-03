// lib/features/accounts/screens/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';
import 'package:finai_flutter/features/accounts/services/accounts_service.dart';
import 'package:finai_flutter/features/accounts/widgets/account_card.dart';
import 'package:finai_flutter/features/accounts/widgets/accounts_summary_card.dart';
import 'package:finai_flutter/features/accounts/widgets/empty_accounts_widget.dart';
import '../widgets/internal_transfer_dialog.dart';
import 'add_edit_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountsService _accountsService = AccountsService();
  late Future<AccountSummary> _accountSummaryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _accountSummaryFuture = _accountsService.getAccountSummary();
    });
  }

  void _navigateToAddAccount() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddEditAccountScreen()),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _showTransferDialog(List<Account> spendingAccounts, Account savingsAccount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InternalTransferDialog(
        spendingAccounts: spendingAccounts,
        savingsAccount: savingsAccount,
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1E22),
      appBar: AppBar(
        title: const Text('Mis Cuentas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        elevation: 0,
        centerTitle: false,
        actions: [
          // 3. AÑADIMOS EL BOTÓN DE TRANSFERENCIA A LA APPBAR
          FutureBuilder<AccountSummary>(
            future: _accountSummaryFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.spendingAccounts.isNotEmpty && snapshot.data!.savingsAccount != null) {
                return IconButton(
                  icon: const Icon(FontAwesomeIcons.rightLeft),
                  tooltip: 'Realizar Traspaso',
                  onPressed: () => _showTransferDialog(
                    snapshot.data!.spendingAccounts,
                    snapshot.data!.savingsAccount!,
                  ),
                );
              }
              return const SizedBox.shrink(); // Oculta el botón si no se cumplen las condiciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir cuenta',
            onPressed: _navigateToAddAccount,
          ),
        ],
      ),
      body: FutureBuilder<AccountSummary>(
        future: _accountSummaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const EmptyAccountsWidget(); // Fallback por si no hay datos
          }

          final summary = snapshot.data!;
          
          // --- LÓGICA CORREGIDA PARA EL ESTADO VACÍO ---
          if (summary.spendingAccounts.isEmpty && summary.savingsAccount == null) {
            return const EmptyAccountsWidget();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // SECCIÓN 1: CUENTAS PARA GASTAR
                AccountsSummaryCard(
                  title: 'Total Disponible',
                  totalAmount: summary.totalSpendingBalance,
                  iconData: FontAwesomeIcons.wallet,
                  neonColor: Colors.blueAccent,
                  child: summary.spendingAccounts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No hay cuentas para gastos.', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                        )
                      : Column(
                          children: summary.spendingAccounts
                              .map((acc) => AccountCard(account: acc))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN 2: CUENTA DE AHORRO (CON TARJETA REDISEÑADA)
                if (summary.savingsAccount != null)
                  AccountsSummaryCard(
                    title: 'Total Ahorrado',
                    totalAmount: summary.totalSavingsBalance,
                    iconData: FontAwesomeIcons.piggyBank,
                    neonColor: Colors.purpleAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccountCard(account: summary.savingsAccount!),
                        const SizedBox(height: 8),
                        // 2. El texto ahora es un botón funcional.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navegamos a la pantalla de Metas
                              Navigator.of(context).pushNamed('/goals');
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gestionar mis Huchas',
                                  style: TextStyle(color: Colors.purpleAccent),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.purpleAccent, size: 16),
                              ],
                            ),
                          ),
                        )
                        // --- FIN DE LA MODIFICACIÓN ---
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
