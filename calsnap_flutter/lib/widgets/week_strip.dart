import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_translations.dart';
import 'glass_card.dart';

/// Premium 7-day strip — today as a glowing gradient pill,
/// logged days marked with a dot. Replaces the old streak bars.
class WeekStrip extends StatelessWidget {
  final int streak;
  final List<bool> last7;
  const WeekStrip({super.key, required this.streak, required this.last7});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;
    final now = DateTime.now();
    final days = List.generate(
        7,
        (i) => DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i)));

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Text('$streak ${t('streak_days')}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(7, (i) {
              final d = days[i];
              final isToday = i == 6;
              final logged = i < last7.length && last7[i];
              return Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs + 2),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: isToday ? AppColors.gradientPrimary : null,
                    color: isToday
                        ? null
                        : Colors.white.withValues(alpha: 0.04),
                    boxShadow: isToday ? AppShadows.glow : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.E(lang.isArabic ? 'ar' : 'en')
                            .format(d)
                            .substring(0, lang.isArabic ? 1 : 3),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.background
                              : AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isToday
                              ? AppColors.background
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: logged
                              ? (isToday
                                  ? AppColors.background
                                  : AppColors.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
