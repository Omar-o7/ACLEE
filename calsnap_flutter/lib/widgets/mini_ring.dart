import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Small circular macro indicator used on the result screen
/// and inside the Story Studio badges.
class MiniRing extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;
  final double size;

  const MiniRing({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.unit = 'g',
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: AppMotion.ring,
            curve: AppMotion.easeOutExpo,
            builder: (_, p, __) => CustomPaint(
              painter: _MiniRingPainter(progress: p, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value.round().toString(),
                        style: TextStyle(
                            fontSize: size * 0.24,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    Text(unit,
                        style: TextStyle(
                            fontSize: size * 0.13,
                            color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground)),
      ],
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _MiniRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.white.withValues(alpha: 0.07));

    if (progress <= 0) return;
    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color);
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}
