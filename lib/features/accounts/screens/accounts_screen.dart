// lib/features/accounts/screens/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';
import 'package:finai_flutter/features/accounts/services/accounts_service.dart';
import 'package:finai_flutter/features/accounts/widgets/account_card.dart';
import 'package:finai_flutter/features/accounts/widgets/accounts_action_button.dart';
import 'package:finai_flutter/features/accounts/widgets/accounts_summary_card.dart';
import 'package:finai_flutter/features/accounts/widgets/empty_accounts_widget.dart';
import 'package:finai_flutter/features/accounts/widgets/internal_transfer_dialog.dart';
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

  Future<void> _confirmDeleteAccount(Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        const backgroundColor = Color(0xFF31090D);
        const borderColor = Color(0xFFFF4D4D);
        const highlightColor = Color(0xFFFF6B6B);

        return AlertDialog(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: borderColor,
              width: 1.6,
            ),
          ),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xFFFFCDD2),
            fontSize: 16,
            height: 1.4,
          ),
          title: const Text('Eliminar cuenta'),
          content: Text(
            '¿Seguro que deseas eliminar "${account.name}"? Esta acción no se puede deshacer.',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                foregroundColor: Colors.white70,
                backgroundColor: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              ),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                foregroundColor: Colors.white,
                backgroundColor: highlightColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final result = await _accountsService.deleteAccount(account.id);
      if (!mounted) return;

      final snackBarMessage =
          result.success ? '${result.message} (${account.name})' : result.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          backgroundColor:
              result.success ? Colors.green.shade600 : Colors.red.shade700,
        ),
      );
      _loadData();
    }
  }

  List<Widget> _buildAccountHeaderActions(Account cuenta) {
    return [
      IconButton(
        tooltip: 'Editar cuenta',
        icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF0088)),
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddEditAccountScreen(account: cuenta),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
      ),
      IconButton(
        tooltip: 'Eliminar cuenta',
        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF0088)),
        onPressed: () => _confirmDeleteAccount(cuenta),
      ),
    ];
  }

  void _navigateToGoals() {
    Navigator.of(context).pushNamed('/goals');
  }

  Future<void> _showInternalTransferDialog(AccountSummary summary) async {
    if (summary.savingsAccount == null || summary.spendingAccounts.isEmpty) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => InternalTransferDialog(
        spendingAccounts: summary.spendingAccounts,
        savingsAccount: summary.savingsAccount!,
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
        body: SafeArea(
          top: true,
          bottom: false,
          child: FutureBuilder<AccountSummary>(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Mis Cuentas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Color(0xFFFF0088),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AccountsActionButton(
                              label: 'Añadir cuenta',
                              icon: Icons.add,
                              onPressed: _navigateToAddAccount,
                            ),
                            const SizedBox(width: 12),
                            AccountsActionButton(
                              label: 'Transferencia entre cuentas',
                              icon: Icons.sync_alt_rounded,
                              onPressed: (summary.spendingAccounts.isEmpty ||
                                      summary.savingsAccount == null)
                                  ? null
                                  : () => _showInternalTransferDialog(summary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    // SECCIÓN 1: CUENTAS PARA GASTAR
                    AccountsSummaryCard(
                      headerTitle: 'Cuenta para gastos',
                      headerActions: summary.spendingAccounts.length == 1
                          ? _buildAccountHeaderActions(summary.spendingAccounts.first)
                          : const [],
                      title: 'Total Disponible',
                      totalAmount: summary.totalSpendingBalance,
                      iconData: FontAwesomeIcons.wallet,
                      iconColor: const Color(0xFFFF0088),
                      iconBackgroundColor: const Color.fromARGB(255, 44, 0, 23),
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
                        headerTitle: 'Cuenta ahorro',
                        headerActions: _buildAccountHeaderActions(summary.savingsAccount!),
                        title: 'Total Ahorrado',
                        totalAmount: summary.totalSavingsBalance,
                        iconData: FontAwesomeIcons.piggyBank,
                        iconColor: const Color(0xFFFF0088),
                      iconBackgroundColor: const Color.fromARGB(255, 44, 0, 23),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AccountCard(
                              account: summary.savingsAccount!,
                              onManageSavings: _navigateToGoals,
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
      ),
    );
  }
}
