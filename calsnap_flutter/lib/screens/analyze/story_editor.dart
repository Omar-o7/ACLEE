import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../models/models.dart';

/// ACLEE Story Studio — Instagram-story style editor.
/// Glass nutrition badges: drag, pinch to scale, twist to rotate,
/// toggle visibility, export & share.
class StoryEditor extends StatefulWidget {
  final Uint8List initialImage;
  final NutritionResult nutrition;

  const StoryEditor({
    super.key,
    required this.initialImage,
    required this.nutrition,
  });

  @override
  State<StoryEditor> createState() => _StoryEditorState();
}

class _BadgeState {
  Offset position;
  double scale;
  double rotation;
  bool visible;
  // gesture baselines
  double _baseScale = 1;
  double _baseRot = 0;

  _BadgeState({
    required this.position,
    this.scale = 1,
    this.rotation = 0,
    this.visible = true,
  });
}

class _StoryEditorState extends State<StoryEditor> {
  final _canvasKey = GlobalKey();
  final _picker = ImagePicker();
  late Uint8List _image = widget.initialImage;
  bool _exporting = false;

  late final Map<String, _BadgeState> _badges = {
    'calories': _BadgeState(position: const Offset(24, 60)),
    'protein': _BadgeState(position: const Offset(24, 130)),
    'carbs':
        _BadgeState(position: const Offset(24, 200), visible: false),
    'fat': _BadgeState(position: const Offset(24, 270), visible: false),
    'fiber':
        _BadgeState(position: const Offset(24, 340), visible: false),
  };

  ({String value, String label, Color color}) _badgeData(
      String id, String Function(String, [Map<String, Object>?]) t) {
    final n = widget.nutrition;
    return switch (id) {
      'calories' => (
          value: '${n.calories}',
          label: t('kcal'),
          color: AppColors.primary
        ),
      'protein' => (
          value: '${n.proteinG.round()}g',
          label: t('protein'),
          color: AppColors.protein
        ),
      'carbs' => (
          value: '${n.carbsG.round()}g',
          label: t('carbs'),
          color: AppColors.carbs
        ),
      'fat' => (
          value: '${n.fatG.round()}g',
          label: t('fat'),
          color: AppColors.fat
        ),
      _ => (
          value: '${n.fiberG.round()}g',
          label: t('fiber'),
          color: AppColors.fiber
        ),
    };
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 2000, imageQuality: 92);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _image = bytes);
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      // Let UI settle (hide any transient chrome) then rasterize.
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _canvasKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/aclee_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
    } catch (_) {
      if (mounted) {
        final t = context.read<LanguageProvider>().t;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('error_generic'))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D16),
      appBar: AppBar(
        title: Text(t('story_editor')),
        actions: [
          IconButton(
            tooltip: t('pick_image'),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(t('position_hint'),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mutedForeground)),
            ),

            // ── 9:16 canvas ──
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_image, fit: BoxFit.cover),
                          // Subtle brand watermark
                          PositionedDirectional(
                            bottom: 10,
                            end: 12,
                            child: Text(
                              'ACLEE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                                color: Colors.white
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          // Badges
                          for (final e in _badges.entries)
                            if (e.value.visible)
                              _buildBadge(e.key, e.value, t),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Toggle chips ──
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page),
                children: _badges.keys.map((id) {
                  final on = _badges[id]!.visible;
                  final d = _badgeData(id, t);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(d.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: on
                                  ? AppColors.background
                                  : AppColors.foreground)),
                      selected: on,
                      selectedColor: d.color,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(color: AppColors.border),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill)),
                      onSelected: (v) =>
                          setState(() => _badges[id]!.visible = v),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Share ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: GestureDetector(
                onTap: _export,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.glow,
                  ),
                  alignment: Alignment.center,
                  child: _exporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.background))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.ios_share_rounded,
                                size: 18, color: AppColors.background),
                            const SizedBox(width: AppSpacing.sm),
                            Text(t('export_share'),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.background)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String id, _BadgeState b,
      String Function(String, [Map<String, Object>?]) t) {
    final d = _badgeData(id, t);
    return Positioned(
      left: b.position.dx,
      top: b.position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          b._baseScale = b.scale;
          b._baseRot = b.rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            b.position += details.focalPointDelta;
            b.scale = (b._baseScale * details.scale).clamp(0.6, 2.4);
            b.rotation = b._baseRot + details.rotation;
          });
        },
        child: Transform.rotate(
          angle: b.rotation,
          child: Transform.scale(
            scale: b.scale,
            child: _GlassBadge(
                value: d.value, label: d.label, color: d.color),
          ),
        ),
      ),
    );
  }
}

/// Frosted nutrition badge rendered into the story canvas.
class _GlassBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _GlassBadge(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.8), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}
