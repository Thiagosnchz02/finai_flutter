import 'dart:ui';

import 'package:finai_flutter/presentation/widgets/glass_card.dart';
import 'package:flutter/material.dart';

/// Pantalla principal de herramientas de FinAi.
///
/// Muestra un sistema de pestañas que alojará las diferentes utilidades
/// financieras de la app. Por ahora, solo la calculadora de gastos está
/// implementada; el divisor de cuentas queda preparado como placeholder.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // --- Paleta FinAi Glass-Neon ---
  static const Color _backgroundColor = Color(0xFF1C1E22);
  static const Color _neonBlue = Color(0xFF00C6FF);
  static const Color _neonPurple = Color(0xFF845EF7);
  static const Color _neonCoral = Color(0xFFFF6B6B);
  static const Color _glassStroke = Color(0x33FFFFFF);

  // --- Estado de la calculadora ---
  String _currentInput = '0';
  double? _previousValue;
  String? _selectedOperation;
  bool _shouldResetCurrent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF15161A),
                _backgroundColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Text(
                  'Herramientas',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildTabBar(context),
              ),
              const SizedBox(height: 12.0),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalculatorTab(context),
                    _buildSplitBillPlaceholder(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la pestaña de la calculadora de gastos con un estilo glassmorphism.
  Widget _buildCalculatorTab(BuildContext context) {
    final previousDisplay = _previousValue != null && _selectedOperation != null
        ? '${_formatNumber(_previousValue!)} ${_selectedOperation!}'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCalculatorDisplay(previousDisplay),
                const SizedBox(height: 32.0),
                _buildCalculatorButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la pantalla de resultados de la calculadora.
  Widget _buildCalculatorDisplay(String previousDisplay) {
    final bool hasError = _currentInput == 'Error';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: _glassStroke),
        boxShadow: [
          BoxShadow(
            color: _neonBlue.withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: previousDisplay.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: Text(
              previousDisplay,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          _buildDisplayText(hasError),
        ],
      ),
    );
  }

  Widget _buildDisplayText(bool hasError) {
    final textWidget = Text(
      _currentInput,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: hasError ? _neonCoral : Colors.white,
        fontSize: hasError ? 36 : 42,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontFamily: 'Inter',
        shadows: [
          Shadow(
            color: hasError
                ? _neonCoral.withOpacity(0.6)
                : _neonBlue.withOpacity(0.6),
            blurRadius: 16,
          ),
        ],
      ),
    );

    if (hasError) {
      return textWidget;
    }

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [_neonBlue, _neonPurple],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: textWidget,
    );
  }

  /// Construye la rejilla de botones de la calculadora (4 columnas).
  Widget _buildCalculatorButtons() {
    const buttons = <String>[
      'AC',
      'DEL',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '-',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '',
      '00',
      '0',
      '.',
      '=',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final label = buttons[index];
        if (label.isEmpty) {
          return const SizedBox.shrink();
        }

        final isOperation = _isOperationButton(label);
        final isPrimaryAction = label == '=';

        return _CalculatorButton(
          label: label,
          onTap: () => _onButtonPressed(label),
          background: isOperation
              ? _neonCoral.withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          borderColor: isOperation ? _neonCoral.withOpacity(0.6) : _glassStroke,
          labelColor: isOperation
              ? Colors.white
              : Colors.white.withOpacity(isPrimaryAction ? 0.95 : 0.85),
          glowColor: isOperation ? _neonCoral : _neonBlue,
        );
      },
    );
  }

  /// Placeholder para la herramienta de división de cuentas.
  Widget _buildSplitBillPlaceholder(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _glassStroke),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Próximamente',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Escanea y divide tus facturas con OCR para simplificar tus gastos compartidos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TabBar estilizada con efecto glass.
  Widget _buildTabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: _glassStroke),
        color: Colors.white.withOpacity(0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
        unselectedLabelColor: Colors.white60,
        labelColor: Colors.white,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: const LinearGradient(
            colors: [_neonBlue, _neonPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: _neonBlue.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'Calculadora'),
          Tab(text: 'Divisor de Cuentas'),
        ],
      ),
    );
  }

  bool _isOperationButton(String label) {
    const operations = {'+', '-', '×', '÷', '='};
    return operations.contains(label);
  }

  void _onButtonPressed(String label) {
    if (_currentInput == 'Error' && label != 'AC') {
      return;
    }

    switch (label) {
      case 'AC':
        _resetCalculator();
        break;
      case 'DEL':
        _deleteLastDigit();
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        _selectOperation(label);
        break;
      case '=':
        _calculateResult();
        break;
      case '.':
        _addDecimalPoint();
        break;
      case '00':
        _appendDigit('00');
        break;
      default:
        _appendDigit(label);
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_shouldResetCurrent || _currentInput == '0') {
        _currentInput = digit == '00' ? '0' : digit;
        _shouldResetCurrent = false;
      } else {
        _currentInput += digit;
      }
    });
  }

  void _addDecimalPoint() {
    setState(() {
      if (_shouldResetCurrent) {
        _currentInput = '0.';
        _shouldResetCurrent = false;
      } else if (!_currentInput.contains('.')) {
        _currentInput += '.';
      }
    });
  }

  void _selectOperation(String operation) {
    setState(() {
      final currentValue = double.tryParse(_currentInput);
      if (currentValue == null) {
        _triggerError();
        return;
      }

      if (_previousValue != null && _selectedOperation != null &&
          !_shouldResetCurrent) {
        final result = _performOperation(_previousValue!, currentValue);
        if (result == null) {
          _triggerError();
          return;
        }
        _previousValue = result;
        _currentInput = _formatNumber(result);
      } else {
        _previousValue = currentValue;
      }

      _selectedOperation = operation;
      _shouldResetCurrent = true;
    });
  }

  void _calculateResult() {
    if (_selectedOperation == null || _previousValue == null) {
      return;
    }

    setState(() {
      final currentValue = double.tryParse(_currentInput);
      if (currentValue == null) {
        _triggerError();
        return;
      }

      final result = _performOperation(_previousValue!, currentValue);
      if (result == null) {
        _triggerError();
        return;
      }

      _currentInput = _formatNumber(result);
      _previousValue = null;
      _selectedOperation = null;
      _shouldResetCurrent = true;
    });
  }

  void _deleteLastDigit() {
    setState(() {
      if (_shouldResetCurrent || _currentInput.length <= 1) {
        _currentInput = '0';
        _shouldResetCurrent = false;
      } else {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    });
  }

  void _resetCalculator() {
    setState(() {
      _currentInput = '0';
      _previousValue = null;
      _selectedOperation = null;
      _shouldResetCurrent = false;
    });
  }

  double? _performOperation(double first, double second) {
    switch (_selectedOperation) {
      case '+':
        return first + second;
      case '-':
        return first - second;
      case '×':
        return first * second;
      case '÷':
        if (second == 0) {
          return null;
        }
        return first / second;
      default:
        return second;
    }
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }
    final formatted = value.toStringAsFixed(6);
    final cleaned = formatted
        .replaceFirst(RegExp('\\.0+\$'), '')
        .replaceFirst(RegExp('(\\.\\d*?[1-9])0+\$'), r'$1');
    return cleaned.isEmpty ? '0' : cleaned;
  }

  void _triggerError() {
    setState(() {
      _currentInput = 'Error';
      _previousValue = null;
      _selectedOperation = null;
      _shouldResetCurrent = true;
    });
  }
}

/// Botón personalizado para la calculadora con estética glass-neon.
class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.borderColor,
    required this.labelColor,
    required this.glowColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color borderColor;
  final Color labelColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: borderColor, width: 1.4),
            color: background,
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: label.length >= 2 ? 20 : 24,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}