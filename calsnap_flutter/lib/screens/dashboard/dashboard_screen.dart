import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../core/constants/gamification.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/calorie_ring.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/macro_card.dart';
import '../../widgets/meal_log_item.dart';
import '../../widgets/water_tracker.dart';
import '../../widgets/week_strip.dart';
import '../achievements/achievements_screen.dart';
import '../settings/settings_screen.dart';

/// ACLEE Home — redesigned to the studio brief:
/// ambient depth, frosted glass, calm hierarchy, cascading entrance.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Profile? _profile;
  UserStats? _stats;
  List<FoodLog> _logs = [];
  List<bool> _last7 = List.filled(7, false);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SupabaseService.instance;
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        svc.getProfile(),
        svc.getStats(),
        svc.todayLogs(),
        svc.logsBetween(dayStart.subtract(const Duration(days: 6)),
            dayStart.add(const Duration(days: 1))),
      ]);
      final weekLogs = results[3] as List<FoodLog>;
      final loggedDays = weekLogs
          .map((l) => DateFormat('yyyy-MM-dd').format(l.loggedAt))
          .toSet();
      final last7 = List.generate(7, (i) {
        final d = dayStart.subtract(Duration(days: 6 - i));
        return loggedDays.contains(DateFormat('yyyy-MM-dd').format(d));
      });
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile?;
        _stats = results[1] as UserStats?;
        _logs = results[2] as List<FoodLog>;
        _last7 = last7;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greetingKey() {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning';
    if (h < 18) return 'greeting_afternoon';
    return 'greeting_evening';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    double cal = 0, p = 0, c = 0, f = 0, fb = 0;
    for (final l in _logs) {
      cal += l.calories;
      p += l.proteinG;
      c += l.carbsG;
      f += l.fatG;
      fb += l.fiberG;
    }

    final goal = _profile?.dailyCalorieGoal ?? 2000;
    final level = levelForPoints(_stats?.totalPoints ?? 0);

    final grouped = <String, List<FoodLog>>{
      'breakfast': [], 'lunch': [], 'dinner': [], 'snack': [],
    };
    for (final l in _logs) {
      (grouped[l.mealType] ?? grouped['snack']!).add(l);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: _load,
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, AppSpacing.md, AppSpacing.page, 120),
              children: [
                // ── Header: one calm line ──
                FadeUp(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.MMMEd(lang.isArabic ? 'ar' : 'en')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${t(_greetingKey())}${_profile?.name != null ? '، ${_profile!.name!.split(' ').first}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3),
                            ),
                          ],
                        ),
                      ),
                      _headerChip(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AchievementsScreen())),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(level.emoji,
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 5),
                            Text('${_stats?.totalPoints ?? 0}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _headerChip(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen())),
                        child: const Icon(Icons.settings_rounded,
                            size: 17, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),

                // ── Hero: calorie ring on frosted glass ──
                FadeUp(
                  index: 1,
                  child: GlassCard(
                    premiumShadow: true,
                    radius: AppRadius.xxl,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.section),
                    child: _loading
                        ? const SizedBox(
                            height: 240,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)))
                        : Center(
                            child: CalorieRing(
                                consumed: cal.round(), goal: goal)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Week strip ──
                FadeUp(
                  index: 2,
                  child: WeekStrip(
                      streak: _stats?.currentStreak ?? 0, last7: _last7),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Macros ──
                FadeUp(
                  index: 3,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                            child: MacroCard(
                                name: t('protein'),
                                value: p,
                                goal: goal * 0.25 / 4,
                                color: AppColors.protein)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: MacroCard(
                                name: t('carbs'),
                                value: c,
                                goal: goal * 0.5 / 4,
                                color: AppColors.carbs)),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      Row(children: [
                        Expanded(
                            child: MacroCard(
                                name: t('fat'),
                                value: f,
                                goal: goal * 0.25 / 9,
                                color: AppColors.fat)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: MacroCard(
                                name: t('fiber'),
                                value: fb,
                                goal: 30,
                                color: AppColors.fiber)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Water ──
                const FadeUp(index: 4, child: WaterTracker()),
                const SizedBox(height: AppSpacing.section),

                // ── Meals ──
                FadeUp(
                  index: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('todays_meals'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2)),
                      const SizedBox(height: AppSpacing.md),
                      if (_logs.isEmpty && !_loading)
                        _emptyMeals(t)
                      else
                        ...[
                          'breakfast', 'lunch', 'dinner', 'snack'
                        ].where((m) => grouped[m]!.isNotEmpty).map((m) {
                          final list = grouped[m]!;
                          final mealKcal = list.fold<int>(
                              0, (s, l) => s + l.calories);
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(t(m),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors
                                                .mutedForeground)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                        child: Container(
                                            height: 1,
                                            color: AppColors.border)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text('$mealKcal ${t('kcal')}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors
                                                .mutedForeground)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ...list.map((l) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm),
                                      child: MealLogItem(log: l),
                                    )),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerChip({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }

  Widget _emptyMeals(String Function(String, [Map<String, Object>?]) t) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.section + 8),
      child: Column(
        children: [
          const Text('📸', style: TextStyle(fontSize: 44)),
          const SizedBox(height: AppSpacing.md),
          Text(t('no_meals_yet'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                  height: 1.5)),
        ],
      ),
    );
  }
}
