import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Real frosted glass: backdrop blur + gradient hairline border
/// + faint top reflection. Subtle by design — never exaggerated.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool premiumShadow;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.premiumShadow = false,
    this.radius = AppRadius.xl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: premiumShadow ? AppShadows.card : AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: AppColors.card.withValues(alpha: 0.55),
              border: GradientBoxBorder(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.2),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.035),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Minimal gradient hairline border (no external package).
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  const GradientBoxBorder({required this.gradient, this.width = 1});

  @override
  BorderSide get top => BorderSide.none;
  @override
  BorderSide get bottom => BorderSide.none;
  @override
  bool get isUniform => true;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect).deflate(width / 2), paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}
