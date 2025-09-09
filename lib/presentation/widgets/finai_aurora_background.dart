import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo gradiente fiel a la imagen original con paleta de colores específica.
/// - Colores exactos proporcionados para máxima fidelidad
/// - Transición suave de azul índigo oscuro a púrpura/magenta
/// - Líneas aurora sutiles pero visibles
class FinAiAuroraBackground extends StatefulWidget {
  const FinAiAuroraBackground({super.key});

  @override
  State<FinAiAuroraBackground> createState() => _FinAiAuroraBackgroundState();
}

class _FinAiAuroraBackgroundState extends State<FinAiAuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _OriginalGradientPainter(_animation.value),
          size: Size.infinite,
          isComplex: true,
          willChange: true,
        );
      },
    );
  }
}

class _OriginalGradientPainter extends CustomPainter {
  final double animationValue;
  
  const _OriginalGradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ===== 1) Fondo base con gradiente vertical principal =====
    final baseGradient = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        const [
          Color(0xFF0A071B), // Negro azulado (top)
          Color(0xFF0D0B2B), // Azul índigo muy oscuro
          Color(0xFF101035), // Azul tinta
          Color(0xFF111B4A), // Azul noche
          Color(0xFF1A1D53), // Azul índigo medio
          Color(0xFF24215C), // Azul violáceo
          Color(0xFF330F3E), // Púrpura oscuro
          Color(0xFF441348), // Morado vino
          Color(0xFF591B5A), // Violeta acento
        ],
        const [0.0, 0.08, 0.15, 0.25, 0.40, 0.55, 0.70, 0.85, 1.0],
      );
    canvas.drawRect(rect, baseGradient);

    // ===== 2) Gradiente diagonal para dar profundidad =====
    final diagonalGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.7, 0),
        Offset(size.width * 0.3, size.height),
        [
          const Color(0xFF1E3A7B).withOpacity(0.3), // Azul más claro
          const Color(0xFF4A65C8).withOpacity(0.2), // Azul brillante
          Colors.transparent,
        ],
        const [0.0, 0.3, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, diagonalGradient);

    // ===== 3) Líneas aurora sutiles (como en la imagen original) =====
    _drawOriginalAuroraLines(canvas, size);

    // ===== 4) Glow principal magenta/púrpura (inferior) =====
    final primaryGlowRadius = size.height * 0.85 * (1.0 + animationValue * 0.05);
    _drawOriginalGlow(
      canvas,
      size,
      center: Offset(size.width * 0.5, size.height * 1.0),
      radius: primaryGlowRadius,
      colors: [
        const Color(0xFFB83DAE).withOpacity(0.6), // Magenta brillante
        const Color(0xFF591B5A).withOpacity(0.4), // Violeta acento
        const Color(0xFF441348).withOpacity(0.25), // Morado vino
        const Color(0xFF330F3E).withOpacity(0.15), // Púrpura oscuro
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.4, 0.65, 1.0],
    );

    // ===== 5) Glow secundario azul (superior lateral) =====
    _drawOriginalGlow(
      canvas,
      size,
      center: Offset(size.width * 0.85, size.height * 0.15),
      radius: size.height * 0.4,
      colors: [
        const Color(0xFF4A65C8).withOpacity(0.25), // Azul brillante
        const Color(0xFF1E3A7B).withOpacity(0.15), // Azul medio
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // ===== 6) Gradiente inferior magenta vibrante =====
    final bottomMagentaGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.5),
        Offset(0, size.height),
        [
          Colors.transparent,
          const Color(0xFF591B5A).withOpacity(0.15), // Violeta acento
          const Color(0xFF441348).withOpacity(0.30), // Morado vino
          const Color(0xFFB83DAE).withOpacity(0.45), // Magenta brillante
          const Color(0xFFB83DAE).withOpacity(0.55), // Magenta más intenso
        ],
        const [0.0, 0.4, 0.65, 0.85, 1.0],
      )
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, bottomMagentaGradient);

    // ===== 7) Capa de brillo superior (azul claro) =====
    final topShineGradient = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, -size.height * 0.1),
        size.height * 0.8,
        [
          const Color(0xFF4A65C8).withOpacity(0.15), // Azul brillante
          const Color(0xFF1E3A7B).withOpacity(0.08), // Azul medio
          Colors.transparent,
        ],
        const [0.0, 0.4, 1.0],
      )
      ..blendMode = BlendMode.screen;
    canvas.drawRect(rect, topShineGradient);

    // ===== 8) Efecto de luz suave (highlight central) =====
    _drawSoftHighlight(canvas, size);

    // ===== 9) Partículas de luz sutiles =====
    _drawSoftParticles(canvas, size);

    // ===== 10) Overlay final para unificar =====
    final unifyingOverlay = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.3),
        Offset(0, size.height),
        [
          Colors.transparent,
          const Color(0xFF221736).withOpacity(0.1), // Púrpura muy oscuro
          const Color(0xFF4E184A).withOpacity(0.15), // Magenta oscuro
        ],
        const [0.0, 0.6, 1.0],
      )
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(rect, unifyingOverlay);

    // ===== 11) Vignette sutil =====
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        size.height * 1.5,
        [
          Colors.transparent,
          const Color(0xFF0A071B).withOpacity(0.25), // Negro azulado
        ],
        const [0.8, 1.0],
      );
    canvas.drawRect(rect, vignette);
  }

  void _drawOriginalGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required List<double> stops,
  }) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        colors,
        stops,
        TileMode.clamp,
      )
      ..blendMode = BlendMode.plus;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawOriginalAuroraLines(Canvas canvas, Size size) {
    // Primera línea aurora - azul suave
    _drawSoftAuroraLine(
      canvas,
      size,
      startPoint: Offset(-size.width * 0.1, size.height * 0.25),
      endPoint: Offset(size.width * 1.1, size.height * 0.35),
      controlPoint: Offset(size.width * 0.5, size.height * 0.28),
      colors: [
        Colors.transparent,
        const Color(0xFF4A65C8).withOpacity(0.15), // Azul brillante
        const Color(0xFF1E3A7B).withOpacity(0.20), // Azul medio
        const Color(0xFF4A65C8).withOpacity(0.15),
        Colors.transparent,
      ],
      width: size.height * 0.08,
      blur: 35.0,
    );

    // Segunda línea aurora - púrpura
    _drawSoftAuroraLine(
      canvas,
      size,
      startPoint: Offset(-size.width * 0.05, size.height * 0.30),
      endPoint: Offset(size.width * 1.05, size.height * 0.40),
      controlPoint: Offset(size.width * 0.6, size.height * 0.33),
      colors: [
        Colors.transparent,
        const Color(0xFF591B5A).withOpacity(0.12), // Violeta acento
        const Color(0xFFB83DAE).withOpacity(0.18), // Magenta
        const Color(0xFF591B5A).withOpacity(0.12),
        Colors.transparent,
      ],
      width: size.height * 0.07,
      blur: 30.0,
    );

    // Tercera línea aurora - magenta suave
    _drawSoftAuroraLine(
      canvas,
      size,
      startPoint: Offset(-size.width * 0.15, size.height * 0.34),
      endPoint: Offset(size.width * 1.15, size.height * 0.43),
      controlPoint: Offset(size.width * 0.4, size.height * 0.36),
      colors: [
        Colors.transparent,
        const Color(0xFFB83DAE).withOpacity(0.10), // Magenta
        const Color(0xFFB83DAE).withOpacity(0.15),
        const Color(0xFF441348).withOpacity(0.10), // Morado vino
        Colors.transparent,
      ],
      width: size.height * 0.06,
      blur: 25.0,
    );
  }

  void _drawSoftAuroraLine(
    Canvas canvas,
    Size size, {
    required Offset startPoint,
    required Offset endPoint,
    required Offset controlPoint,
    required List<Color> colors,
    required double width,
    required double blur,
  }) {
    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(
        controlPoint.dx + (math.sin(animationValue * 2 * math.pi) * 8),
        controlPoint.dy + (math.cos(animationValue * 2 * math.pi) * 4),
        endPoint.dx,
        endPoint.dy,
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..shader = ui.Gradient.linear(
        startPoint,
        endPoint,
        colors,
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    
    canvas.drawPath(path, paint);
  }

  void _drawSoftHighlight(Canvas canvas, Size size) {
    // Efecto de luz central suave
    final highlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.6),
        size.height * 0.5,
        [
          const Color(0xFFB83DAE).withOpacity(0.08), // Magenta muy suave
          const Color(0xFF4A65C8).withOpacity(0.05), // Azul muy suave
          Colors.transparent,
        ],
        const [0.0, 0.5, 1.0],
      )
      ..blendMode = BlendMode.screen;
    
    canvas.drawRect(Offset.zero & size, highlightPaint);
  }

  void _drawSoftParticles(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * 0.2 + (random.nextDouble() * size.height * 0.5);
      final radius = random.nextDouble() * 1.5 + 0.5;
      
      // Animación sutil
      final pulse = math.sin(animationValue * math.pi * 2 + i * 0.4) * 0.3 + 0.7;
      final opacity = (random.nextDouble() * 0.2 + 0.1) * pulse;
      
      // Partícula con los colores de la paleta
      final particlePaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(x, y),
          radius * 3,
          [
            const Color(0xFFB83DAE).withOpacity(opacity * 0.8), // Magenta
            const Color(0xFF4A65C8).withOpacity(opacity * 0.4), // Azul
            Colors.transparent,
          ],
          const [0.0, 0.4, 1.0],
        )
        ..blendMode = BlendMode.plus;
      
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OriginalGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}