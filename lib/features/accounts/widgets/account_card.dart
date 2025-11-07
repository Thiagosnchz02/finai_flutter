// lib/features/accounts/widgets/account_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/account_model.dart';
import '../models/accounts_preferences.dart';
import 'account_button_styles.dart';
import 'sparkline_chart.dart';
import 'swipe_action_button.dart';

class AccountCard extends StatefulWidget {
  final Account account;
  final bool? showAddMoneyButton;
  final bool? showManageSavingsButton;
  final VoidCallback? onAddMoney;
  final VoidCallback? onManageSavings;
  final VoidCallback? onInternalTransfer;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final AccountsViewMode viewMode;
  final bool enableAdvancedAnimations;
  final bool showSparkline;

  const AccountCard({
    super.key,
    required this.account,
    this.showAddMoneyButton,
    this.showManageSavingsButton,
    this.onAddMoney,
    this.onManageSavings,
    this.onInternalTransfer,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.viewMode = AccountsViewMode.compact,
    this.enableAdvancedAnimations = true,
    this.showSparkline = false,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _swipeController;
  late Animation<double> _iconRotation;
  late Animation<double> _elevation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _swipeOffset;

  bool _isSwipeRevealed = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.enableAdvancedAnimations ? 300 : 200;
    final curve = widget.enableAdvancedAnimations
        ? Curves.easeOutBack
        : Curves.easeOut;

    _expandController = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    // Controlador para el swipe horizontal
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _expandController, curve: curve));

