import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/ambient_background.dart';
import '../../core/i18n/app_translations.dart';
import '../../core/constants/gamification.dart' as g;
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/glass_card.dart';

/// Achievements — level card + badges grid, port of achievements.tsx
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.getStats().then((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final points = _stats?.totalPoints ?? 0;
    final level = g.levelForPoints(points);
    final idx = g.levels.indexOf(level);
    final next = idx < g.levels.length - 1 ? g.levels[idx + 1] : null;
    final progress = next != null
        ? ((points - level.min) / (next.min - level.min)).clamp(0.0, 1.0)
        : 1.0;
    final earned = _stats?.badges ?? const <String>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(t('achievements_title'))),
      body: AmbientBackground(
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Level card
            FadeUp(
              index: 0,
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.glow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(level.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.background)),
                          Text('$points ${t('points')}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.background
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor:
                            AppColors.background.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.background),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${next.min - points} → ${next.emoji} ${next.name}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                AppColors.background.withValues(alpha: 0.8))),
                  ],
                ],
              ),
            ),
            ),
            const SizedBox(height: 24),
            FadeUp(index: 1, child: Text(
                '${t('badges_earned')} (${earned.length}/${g.badges.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            FadeUp(
              index: 2,
              child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: g.badges.map((b) {
                final unlocked = earned.contains(b.id);
                return GlassCard(
                  padding: const EdgeInsets.all(10),
                  child: Opacity(
                    opacity: unlocked ? 1 : 0.35,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        Text(b.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(unlocked ? '' : t('badges_locked'),
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
