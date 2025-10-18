// lib/features/fincount/screens/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fincount/models/plan_participant_model.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';

class PlanDetailsScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanDetailsScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final FincountService _service = FincountService();
  late Future<List<PlanParticipant>> _detailsFuture;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    setState(() {
      _detailsFuture = _service.getPlanDetails(widget.planId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
            tooltip: 'Recargar Saldos',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              // TODO: Implementar añadir participante
            },
            tooltip: 'Añadir Participante',
          ),
        ],
      ),
      body: FutureBuilder<List<PlanParticipant>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los saldos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aún no hay participantes en este plan.'));
          }

          final participants = snapshot.data!;
          
          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              final balance = participant.balance;
              final Color balanceColor = _getBalanceColor(balance);
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(participant.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(participant.name),
                trailing: Text(
                  _currencyFormatter.format(balance),
                  style: TextStyle(
                    color: balanceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(_getBalanceLabel(balance), style: TextStyle(color: balanceColor)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navegar a la pantalla de añadir gasto
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir Gasto'),
      ),
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) return const Color(0xFFFF6F61); // Rojo coral
    if (balance > 0) return const Color(0xFF39FF14); // Verde neón
    return Colors.grey.shade400;
  }

  String _getBalanceLabel(double balance) {
    if (balance < 0) return 'Debe';
    if (balance > 0) return 'Le deben';
    return 'En paz';
  }
}