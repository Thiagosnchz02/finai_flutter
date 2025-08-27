// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importaciones de las pantallas y widgets necesarios
import 'package:finai_flutter/features/accounts/screens/accounts_screen.dart';
import 'package:finai_flutter/features/dashboard/widgets/accounts_widget.dart';
import 'package:finai_flutter/features/profile/screens/profile_screen.dart';
import 'package:finai_flutter/features/transactions/screens/transactions_screen.dart';
import 'package:finai_flutter/features/dashboard/widgets/recent_transactions_widget.dart';
import 'package:finai_flutter/features/fixed_expenses/screens/fixed_expenses_screen.dart'; 
import 'package:finai_flutter/features/dashboard/widgets/upcoming_fixed_expenses_widget.dart';
import 'package:finai_flutter/features/goals/screens/goals_screen.dart';
import 'package:finai_flutter/features/dashboard/widgets/goals_dashboard_widget.dart';
import 'package:finai_flutter/features/budgets/screens/budget_screen.dart';
import 'package:finai_flutter/features/dashboard/widgets/budgets_dashboard_widget.dart';
import 'package:finai_flutter/features/investments/screens/investments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Lista de las pantallas principales que se mostrarán
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardView(),
    TransactionsScreen(),
    AccountsScreen(),
    FixedExpensesScreen(),
    BudgetScreen(),
    GoalsScreen(),
    InvestmentsScreen(),
    ProfileScreen(), // Ahora usa la pantalla de Perfil real
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), // Icono para transacciones
            label: 'Transacciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule), // <-- AÑADIR NUEVO ÍTEM
            label: 'Fijos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart), 
            label: 'Presupuesto'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Metas'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
             label: 'Inversiones'
             ),  
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (user?.userMetadata?['full_name'] != null)
            Text(
              'Bienvenido, ${user!.userMetadata!['full_name']}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          const SizedBox(height: 24),

          const AccountsDashboardWidget(),

          const SizedBox(height: 24),

          const RecentTransactionsDashboardWidget(),

          const SizedBox(height: 24),
          const UpcomingFixedExpensesWidget(),
          const SizedBox(height: 24),

          const GoalsDashboardWidget(),
          const SizedBox(height: 24), // Espaciador
          const BudgetsDashboardWidget(),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Próximos Pagos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text('Funcionalidad en desarrollo...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}