import 'dart:math' as math;

import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  static const List<String> _buttons = <String>[
    'C',
    '⌫',
    '%',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '±',
    '0',
    '.',
    '=',
  ];

  String _displayValue = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onButtonPressed(String value) {
    if (value == 'C') {
      _clearAll();
      return;
    }

    if (value == '⌫') {
      _backspace();
      return;
    }

    if (value == '%') {
      _convertToPercentage();
      return;
    }

    if (value == '=') {
      _calculateResult();
      return;
    }

    if (value == '±') {
      _toggleSign();
      return;
    }

    if (_isOperator(value)) {
      _selectOperator(value);
      return;
    }

    if (value == '.') {
      _appendDecimalPoint();
      return;
    }

    _appendDigit(value);
  }

  void _clearAll() {
    setState(() {
      _displayValue = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_shouldResetDisplay) {
        _displayValue = '0';
        _shouldResetDisplay = false;
        return;
      }

      if (_displayValue.length <= 1) {
        _displayValue = '0';
      } else {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      }
    });
  }

  void _convertToPercentage() {
    final double? currentValue = double.tryParse(_displayValue);
    if (currentValue == null) {
      return;
    }

    setState(() {
      final double percentage = currentValue / 100;
      _displayValue = _formatNumber(percentage);
      _shouldResetDisplay = true;
    });
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_displayValue == 'Error') {
        _displayValue = digit;
        _shouldResetDisplay = false;
        return;
      }

      if (_shouldResetDisplay) {
        _displayValue = digit;
        _shouldResetDisplay = false;
      } else if (_displayValue == '0') {
        _displayValue = digit;
      } else {
        _displayValue += digit;
      }
    });
  }

  void _appendDecimalPoint() {
    setState(() {
      if (_displayValue == 'Error') {
        _displayValue = '0.';
        _shouldResetDisplay = false;
        return;
      }

      if (_shouldResetDisplay) {
        _displayValue = '0.';
        _shouldResetDisplay = false;
        return;
      }

      if (!_displayValue.contains('.')) {
        _displayValue += '.';
      }
    });
  }

  void _selectOperator(String operator) {
    final double? currentValue = double.tryParse(_displayValue);
    if (currentValue == null) {
      return;
    }

    setState(() {
      if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
        _firstOperand = _performOperation(_firstOperand!, currentValue, _operator!);
        _displayValue = _formatNumber(_firstOperand!);
      } else {
        _firstOperand = currentValue;
      }

      _operator = operator;
      _shouldResetDisplay = true;
    });
  }

  void _toggleSign() {
    final double? currentValue = double.tryParse(_displayValue);
    if (currentValue == null) {
      return;
    }

    setState(() {
      final double toggled = -currentValue;
      _displayValue = _formatNumber(toggled);
    });
  }

  void _calculateResult() {
    final double? currentValue = double.tryParse(_displayValue);
    if (_operator == null || _firstOperand == null || currentValue == null) {
      return;
    }

    setState(() {
      final double result = _performOperation(_firstOperand!, currentValue, _operator!);
      _displayValue = _formatNumber(result);
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  bool _isOperator(String value) => value == '÷' || value == '×' || value == '−' || value == '+';

  double _performOperation(double first, double second, String operator) {
    switch (operator) {
      case '÷':
        if (second == 0) {
          return double.nan;
        }
        return first / second;
      case '×':
        return first * second;
      case '−':
        return first - second;
      case '+':
        return first + second;
      default:
        return second;
    }
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    final double rounded = double.parse(value.toStringAsFixed(10));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }

    String stringValue = rounded.toString();
    if (stringValue.contains('.')) {
      stringValue = stringValue.replaceFirst(RegExp(r'0+$'), '');
      if (stringValue.endsWith('.')) {
        stringValue = stringValue.substring(0, stringValue.length - 1);
      }
    }
    return stringValue;
  }

  String get _expressionText {
    if (_operator == null || _firstOperand == null) {
      return '';
    }

    final String firstOperandText = _formatNumber(_firstOperand!);
    if (_shouldResetDisplay) {
      return '$firstOperandText $_operator';
    }

    return '$firstOperandText $_operator $_displayValue';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth = math.min(constraints.maxWidth, 360);
          final ColorScheme colorScheme = theme.colorScheme;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _expressionText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _displayValue,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _buttons.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final String value = _buttons[index];
                        return _CalculatorButton(
                          label: value,
                          isPrimary: _isOperator(value) || value == '=',
                          onPressed: () => _onButtonPressed(value),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isActionButton = label == 'C' || label == '⌫' || label == '%';

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary
            ? colorScheme.onPrimary
            : (isActionButton ? colorScheme.primary : colorScheme.onSurface),
        backgroundColor: isPrimary
            ? colorScheme.primary
            : (isActionButton
                ? colorScheme.primaryContainer
                : colorScheme.surfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.zero,
        textStyle: theme.textTheme.titleLarge,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
