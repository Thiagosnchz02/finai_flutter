// lib/features/transactions/screens/transactions_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Necesario para groupBy
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finai_flutter/features/accounts/services/accounts_service.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';
import 'package:finai_flutter/features/transactions/screens/add_edit_transaction_screen.dart';
import 'package:finai_flutter/features/transactions/services/transactions_service.dart';
import 'package:finai_flutter/features/transactions/widgets/transaction_tile.dart';
import 'package:finai_flutter/features/transactions/widgets/transactions_filter_sheet.dart';

class TransactionsViewData {
  TransactionsViewData({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
  });

  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpenses;
  final double? currentBalance;
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionsService();
  final _accountsService = AccountsService();
  late Future<TransactionsViewData> _transactionsFuture;

  String _filterType = 'todos';
  double? _minAmount;
  double? _maxAmount;
  String? _categoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _concept;
  final Map<String, List<Map<String, dynamic>>> _filterCategoriesCache = {};

  String get _currentFilterSegment {
    switch (_filterType) {
      case 'ingreso':
        return 'ingreso';
      case 'gasto':
        return 'gasto';
      default:
        return 'todos';
    }
  }

  bool get _hasActiveFilters {
    return _filterType != 'todos' ||
        _minAmount != null ||
        _maxAmount != null ||
        _categoryId != null ||
        _startDate != null ||
        _endDate != null ||
        (_concept != null && _concept!.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _transactionsFuture = () async {
        final maps = await _service.fetchTransactions(
          type: _filterType,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          categoryId: _categoryId,
          startDate: _startDate,
          endDate: _endDate,
          concept: _concept,
        );

        final transactions =
            maps.map((map) => Transaction.fromMap(map)).toList();

        final totalIncome = transactions
            .where((tx) => tx.type == 'ingreso')
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        final totalExpenses = transactions
            .where((tx) => tx.type == 'gasto')
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        final balance = await _accountsService.getParaGastarBalance();

        return TransactionsViewData(
          transactions: transactions,
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
          currentBalance: balance,
        );
      }();
    });
  }

  // Navega a la pantalla de añadir/editar y recarga los datos si es necesario.
  void _navigateAndRefresh({Transaction? transaction}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(transaction: transaction),
      ),
    );
    if (result == true && mounted) {
      _loadTransactions();
    }
  }

  // Elimina una transacción después de confirmar con el usuario.
  Future<void> _deleteTransaction(Transaction transaction) async {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final formattedAmount = currencyFormat.format(transaction.amount.abs());
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Fondo más oscuro para resaltar el diálogo
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur en el fondo
          child: AlertDialog(
            backgroundColor: const Color(0xFF000000).withOpacity(0.85), // Negro semi-transparente
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(
                color: Color(0xFFE5484D), // Borde rojo
                width: 0.8,
              ),
            ),
            shadowColor: const Color(0xFFE5484D).withOpacity(0.5),
            elevation: 40, // Elevación alta para efecto 3D
            titleTextStyle: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFFFFFFFF), // Blanco Puro
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.01,
            ),
            contentTextStyle: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFFFFFFFF), // Texto blanco
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0.005,
            ),
            title: const Text('Eliminar transacción'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('¿Seguro que deseas eliminar esta transacción?'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4a0873).withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        transaction.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFFFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedAmount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: transaction.type == 'ingreso'
                              ? const Color(0xFF25C9A4) // Verde Digital
                              : const Color(0xFFE5484D), // Rojo Sobrio
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.01,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              // Botón Secundario (Cancelar)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  foregroundColor: const Color(0xFFFFFFFF), // Texto blanco
                  backgroundColor: const Color(0xFF000000), // Fondo negro brillante
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0x26FFFFFF), // Borde blanco sutil
                      width: 0.8,
                    ),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              // Botón Primario (Eliminar)
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  foregroundColor: const Color(0xFFFFFFFF), // Blanco Puro
                  backgroundColor: const Color(0xFFE5484D), // Rojo Sobrio
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
      await _service.deleteTransaction(transaction.id);
      if (!mounted) return;
      final message = transaction.type == 'transferencia'
          ? 'Transacción eliminada. Recuerda borrar la contraparte de la transferencia manualmente.'
          : 'Transacción eliminada.';
      
      _showSuccessSnackBar(message);
      _loadTransactions();
    }
  }

  // Agrupa las transacciones por fecha.
  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    return groupBy(transactions, (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day));
  }
  
  // Muestra un SnackBar elegante con animación para mensajes de éxito
  void _showSuccessSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF25C9A4).withOpacity(0.3),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25C9A4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF25C9A4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remover después de 3 segundos con animación de salida
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
  
  // Formatea el encabezado de cada grupo de fechas.
  String _formatDateHeader(DateTime date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (date == today) return 'Hoy';
      if (date == yesterday) return 'Ayer';
      
      return DateFormat.yMMMd('es_ES').format(date);
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
              const Color(0xFF0A0A0A).withOpacity(0.98), // Negro ligeramente más claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<TransactionsViewData>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final viewData = snapshot.data;
                final transactions = viewData?.transactions ?? [];

                Widget transactionsSliver;
                if (transactions.isEmpty) {
                  transactionsSliver = const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No hay transacciones todavía.')),
                  );
                } else {
                  final groupedTransactions = _groupTransactionsByDate(transactions);
                  final dateKeys =
                      groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));
                  transactionsSliver = SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final date = dateKeys[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == dateKeys.length - 1 ? 0 : 24,
                          ),
                          child: _buildTransactionGroup(
                            _formatDateHeader(date),
                            groupedTransactions[date]!,
                          ),
                        );
                      },
                      childCount: dateKeys.length,
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(viewData)),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    transactionsSliver,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Cabecera con resumen financiero y acciones
  Widget _buildHeader(TransactionsViewData? viewData) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final balance = viewData?.currentBalance;
    final income = viewData?.totalIncome ?? 0;
    final expenses = viewData?.totalExpenses ?? 0;

    final balanceText = balance != null ? currencyFormat.format(balance) : '--';
    final incomeText = '+${currencyFormat.format(income.abs())}';
    final expensesText = '-${currencyFormat.format(expenses.abs())}';

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Tarjeta con efecto glassmorphism
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente (no seleccionado)
                  const Color(0xFF5a0d8d).withOpacity(0.12), // Muy transparente
                  const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4a0873).withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Balance actual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.01,
                    color: Color(0xFFA0AEC0), // Gris Neutro
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  balanceText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                    color: Color(0xFFFFFFFF), // Blanco Puro
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Positivo',
                  incomeText,
                  const Color(0xFF25C9A4), // Verde Digital
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Negativo',
                  expensesText,
                  const Color(0xFFE5484D), // Rojo Sobrio
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNewTransactionButton(),
          const SizedBox(height: 16),
          _buildFilterSegmentedButton(),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _editActiveFilters,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Editar filtros'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9927FD), // Púrpura Aurora
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente (no seleccionado)
            const Color(0xFF5a0d8d).withOpacity(0.12), // Muy transparente
            const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4a0873).withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.01,
                  color: Color(0xFFA0AEC0), // Gris Neutro
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildNewTransactionButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Negro brillante
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0x26FFFFFF), // Borde blanco sutil como las tarjetas
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () => _navigateAndRefresh(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF9E9E9E), // Gris más oscuro, menos brillante
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Nueva Transacción +'),
        ),
      ),
    );
  }

  // TU WIDGET DE GRUPO DE TRANSACCIONES (MODIFICADO PARA USAR EL NUEVO MODELO)
  Widget _buildTransactionGroup(String title, List<Transaction> transactions) {
    final headerStyle = const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0.004,
      color: Color(0xFFA0AEC0), // Gris Neutro
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: headerStyle),
        const SizedBox(height: 12),
        ...List.generate(transactions.length, (index) {
          final tx = transactions[index];
          final isLast = index == transactions.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: TransactionTile(
              transaction: tx,
              onTap: () => _navigateAndRefresh(transaction: tx),
              onDelete: () => _deleteTransaction(tx),
            ),
          );
        }),
      ],
    );
  }
  Widget _buildFilterSegmentedButton() {
    const filters = [
      ('todos', 'Todo'),
      ('ingreso', 'Ingreso'),
      ('gasto', 'Gasto'),
    ];

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _currentFilterSegment == filters[i].$1
                      ? const Color(0xFF3a0560).withOpacity(0.6) // Morado oscuro solo un poco opaco (seleccionado)
                      : null,
                  gradient: _currentFilterSegment == filters[i].$1
                      ? null
                      : LinearGradient(
                          colors: [
                            const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente (no seleccionado)
                            const Color(0xFF5a0d8d).withOpacity(0.12), // Muy transparente
                            const Color(0xFF4a0873).withOpacity(0.15), // Muy transparente
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _currentFilterSegment == filters[i].$1
                        ? const Color(0xFF3a0560).withOpacity(0.8)
                        : const Color(0xFF4a0873).withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: TextButton(
                  onPressed: () => _handleFilterSelection(filters[i].$1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    backgroundColor: Colors.transparent,
                    foregroundColor: _currentFilterSegment == filters[i].$1
                        ? const Color(0xFF9E9E9E) // Gris más oscuro cuando activo
                        : const Color(0xFF6B6B6B), // Gris aún más oscuro cuando no activo
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(filters[i].$2),
                ),
              ),
            ),
            if (i < filters.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _handleFilterSelection(String selectedType) async {
    if (selectedType == 'todos') {
      if (!_hasActiveFilters) {
        if (_filterType != 'todos') {
          setState(() {
            _filterType = 'todos';
          });
        }
        return;
      }

      setState(() {
        _filterType = 'todos';
        _minAmount = null;
        _maxAmount = null;
        _categoryId = null;
        _startDate = null;
        _endDate = null;
        _concept = null;
      });
      _loadTransactions();
      return;
    }

    final result = await _showFiltersSheet(initialType: selectedType);
    if (!mounted) return;

    if (result != null) {
      _applyFilterResult(result, fallbackType: selectedType);
    }
  }

  Future<void> _editActiveFilters() async {
    final result = await _showFiltersSheet(initialType: _currentFilterSegment);
    if (!mounted) return;

    if (result != null) {
      _applyFilterResult(result, fallbackType: _currentFilterSegment);
    }
  }

  Future<Map<String, dynamic>?> _showFiltersSheet({required String initialType}) async {
    final categories = await _loadFilterCategories(initialType);
    if (!mounted) return null;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionsFilterSheet(
        type: initialType,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        categoryId: _categoryId,
        startDate: _startDate,
        endDate: _endDate,
        concept: _concept,
        filteredCategories: categories,
        loadCategoriesForType: _loadFilterCategories,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadFilterCategories(String type) async {
    if (type == 'todos') {
      final gasto = await _loadFilterCategories('gasto');
      final ingreso = await _loadFilterCategories('ingreso');
      final combined = <String, Map<String, dynamic>>{};
      for (final category in [...gasto, ...ingreso]) {
        final id = category['id'];
        if (id is String) {
          combined[id] = category;
        }
      }
      final combinedList = combined.values.toList()
        ..sort((a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
      return combinedList;
    }

    final cached = _filterCategoriesCache[type];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, icon')
          .eq('type', type)
          .order('name');
      final raw = response as List<dynamic>;
      final categories = raw
          .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
          .toList();
      _filterCategoriesCache[type] = categories;
      return categories;
    } catch (_) {
      return [];
    }
  }

  void _applyFilterResult(Map<String, dynamic> result,
      {required String fallbackType}) {
    setState(() {
      _filterType = (result['type'] as String?) ?? fallbackType;
      _minAmount = result['minAmount'] as double?;
      _maxAmount = result['maxAmount'] as double?;
      _categoryId = result['categoryId'] as String?;
      _startDate = result['startDate'] as DateTime?;
      _endDate = result['endDate'] as DateTime?;
      _concept = result['concept'] as String?;
    });
    _loadTransactions();
  }
}
