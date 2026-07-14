import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'glass_card.dart';

/// Unified glass bottom sheet — frosted blur, hairline gradient border,
/// drag handle. Every sheet in ACLEE goes through this.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl)),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Flexible(child: builder(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Unified glass dialog — blurred barrier + frosted card scaling in
/// with ACLEE's ease-out-expo motion.
Future<T?> showGlassDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required List<Widget> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.base,
    transitionBuilder: (ctx, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: AppMotion.easeOutExpo);
      return BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: 8 * anim.value, sigmaY: 8 * anim.value),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.section),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: GradientBoxBorder(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(message,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.mutedForeground)),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      content,
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          actions[i],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
