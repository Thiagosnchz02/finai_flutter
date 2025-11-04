// lib/features/fincount/screens/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fincount/models/plan_participant_model.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';
import 'add_participant_screen.dart'; // <-- IMPORTACIÓN AÑADIDA

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

class _PlanDetailsScreenState extends State<PlanDetailsScreen>
    with SingleTickerProviderStateMixin {
  final FincountService _service = FincountService();
  late Future<List<PlanParticipant>> _detailsFuture;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_ES', symbol: '€');

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDetails() {
    setState(() {
      _detailsFuture = _service.getPlanDetails(widget.planId);
    });
  }

  // --- INICIO DE LA MODIFICACIÓN ---
  /// Navega a la pantalla de añadir participante y recarga si es necesario
  Future<void> _navigateAndReloadParticipants() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddParticipantScreen(planId: widget.planId),
      ),
    );

    // Si la pantalla devolvió 'true', recargamos los detalles (saldos)
    if (result == true && mounted) {
      _loadDetails();
    }
  }
  // --- FIN DE LA MODIFICACIÓN ---

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
          // --- INICIO DE LA MODIFICACIÓN ---
          // Se cambia el botón de editar por "Añadir Participante"
          IconButton(
            icon: const Icon(Icons.person_add_alt_1), // Icono cambiado
            onPressed: _navigateAndReloadParticipants, // Lógica añadida
            tooltip: 'Añadir Participante', // Tooltip cambiado
          ),
          // --- FIN DE LA MODIFICACIÓN ---
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Gastos'),
            Tab(icon: Icon(Icons.account_balance), text: 'Saldos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildBalancesTab(),
        ],
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

  Widget _buildExpensesTab() {
    // ... (sin cambios)
    return const Center(
      child: Text(
        'Aquí se mostrará la lista de gastos.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildBalancesTab() {
    // ... (sin cambios)
    return FutureBuilder<List<PlanParticipant>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar los saldos: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Aún no hay participantes en este plan.'));
        }

        final participants = snapshot.data!;
        // ... (resto del ListView sin cambios)
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
              subtitle: Text(_getBalanceLabel(balance),
                  style: TextStyle(color: balanceColor)),
            );
          },
        );
      },
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