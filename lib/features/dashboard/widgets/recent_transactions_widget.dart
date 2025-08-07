// lib/features/dashboard/widgets/recent_transactions_widget.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/transactions/models/transaction_model.dart';
import 'package:finai_flutter/features/transactions/screens/add_edit_transaction_screen.dart';
import 'package:finai_flutter/features/transactions/services/transactions_service.dart';
import 'package:finai_flutter/features/transactions/widgets/transaction_tile.dart';

class RecentTransactionsDashboardWidget extends StatefulWidget {
  const RecentTransactionsDashboardWidget({super.key});

  @override
  State<RecentTransactionsDashboardWidget> createState() => _RecentTransactionsDashboardWidgetState();
}

class _RecentTransactionsDashboardWidgetState extends State<RecentTransactionsDashboardWidget> {
  final _service = TransactionsService();
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    _transactionsFuture = _service.fetchRecentTransactions()
        .then((maps) => maps.map((map) => Transaction.fromMap(map)).toList());
  }

  void _navigateToEdit(Transaction tx) {
     Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(transaction: tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del Widget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Últimos Movimientos', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    // Navega a la pantalla de transacciones usando su ruta con nombre
                    Navigator.of(context).pushNamed('/transactions');
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Cuerpo del Widget
            FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar transacciones.');
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Text('Aún no hay movimientos.');
                }
                
                return ListView.builder(
                  shrinkWrap: true, // Importante para que el ListView no ocupe espacio infinito
                  physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll dentro de la tarjeta
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return TransactionTile( // Reutilizamos el widget que ya teníamos
                      transaction: tx,
                      onTap: () => _navigateToEdit(tx),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}