// lib/features/accounts/widgets/empty_accounts_widget.dart

import 'package:flutter/material.dart';

class EmptyAccountsWidget extends StatelessWidget {
  const EmptyAccountsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí podrías añadir la imagen de la mascota
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '¡Bienvenido a FinAi!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no has creado ninguna cuenta. Pulsa el botón "+" para empezar a organizar tus finanzas.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}