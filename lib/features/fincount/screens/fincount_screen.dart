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
      backgroundColor: const Color(0xFF0B1120),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF15243B),
              Color(0xFF070D18),
            ],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _plansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Crea tu primer plan de gastos compartidos.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final plans = snapshot.data!;

            return RefreshIndicator(
              color: const Color(0xFF39FF14),
              backgroundColor: const Color(0xFF0B1120),
              onRefresh: _refreshPlans,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final double balance = (plan['user_balance'] as num? ?? 0.0).toDouble();
                  final Color balanceColor = _getBalanceColor(balance);
                  final String balanceText = _currencyFormatter.format(balance);
                  final String planId = plan['id'].toString();
                  final String planName = plan['name'].toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PlanDetailsScreen(
                              planId: planId,
                              planName: planName,
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
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
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
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _getIconForPlan(planName),
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
                                        planName,
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
                                          color: Colors.white.withOpacity(0.72),
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
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 14,
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
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndReload,
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshPlans() async {
    _loadPlans();
    await _plansFuture;
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
