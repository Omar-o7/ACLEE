import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_translations.dart';
import '../services/supabase_service.dart';
import 'glass_card.dart';

/// Water tracker — port of WaterTracker.tsx (250ml glasses, 8-glass goal, undo).
class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  static const glassMl = 250;
  static const goalGlasses = 8;
  int _totalMl = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ml = await SupabaseService.instance.todayWaterMl();
    if (mounted) setState(() => _totalMl = ml);
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _totalMl += glassMl; // optimistic
    });
    try {
      await SupabaseService.instance.addWater(glassMl);
    } catch (_) {
      setState(() => _totalMl -= glassMl);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    if (_busy || _totalMl <= 0) return;
    setState(() {
      _busy = true;
      _totalMl -= glassMl;
    });
    try {
      await SupabaseService.instance.undoLastWater();
    } catch (_) {
      setState(() => _totalMl += glassMl);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final glasses = (_totalMl / glassMl).round();
    final reached = glasses >= goalGlasses;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(t('water_label'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                '$glasses/$goalGlasses ${t('water_glasses')} · ${(_totalMl / 1000).toStringAsFixed(2)} ${t('liters')}',
                style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(goalGlasses, (i) {
              final filled = i < glasses;
              return Expanded(
                child: GestureDetector(
                  onTap: filled && i == glasses - 1 ? _undo : _add,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: filled
                          ? AppColors.water.withValues(alpha: 0.85)
                          : AppColors.muted,
                      border: Border.all(
                          color: filled
                              ? AppColors.water
                              : AppColors.border),
                    ),
                    child: filled
                        ? const Icon(Icons.water_drop, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }),
          ),
          if (reached) ...[
            const SizedBox(height: 10),
            Text('🎉 ${t('water_goal_reached')}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}
