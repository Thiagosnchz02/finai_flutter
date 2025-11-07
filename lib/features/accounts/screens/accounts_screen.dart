// lib/features/accounts/screens/accounts_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finai_flutter/features/accounts/models/account_model.dart';
import 'package:finai_flutter/features/accounts/services/accounts_service.dart';
import 'package:finai_flutter/features/accounts/widgets/account_card.dart';
import 'package:finai_flutter/features/accounts/widgets/accounts_action_button.dart';
import 'package:finai_flutter/features/accounts/widgets/accounts_summary_card.dart';
import 'package:finai_flutter/features/accounts/widgets/empty_accounts_widget.dart';
import 'package:finai_flutter/features/accounts/widgets/internal_transfer_dialog.dart';
import 'package:finai_flutter/features/settings/services/preferences_service.dart';
import 'add_edit_account_screen.dart';
import 'add_money_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountsService _accountsService = AccountsService();
  final PreferencesService _preferencesService = PreferencesService();
  late Future<AccountSummary> _accountSummaryFuture;
  late Future<UserPreferences> _preferencesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _accountSummaryFuture = _accountsService.getAccountSummary();
      _preferencesFuture = _preferencesService.getAllPreferences();
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

  void _navigateToEditAccount(Account account) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEditAccountScreen(account: account)),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _navigateToAddMoney(Account account) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMoneyScreen(initialAccount: account),
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _navigateToGoals() {
    Navigator.of(context).pushNamed('/goals');
  }

  Future<void> _showInternalTransferDialog(AccountSummary summary) async {
    if (summary.savingsAccount == null || summary.spendingAccounts.isEmpty) {
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InternalTransferDialog(
        spendingAccounts: summary.spendingAccounts,
        savingsAccount: summary.savingsAccount!,
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _confirmDeleteAccount(Account account) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // Fondo más oscuro
      builder: (dialogContext) {
        const backgroundColor = Color(0xFF0A0A0A); // Negro brillante
        const borderColor = Color(0xFFE5484D); // Rojo consistente
        const highlightColor = Color(0xFFE5484D); // Rojo consistente

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto de blur
          child: AlertDialog(
            backgroundColor: backgroundColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Bordes más redondeados
              side: const BorderSide(color: borderColor, width: 1.2),
            ),
            titleTextStyle: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            contentTextStyle: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFFA0AEC0), // Color de texto secundario
              fontSize: 15,
              height: 1.5,
            ),
            title: const Text('Eliminar cuenta'),
            content: Text(
              '¿Seguro que deseas eliminar "${account.name}"? Esta acción no se puede deshacer.',
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  foregroundColor: Colors.white70,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  foregroundColor: Colors.white,
                  backgroundColor: highlightColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true) {
      final result = await _accountsService.deleteAccount(account.id);
      if (!mounted) return;

      final snackBarMessage = result.success
          ? '${result.message} (${account.name})'
          : result.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          backgroundColor: result.success
              ? const Color(0xFF25C9A4)
              : const Color(0xFFE5484D), // Verde/Rojo consistentes
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Negro puro brillante
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF000000), // Negro puro
              const Color(
                0xFF0A0A0A,
              ).withOpacity(0.98), // Negro ligeramente más claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([_accountSummaryFuture, _preferencesFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4a0873), // Color morado
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return EmptyAccountsWidget(
                  onAddAccount: _navigateToAddAccount,
                ); // Fallback por si no hay datos
              }

              final summary = snapshot.data![0] as AccountSummary;
              final prefs = snapshot.data![1] as UserPreferences;

              // --- LÓGICA CORREGIDA PARA EL ESTADO VACÍO ---
              if (summary.spendingAccounts.isEmpty &&
                  summary.savingsAccount == null) {
                return EmptyAccountsWidget(onAddAccount: _navigateToAddAccount);
              }

              return _AccountsContent(
                summary: summary,
                prefs: prefs,
                onRefresh: _loadData,
                onAddAccount: _navigateToAddAccount,
                onEditAccount: _navigateToEditAccount,
                onDeleteAccount: _confirmDeleteAccount,
                onAddMoney: _navigateToAddMoney,
                onManageSavings: _navigateToGoals,
                onInternalTransfer: _showInternalTransferDialog,
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget separado que contiene todo el contenido y maneja el estado del acordeón
class _AccountsContent extends StatefulWidget {
  final AccountSummary summary;
  final UserPreferences prefs;
  final VoidCallback onRefresh;
  final VoidCallback onAddAccount;
  final Function(Account) onEditAccount;
  final Function(Account) onDeleteAccount;
  final Function(Account) onAddMoney;
  final VoidCallback onManageSavings;
  final Function(AccountSummary) onInternalTransfer;

  const _AccountsContent({
    required this.summary,
    required this.prefs,
    required this.onRefresh,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onDeleteAccount,
    required this.onAddMoney,
    required this.onManageSavings,
    required this.onInternalTransfer,
  });

  @override
  State<_AccountsContent> createState() => _AccountsContentState();
}

class _AccountsContentState extends State<_AccountsContent> {
  String? _expandedAccountId; // Estado del acordeón SOLO aquí

  List<Widget> _buildAccountHeaderActions(Account account) {
    return [
      IconButton(
        icon: const Icon(Icons.edit, color: Color(0xFF4a0873), size: 18),
        tooltip: 'Editar cuenta',
        onPressed: () => widget.onEditAccount(account),
      ),
      IconButton(
        icon: const Icon(Icons.delete, color: Color(0xFFE5484D), size: 18),
        tooltip: 'Eliminar cuenta',
        onPressed: () => widget.onDeleteAccount(account),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
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
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
                    onPressed: widget.onAddAccount,
                  ),
                  const SizedBox(width: 12),
                  AccountsActionButton(
                    label: 'Transferencia entre cuentas',
                    icon: Icons.sync_alt_rounded,
                    onPressed:
                        (widget.summary.spendingAccounts.isEmpty ||
                            widget.summary.savingsAccount == null)
                        ? null
                        : () => widget.onInternalTransfer(widget.summary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
          // SECCIÓN 1: CUENTAS PARA GASTAR
          AccountsSummaryCard(
            headerTitle: 'Cuenta para gastos',
            headerActions: widget.summary.spendingAccounts.length == 1
                ? _buildAccountHeaderActions(
                    widget.summary.spendingAccounts.first,
                  )
                : const [],
            title: 'Total Disponible',
            totalAmount: widget.summary.totalSpendingBalance,
            iconData: FontAwesomeIcons.wallet,
            iconColor: const Color(0xFF4a0873),
            iconBackgroundColor: const Color(0xFF4a0873).withOpacity(0.15),
            child: widget.summary.spendingAccounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No hay cuentas para gastos.',
                      style: TextStyle(
                        color: Color(0xFFA0AEC0),
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : Column(
                    children: widget.summary.spendingAccounts
                        .map(
                          (acc) => AccountCard(
                            key: ValueKey(acc.id),
                            account: acc,
                            isExpanded: _expandedAccountId == acc.id,
                            onToggleExpanded: () {
                              setState(() {
                                _expandedAccountId =
                                    (_expandedAccountId == acc.id)
                                    ? null
                                    : acc.id;
                              });
                            },
                            viewMode: widget.prefs.accountsViewMode,
                            enableAdvancedAnimations:
                                widget.prefs.accountsAdvancedAnimations,
                            showSparkline: widget.prefs.showAccountSparkline,
                            onAddMoney: () => widget.onAddMoney(acc),
                            onInternalTransfer: () =>
                                widget.onInternalTransfer(widget.summary),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),

          // SECCIÓN 2: CUENTA DE AHORRO
          if (widget.summary.savingsAccount != null)
            AccountsSummaryCard(
              headerTitle: 'Cuenta ahorro',
              headerActions: _buildAccountHeaderActions(
                widget.summary.savingsAccount!,
              ),
              title: 'Total Ahorrado',
              totalAmount: widget.summary.totalSavingsBalance,
              iconData: FontAwesomeIcons.piggyBank,
              iconColor: const Color(0xFF4a0873),
              iconBackgroundColor: const Color(0xFF4a0873).withOpacity(0.15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccountCard(
                    key: ValueKey(widget.summary.savingsAccount!.id),
                    account: widget.summary.savingsAccount!,
                    isExpanded:
                        _expandedAccountId == widget.summary.savingsAccount!.id,
                    onToggleExpanded: () {
                      setState(() {
                        _expandedAccountId =
                            (_expandedAccountId ==
                                widget.summary.savingsAccount!.id)
                            ? null
                            : widget.summary.savingsAccount!.id;
                      });
                    },
                    viewMode: widget.prefs.accountsViewMode,
                    enableAdvancedAnimations:
                        widget.prefs.accountsAdvancedAnimations,
                    showSparkline: widget.prefs.showAccountSparkline,
                    onManageSavings: widget.onManageSavings,
                    onInternalTransfer: () =>
                        widget.onInternalTransfer(widget.summary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
