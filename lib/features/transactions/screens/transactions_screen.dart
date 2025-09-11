// lib/features/transactions/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Necesario para groupBy
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:finai_flutter/features/transactions/models/transaction_model.dart';
import 'package:finai_flutter/features/transactions/screens/add_edit_transaction_screen.dart';
import 'package:finai_flutter/features/transactions/services/transactions_service.dart';
import 'package:finai_flutter/features/transactions/widgets/transaction_tile.dart';
import 'package:finai_flutter/features/transactions/widgets/transactions_filter_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionsService();
  late Future<List<Transaction>> _transactionsFuture;

  String _filterType = 'todos';
  double? _minAmount;
  double? _maxAmount;
  String? _categoryId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _concept;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    final filters = {
      'type': _filterType,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'categoryId': _categoryId,
      'startDate': _startDate,
      'endDate': _endDate,
      'concept': _concept,
    };

    setState(() {
      // Usamos el nuevo servicio para obtener las transacciones y las convertimos al modelo correcto.
      _transactionsFuture = _service
          .fetchTransactions(
            type: filters['type'],
            minAmount: filters['minAmount'],
            maxAmount: filters['maxAmount'],
            categoryId: filters['categoryId'],
            startDate: filters['startDate'],
            endDate: filters['endDate'],
            concept: filters['concept'],
          )
          .then((maps) =>
              maps.map((map) => Transaction.fromMap(map)).toList());
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildHeader(), // Mantenemos tu cabecera
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Transaction>>(
                  future: _transactionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final transactions = snapshot.data ?? [];
                    if (transactions.isEmpty) {
                      return const Center(child: Text('No hay transacciones todavía.'));
                    }

                    final groupedTransactions = _groupTransactionsByDate(transactions);
                    final dateKeys = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

                    return ListView.builder(
                      itemCount: dateKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = dateKeys[index];
                        final transactionsInGroup = groupedTransactions[dateKey]!;
                        return _buildTransactionGroup(_formatDateHeader(dateKey), transactionsInGroup);
                      },
                    );
                  },
                ),
              ),
              _buildPaginationControls(), // Mantenemos tus controles de paginación
            ],
          ),
        ),
      ),
    );
  }

  // TU WIDGET DE CABECERA (INTACTO)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Transacciones',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.filter),
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => TransactionsFilterSheet(
                      type: _filterType,
                      minAmount: _minAmount,
                      maxAmount: _maxAmount,
                      categoryId: _categoryId,
                      startDate: _startDate,
                      endDate: _endDate,
                      concept: _concept,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _filterType = result['type'] ?? 'todos';
                      _minAmount = result['minAmount'];
                      _maxAmount = result['maxAmount'];
                      _categoryId = result['categoryId'];
                      _startDate = result['startDate'];
                      _endDate = result['endDate'];
                      _concept = result['concept'];
                    });
                    _loadTransactions();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () { /* TODO: Lógica de cambio de vista */ },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateAndRefresh(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TU WIDGET DE GRUPO DE TRANSACCIONES (MODIFICADO PARA USAR EL NUEVO MODELO)
  Widget _buildTransactionGroup(String title, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...transactions.map((tx) => TransactionTile(
          transaction: tx,
          onTap: () => _navigateAndRefresh(transaction: tx),
          onDelete: () => _deleteTransaction(tx),
        )).toList(),
      ],
    );
  }

  // TU WIDGET DE PAGINACIÓN (INTACTO)
  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () { /* TODO: Lógica página anterior */ },
            icon: const Icon(Icons.chevron_left),
            label: const Text('Anterior'),
          ),
          Text(
            'Página 1 de 5', // TODO: Hacer dinámico
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton.icon(
            onPressed: () { /* TODO: Lógica página siguiente */ },
            label: const Text('Siguiente'),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
