// lib/features/accounts/widgets/sparkline_chart.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class SparklineChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final double height;
  final double width;

  const SparklineChart({
    super.key,
    required this.data,
    this.lineColor = const Color(0xFF4a0873),
    this.fillColor = const Color(0x1A4a0873),
    this.height = 60,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length < 2) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            'Datos insuficientes',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lineColor.withOpacity(0.2),
          width: 0.6,
        ),
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(
          data: data,
          lineColor: lineColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final double minValue = data.reduce(math.min);
    final double maxValue = data.reduce(math.max);
    final double range = maxValue - minValue;

    // Si todos los valores son iguales, dibujar línea recta
    if (range == 0) {
      final y = size.height / 2;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      canvas.drawPath(path, linePaint);
      return;
    }

    // Normalizar datos a coordenadas del canvas
    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalizedValue = (data[i] - minValue) / range;
      final x = i * stepX;
      // Invertir Y porque canvas Y crece hacia abajo
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Crear path con curva suave (Cubic Bezier)
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      // Control points para curva suave
      final controlPoint1 = Offset(
        p0.dx + (p1.dx - p0.dx) / 2,
        p0.dy,
      );
      final controlPoint2 = Offset(
        p0.dx + (p1.dx - p0.dx) / 2,
        p1.dy,
      );

      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Crear path para relleno (área bajo la curva)
    final fillPath = Path.from(linePath);
    fillPath.lineTo(size.width, size.height); // Esquina inferior derecha
    fillPath.lineTo(0, size.height); // Esquina inferior izquierda
    fillPath.close();

    // Dibujar relleno primero, luego línea
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // Dibujar punto en el último valor
    final lastPoint = points.last;
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastPoint, 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
