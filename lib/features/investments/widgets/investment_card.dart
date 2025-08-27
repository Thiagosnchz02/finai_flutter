// lib/features/investments/widgets/investment_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/presentation/widgets/glass_card.dart';
import '../models/investment_model.dart';

class InvestmentCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InvestmentCard({
    super.key,
    required this.investment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final profitLoss = investment.profitLoss;
    final profitLossColor = profitLoss > 0 ? Colors.greenAccent : (profitLoss < 0 ? Colors.redAccent : Colors.grey);
    final profitLossSign = profitLoss > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(investment.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                        if (investment.symbol != null && investment.symbol!.isNotEmpty)
                          Text(investment.symbol!, style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(investment.type),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  )
                ],
              ),
              const Divider(height: 24, color: Colors.white24),
              _buildInfoRow('Cantidad:', investment.quantity.toString()),
              _buildInfoRow('P. Compra:', formatter.format(investment.purchasePrice)),
              _buildInfoRow('V. Compra Total:', formatter.format(investment.purchaseTotalValue)),
              _buildInfoRow('V. Actual Total:', formatter.format(investment.currentValue), isImportant: true),
              const SizedBox(height: 12),
              // Indicador de Ganancia/Pérdida
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gan./Pérd.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Text(
                    '$profitLossSign${formatter.format(profitLoss)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: profitLossColor,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: profitLossColor.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Editar'),
                  IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, color: Colors.red.shade300), tooltip: 'Eliminar'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}