// lib/features/investments/screens/investments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/investments/models/investment_model.dart';
import 'package:finai_flutter/features/investments/services/investments_service.dart';
import 'package:finai_flutter/features/investments/widgets/investment_card.dart';
import 'add_edit_investment_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final _service = InvestmentsService();
  late Future<List<Investment>> _investmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _investmentsFuture = _service.getInvestments();
    });
  }

  void _navigateAndRefresh({Investment? investment}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddEditInvestmentScreen(investment: investment)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _confirmDelete(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Seguro que quieres eliminar la inversión "${investment.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteInvestment(investment.id, investment.type);
        _loadData();
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Inversiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateAndRefresh(),
          ),
        ],
      ),
      body: FutureBuilder<List<Investment>>(
        future: _investmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final investments = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: investments.isEmpty
                    ? const Center(child: Text('Añade tu primera inversión para empezar.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: investments.length,
                        itemBuilder: (context, index) {
                          final investment = investments[index];
                          return InvestmentCard(
                            investment: investment,
                            onEdit: () => _navigateAndRefresh(investment: investment),
                            onDelete: () => _confirmDelete(investment),
                          );
                        },
                      ),
              ),
              _buildSummaryFooter(investments),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryFooter(List<Investment> investments) {
    final totalValue = investments.fold<double>(0, (sum, item) => sum + item.currentValue);
    final totalProfitLoss = investments.fold<double>(0, (sum, item) => sum + item.profitLoss);
    final profitLossColor = totalProfitLoss >= 0 ? Colors.greenAccent : Colors.redAccent;
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.white24, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valor Total Portfolio:', style: Theme.of(context).textTheme.bodySmall),
              Text(formatter.format(totalValue), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Gan./Pérd. Total:', style: Theme.of(context).textTheme.bodySmall),
              Text(formatter.format(totalProfitLoss), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: profitLossColor)),
            ],
          ),
        ],
      ),
    );
  }
}