import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/transaction_model.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<Map<String, List<Transaction>>> _groupedTransactionsFuture;

  @override
  void initState() {
    super.initState();
    // Inicializamos la localización para español para los nombres de los meses
    initializeDateFormatting('es_ES', null);
    _groupedTransactionsFuture = _fetchAndGroupTransactions();
  }

  Future<Map<String, List<Transaction>>> _fetchAndGroupTransactions() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('transactions')
          .select('*, categories(*)') // Hacemos JOIN con la tabla de categorías
          .eq('user_id', userId)
          .order('transaction_date', ascending: false)
          .limit(100); // Límite inicial, la paginación se añadirá después

      final List<Transaction> transactions = response
          .map((item) => Transaction.fromJson(item))
          .toList();
      
      return _groupTransactionsByDate(transactions);

    } catch (e) {
      // Si algo falla, lanzamos una excepción para que el FutureBuilder la capture
      throw Exception('Error al cargar las transacciones: $e');
    }
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final DateFormat formatter = DateFormat('d \'de\' MMMM', 'es_ES');

    for (var tx in transactions) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String groupKey;

      if (txDate.isAtSameMomentAs(today)) {
        groupKey = 'HOY';
      } else if (txDate.isAtSameMomentAs(yesterday)) {
        groupKey = 'AYER';
      } else {
        groupKey = formatter.format(tx.date).toUpperCase();
      }
      
      if (grouped[groupKey] == null) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(tx);
    }
    return grouped;
  }

  // Mapea los nombres de FontAwesome a objetos IconData
  IconData _getIconData(String iconName) {
    // Esta es una lista básica, habría que expandirla o usar un mapa más completo
    switch (iconName) {
      case 'fas fa-utensils':
        return FontAwesomeIcons.utensils;
      case 'fas fa-money-bill-transfer':
        return FontAwesomeIcons.moneyBillTransfer;
      case 'fas fa-shopping-cart':
        return FontAwesomeIcons.cartShopping;
      case 'fas fa-file-invoice-dollar':
         return FontAwesomeIcons.fileInvoiceDollar;
      case 'fas fa-house-user':
         return FontAwesomeIcons.houseUser;
      default:
        return FontAwesomeIcons.circleQuestion; // Icono por defecto
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // NAVEGAMOS A LA NUEVA PANTALLA
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionScreen(),
            ),
          );
          // Si la pantalla devuelve 'true', refrescamos la lista
          if (result == true) {
            setState(() {
              _groupedTransactionsFuture = _fetchAndGroupTransactions();
            });
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<Map<String, List<Transaction>>>(
                  future: _groupedTransactionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay transacciones todavía.'));
                    }

                    final groupedTransactions = snapshot.data!;
                    final dateKeys = groupedTransactions.keys.toList();

                    return ListView.builder(
                      itemCount: dateKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = dateKeys[index];
                        final transactionsInGroup = groupedTransactions[dateKey]!;
                        return _buildTransactionGroup(dateKey, transactionsInGroup);
                      },
                    );
                  },
                ),
              ),
              _buildPaginationControls(),
            ],
          ),
        ),
      ),
    );
  }

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
                onPressed: () {
                  // TODO: Lógica de filtros
                },
              ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  // TODO: Lógica de cambio de vista
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        ...transactions.map((tx) => _TransactionListItem(transaction: tx, iconData: _getIconData(tx.categoryIcon))).toList(),
      ],
    );
  }

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

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final IconData iconData;

  const _TransactionListItem({required this.transaction, required this.iconData});

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'ingreso';
    final amountColor = isIncome ? Colors.green.shade400 : Theme.of(context).colorScheme.onSurface;
    final amountString = '${isIncome ? '+' : '-'}${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(transaction.amount)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.categoryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: transaction.categoryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(transaction.categoryName),
                    labelStyle: TextStyle(fontSize: 11, color: transaction.categoryColor.withOpacity(0.9)),
                    backgroundColor: transaction.categoryColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountString,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}