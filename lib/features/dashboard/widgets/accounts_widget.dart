// lib/features/dashboard/widgets/accounts_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../accounts/services/accounts_service.dart';
import '../../accounts/models/account_model.dart';

class AccountsDashboardWidget extends StatefulWidget {
  const AccountsDashboardWidget({super.key});

  @override
  State<AccountsDashboardWidget> createState() => _AccountsDashboardWidgetState();
}

class _AccountsDashboardWidgetState extends State<AccountsDashboardWidget> {
  final AccountsService _service = AccountsService();
  late Future<AccountSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _service.getAccountSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de Cuentas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<AccountSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar saldos.');
                }
                if (!snapshot.hasData) {
                  return const Text('No hay datos de cuentas.');
                }
                
                final summary = snapshot.data!;
                final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      'Total para Gastar',
                      formatter.format(summary.totalSpendingBalance),
                      Colors.blueAccent,
                    ),
                    _buildSummaryItem(
                      context,
                      'Total Ahorrado',
                      formatter.format(summary.totalSavingsBalance),
                      Colors.purpleAccent,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}