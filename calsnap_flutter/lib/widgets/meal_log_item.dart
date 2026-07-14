import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';

/// A single logged meal row — port of MealLogItem.tsx
class MealLogItem extends StatelessWidget {
  final FoodLog log;
  final VoidCallback? onDelete;
  const MealLogItem({super.key, required this.log, this.onDelete});

  static const _emoji = {
    'breakfast': '🌅',
    'lunch': '☀️',
    'dinner': '🌙',
    'snack': '🍎',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: log.imageUrl != null
                ? Image.network(log.imageUrl!,
                    width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback())
                : _fallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.foodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'P ${log.proteinG.round()} · C ${log.carbsG.round()} · F ${log.fatG.round()} · ${DateFormat.jm().format(log.loggedAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${log.calories}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Text(' kcal',
              style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.mutedForeground),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        width: 48,
        height: 48,
        color: AppColors.muted,
        alignment: Alignment.center,
        child: Text(_emoji[log.mealType] ?? '🍽️', style: const TextStyle(fontSize: 22)),
      );
}
