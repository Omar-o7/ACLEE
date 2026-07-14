import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/ambient_background.dart';
import '../../core/i18n/app_translations.dart';
import '../../services/supabase_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_modals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.getProfile().then((p) {
      if (p != null && mounted) {
        setState(() {
          _name.text = p.name ?? '';
          _goal.text = p.dailyCalorieGoal.toString();
        });
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.updateProfile(
        name: _name.text.trim(),
        dailyCalorieGoal: int.tryParse(_goal.text),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(t('settings_title'))),
      body: AmbientBackground(
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeUp(
              index: 0,
              child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('edit_name'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground)),
                  const SizedBox(height: 8),
                  TextField(controller: _name),
                  const SizedBox(height: 16),
                  Text(t('daily_calorie_goal'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _goal,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? t('saving') : t('save')),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 14),
            FadeUp(
              index: 1,
              child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(t('language'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('EN')),
                      ButtonSegment(value: 'ar', label: Text('عربي')),
                    ],
                    selected: {lang.lang},
                    onSelectionChanged: (s) => lang.setLang(s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary,
                      selectedForegroundColor: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 14),
            FadeUp(
              index: 2,
              child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: BorderSide(
                      color: AppColors.destructive.withValues(alpha: 0.4))),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(t('sign_out')),
              onPressed: () async {
                final confirm = await showGlassDialog<bool>(
                  context,
                  title: t('confirm_signout'),
                  actions: [
                    TextButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .pop(false),
                        child: Text(t('cancel'),
                            style: const TextStyle(
                                color: AppColors.mutedForeground))),
                    TextButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .pop(true),
                        child: Text(t('sign_out'),
                            style: const TextStyle(
                                color: AppColors.destructive))),
                  ],
                );
                if (confirm == true) {
                  await SupabaseService.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                }
              },
            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
