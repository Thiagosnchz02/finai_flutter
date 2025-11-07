// lib/features/settings/screens/preferences_screen.dart

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../../accounts/models/accounts_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _preferencesService = PreferencesService();
  late Future<UserPreferences> _preferencesFuture;

  String? _expandedSection; // Control de acordeón

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() {
      _preferencesFuture = _preferencesService.getAllPreferences();
    });
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    final previousPrefs = await _preferencesFuture;

    // Actualizar optimistamente
    setState(() {
      _preferencesFuture = Future.value(_applyChange(previousPrefs, key, value));
    });

    try {
      await _preferencesService.updatePreference(key, value);
      _loadPreferences();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencia actualizada'),
            backgroundColor: Color(0xFF25C9A4),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revertir en caso de error
      setState(() {
        _preferencesFuture = Future.value(previousPrefs);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: const Color(0xFFE5484D),
          ),
        );
      }
    }
  }

  UserPreferences _applyChange(UserPreferences prefs, String key, dynamic value) {
    switch (key) {
      case 'swipe_month_navigation':
        return prefs.copyWith(swipeMonthNavigation: value as bool);
      case 'show_transfers_card':
        return prefs.copyWith(showTransfersCard: value as String);
      case 'accounts_view_mode':
        return prefs.copyWith(accountsViewMode: AccountsViewMode.fromString(value as String));
      case 'accounts_advanced_animations':
        return prefs.copyWith(accountsAdvancedAnimations: value as bool);
      case 'show_account_sparkline':
        return prefs.copyWith(showAccountSparkline: value as bool);
      default:
        return prefs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personalización',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: FutureBuilder<UserPreferences>(
        future: _preferencesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4a0873),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE5484D),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar preferencias',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPreferences,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4a0873),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final prefs = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Descripción
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Personaliza la experiencia de cada pantalla según tus preferencias',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              // SECCIÓN: TRANSACCIONES
              _PreferencesSection(
                title: 'Transacciones',
                icon: Icons.receipt_long,
                isExpanded: _expandedSection == 'transactions',
                onToggle: () {
                  setState(() {
                    _expandedSection = 
                      _expandedSection == 'transactions' ? null : 'transactions';
                  });
                },
                children: [
                  _buildSwitchTile(
                    title: 'Deslizar para cambiar de mes',
                    subtitle: 'Navega entre meses con gestos horizontales',
                    value: prefs.swipeMonthNavigation,
                    onChanged: (value) => _updatePreference('swipe_month_navigation', value),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownTile(
                    title: 'Mostrar tarjeta de traspasos',
                    subtitle: 'Controla cuándo aparece la tarjeta de traspasos',
                    value: prefs.showTransfersCard,
                    items: const [
                      {'value': 'never', 'label': 'Nunca'},
                      {'value': 'auto', 'label': 'Automático'},
                      {'value': 'always', 'label': 'Siempre'},
                    ],
                    onChanged: (value) => _updatePreference('show_transfers_card', value),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // SECCIÓN: CUENTAS
              _PreferencesSection(
                title: 'Cuentas',
                icon: Icons.account_balance_wallet,
                isExpanded: _expandedSection == 'accounts',
                onToggle: () {
                  setState(() {
                    _expandedSection = 
                      _expandedSection == 'accounts' ? null : 'accounts';
                  });
                },
                children: [
                  _buildSegmentedTile(
                    title: 'Modo de vista',
                    subtitle: 'Cantidad de información mostrada',
                    value: prefs.accountsViewMode.toDbValue(),
                    options: const [
                      {'value': 'compact', 'label': 'Compacta'},
                      {'value': 'context', 'label': 'Contexto'},
                    ],
                    onChanged: (value) => _updatePreference('accounts_view_mode', value),
                  ),
                  const Divider(color: Color(0x1FFFFFFF), height: 32),
                  _buildSwitchTile(
                    title: 'Animaciones avanzadas',
                    subtitle: 'Efectos de bounce y elevación en tarjetas',
                    value: prefs.accountsAdvancedAnimations,
                    onChanged: (value) => _updatePreference('accounts_advanced_animations', value),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    title: 'Mostrar gráfico sparkline',
                    subtitle: 'Mini-gráfico de evolución en cada cuenta',
                    value: prefs.showAccountSparkline,
                    onChanged: (value) => _updatePreference('show_account_sparkline', value),
                  ),

                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 0.6,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4a0873),
        activeTrackColor: const Color(0xFF4a0873).withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4a0873).withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF0A0A0A),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4a0873)),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label']!),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTile({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4a0873).withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: options.map((option) {
                final isSelected = value == option['value'];
                final isFirst = options.first == option;
                final isLast = options.last == option;

                return Expanded(
                  child: InkWell(
                    onTap: () => onChanged(option['value']!),
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst ? const Radius.circular(9) : Radius.zero,
                      right: isLast ? const Radius.circular(9) : Radius.zero,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFF4a0873).withOpacity(0.2) 
                          : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isFirst ? const Radius.circular(9) : Radius.zero,
                          right: isLast ? const Radius.circular(9) : Radius.zero,
                        ),
                        border: isSelected
                          ? Border.all(
                              color: const Color(0xFF4a0873),
                              width: 1.2,
                            )
                          : null,
                      ),
                      child: Text(
                        option['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isSelected 
                            ? const Color(0xFF4a0873) 
                            : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de sección desplegable con acordeón
class _PreferencesSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _PreferencesSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  @override
  State<_PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<_PreferencesSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_PreferencesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D0D0D).withOpacity(0.8),
            const Color(0xFF0A0A0A).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4a0873).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF4a0873),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF4a0873),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeOutBack,
            secondCurve: Curves.easeOutBack,
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    color: Color(0x1FFFFFFF),
                    thickness: 0.6,
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  ...widget.children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
