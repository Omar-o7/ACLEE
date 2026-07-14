import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/ambient_background.dart';
import '../../core/i18n/app_translations.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/meal_log_item.dart';

/// Meal history grouped by day (last 30 days).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FoodLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final logs = await SupabaseService.instance.logsBetween(
          now.subtract(const Duration(days: 30)),
          now.add(const Duration(days: 1)));
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(FoodLog l) async {
    await SupabaseService.instance.deleteLog(l.id);
    setState(() => _logs.removeWhere((x) => x.id == l.id));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    final grouped = <String, List<FoodLog>>{};
    for (final l in _logs) {
      final k = DateFormat('yyyy-MM-dd').format(l.loggedAt);
      grouped.putIfAbsent(k, () => []).add(l);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(t('history_title'))),
      body: AmbientBackground(
        child: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : keys.isEmpty
                ? Center(
                    child: Text(t('no_history'),
                        style:
                            const TextStyle(color: AppColors.mutedForeground)))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: keys.length,
                      itemBuilder: (_, i) {
                        final k = keys[i];
                        final list = grouped[k]!;
                        final total =
                            list.fold<int>(0, (s, l) => s + l.calories);
                        final date = DateTime.parse(k);
                        return FadeUp(
                          index: i.clamp(0, 6),
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat.MMMEd(
                                            lang.isArabic ? 'ar' : 'en')
                                        .format(date),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  Text('$total ${t('kcal')}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...list.map((l) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: MealLogItem(
                                        log: l, onDelete: () => _delete(l)),
                                  )),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
                  ),
      ),
      ),
    );
  }
}
