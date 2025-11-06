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
import 'package:finai_flutter/features/settings/services/settings_service.dart';

class TransactionsViewData {
  TransactionsViewData({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.totalTransfersIn,
    required this.totalTransfersOut,
    required this.availableToSpend,
    required this.isCurrentMonth,
  });

  final List<Transaction> transactions;
  final double totalIncome; // Solo ingresos reales (sin transferencias)
  final double totalExpenses; // Solo gastos reales (sin transferencias)
  final double? currentBalance; // Saldo actual de la cuenta
  final double totalTransfersIn; // Transferencias entrantes a esta cuenta
  final double totalTransfersOut; // Transferencias salientes de esta cuenta
  final double? availableToSpend; // Disponible para gastar (solo mes actual)
  final bool isCurrentMonth; // Si estamos viendo el mes actual
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  final _service = TransactionsService();
  final _accountsService = AccountsService();
  final _settingsService = SettingsService();
  late Future<TransactionsViewData> _transactionsFuture;

  String _filterType = 'todos';
  double? _minAmount;
  double? _maxAmount;
  String? _categoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _concept;
  final Map<String, List<Map<String, dynamic>>> _filterCategoriesCache = {};

  // Navegación por meses
  late DateTime _selectedMonth; // Mes actualmente seleccionado
  bool _swipeMonthNavigationEnabled = false; // Si el usuario tiene habilitado el swipe
  String _showTransfersCard = 'never'; // Configuración de visualización de traspasos
  TransactionsViewData? _cachedViewData; // Para mantener datos mientras se navega
  
  // Animación para el efecto de rebote cuando se intenta ir a mes futuro
  late AnimationController _bounceController;
  late Animation<Offset> _bounceAnimation;

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

