import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../models/models.dart';

/// ACLEE's signature moment — the AI scan.
/// Frozen frame + sweeping beam + focus brackets + progressive reveal.
class ScanView extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<NutritionResult> Function() analyze;
  final void Function(NutritionResult) onDone;
  final void Function(String) onError;

  const ScanView({
    super.key,
    required this.imageBytes,
    required this.analyze,
    required this.onDone,
    required this.onError,
  });

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beam;
  NutritionResult? _result;
  int _revealed = 0; // 0 none · 1 name · 2 portion → done

  @override
  void initState() {
    super.initState();
    _beam = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _run();
  }

  Future<void> _run() async {
    final t = context.read<LanguageProvider>().t;
    final started = DateTime.now();
    try {
      final r = await widget.analyze();
      // Let the scan breathe — never flash results instantly.
      final elapsed = DateTime.now().difference(started);
      if (elapsed < const Duration(milliseconds: 2200)) {
        await Future.delayed(
            const Duration(milliseconds: 2200) - elapsed);
      }
      if (!mounted) return;
      _beam.stop();
      setState(() {
        _result = r;
        _revealed = 1;
      });
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _revealed = 2);
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      widget.onDone(r);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('Exception: ')
          ? e.toString().replaceFirst('Exception: ', '')
          : t('error_generic');
      widget.onError(msg);
    }
  }

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Frozen frame
        Image.memory(widget.imageBytes, fit: BoxFit.cover),
        // Calm dim
        Container(color: Colors.black.withValues(alpha: 0.35)),

        // Sweeping beam
        if (_result == null)
          AnimatedBuilder(
            animation: _beam,
            builder: (_, __) {
              final h = MediaQuery.of(context).size.height;
              final y = (_beam.value * 1.3 - 0.15) * h;
              return Positioned(
                top: y,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0),
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primaryLight.withValues(alpha: 0.55),
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Focus brackets
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(painter: _BracketsPainter()),
          ),
        ),

        // Bottom: status → progressive reveal
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0,
                  AppSpacing.page, AppSpacing.section),
              child: AnimatedSize(
                duration: AppMotion.base,
                curve: AppMotion.easeOutExpo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: _result == null
                      ? Row(
                          children: [
                            const _PulsingDot(),
                            const SizedBox(width: AppSpacing.md),
                            Text(t('scanning'),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _revealRow(
                              visible: _revealed >= 1,
                              icon: Icons.check_circle_rounded,
                              text:
                                  '${t('identified')}: ${_result!.foodName}',
                              trailing:
                                  '${(_result!.confidenceScore * 100).round()}%',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _revealRow(
                              visible: _revealed >= 2,
                              icon: Icons.straighten_rounded,
                              text:
                                  '${t('portion')}: ${_result!.servingSize}',
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _revealRow({
    required bool visible,
    required IconData icon,
    required String text,
    String? trailing,
  }) {
    return AnimatedOpacity(
      duration: AppMotion.base,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: AppMotion.base,
        curve: AppMotion.easeOutExpo,
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(trailing,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.7),
                blurRadius: 12),
          ],
        ),
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const r = 22.0;

    void corner(double x, double y, int dx, int dy) {
      final path = Path()
        ..moveTo(x + dx * len, y)
        ..lineTo(x + dx * r, y)
        ..arcToPoint(Offset(x, y + dy * r),
            radius: const Radius.circular(r),
            clockwise: (dx > 0) != (dy > 0))
        ..lineTo(x, y + dy * len);
      canvas.drawPath(path, paint);
    }

    corner(0, 0, 1, 1);
    corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1);
    corner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
