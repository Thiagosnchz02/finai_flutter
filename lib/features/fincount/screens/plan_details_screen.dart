// lib/features/fincount/screens/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fincount/models/plan_participant_model.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';
import 'add_participant_screen.dart';
import 'add_expense_screen.dart'; // <-- IMPORTACIÓN AÑADIDA

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
  
  // --- VARIABLE AÑADIDA ---
  List<PlanParticipant> _participants = []; // Para pasarla al formulario de gasto

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

  Future<void> _navigateAndReloadParticipants() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddParticipantScreen(planId: widget.planId),
      ),
    );
    if (result == true && mounted) {
      _loadDetails();
    }
  }

  // --- INICIO DEL NUEVO MÉTODO ---
  /// Navega a la pantalla de añadir gasto y recarga si es necesario
  Future<void> _navigateAndAddExpense() async {
    // Comprobar si hay participantes antes de añadir un gasto
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes añadir participantes al plan antes de crear un gasto.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          planId: widget.planId,
          participants: _participants, // Pasamos la lista de participantes
        ),
      ),
    );
    
    // Si se añadió un gasto, recargamos los detalles (saldos)
    if (result == true && mounted) {
      _loadDetails();
    }
  }
  // --- FIN DEL NUEVO MÉTODO ---

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
            onPressed: _navigateAndReloadParticipants,
            tooltip: 'Añadir Participante',
          ),
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
      // --- INICIO DE LA MODIFICACIÓN ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddExpense, // Se conecta el nuevo método
        icon: const Icon(Icons.add),
        label: const Text('Añadir Gasto'),
      ),
      // --- FIN DE LA MODIFICACIÓN ---
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
          // --- INICIO DE LA MODIFICACIÓN ---
          // Limpiamos la lista de participantes si está vacía
          _participants = [];
          // --- FIN DE LA MODIFICACIÓN ---
          return const Center(
              child: Text('Aún no hay participantes en este plan.'));
        }

        final participants = snapshot.data!;
        // --- INICIO DE LA MODIFICACIÓN ---
        // Guardamos la lista de participantes para usarla en el FAB
        _participants = participants;
        // --- FIN DE LA MODIFICACIÓN ---
        
        return ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            // ... (ListTile sin cambios)
            final participant = participants[index];
            final balance = participant.balance;
            final Color balanceColor = _getBalanceColor(balance);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
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
    if (balance < 0) return 'Debes';
    if (balance > 0) return 'Te deben';
    return 'En paz';
  }
}