  // Detecta si el usuario ha establecido filtros de fecha personalizados (no por navegación de mes)
  bool get _hasCustomDateFilter {
    return _startDate != null || _endDate != null;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    
    // Inicializar controlador de animación para efecto rebote
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.05, 0), // Pequeño desplazamiento a la izquierda y regresa
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack, // Curva más suave sin pausas
    ));
    
    _loadUserPreferences();
    _loadTransactions();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final profile = await _settingsService.getProfileSettings();
      setState(() {
        _swipeMonthNavigationEnabled = profile.swipeMonthNavigation;
        _showTransfersCard = profile.showTransfersCard;
      });
    } catch (e) {
      // Si falla, mantenemos los valores por defecto
    }
  }

  void _loadTransactions() {
    // Cuando hay navegación por mes, establecemos los filtros de fecha
    final useMonthFilter = _swipeMonthNavigationEnabled && !_hasCustomDateFilter;
    final DateTime? effectiveStartDate;
    final DateTime? effectiveEndDate;

    if (useMonthFilter) {
      effectiveStartDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      effectiveEndDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    } else {
      effectiveStartDate = _startDate;
      effectiveEndDate = _endDate;
    }

    setState(() {
      _transactionsFuture = () async {
        final maps = await _service.fetchTransactions(
          type: _filterType,
          minAmount: _minAmount,
          maxAmount: _maxAmount,
          categoryId: _categoryId,
          startDate: effectiveStartDate,
          endDate: effectiveEndDate,
          concept: _concept,
        );

        final transactions =
            maps.map((map) => Transaction.fromMap(map)).toList();

        // Solo ingresos reales (sin transferencias)
        final totalIncome = transactions
            .where((tx) => tx.type == 'ingreso')
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        // Solo gastos reales (sin transferencias)
        final totalExpenses = transactions
            .where((tx) => tx.type == 'gasto')
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        // Transferencias entrantes (positivas)
        final totalTransfersIn = transactions
            .where((tx) => tx.type == 'transferencia' && tx.amount > 0)
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        // Transferencias salientes (negativas, convertimos a positivo para mostrar)
        final totalTransfersOut = transactions
            .where((tx) => tx.type == 'transferencia' && tx.amount < 0)
            .fold<double>(0.0, (sum, tx) => sum + tx.amount.abs());

        final balance = await _accountsService.getParaGastarBalance();

        // Calcular disponible para gastar (solo mes actual)
        // Disponible = Saldo actual − Gastos fijos pendientes del mes
        final now = DateTime.now();
        final useMonthFilter = _swipeMonthNavigationEnabled && !_hasCustomDateFilter;
        
        final bool isCurrentMonth;
        if (useMonthFilter) {
          // Si estamos usando navegación por mes, comprobamos si el mes seleccionado es el actual
          isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
        } else {
          // Si no, comprobamos los filtros de fecha normales
          isCurrentMonth = (effectiveStartDate == null && effectiveEndDate == null) ||
              (effectiveStartDate != null &&
                  effectiveEndDate != null &&
                  effectiveStartDate.year == now.year &&
                  effectiveStartDate.month == now.month);
        }

        double? availableToSpend;
        if (isCurrentMonth && balance != null) {
          final pendingFixedExpenses =
              await _service.getPendingFixedExpensesForCurrentMonth();
          availableToSpend = balance - pendingFixedExpenses;
        }

        return TransactionsViewData(
          transactions: transactions,
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
          currentBalance: balance,
          totalTransfersIn: totalTransfersIn,
          totalTransfersOut: totalTransfersOut,
          availableToSpend: availableToSpend,
          isCurrentMonth: isCurrentMonth,
        );
      }();
    });
  }

  // Cambia al mes anterior
  void _navigateToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _loadTransactions();
  }

  // Cambia al mes siguiente (solo si no es mes futuro)
  void _navigateToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    
    // No permitir navegar a meses futuros
    if (nextMonth.year > now.year || 
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }

    setState(() {
      _selectedMonth = nextMonth;
    });
    _loadTransactions();
  }

  // Vuelve al mes actual
  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
    _loadTransactions();
  }

  // Detecta si el mes seleccionado es el actual
  bool get _isViewingCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  // Determina si mostrar la tarjeta de traspasos según configuración
  bool _shouldShowTransfersCard(double transfersIn, double transfersOut) {
    final hasTransfers = transfersIn > 0 || transfersOut > 0;
    
    switch (_showTransfersCard) {
      case 'always':
        return true;
      case 'auto':
        return hasTransfers;
      case 'never':
      default:
        return false;
    }
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
                // Si tenemos datos cacheados y estamos esperando nuevos datos,
                // mostramos los datos cacheados para evitar pantalla de carga
                final viewData = snapshot.hasData 
                    ? snapshot.data 
                    : (snapshot.connectionState == ConnectionState.waiting && _cachedViewData != null)
                        ? _cachedViewData
                        : null;
                
                // Si tenemos nuevos datos, actualizamos el cache
                if (snapshot.hasData) {
                  _cachedViewData = snapshot.data;
                }
                
                // Solo mostramos loading si no hay datos en cache
                if (viewData == null && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                return _swipeMonthNavigationEnabled && !_hasCustomDateFilter
                    ? GestureDetector(
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          
                          if (velocity > 500) {
                            // Swipe derecha → mes anterior (siempre permitido)
                            _navigateToPreviousMonth();
                          } else if (velocity < -500) {
                            // Swipe izquierda → mes siguiente (solo si no estamos en mes actual)
                            if (!_isViewingCurrentMonth) {
                              _navigateToNextMonth();
                            } else {
                              // Mostrar animación de rebote para indicar que está bloqueado
                              _bounceController.forward().then((_) {
                                _bounceController.reverse();
                              });
                            }
                          }
                        },
                        child: SlideTransition(
                          position: _bounceAnimation,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.15, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(_selectedMonth.toString()),
                              child: _buildMonthPage(viewData),
                            ),
                          ),
                        ),
                      )
                    : _buildMonthPage(viewData);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget de página de mes (reutilizable para PageView o vista simple)
  Widget _buildMonthPage(TransactionsViewData? viewData) {
    final transactions = viewData?.transactions ?? [];

    Widget transactionsSliver;
    if (transactions.isEmpty) {
      transactionsSliver = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No hay transacciones en este período',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA0AEC0),
            ),
          ),
        ),
      );
    } else {
      final groupedTransactions = _groupTransactionsByDate(transactions);
      final dateKeys = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));
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
        if (_swipeMonthNavigationEnabled && !_hasCustomDateFilter)
          SliverToBoxAdapter(child: _buildMonthIndicator()),
        SliverToBoxAdapter(child: _buildHeader(viewData)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        transactionsSliver,
      ],
    );
  }

  // Indicador del mes actual con navegación
  Widget _buildMonthIndicator() {
    final monthName = DateFormat.yMMMM('es_ES').format(_selectedMonth);
    final isCurrentMonth = _isViewingCurrentMonth;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        children: [
          Text(
            monthName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
              letterSpacing: 0,
            ),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4a0873).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4a0873).withOpacity(0.4),
                  width: 0.8,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _goToCurrentMonth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.today,
                          size: 16,
                          color: Color(0xFFFFFFFF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Volver a este mes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Cabecera con resumen financiero y acciones
  Widget _buildHeader(TransactionsViewData? viewData) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final income = viewData?.totalIncome ?? 0;
    final expenses = viewData?.totalExpenses ?? 0;
    final transfersIn = viewData?.totalTransfersIn ?? 0;
    final transfersOut = viewData?.totalTransfersOut ?? 0;
    final transfersNet = transfersIn - transfersOut;
    final availableToSpend = viewData?.availableToSpend;
    final isCurrentMonth = viewData?.isCurrentMonth ?? true;

    final incomeText = '+${currencyFormat.format(income.abs())}';
    final expensesText = '-${currencyFormat.format(expenses.abs())}';
    final transfersNetText = transfersNet >= 0
        ? '+${currencyFormat.format(transfersNet.abs())}'
        : '-${currencyFormat.format(transfersNet.abs())}';
    final availableText = availableToSpend != null
        ? currencyFormat.format(availableToSpend)
        : '--';

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Fila: Disponible, Positivo y Negativo (todas del mismo tamaño)
          Row(
            children: [
              // Disponible (solo en mes actual)
              if (isCurrentMonth) ...[
                Expanded(
                  child: _buildCompactCard(
                    'Disponible',
                    availableText,
                    const Color(0xFF4a0873), // Morado
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Positivo
              Expanded(
                child: _buildCompactCard(
                  'Positivo',
                  incomeText,
                  const Color(0xFF25C9A4), // Verde
                ),
              ),
              const SizedBox(width: 12),
              // Negativo
              Expanded(
                child: _buildCompactCard(
                  'Negativo',
                  expensesText,
                  const Color(0xFFE5484D), // Rojo
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tarjeta de Traspasos (condicional)
          if (_shouldShowTransfersCard(transfersIn, transfersOut))
            _buildTransfersItem(
              transfersNetText,
              transfersNet,
              currencyFormat.format(transfersIn.abs()),
              currencyFormat.format(transfersOut.abs()),
            ),
          if (_shouldShowTransfersCard(transfersIn, transfersOut))
            const SizedBox(height: 24)
          else
            const SizedBox(height: 8),
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
                  foregroundColor: const Color(0xFF9927FD),
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

  // Tarjeta compacta para Disponible, Positivo y Negativo
  Widget _buildCompactCard(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4a0873).withOpacity(0.15),
            const Color(0xFF5a0d8d).withOpacity(0.12),
            const Color(0xFF4a0873).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
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
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.01,
              color: Color(0xFFA0AEC0),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta especial para traspasos con desglose
  Widget _buildTransfersItem(
      String netValue, double netAmount, String inValue, String outValue) {
    final Color netColor = netAmount >= 0
        ? const Color(0xFF25C9A4) // Verde si es positivo
        : const Color(0xFFE5484D); // Rojo si es negativo

    return Opacity(
      opacity: 0.8, // Más sutil
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0), // 30% más pequeño
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4a0873).withOpacity(0.10), // Menos intenso
              const Color(0xFF5a0d8d).withOpacity(0.08),
              const Color(0xFF4a0873).withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(14), // Bordes menos redondeados
          border: Border.all(
            color: const Color(0xFF4a0873).withOpacity(0.15), // Borde más sutil
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Traspasos',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13, // Más pequeño
                fontWeight: FontWeight.w400,
                letterSpacing: 0.01,
                color: Color(0xFFA0AEC0),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    netValue,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16, // Más pequeño
                      fontWeight: FontWeight.w600,
                      color: netColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Desglose pequeño: Entraron · Salieron
                  Text(
                    '↑$inValue · ↓$outValue',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10, // Más pequeño
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFA0AEC0).withOpacity(0.6),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTransactionButton() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF000000).withOpacity(0.88), // Izquierda oscuro
                  const Color(0xFF0D0D0D).withOpacity(0.92), // Centro claro
                  const Color(0xFF000000).withOpacity(0.88), // Derecha oscuro
                ],
                stops: const [0.0, 0.5, 1.0], // Izquierda, Centro, Derecha
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0x1FFFFFFF),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: -4,
                  offset: const Offset(0, -3),
                ),
                BoxShadow(
                  color: const Color(0xFF700aa3).withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 0),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: TextButton(
              onPressed: () => _navigateAndRefresh(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF9E9E9E),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Nueva Transacción'),
            ),
          ),
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
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < filters.length; i++) ...[
            Expanded(
              child: Container(
                height: 32,
                constraints: const BoxConstraints(minWidth: 70), // Ancho mínimo
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentFilterSegment == filters[i].$1
                        ? const Color(0xFF3a0560).withOpacity(0.8)
                        : const Color(0xFF4a0873).withOpacity(0.25),
                    width: 0.6,
                  ),
                ),
                child: TextButton(
                  onPressed: () => _handleFilterSelection(filters[i].$1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    backgroundColor: Colors.transparent,
                    foregroundColor: _currentFilterSegment == filters[i].$1
                          ? const Color(0xFF9E9E9E) // Gris más oscuro cuando activo
                          : const Color(0xFF6B6B6B), // Gris aún más oscuro cuando no activo
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
