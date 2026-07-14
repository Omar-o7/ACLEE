import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Macro progress card (protein / carbs / fat / fiber) — port of MacroCard.tsx
class MacroCard extends StatelessWidget {
  final String name;
  final double value;
  final double goal;
  final Color color;
  const MacroCard({
    super.key,
    required this.name,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value.round().toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
              Text(' / ${goal.round()}g',
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, p, __) => LinearProgressIndicator(
                value: p,
                minHeight: 5,
                backgroundColor: AppColors.muted,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
