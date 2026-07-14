import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_translations.dart';
import 'glass_card.dart';

/// 7-day streak strip — port of StreakTracker.tsx
class StreakTracker extends StatelessWidget {
  final int streak;
  final List<bool> last7;
  const StreakTracker({super.key, required this.streak, required this.last7});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
              Text(t('streak_days'),
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(7, (i) {
              final active = i < last7.length && last7[i];
              return Container(
                margin: const EdgeInsetsDirectional.only(start: 5),
                width: 12,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: active ? AppColors.gradientPrimary : null,
                  color: active ? null : AppColors.muted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
