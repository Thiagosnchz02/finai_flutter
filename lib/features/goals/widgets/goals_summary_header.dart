// lib/features/goals/widgets/goals_summary_header.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';

class GoalsSummaryHeader extends StatelessWidget {
  final GoalsSummary summary;

  const GoalsSummaryHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromRGBO(11, 11, 15, 0.8),
            Color.fromRGBO(31, 1, 66, 0.6),
          ],
        ),
        border: Border.all(color: const Color(0x828B5CF6)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 25),
            blurRadius: 50,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen Financiero',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSummaryColumn(
                  'Total Ahorrado',
                  formatter.format(summary.totalSavingsBalance),
                  const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryColumn(
                  'Asignado a metas',
                  formatter.format(summary.totalAllocated),
                  const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2971FF),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryColumn(
                  'Capital Disponible',
                  formatter.format(summary.availableToAllocate),
                  const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryColumn(
    String title,
    String formattedAmount,
    TextStyle amountStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD1D5DB),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formattedAmount,
          style: amountStyle,
        ),
      ],
    );
  }
}