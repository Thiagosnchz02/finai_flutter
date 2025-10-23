// lib/features/transactions/screens/transactions_screen.dart

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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text('¿Seguro que deseas eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _service.deleteTransaction(transaction.id);
      if (!mounted) return;
      final message = transaction.type == 'transferencia'
          ? 'Transacción eliminada. Recuerda borrar la contraparte de la transferencia manualmente.'
          : 'Transacción eliminada.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _loadTransactions();
    }
  }

  // Agrupa las transacciones por fecha.
  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    return groupBy(transactions, (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day));
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
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF80008B),
              Color(0xFF3C0F48),
              Color(0xFF1A0A22),
              Color(0xFF121212),
            ],
            stops: [0.0, 0.45, 0.75, 1.0],
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
    final incomeText = '+${currencyFormat.format(income)}';
    final expensesText = '-${currencyFormat.format(expenses)}';

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x33B400C4),
                  blurRadius: 32,
                  spreadRadius: -12,
                  offset: Offset(0, 12),
                  blurStyle: BlurStyle.inner,
                ),
              ],
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
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  balanceText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB400C4),
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
                  '+ Positivo',
                  incomeText,
                  const Color(0xFF00FF00),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  '- Negativo',
                  expensesText,
                  const Color(0xFFFF0000),
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
                icon: const Icon(Icons.filter_list),
                label: const Text('Editar filtros'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNewTransactionButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _navigateAndRefresh(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          backgroundColor: const Color(0x1FEA00FF),
          foregroundColor: const Color(0xFFE0E0E0),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFEA00FF),
              width: 4.19,
            ),
          ),
        ),
        child: const Text('Nueva Transacción +'),
      ),
    );
  }

  // TU WIDGET DE GRUPO DE TRANSACCIONES (MODIFICADO PARA USAR EL NUEVO MODELO)
  Widget _buildTransactionGroup(String title, List<Transaction> transactions) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: theme.colorScheme.onSurface.withOpacity(0.7),
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
              child: TextButton(
                onPressed: () => _handleFilterSelection(filters[i].$1),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  backgroundColor: _currentFilterSegment == filters[i].$1
                      ? const Color(0x3DEA00FF)
                      : const Color(0x1FEA00FF),
                  foregroundColor: const Color(0xFFE0E0E0),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _currentFilterSegment == filters[i].$1
                          ? const Color(0xFFEA00FF)
                          : const Color(0x66EA00FF),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(filters[i].$2),
              ),
            ),
            if (i < filters.length - 1) const SizedBox(width: 12),
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
