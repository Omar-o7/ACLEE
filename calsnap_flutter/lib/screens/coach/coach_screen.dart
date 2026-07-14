import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_modals.dart';

/// ACLEE Coach — glass bubbles, floating pill composer,
/// animated typing dots. Calm, alive, premium.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _Msg {
  final String role;
  final String content;
  _Msg(this.role, this.content);
}

class _CoachScreenState extends State<CoachScreen> {
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _typing = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final can = _input.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await SupabaseService.instance.coachHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(rows
              .map((r) => _Msg(r['role'] as String, r['content'] as String)));
      });
      _jumpToEnd();
    } catch (_) {}
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: AppMotion.slow, curve: AppMotion.easeOutExpo);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _typing) return;
    _input.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Msg('user', text));
      _typing = true;
    });
    _jumpToEnd();
    try {
      final history = _messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList()
          .cast<Map<String, String>>();
      final reply =
          await SupabaseService.instance.sendCoachMessage(text, history);
      if (!mounted) return;
      setState(() => _messages.add(_Msg('assistant', reply)));
    } catch (_) {
      if (!mounted) return;
      final t = context.read<LanguageProvider>().t;
      setState(() => _messages.add(_Msg('assistant', t('error_generic'))));
    } finally {
      if (mounted) setState(() => _typing = false);
      _jumpToEnd();
    }
  }

  Future<void> _confirmClear() async {
    final t = context.read<LanguageProvider>().t;
    final ok = await showGlassDialog<bool>(
      context,
      title: t('clear_chat'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel'),
                style: const TextStyle(color: AppColors.mutedForeground))),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete'),
                style: const TextStyle(color: AppColors.destructive))),
      ],
    );
    if (ok == true) {
      await SupabaseService.instance.clearCoachChat();
      if (mounted) setState(() => _messages.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page,
                    AppSpacing.md, AppSpacing.page, AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.glow,
                      ),
                      child: const Icon(Icons.spa_rounded,
                          size: 21, color: AppColors.background),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('coach_title'),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2)),
                          Text(t('coach_subtitle'),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    if (_messages.isNotEmpty)
                      GestureDetector(
                        onTap: _confirmClear,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.delete_sweep_outlined,
                              size: 17, color: AppColors.mutedForeground),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Messages ──
              Expanded(
                child: _messages.isEmpty && !_typing
                    ? _emptyState(t)
                    : ListView.builder(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.page,
                            AppSpacing.sm, AppSpacing.page, AppSpacing.md),
                        itemCount: _messages.length + (_typing ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) {
                            return const Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _TypingBubble(),
                            );
                          }
                          return _bubble(_messages[i]);
                        },
                      ),
              ),

              // ── Floating pill composer ──
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0,
                    AppSpacing.page, AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                          start: AppSpacing.xl, end: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: GradientBoxBorder(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.03),
                            ],
                          ),
                        ),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              focusNode: _focus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: t('coach_placeholder'),
                                hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.mutedForeground),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AnimatedScale(
                            duration: AppMotion.base,
                            curve: AppMotion.easeOutBack,
                            scale: _canSend ? 1 : 0.88,
                            child: AnimatedOpacity(
                              duration: AppMotion.base,
                              opacity: _canSend ? 1 : 0.45,
                              child: GestureDetector(
                                onTap: _send,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientPrimary,
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        _canSend ? AppShadows.glow : null,
                                  ),
                                  child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 20,
                                      color: AppColors.background),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String Function(String, [Map<String, Object>?]) t) {
    final quick = [
      t('quick_week'),
      t('quick_plan'),
      t('quick_today'),
      t('quick_weight'),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeUp(
              index: 0,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(Icons.spa_rounded,
                    size: 38, color: AppColors.background),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeUp(
              index: 1,
              child: Text(t('coach_subtitle'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground)),
            ),
            const SizedBox(height: AppSpacing.section),
            FadeUp(
              index: 2,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: quick
                    .map((q) => GestureDetector(
                          onTap: () => _send(q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(q,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.gradientPrimary : null,
          color: isUser ? null : AppColors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(AppRadius.lg),
            topEnd: const Radius.circular(AppRadius.lg),
            bottomStart: Radius.circular(isUser ? AppRadius.lg : AppRadius.xs),
            bottomEnd: Radius.circular(isUser ? AppRadius.xs : AppRadius.lg),
          ),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: isUser ? AppShadows.glow : null,
        ),
        child: Text(
          m.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser ? AppColors.background : AppColors.foreground,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Three softly bouncing dots — the coach is thinking.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.lg),
          topEnd: Radius.circular(AppRadius.lg),
          bottomStart: Radius.circular(AppRadius.xs),
          bottomEnd: Radius.circular(AppRadius.lg),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.18) % 1.0;
            final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Padding(
              padding: EdgeInsetsDirectional.only(end: i < 2 ? 5 : 0),
              child: Transform.translate(
                offset: Offset(0, -3.5 * wave),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mutedForeground
                        .withValues(alpha: 0.45 + 0.55 * wave),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
