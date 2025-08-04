// lib/features/accounts/widgets/account_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../presentation/widgets/glass_card.dart'; // Asumiendo la ruta
import '../models/account_model.dart';

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final balanceColor = account.balance < 0 ? Colors.redAccent : Colors.greenAccent;
    final formattedBalance = NumberFormat.currency(locale: 'es_ES', symbol: '€').format(account.balance);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (account.bankName != null && account.bankName!.isNotEmpty)
                      Text(account.bankName!, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
              Text(
                formattedBalance,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: balanceColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}