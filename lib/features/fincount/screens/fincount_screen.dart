// lib/features/fincount/screens/fincount_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/fincount/services/fincount_service.dart';
import 'add_plan_screen.dart';
import 'plan_details_screen.dart';

class FincountScreen extends StatefulWidget {
  const FincountScreen({super.key});

  @override
  State<FincountScreen> createState() => _FincountScreenState();
}

class _FincountScreenState extends State<FincountScreen> {
  final FincountService _service = FincountService();
  late Future<List<Map<String, dynamic>>> _plansFuture;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() {
    setState(() {
      _plansFuture = _service.getSplitPlans();
    });
  }

  Future<void> _navigateAndReload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddPlanScreen()),
    );
    if (result == true && mounted) {
      _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1E22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Fincount',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Crea tu primer plan de gastos compartidos.', style: TextStyle(color: Colors.white70)));
          }

          final plans = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final double balance = (plan['user_balance'] as num? ?? 0.0).toDouble();
              final Color balanceColor = _getBalanceColor(balance);
              final String balanceText = _currencyFormatter.format(balance);
              // --- INICIO DE LA CORRECCIÓN ---
              // Extraer id y name del mapa 'plan'
              final String planId = plan['id'] as String;
              final String planName = plan['name'] as String;
              // --- FIN DE LA CORRECCIÓN ---

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlanDetailsScreen(
                          planId: planId, // Ahora planId está definida
                          planName: planName, // Ahora planName está definida
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getIconForPlan(planName), // Usar planName aquí
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    planName, // Usar planName aquí
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${plan['participants_count']} participantes',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  balanceText,
                                  style: TextStyle(
                                    color: balanceColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getBalanceLabel(balance),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndReload,
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
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

  IconData _getIconForPlan(String name) {
    if (name.toLowerCase().contains('viaje') || name.toLowerCase().contains('playa')) {
      return Icons.beach_access;
    }
    if (name.toLowerCase().contains('cena')) {
      return Icons.restaurant;
    }
    if (name.toLowerCase().contains('regalo')) {
      return Icons.card_giftcard;
    }
    return Icons.group;
  }
}
