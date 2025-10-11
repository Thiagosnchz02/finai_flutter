import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final List<Map<String, dynamic>> mockPlans = [
  {
    'id': 'plan_01',
    'name': 'Viaje a la playa',
    'participants': 4,
    'balance': -125.75,
    'icon': Icons.beach_access,
  },
  {
    'id': 'plan_02',
    'name': 'Cena mensual',
    'participants': 6,
    'balance': 48.2,
    'icon': Icons.restaurant,
  },
  {
    'id': 'plan_03',
    'name': 'Regalo sorpresa',
    'participants': 3,
    'balance': 0.0,
    'icon': Icons.card_giftcard,
  },
];

class FincountScreen extends StatefulWidget {
  const FincountScreen({super.key});

  @override
  State<FincountScreen> createState() => _FincountScreenState();
}

class _FincountScreenState extends State<FincountScreen> {
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockPlans.length,
        itemBuilder: (context, index) {
          final plan = mockPlans[index];
          final double balance = plan['balance'] as double;
          final Color balanceColor = _getBalanceColor(balance);
          final String balanceText = _currencyFormatter.format(balance);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                          plan['icon'] as IconData,
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
                              plan['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${plan['participants']} participantes',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nuevo plan')),
          );
        },
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getBalanceColor(double balance) {
    if (balance < 0) {
      return const Color(0xFFFF6F61);
    }
    if (balance > 0) {
      return const Color(0xFF39FF14);
    }
    return Colors.grey.shade400;
  }

  String _getBalanceLabel(double balance) {
    if (balance < 0) {
      return 'Deuda';
    }
    if (balance > 0) {
      return 'A favor';
    }
    return 'Saldo cero';
  }
}
