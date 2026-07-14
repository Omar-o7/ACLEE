import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/app_translations.dart';
import '../widgets/glass_card.dart';
import 'dashboard/dashboard_screen.dart';
import 'analyze/analyze_screen.dart';
import 'coach/coach_screen.dart';
import 'progress/progress_screen.dart';
import 'history/history_screen.dart';

/// ACLEE shell — floating frosted-glass pill navigation
/// with a glowing central camera action.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    HistoryScreen(),
    CoachScreen(),
    ProgressScreen(),
  ];

  void _openAnalyze() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.base,
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: AppMotion.easeOutExpo),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: a, curve: AppMotion.easeOutExpo)),
          child: const AnalyzeScreen(),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        ),
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Frosted pill bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A2B).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: GradientBoxBorder(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        _navItem(0, Icons.home_rounded, t('nav_home')),
                        _navItem(1, Icons.receipt_long_rounded, t('nav_history')),
                        const SizedBox(width: 68), // camera slot
                        _navItem(2, Icons.chat_bubble_rounded, t('nav_coach')),
                        _navItem(3, Icons.insights_rounded, t('nav_progress')),
                      ],
                    ),
                  ),
                ),
              ),
              // Raised glowing camera button
              Positioned(
                top: -6,
                child: GestureDetector(
                  onTap: _openAnalyze,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                      boxShadow: AppShadows.glow,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.background, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.easeOutExpo,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: AppMotion.base,
                curve: AppMotion.easeOutBack,
                scale: active ? 1.12 : 1.0,
                child: Icon(icon,
                    size: 23,
                    color: active
                        ? AppColors.primary
                        : AppColors.mutedForeground),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppMotion.base,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color:
                      active ? AppColors.primary : AppColors.mutedForeground,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