    _elevation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _expandController, curve: curve));

    // Animación de deslizamiento desde la izquierda
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0), // Desde la izquierda
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _expandController, curve: curve));

    // Animación del offset horizontal para el swipe
    // 2 botones (80px cada uno) + 1 espacio (8px) + padding (16px) = 184px
    _swipeOffset = Tween<double>(
      begin: 0,
      end: -184,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AccountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }

    // Actualizar duración y curva si cambian las preferencias
    if (widget.enableAdvancedAnimations != oldWidget.enableAdvancedAnimations) {
      final duration = widget.enableAdvancedAnimations ? 300 : 200;
      final curve = widget.enableAdvancedAnimations
          ? Curves.easeOutBack
          : Curves.easeOut;

      _expandController.duration = Duration(milliseconds: duration);

      _iconRotation = Tween<double>(
        begin: 0,
        end: 0.5,
      ).animate(CurvedAnimation(parent: _expandController, curve: curve));
      _elevation = Tween<double>(
        begin: 0,
        end: 8,
      ).animate(CurvedAnimation(parent: _expandController, curve: curve));
      _slideAnimation = Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _expandController, curve: curve));
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedBalance = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
    ).format(widget.account.balance);
    final isSavingsAccount =
        widget.account.conceptualType.toLowerCase() == 'ahorro';
    final shouldShowAddMoneyButton =
        widget.showAddMoneyButton ?? !isSavingsAccount;
    final shouldShowManageSavingsButton =
        widget.showManageSavingsButton ?? isSavingsAccount;

    final infoTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.86),
      fontWeight: FontWeight.w500,
    );

    final titleTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final balanceTextStyle = theme.textTheme.headlineSmall?.copyWith(
      color: widget.account.balance < 0
          ? const Color(0xFFFFD166)
          : const Color(0xFFADF6FF),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );

    return AnimatedBuilder(
      animation: _elevation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent, width: 1.2),
            boxShadow: widget.enableAdvancedAnimations
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF4a0873,
                      ).withOpacity(0.2 + (_elevation.value / 80)),
                      blurRadius: 12 + _elevation.value,
                      offset: Offset(0, 2 + (_elevation.value / 4)),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Botones de swipe posicionados a la derecha
            if (!widget.isExpanded)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _swipeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _swipeController.value,
                      child: child,
                    );
                  },
                  child: SwipeActionsOverlay(
                    isSavingsAccount: isSavingsAccount,
                    onAddMoney: () {
                      _swipeController.reverse();
                      setState(() => _isSwipeRevealed = false);
                      widget.onAddMoney?.call();
                    },
                    onTransfer: () {
                      _swipeController.reverse();
                      setState(() => _isSwipeRevealed = false);
                      widget.onInternalTransfer?.call();
                    },
                    onManageSavings: () {
                      _swipeController.reverse();
                      setState(() => _isSwipeRevealed = false);
                      widget.onManageSavings?.call();
                    },
                  ),
                ),
              ),

            // Contenido principal de la tarjeta
            GestureDetector(
              onHorizontalDragUpdate: !widget.isExpanded
                  ? (details) {
                      // Solo permitir swipe cuando la carta está colapsada
                      final delta = details.primaryDelta ?? 0;
                      final newValue =
                          _swipeController.value -
                          (delta / 184); // 184 es el ancho total de 2 botones
                      _swipeController.value = newValue.clamp(0.0, 1.0);
                    }
                  : null,
              onHorizontalDragEnd: !widget.isExpanded
                  ? (details) {
                      // Determinar si revelar u ocultar basado en la velocidad o posición
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -500 || _swipeController.value > 0.4) {
                        // Revelar completamente
                        _swipeController.forward();
                        setState(() => _isSwipeRevealed = true);
                      } else {
                        // Ocultar completamente
                        _swipeController.reverse();
                        setState(() => _isSwipeRevealed = false);
                      }
                    }
                  : null,
              onTap: () {
                // Si el swipe está revelado, ocultarlo al tocar
                if (_isSwipeRevealed) {
                  _swipeController.reverse();
                  setState(() => _isSwipeRevealed = false);
                } else {
                  widget.onToggleExpanded?.call();
                }
              },
              child: AnimatedBuilder(
                animation: _swipeOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_swipeOffset.value, 0),
                    child: child,
                  );
                },
                child: InkWell(
                  onTap: null, // El tap lo maneja el GestureDetector
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A), // Fondo negro opaco
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con nombre + chevron
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.account.name,
                                  style: titleTextStyle,
                                ),
                              ),
                              RotationTransition(
                                turns: _iconRotation,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: const Color(0xFF4a0873),
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Contenido según ViewMode
                          if (widget.viewMode == AccountsViewMode.context)
                            // MODO CONTEXTO: Siempre visible
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AccountInfoRow(
                                  label: 'Banco',
                                  value:
                                      (widget.account.bankName?.isNotEmpty ??
                                          false)
                                      ? widget.account.bankName!
                                      : 'Sin banco asociado',
                                  valueStyle: infoTextStyle,
                                ),
                                const SizedBox(height: 10),
                                _AccountInfoRow(
                                  label: 'Tipo de cuenta',
                                  value: _prettyConceptualType(
                                    widget.account.conceptualType,
                                    widget.account.type,
                                  ),
                                  valueStyle: infoTextStyle,
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                  color: Color(0x33FFFFFF),
                                  thickness: 1,
                                  height: 1,
                                ),
                                const SizedBox(height: 12),
                                _AccountInfoRow(
                                  label: 'Saldo',
                                  value: formattedBalance,
                                  valueStyle: balanceTextStyle,
                                ),
                                // Sparkline si está habilitado
                                if (widget.showSparkline)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SparklineChart(
                                      data: _generateMockSparklineData(),
                                      lineColor: const Color(0xFF4a0873),
                                      fillColor: const Color(
                                        0xFF4a0873,
                                      ).withOpacity(0.1),
                                      height: 60,
                                      width: 120,
                                    ),
                                  ),
                                if (widget.isExpanded &&
                                    (shouldShowAddMoneyButton ||
                                        shouldShowManageSavingsButton))
                                  const SizedBox(height: 18),
                                if (widget.isExpanded &&
                                    (shouldShowAddMoneyButton ||
                                        shouldShowManageSavingsButton))
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      if (shouldShowAddMoneyButton)
                                        _AccountActionButton(
                                          label: 'Añadir dinero',
                                          onPressed: widget.onAddMoney,
                                          style: AccountButtonStyles.maroon,
                                        ),
                                      if (shouldShowManageSavingsButton)
                                        _AccountActionButton(
                                          label: 'Gestionar mis huchas',
                                          onPressed: widget.onManageSavings,
                                          style: AccountButtonStyles.pink,
                                        ),
                                    ],
                                  ),
                              ],
                            )
                          else
                            // MODO COMPACTO: Expandible con acordeón
                            ClipRect(
                              child: SizeTransition(
                                sizeFactor: CurvedAnimation(
                                  parent: _expandController,
                                  curve: widget.enableAdvancedAnimations
                                      ? Curves.easeOutBack
                                      : Curves.easeOut,
                                ),
                                axisAlignment: -1.0, // Animar desde arriba
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _AccountInfoRow(
                                        label: 'Banco',
                                        value:
                                            (widget
                                                    .account
                                                    .bankName
                                                    ?.isNotEmpty ??
                                                false)
                                            ? widget.account.bankName!
                                            : 'Sin banco asociado',
                                        valueStyle: infoTextStyle,
                                      ),
                                      const SizedBox(height: 10),
                                      _AccountInfoRow(
                                        label: 'Tipo de cuenta',
                                        value: _prettyConceptualType(
                                          widget.account.conceptualType,
                                          widget.account.type,
                                        ),
                                        valueStyle: infoTextStyle,
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(
                                        color: Color(0x33FFFFFF),
                                        thickness: 1,
                                        height: 1,
                                      ),
                                      const SizedBox(height: 12),
                                      _AccountInfoRow(
                                        label: 'Saldo',
                                        value: formattedBalance,
                                        valueStyle: balanceTextStyle,
                                      ),
                                      // Sparkline si está habilitado
                                      if (widget.showSparkline)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: SparklineChart(
                                            data: _generateMockSparklineData(),
                                            lineColor: const Color(0xFF4a0873),
                                            fillColor: const Color(
                                              0xFF4a0873,
                                            ).withOpacity(0.1),
                                            height: 60,
                                            width: 120,
                                          ),
                                        ),
                                      if (shouldShowAddMoneyButton ||
                                          shouldShowManageSavingsButton)
                                        const SizedBox(height: 18),
                                      if (shouldShowAddMoneyButton ||
                                          shouldShowManageSavingsButton)
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            if (shouldShowAddMoneyButton)
                                              _AccountActionButton(
                                                label: 'Añadir dinero',
                                                onPressed: widget.onAddMoney,
                                                style:
                                                    AccountButtonStyles.maroon,
                                              ),
                                            if (shouldShowManageSavingsButton)
                                              _AccountActionButton(
                                                label: 'Gestionar mis huchas',
                                                onPressed:
                                                    widget.onManageSavings,
                                                style: AccountButtonStyles.pink,
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ], // Cierra children de Column
                      ), // Cierra Column
                    ), // Cierra Padding
                  ), // Cierra Container
                ), // Cierra InkWell
              ), // Cierra AnimatedBuilder (Transform)
            ), // Cierra GestureDetector
          ], // Cierra children de Stack
        ), // Cierra Stack
      ), // Cierra ClipRRect
    );
  }

  String _prettyConceptualType(String conceptualType, String rawType) {
    final normalizedConcept = conceptualType.toLowerCase();
    switch (normalizedConcept) {
      case 'ahorro':
        return 'Ahorro';
      case 'nomina':
        return 'Gasto / Nómina';
      default:
        return rawType.isEmpty ? conceptualType : _capitalize(rawType);
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Genera datos mock de sparkline basados en el saldo actual
  /// En producción, esto vendría de una consulta de historial de saldos
  List<double> _generateMockSparklineData() {
    final currentBalance = widget.account.balance;
    final random = math.Random(
      widget.account.id.hashCode,
    ); // Seed consistente por cuenta

    final data = <double>[];
    const days = 7;

    // Generar tendencia: si saldo positivo, tendencia alcista; si negativo, bajista
    final trend = currentBalance > 0 ? 1.05 : 0.95;
    double value = currentBalance / trend;

    for (int i = 0; i < days; i++) {
      // Añadir variación aleatoria ±10%
      final variation = 0.9 + (random.nextDouble() * 0.2);
      value = value * variation;
      data.add(value);
    }

    // Último valor siempre es el saldo actual
    data[days - 1] = currentBalance;

    return data;
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
