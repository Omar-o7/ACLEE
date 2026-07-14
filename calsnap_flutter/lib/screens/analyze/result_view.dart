import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_ring.dart';
import '../../widgets/glass_modals.dart';
import 'story_editor.dart';

/// Luxurious analysis result: hero photo, floating glass nutrition,
/// AI insight, elegant actions.
class ResultView extends StatefulWidget {
  final Uint8List imageBytes;
  final String mime;
  final NutritionResult result;
  final VoidCallback onSaved;
  final VoidCallback onRetake;

  const ResultView({
    super.key,
    required this.imageBytes,
    required this.mime,
    required this.result,
    required this.onSaved,
    required this.onRetake,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  late String _mealType = _defaultMealType();
  bool _saving = false;

  static String _defaultMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return 'breakfast';
    if (h < 16) return 'lunch';
    if (h < 21) return 'dinner';
    return 'snack';
  }

  String _insight(String Function(String, [Map<String, Object>?]) t) {
    final r = widget.result;
    if (r.proteinG >= 25 && r.fiberG < 4) {
      return '${t('insight_protein')} ${t('insight_fiber')}';
    }
    if (r.proteinG >= 25) return t('insight_protein');
    if (r.calories > 800) return t('insight_rich');
    if (r.notes.isNotEmpty) return r.notes;
    return t('insight_balanced');
  }

  Future<void> _save() async {
    if (_saving) return;
    final t = context.read<LanguageProvider>().t;
    setState(() => _saving = true);
    try {
      final svc = SupabaseService.instance;
      final url = await svc.uploadFoodImage(
          widget.imageBytes, widget.mime == 'png' ? 'png' : 'jpg');
      await svc.logFood(
          n: widget.result, mealType: _mealType, imageUrl: url);
      final award = await svc.awardMealPoints();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      if (award.pointsEarned > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✨ +${award.pointsEarned} ${t('points')}'
                '${award.leveledUp ? ' · ${award.levelName}!' : ''}')));
      }
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('error_generic'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openStory() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoryEditor(
          initialImage: widget.imageBytes, nutrition: widget.result),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final r = widget.result;
    final h = MediaQuery.of(context).size.height;

    return AmbientBackground(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Hero photo with soft fade into the page ──
              SizedBox(
                height: h * 0.40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(widget.imageBytes, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.45, 1],
                          colors: [
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, 0, AppSpacing.page, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + serving
                    FadeUp(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.foodName,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(r.servingSize,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Calories hero
                    FadeUp(
                      index: 1,
                      child: GlassCard(
                        premiumShadow: true,
                        radius: AppRadius.xxl,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text('${r.calories}',
                                    style: const TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                        color: AppColors.primary)),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8, left: 6, right: 6),
                                  child: Text(t('kcal'),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors
                                              .mutedForeground)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                MiniRing(
                                    label: t('protein'),
                                    value: r.proteinG,
                                    goal: 50,
                                    color: AppColors.protein),
                                MiniRing(
                                    label: t('carbs'),
                                    value: r.carbsG,
                                    goal: 80,
                                    color: AppColors.carbs),
                                MiniRing(
                                    label: t('fat'),
                                    value: r.fatG,
                                    goal: 35,
                                    color: AppColors.fat),
                                MiniRing(
                                    label: t('fiber'),
                                    value: r.fiberG,
                                    goal: 12,
                                    color: AppColors.fiber),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 13,
                                    color: AppColors.mutedForeground),
                                const SizedBox(width: 5),
                                Text(
                                    '${t('confidence')} ${(r.confidenceScore * 100).round()}%',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.mutedForeground)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // AI Insight
                    FadeUp(
                      index: 2,
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  size: 17,
                                  color: AppColors.background),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(t('ai_insight'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors
                                              .mutedForeground)),
                                  const SizedBox(height: 3),
                                  Text(_insight(t),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Meal type
                    FadeUp(
                      index: 3,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final m in [
                            'breakfast', 'lunch', 'dinner', 'snack'
                          ])
                            ChoiceChip(
                              label: Text(t(m)),
                              selected: _mealType == m,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _mealType == m
                                      ? AppColors.background
                                      : AppColors.foreground),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                              side:
                                  BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.pill)),
                              onSelected: (_) =>
                                  setState(() => _mealType = m),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Secondary actions
                    FadeUp(
                      index: 4,
                      child: Row(
                        children: [
                          _action(Icons.edit_rounded, t('edit_values'),
                              _openEditSheet),
                          const SizedBox(width: AppSpacing.sm),
                          _action(Icons.ios_share_rounded,
                              t('share_story'), _openStory),
                          const SizedBox(width: AppSpacing.sm),
                          _action(Icons.refresh_rounded, t('retake'),
                              widget.onRetake),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating close
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GestureDetector(
                onTap: widget.onRetake,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 20, color: Colors.white),
                ),
              ),
            ),
          ),

          // Floating primary save
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.glow,
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.background))
                        : Text(t('save_meal'),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.background)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.foreground),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _openEditSheet() {
    final t = context.read<LanguageProvider>().t;
    final r = widget.result;
    final cal = TextEditingController(text: r.calories.toString());
    final p = TextEditingController(text: r.proteinG.toStringAsFixed(1));
    final c = TextEditingController(text: r.carbsG.toStringAsFixed(1));
    final f = TextEditingController(text: r.fatG.toStringAsFixed(1));
    showGlassSheet(
      context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xxl,
            AppSpacing.page,
            AppSpacing.xxl + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('edit_values'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.lg),
            _editField(t('calories'), cal),
            _editField(t('protein'), p),
            _editField(t('carbs'), c),
            _editField(t('fat'), f),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  r.calories = int.tryParse(cal.text) ?? r.calories;
                  r.proteinG = double.tryParse(p.text) ?? r.proteinG;
                  r.carbsG = double.tryParse(c.text) ?? r.carbsG;
                  r.fatG = double.tryParse(f.text) ?? r.fatG;
                });
                Navigator.pop(ctx);
              },
              child: Text(t('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );
}

/// ── Success view after saving ──
class LoggedView extends StatelessWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final VoidCallback onHome;
  final VoidCallback onAgain;

  const LoggedView({
    super.key,
    required this.imageBytes,
    required this.result,
    required this.onHome,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    return AmbientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder: (_, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              AppColors.success.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.success
                                .withValues(alpha: 0.45),
                            blurRadius: 44,
                            spreadRadius: -8),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 46, color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeUp(
                index: 1,
                child: Text(t('meal_logged'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeUp(
                index: 2,
                child: Text(t('meal_logged_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground)),
              ),
              const SizedBox(height: AppSpacing.section + 8),
              FadeUp(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                        onPressed: onHome, child: Text(t('back_home'))),
                    const SizedBox(height: AppSpacing.sm),
                    if (imageBytes != null && result != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.ios_share_rounded,
                            size: 17),
                        label: Text(t('share_story')),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryEditor(
                                initialImage: imageBytes!,
                                nutrition: result!),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                        onPressed: onAgain,
                        child: Text(t('snap_another'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
