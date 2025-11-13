// lib/features/fincount/screens/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fincount/models/plan_participant_model.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';
import 'package:finai_flutter/features/fincount/models/plan_expense_model.dart';
import 'add_participant_screen.dart';
import 'add_expense_screen.dart';

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
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_ES', symbol: '€');

  late TabController _tabController;
  late Future<List<PlanParticipant>> _detailsFuture;
  late Future<List<PlanExpense>> _expensesFuture; // Future para gastos
  List<PlanParticipant> _participants = []; 

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
      _expensesFuture = _service.getPlanExpenses(widget.planId); // Cargamos gastos
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

  Future<void> _navigateAndAddExpense() async {
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
          participants: _participants,
        ),
      ),
    );
    
    if (result == true && mounted) {
      _loadDetails();
    }
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
            tooltip: 'Recargar',
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
          _buildExpensesTab(), // <-- Pestaña de Gastos REAL
          _buildBalancesTab(), // <-- Pestaña de Saldos REAL
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Añadir Gasto'),
      ),
    );
  }

  // --- PESTAÑA DE GASTOS (Código Nuevo) ---
  Widget _buildExpensesTab() {
    return FutureBuilder<List<PlanExpense>>(
      future: _expensesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Aún no se han añadido gastos.', style: TextStyle(color: Colors.white70)));
        }

        final expenses = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            
            return Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.shopping_cart, color: Colors.white),
                ),
                title: Text(expense.description, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Pagado por: ${_getParticipantName(expense.paidByParticipantId)}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                trailing: Text(
                  _currencyFormatter.format(expense.amount),
                  style: const TextStyle(
                    color: Color(0xFF39FF14), // Verde neón
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- PESTAÑA DE SALDOS (Código Existente) ---
  Widget _buildBalancesTab() {
    return FutureBuilder<List<PlanParticipant>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          _participants = [];
          return const Center(
              child: Text('Aún no hay participantes en este plan.', style: TextStyle(color: Colors.white70)));
        }

        final participants = snapshot.data!;
        _participants = participants;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            final balance = participant.balance;
            final Color balanceColor = _getBalanceColor(balance);

            return Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  child: Text(participant.name.substring(0, 1).toUpperCase()),
                ),
                title: Text(participant.name, style: const TextStyle(color: Colors.white)),
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
              ),
            );
          },
        );
      },
    );
  }

  String _getParticipantName(String participantId) {
    try {
      return _participants.firstWhere((p) => p.id == participantId).name;
    } catch (e) {
      return '...';
    }
  }

  Color _getBalanceColor(double balance) {
    if (balance < -0.01) return const Color(0xFFFF6F61); // Deuda (Rojo)
    if (balance > 0.01) return const Color(0xFF39FF14); // A favor (Verde)
    return Colors.grey.shade400; // En paz
  }

  String _getBalanceLabel(double balance) {
    if (balance < -0.01) return 'Debe';
    if (balance > 0.01) return 'Le deben';
    return 'En paz';
  }
}