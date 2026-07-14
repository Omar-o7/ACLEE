import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/ambient_background.dart';
import '../../core/i18n/app_translations.dart';
import '../../services/supabase_service.dart';
import '../../widgets/glass_card.dart';

/// Weekly progress — bar chart of calories per day + averages.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, int> _dayTotals = {};
  int _goal = 2000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final svc = SupabaseService.instance;
      final logs = await svc.logsBetween(
          start, DateTime(now.year, now.month, now.day).add(const Duration(days: 1)));
      final profile = await svc.getProfile();
      final totals = <String, int>{};
      for (final l in logs) {
        final k = DateFormat('yyyy-MM-dd').format(l.loggedAt);
        totals[k] = (totals[k] ?? 0) + l.calories;
      }
      if (!mounted) return;
      setState(() {
        _dayTotals = totals;
        _goal = profile?.dailyCalorieGoal ?? 2000;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;
    final now = DateTime.now();

    final days = List.generate(7, (i) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final values = days
        .map((d) => _dayTotals[DateFormat('yyyy-MM-dd').format(d)] ?? 0)
        .toList();
    final loggedValues = values.where((v) => v > 0).toList();
    final avg = loggedValues.isEmpty
        ? 0
        : (loggedValues.reduce((a, b) => a + b) / loggedValues.length).round();
    final best = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = [best, _goal].reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(t('progress_title'))),
      body: AmbientBackground(
        child: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    FadeUp(
                      index: 0,
                      child: GlassCard(
                      premiumShadow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('weekly_calories'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                maxY: maxY <= 0 ? 100 : maxY,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(),
                                  rightTitles: const AxisTitles(),
                                  topTitles: const AxisTitles(),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, _) => Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          DateFormat.E(lang.isArabic ? 'ar' : 'en')
                                              .format(days[v.toInt()]),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.mutedForeground),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                barTouchData: BarTouchData(enabled: false),
                                extraLinesData: ExtraLinesData(horizontalLines: [
                                  HorizontalLine(
                                    y: _goal.toDouble(),
                                    color: AppColors.mutedForeground
                                        .withValues(alpha: 0.4),
                                    strokeWidth: 1,
                                    dashArray: [6, 4],
                                  ),
                                ]),
                                barGroups: List.generate(7, (i) {
                                  final over = values[i] > _goal;
                                  return BarChartGroupData(x: i, barRods: [
                                    BarChartRodData(
                                      toY: values[i].toDouble(),
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6)),
                                      gradient: over
                                          ? const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                  AppColors.destructive,
                                                  Color(0xFFF0654A)
                                                ])
                                          : const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                  AppColors.primary,
                                                  AppColors.primaryLight
                                                ]),
                                    ),
                                  ]);
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 14),
                    FadeUp(
                      index: 1,
                      child: Row(
                      children: [
                        Expanded(child: _statCard(t('avg_daily'), '$avg', t('kcal'))),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(t('best_day'), '$best', t('kcal'))),
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

  Widget _statCard(String label, String value, String unit) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}
