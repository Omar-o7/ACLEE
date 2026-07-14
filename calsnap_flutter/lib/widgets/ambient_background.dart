import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Ambient atmosphere layer — very subtle orange + blue radial glows
/// over deep midnight navy, per the ACLEE design language.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base
        const Positioned.fill(
          child: ColoredBox(color: AppColors.background),
        ),
        // Warm glow — top start
        PositionedDirectional(
          top: -140,
          start: -100,
          child: _glow(AppColors.primary.withValues(alpha: 0.14), 380),
        ),
        // Cool glow — top end
        PositionedDirectional(
          top: -60,
          end: -120,
          child: _glow(AppColors.info.withValues(alpha: 0.10), 340),
        ),
        // Faint green — bottom center
        Positioned(
          bottom: -180,
          left: 0,
          right: 0,
          child: Center(
            child: _glow(AppColors.success.withValues(alpha: 0.05), 420),
          ),
        ),
        child,
      ],
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}
