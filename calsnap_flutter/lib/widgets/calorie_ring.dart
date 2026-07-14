import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_translations.dart';

/// Premium animated calorie ring — faithful port of CalorieRing.tsx:
/// gradient stroke + soft glow + smooth sweep + count-up center.
class CalorieRing extends StatelessWidget {
  final int consumed;
  final int goal;
  const CalorieRing({super.key, required this.consumed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final pct = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final over = goal > 0 && consumed > goal;
    final remaining = math.max(goal - consumed, 0);

    return SizedBox(
      width: 240,
      height: 240,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: const Duration(milliseconds: 1100),
        curve: const Cubic(0.16, 1, 0.3, 1), // ease-out-expo
        builder: (context, progress, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _RingPainter(progress: progress, over: over),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('today_label').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: consumed.toDouble()),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      v.round().toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('of_goal', {'goal': goal}),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (over ? AppColors.destructive : AppColors.primary)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      over
                          ? '+${consumed - goal} ${t('kcal')}'
                          : '$remaining ${t('kcal')} ${t('calories_remaining')}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: over ? AppColors.destructive : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool over;
  _RingPainter({required this.progress, required this.over});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.muted.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    final colors = over
        ? [const Color(0xFFF0654A), AppColors.destructive]
        : [AppColors.primaryLight, AppColors.primary];

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: [colors[0], colors[1], colors[0]],
      transform: const GradientRotation(startAngle),
    );

    // Glow layer (blurred copy underneath)
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, startAngle, sweep, false, glow);

    // Crisp progress arc
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);
    canvas.drawArc(rect, startAngle, sweep, false, arc);

    // Glowing end-cap dot — gives the ring a living "tip"
    final endAngle = startAngle + sweep;
    final tip = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(
      tip,
      stroke * 0.62,
      Paint()
        ..color = colors[1].withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(tip, stroke * 0.30, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.over != over;
}
