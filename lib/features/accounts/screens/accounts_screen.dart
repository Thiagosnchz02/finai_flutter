// lib/features/accounts/screens/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/account_model.dart';
import '../services/accounts_service.dart';
import '../widgets/account_card.dart';
import '../widgets/accounts_summary_card.dart';
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1E22), // Fondo oscuro del mockup
      appBar: AppBar(
        title: const Text('Mis Cuentas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAccount,
        backgroundColor: Colors.blueAccent.withOpacity(0.8),
        child: const Icon(Icons.add, color: Colors.white),
        shape: const CircleBorder(),
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
            return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.white)));
          }

          final summary = snapshot.data!;
          
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
                      ? const Text('No hay cuentas para gastos.', style: TextStyle(color: Colors.white70))
                      : Column(
                          children: summary.spendingAccounts
                              .map((acc) => AccountCard(account: acc))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN 2: CUENTA DE AHORRO
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
                        const SizedBox(height: 12),
                        // Placeholder para la barra de progreso y CTA de Huchas
                        LinearProgressIndicator(
                          value: 0.7, // Valor de ejemplo
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () { /* TODO: Navegar a pantalla de Huchas */ },
                            child: const Text(
                              'Gestionar mis Huchas →',
                              style: TextStyle(color: Colors.purpleAccent),
                            ),
                          ),
                        )
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