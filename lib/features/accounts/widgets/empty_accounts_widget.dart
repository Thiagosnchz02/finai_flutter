// lib/features/accounts/widgets/empty_accounts_widget.dart

import 'package:flutter/material.dart';

class EmptyAccountsWidget extends StatelessWidget {
  const EmptyAccountsWidget({
    super.key,
    required this.onAddAccount,
  });

  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;
        final double horizontalPadding = isTablet ? 48 : 24;
        final double verticalPadding = isTablet ? 56 : 32;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 900 : 540,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2D006A), Color(0xFF1F003D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7F00FF).withOpacity(0.35),
                        blurRadius: 36,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 48 : 32),
                    child: Flex(
                      direction: isTablet ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: isTablet
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Illustration(isTablet: isTablet),
                        SizedBox(width: isTablet ? 48 : 0, height: isTablet ? 0 : 32),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: isTablet
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
                            children: [
                              Text(
                                '¡Bienvenido a FinAi!',
                                textAlign:
                                    isTablet ? TextAlign.start : TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aún no has creado ninguna cuenta. Pulsa el botón para empezar a organizar tus finanzas y llevar el control de tus gastos.',
                                textAlign: isTablet
                                    ? TextAlign.start
                                    : TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                      fontFamily: 'Inter',
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 32),
                              Align(
                                alignment: isTablet
                                    ? Alignment.centerLeft
                                    : Alignment.center,
                                child: SizedBox(
                                  width: isTablet ? 260 : double.infinity,
                                  child: ElevatedButton(
                                    onPressed: onAddAccount,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      backgroundColor: const Color(0xFFFF4FC2),
                                      shadowColor:
                                          const Color(0xFFFF4FC2).withOpacity(0.4),
                                      elevation: 12,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    child: const Text('Crear mi primera cuenta'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({
    required this.isTablet,
  });

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final double size = isTablet ? 220 : 180;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4FC2), Color(0xFF7C1CFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF45008B).withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.16,
              right: size * 0.18,
              child: _Bubble(
                diameter: size * 0.26,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: size * 0.14,
              left: size * 0.12,
              child: _Bubble(
                diameter: size * 0.22,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            Icon(
              Icons.wallet_rounded,
              size: isTablet ? 96 : 78,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}