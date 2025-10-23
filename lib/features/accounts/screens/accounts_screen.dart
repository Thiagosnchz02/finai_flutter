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
import 'add_money_screen.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4D0029), Color(0xFF121212)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 200,
                        height: 75,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 200,
                                height: 75,
                                color: const Color(0xFFFF0A7A),
                              ),
                            ),
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Mis cuentas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<AccountSummary>(
                          future: _accountSummaryFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data!.spendingAccounts.isNotEmpty &&
                                snapshot.data!.savingsAccount != null) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: AccountsActionButton(
                                  icon: const FaIcon(FontAwesomeIcons.rightLeft, size: 18),
                                  tooltip: 'Realizar Traspaso',
                                  onPressed: () => _showTransferDialog(
                                    snapshot.data!.spendingAccounts,
                                    snapshot.data!.savingsAccount!,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink(); // Oculta el botón si no se cumplen las condiciones
                          },
                        ),
                        AccountsActionButton(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'Añadir cuenta',
                          onPressed: _navigateToAddAccount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: FutureBuilder<AccountSummary>(
          future: _accountSummaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              );
            }
            if (!snapshot.hasData) {
              return EmptyAccountsWidget(
                onAddAccount: _navigateToAddAccount,
              ); // Fallback por si no hay datos
            }

            final summary = snapshot.data!;

            // --- LÓGICA CORREGIDA PARA EL ESTADO VACÍO ---
            if (summary.spendingAccounts.isEmpty && summary.savingsAccount == null) {
              return EmptyAccountsWidget(
                onAddAccount: _navigateToAddAccount,
              );
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
                    child: summary.spendingAccounts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No hay cuentas para gastos.',
                              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                            ),
                          )
                        : Column(
                            children: summary.spendingAccounts
                                .map(
                                  (acc) => AccountCard(
                                    account: acc,
                                    onAddMoney: () async {
                                      final result = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => AddMoneyScreen(initialAccount: acc),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        _loadData();
                                      }
                                    },
                                  ),
                                )
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccountCard(
                            account: summary.savingsAccount!,
                            onManageSavings: () {
                              Navigator.of(context).pushNamed('/goals');
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AccountsActionButton extends StatelessWidget {
  const AccountsActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: OutlinedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(const CircleBorder()),
            side: MaterialStateProperty.all(
              BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
            ),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.resolveWith(
              (states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.white.withOpacity(0.3);
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.white.withOpacity(0.2);
                }
                if (states.contains(MaterialState.focused)) {
                  return Colors.white.withOpacity(0.25);
                }
                return null;
              },
            ),
            minimumSize: MaterialStateProperty.all(const Size(48, 48)),
            padding: MaterialStateProperty.all(EdgeInsets.zero),
          ),
          onPressed: onPressed,
          child: icon,
        ),
      ),
    );
  }
}
