import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A small, non-interactive board preview used purely as decoration on the
/// home screen. Pieces gently float up/down and pulse their glow in a loop.
/// This is NOT the real game board — just a mood-setting visual.
class BoardPreview extends StatefulWidget {
  const BoardPreview({super.key});

  @override
  State<BoardPreview> createState() => _BoardPreviewState();
}

class _BoardPreviewState extends State<BoardPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 10 pieces sitting on the real grid points: full top row = AI (amber),
  // full bottom row = player (teal) — matches the reference board's vertices.
  static const List<_PreviewPoint> _points = [
    _PreviewPoint(dx: 0.0, dy: 0.0, isPlayer: false, phase: 0.0),
    _PreviewPoint(dx: 0.25, dy: 0.0, isPlayer: false, phase: 0.3),
    _PreviewPoint(dx: 0.5, dy: 0.0, isPlayer: false, phase: 0.6),
    _PreviewPoint(dx: 0.75, dy: 0.0, isPlayer: false, phase: 0.15),
    _PreviewPoint(dx: 1.0, dy: 0.0, isPlayer: false, phase: 0.45),
    _PreviewPoint(dx: 0.0, dy: 1.0, isPlayer: true, phase: 0.1),
    _PreviewPoint(dx: 0.25, dy: 1.0, isPlayer: true, phase: 0.4),
    _PreviewPoint(dx: 0.5, dy: 1.0, isPlayer: true, phase: 0.7),
    _PreviewPoint(dx: 0.75, dy: 1.0, isPlayer: true, phase: 0.25),
    _PreviewPoint(dx: 1.0, dy: 1.0, isPlayer: true, phase: 0.55),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BoardPreviewPainter(
              points: _points,
              t: _controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _PreviewPoint {
  const _PreviewPoint({
    required this.dx,
    required this.dy,
    required this.isPlayer,
    required this.phase,
  });

  final double dx; // 0..1 fraction of width
  final double dy; // 0..1 fraction of height
  final bool isPlayer;
  final double
  phase; // offsets each piece's animation so they don't move in sync
}

class _BoardPreviewPainter extends CustomPainter {
  _BoardPreviewPainter({required this.points, required this.t});

  final List<_PreviewPoint> points;
  final double t; // 0..1 looping progress

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.boardLine
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 5x5 grid: 4 columns x 4 rows of cells, margin so pieces/lines don't
    // touch the edges of the box.
    const margin = 0.06;
    final left = size.width * margin;
    final right = size.width * (1 - margin);
    final top = size.height * margin;
    final bottom = size.height * (1 - margin);
    final w = right - left;
    final h = bottom - top;

    Offset gridPoint(int col, int row) =>
        Offset(left + w * (col / 4), top + h * (row / 4));

    // 5 vertical + 5 horizontal grid lines
    for (var col = 0; col <= 4; col++) {
      canvas.drawLine(gridPoint(col, 0), gridPoint(col, 4), linePaint);
    }
    for (var row = 0; row <= 4; row++) {
      canvas.drawLine(gridPoint(0, row), gridPoint(4, row), linePaint);
    }

    // 4 big X's — one per 2x2 block (top-left, top-right, bottom-left,
    // bottom-right), each crossing corner-to-corner through its own center.
    // NOT a diagonal in every small cell — confirmed against reference image.
    for (var blockCol = 0; blockCol < 2; blockCol++) {
      for (var blockRow = 0; blockRow < 2; blockRow++) {
        final c0 = blockCol * 2;
        final r0 = blockRow * 2;
        canvas.drawLine(
          gridPoint(c0, r0),
          gridPoint(c0 + 2, r0 + 2),
          linePaint,
        );
        canvas.drawLine(
          gridPoint(c0 + 2, r0),
          gridPoint(c0, r0 + 2),
          linePaint,
        );
      }
    }

    for (final p in points) {
      // each piece floats on its own offset sine wave so they feel organic, not synced
      final wave = _loopingSine(t, p.phase);
      final floatOffset = wave * 4; // px of vertical float
      final glowPulse =
          0.5 + (wave.abs() * 0.5); // glow breathes between 0.5 and 1.0

      final center = Offset(left + w * p.dx, top + h * p.dy + floatOffset);

      final baseColor = p.isPlayer ? AppColors.playerStart : AppColors.aiStart;

      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.35 * glowPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, 18, glowPaint);

      final corePaint = Paint()..color = baseColor;
      canvas.drawCircle(center, 7, corePaint);
    }
  }

  // returns a value oscillating smoothly between -1 and 1, offset by [phase]
  double _loopingSine(double t, double phase) {
    final adjusted = (t + phase) % 1.0;
    return math.sin(adjusted * 2 * math.pi);
  }

  @override
  bool shouldRepaint(covariant _BoardPreviewPainter oldDelegate) => true;
}
