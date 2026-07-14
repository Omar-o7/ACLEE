import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../main.dart' show supabaseAnonKey;
import '../../services/supabase_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/glass_card.dart';
import 'signup_screen.dart';

/// ACLEE sign-in — centered glass form, real error messages,
/// keyboard-safe & responsive.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _mapError(Object e, String Function(String, [Map<String, Object>?]) t) {
    if (supabaseAnonKey.contains('ضع_مفتاح')) return t('err_key_missing');
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login credentials')) {
        return t('err_invalid_credentials');
      }
      if (m.contains('email not confirmed')) {
        return t('err_email_not_confirmed');
      }
      return e.message; // اعرض رسالة Supabase الحقيقية
    }
    final s = e.toString().toLowerCase();
    if (s.contains('socket') || s.contains('network') || s.contains('host')) {
      return t('err_network');
    }
    return t('error_generic');
  }

  Future<void> _submit() async {
    final t = context.read<LanguageProvider>().t;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance
          .signIn(_email.text.trim(), _password.text);
      // نجاح — _AuthGate سينقل تلقائياً
    } catch (e) {
      if (mounted) setState(() => _error = _mapError(e, t));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.lg * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language toggle — top end
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: GestureDetector(
                        onTap: () =>
                            lang.setLang(lang.isArabic ? 'en' : 'ar'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(lang.isArabic ? 'EN' : 'عربي',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // Logo
                    FadeUp(
                      index: 0,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.glow,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 38, color: AppColors.background),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeUp(
                      index: 1,
                      child: Column(
                        children: [
                          Text(t('login_title'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: AppSpacing.xs + 2),
                          Text(t('login_subtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // Glass form
                    FadeUp(
                      index: 2,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: GlassCard(
                          premiumShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: t('email'),
                                  prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                      size: 19,
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [
                                  AutofillHints.password
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: t('password'),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 19,
                                      color: AppColors.mutedForeground),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                        size: 19,
                                        color:
                                            AppColors.mutedForeground),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                              ),

                              // Real error message
                              AnimatedSize(
                                duration: AppMotion.base,
                                curve: AppMotion.easeOutExpo,
                                child: _error == null
                                    ? const SizedBox(
                                        width: double.infinity)
                                    : Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                            top: AppSpacing.md),
                                        padding: const EdgeInsets.all(
                                            AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: AppColors.destructive
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.md),
                                          border: Border.all(
                                              color: AppColors.destructive
                                                  .withValues(
                                                      alpha: 0.35)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .error_outline_rounded,
                                                size: 16,
                                                color: AppColors
                                                    .destructive),
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(_error!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      height: 1.45,
                                                      color: AppColors
                                                          .destructive,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600)),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Gradient sign-in button
                              GestureDetector(
                                onTap: _loading ? null : _submit,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientPrimary,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                    boxShadow:
                                        _loading ? null : AppShadows.glow,
                                  ),
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: AppColors
                                                      .background))
                                      : Text(t('sign_in'),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  AppColors.background)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FadeUp(
                      index: 3,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen())),
                        child: Text.rich(
                          TextSpan(
                            text: '${t('no_account')} ',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground),
                            children: [
                              TextSpan(
                                text: t('sign_up'),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
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
      ),
    );
  }
}
