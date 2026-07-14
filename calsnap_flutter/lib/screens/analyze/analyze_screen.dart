import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'scan_view.dart';
import 'result_view.dart';

enum AnalyzeStage { camera, scanning, result, logged }

/// ACLEE Camera & AI Scan — the signature experience.
/// Live camera → capture → intelligent scan → luxurious result.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});
  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  bool _cameraReady = false;
  bool _torch = false;
  final _picker = ImagePicker();

  AnalyzeStage _stage = AnalyzeStage.camera;
  Uint8List? _imageBytes;
  String _mime = 'jpeg';
  NutritionResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final ctrl = CameraController(back, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _camera = ctrl;
        _cameraReady = true;
      });
    } catch (_) {
      // No camera / permission denied → gallery-only mode.
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _cameraReady = false;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    final cam = _camera;
    if (cam == null) return;
    _torch = !_torch;
    await cam.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
    HapticFeedback.selectionClick();
    setState(() {});
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    HapticFeedback.mediumImpact();
    try {
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();
      if (_torch) await cam.setFlashMode(FlashMode.off);
      _startScan(bytes, 'jpeg');
    } catch (_) {}
  }

  Future<void> _pickGallery() async {
    final x = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    _startScan(
        bytes, x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg');
  }

  void _startScan(Uint8List bytes, String mime) {
    setState(() {
      _imageBytes = bytes;
      _mime = mime;
      _stage = AnalyzeStage.scanning;
    });
  }

  Future<NutritionResult> _analyze() =>
      SupabaseService.instance.analyzeFood(_imageBytes!, 'image/$_mime');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: AppMotion.slow,
        switchInCurve: AppMotion.easeOutExpo,
        child: switch (_stage) {
          AnalyzeStage.camera => _CameraStage(
              key: const ValueKey('camera'),
              controller: _cameraReady ? _camera : null,
              torch: _torch,
              onTorch: _toggleTorch,
              onCapture: _capture,
              onGallery: _pickGallery,
              onClose: () => Navigator.of(context).pop(),
            ),
          AnalyzeStage.scanning => ScanView(
              key: const ValueKey('scan'),
              imageBytes: _imageBytes!,
              analyze: _analyze,
              onDone: (r) => setState(() {
                _result = r;
                _stage = AnalyzeStage.result;
              }),
              onError: (msg) {
                setState(() => _stage = AnalyzeStage.camera);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(msg)));
              },
            ),
          AnalyzeStage.result => ResultView(
              key: const ValueKey('result'),
              imageBytes: _imageBytes!,
              mime: _mime,
              result: _result!,
              onSaved: () => setState(() => _stage = AnalyzeStage.logged),
              onRetake: () => setState(() {
                _imageBytes = null;
                _result = null;
                _stage = AnalyzeStage.camera;
              }),
            ),
          AnalyzeStage.logged => LoggedView(
              key: const ValueKey('logged'),
              imageBytes: _imageBytes,
              result: _result,
              onHome: () => Navigator.of(context).pop(),
              onAgain: () => setState(() {
                _imageBytes = null;
                _result = null;
                _stage = AnalyzeStage.camera;
              }),
            ),
        },
      ),
    );
  }
}

/// ── Live camera: minimal, food-focused, floating glass controls ──
class _CameraStage extends StatelessWidget {
  final CameraController? controller;
  final bool torch;
  final VoidCallback onTorch, onCapture, onGallery, onClose;

  const _CameraStage({
    super.key,
    required this.controller,
    required this.torch,
    required this.onTorch,
    required this.onCapture,
    required this.onGallery,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final cam = controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview fills the display
        if (cam != null && cam.value.isInitialized)
          _FullPreview(controller: cam)
        else
          Container(
            color: const Color(0xFF0B0D16),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📷', style: TextStyle(fontSize: 44)),
                const SizedBox(height: AppSpacing.md),
                Text(t('upload_prompt'),
                    style: const TextStyle(
                        color: AppColors.mutedForeground, fontSize: 13)),
              ],
            ),
          ),

        // Soft vignette for control legibility
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.18, 0.75, 1],
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xB3000000),
                ],
              ),
            ),
          ),
        ),

        // Top bar: close / flash
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _GlassIconButton(icon: Icons.close_rounded, onTap: onClose),
                const Spacer(),
                _GlassIconButton(
                  icon: torch
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  active: torch,
                  onTap: onTorch,
                ),
              ],
            ),
          ),
        ),

        // Bottom controls: gallery / shutter
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.section),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GlassIconButton(
                      icon: Icons.photo_library_rounded, onTap: onGallery),
                  const SizedBox(width: 44),
                  _Shutter(onTap: onCapture),
                  const SizedBox(width: 44),
                  const SizedBox(width: 44, height: 44), // optical balance
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullPreview extends StatelessWidget {
  final CameraController controller;
  const _FullPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale =
        1 / (controller.value.aspectRatio * size.aspectRatio);
    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _Shutter extends StatefulWidget {
  final VoidCallback onTap;
  const _Shutter({required this.onTap});
  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: -4),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _GlassIconButton(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.primary.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.35),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon,
            size: 20,
            color: active ? AppColors.background : Colors.white),
      ),
    );
  }
}
